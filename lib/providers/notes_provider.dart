import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../models/tag_model.dart';
import '../utils/async_util.dart';
import 'user_settings_provider.dart';

class NotesProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Note> _notes = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notesSubscription;

  TagColor? _activeTag;
  String? _ownerId;
  bool _isLoading = false;
  UserSettingsProvider? _userSettingsProvider;

  List<Note> get notes => List.unmodifiable(_notes);
  TagColor? get activeTag => _activeTag;
  bool get isLoading => _isLoading;
  String? get ownerId => _ownerId;

  /// Set UserSettingsProvider for stats updates
  void setUserSettingsProvider(UserSettingsProvider? provider) {
    _userSettingsProvider = provider;
  }

  /// Update note statistics in UserSettingsProvider
  Future<void> _updateNoteStats() async {
    if (_userSettingsProvider == null || _ownerId == null) return;

    final activeCount = _notes.where((n) => !n.archived && n.deletedAt == null).length;
    final archivedCount = _notes.where((n) => n.archived && n.deletedAt == null).length;

    await _userSettingsProvider!.updateNoteStats(
      noteCount: activeCount,
      archivedCount: archivedCount,
    );
  }

  void setActiveTag(TagColor? tag) {
    _activeTag = tag;
    notifyListeners();
  }

  Future<void> startListening(String ownerId) async {
    if (_ownerId == ownerId && _notesSubscription != null) return;

    _ownerId = ownerId;
    _isLoading = true;
    notifyListeners();

    await _notesSubscription?.cancel();

    // Query without orderBy to avoid requiring an index
    // We'll sort client-side instead
    _notesSubscription = _firestore
        .collection('notes')
        .where('ownerId', isEqualTo: ownerId)
        .where('deletedAt', isNull: true)
        .snapshots()
        .listen(
      (snapshot) {
        // Check if user is still logged in before processing
        if (_ownerId == null) {
          // User logged out, ignore this snapshot
          return;
        }
        
        try {
          // Convert to notes and sort by updatedAt descending (most recent first)
          final notesList = <Note>[];
          
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              final note = Note.fromMap(data);
              notesList.add(note);
            } catch (e) {
              if (kDebugMode) {
                debugPrint('Error parsing note document ${doc.id}: $e');
              }
              // Continue with other documents
            }
          }
          
          notesList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          
          // Only update if list actually changed (optimization to avoid unnecessary rebuilds)
          final notesChanged = _notes.length != notesList.length ||
              !_notes.every((note) => notesList.any((n) => n.id == note.id && n.updatedAt == note.updatedAt));
          
          if (notesChanged) {
            _notes
              ..clear()
              ..addAll(notesList);
            _isLoading = false;
            notifyListeners();
            
            // Update note stats when notes change
            unawaited(_updateNoteStats());
          } else {
            // Still update loading state even if notes didn't change
            if (_isLoading) {
              _isLoading = false;
              notifyListeners();
            }
          }
        } catch (e) {
          // Ignore errors if user logged out
          if (_ownerId == null) {
            return;
          }
          
          if (kDebugMode) {
            debugPrint('Error processing notes snapshot: $e');
          }
          _isLoading = false;
          notifyListeners();
        }
      },
      onError: (error) {
        // Ignore permission errors if user is logged out (ownerId is null)
        if (_ownerId == null) {
          // User logged out, silently ignore
          return;
        }
        
        if (kDebugMode) {
          debugPrint('Notes stream error: $error');
        }
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> stopListening() async {
    // Set ownerId to null first to prevent permission errors in listener callbacks
    _ownerId = null;
    _activeTag = null;
    
    // Cancel subscription and clear data
    await _notesSubscription?.cancel();
    _notesSubscription = null;
    _notes.clear();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> clear() => stopListening();

  Future<void> addNote(
    String title,
    String? content,
    TagColor tagColor,
    List<ChecklistItem> checklist,
  ) async {
    if (_ownerId == null) return;

    final docRef = _firestore.collection('notes').doc();
    final type = checklist.isNotEmpty ? 'checklist' : 'note';
    final now = DateTime.now();

    // Optimistic UI update - add note immediately to local list
    final optimisticNote = Note(
      id: docRef.id,
      ownerId: _ownerId!,
      title: title,
      content: content,
      checklist: checklist,
      tagColor: tagColor,
      favorite: false,
      favoriteAt: null,
      archived: false,
      archivedAt: null,
      deletedAt: null,
      reminderAt: null,
      pinWeight: 0,
      createdAt: now,
      updatedAt: now,
    );

    // Add to local list immediately (optimistic update)
    _notes.insert(0, optimisticNote); // Insert at beginning (newest first)
    notifyListeners();

    // Save to Firestore in background
    try {
      await docRef.set({
        'id': docRef.id,
        'ownerId': _ownerId,
        'title': title,
        'type': type,
        'content': content,
        'checklist': checklist.map((item) => item.toMap()).toList(),
        'color': tagColor.hex,
        'favorite': false,
        'favoriteAt': null,
        'archived': false,
        'archivedAt': null,
        'deletedAt': null,
        'reminderAt': null,
        'pinWeight': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'checklistSummary': {
          'total': checklist.length,
          'completed': checklist.where((item) => item.completed).length,
        },
      });

      // Update note stats
      unawaited(_updateNoteStats());
    } catch (e) {
      // If Firestore save fails, remove the optimistic note
      _notes.removeWhere((note) => note.id == docRef.id);
    notifyListeners();
      rethrow;
    }
    // Note: The real-time listener will update the note with server timestamp when it arrives
  }

  Future<void> updateNote(
    String id, {
    String? title,
    String? content,
    TagColor? tagColor,
    List<ChecklistItem>? checklist,
    bool? archived,
    bool? favorite,
    DateTime? reminderAt,
    int? pinWeight,
  }) async {
    // Optimistic UI update - update local note immediately
    final noteIndex = _notes.indexWhere((n) => n.id == id);
    Note? oldNote;
    if (noteIndex != -1) {
      oldNote = _notes[noteIndex];
      final updatedNote = oldNote.copyWith(
        title: title ?? oldNote.title,
        content: content,
        tagColor: tagColor ?? oldNote.tagColor,
        checklist: checklist ?? oldNote.checklist,
        archived: archived ?? oldNote.archived,
        archivedAt: archived == true ? DateTime.now() : (archived == false ? null : oldNote.archivedAt),
        favorite: favorite ?? oldNote.favorite,
        favoriteAt: favorite == true ? DateTime.now() : (favorite == false ? null : oldNote.favoriteAt),
        reminderAt: reminderAt ?? oldNote.reminderAt,
        pinWeight: pinWeight ?? oldNote.pinWeight,
        updatedAt: DateTime.now(), // Optimistic timestamp
      );
      
      // Update in local list immediately
      _notes[noteIndex] = updatedNote;
      // Re-sort to maintain order
      _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      notifyListeners();
    }

    final Map<String, dynamic> updates = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (title != null) updates['title'] = title;
    // Update content when editing (always provided from edit screen)
    // If converting to checklist, clear content; otherwise update with provided value
    if (checklist != null && checklist.isNotEmpty) {
      // Converting to checklist - clear content
      updates['content'] = null;
    } else if (title != null) {
      // When title is updated, also update content (edit screen always provides it)
      // content can be null to clear it
      updates['content'] = content;
    } else if (content != null) {
      // Content explicitly provided without title update
      updates['content'] = content;
    }
    if (tagColor != null) updates['color'] = tagColor.hex;
    if (checklist != null) {
      updates['checklist'] = checklist.map((item) => item.toMap()).toList();
      updates['type'] = checklist.isNotEmpty ? 'checklist' : 'note';
      updates['checklistSummary'] = {
        'total': checklist.length,
        'completed': checklist.where((item) => item.completed).length,
      };
    }
    if (archived != null) {
      updates['archived'] = archived;
      updates['archivedAt'] =
          archived ? FieldValue.serverTimestamp() : null;
  }
    if (favorite != null) {
      updates['favorite'] = favorite;
      updates['favoriteAt'] =
          favorite ? FieldValue.serverTimestamp() : null;
    }
    if (reminderAt != null) {
      updates['reminderAt'] = Timestamp.fromDate(reminderAt);
    }
    if (pinWeight != null) {
      updates['pinWeight'] = pinWeight;
    }

    try {
      await _firestore.collection('notes').doc(id).update(updates);
      
      // Update note stats if archive status changed
      if (archived != null) {
        unawaited(_updateNoteStats());
      }
    } catch (e) {
      // If Firestore update fails, revert optimistic update
      if (oldNote != null && noteIndex != -1) {
        _notes[noteIndex] = oldNote;
        _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      notifyListeners();
    }
      rethrow;
    }
    // Note: The real-time listener will update the note with server timestamp when it arrives
  }

  Future<void> deleteNote(String id) async {
    // Optimistic UI update - remove from local list immediately
    final noteIndex = _notes.indexWhere((n) => n.id == id);
    Note? oldNote;
    if (noteIndex != -1) {
      oldNote = _notes[noteIndex];
      _notes.removeAt(noteIndex);
    notifyListeners();
  }

    try {
      await _firestore.collection('notes').doc(id).update({
        'deletedAt': FieldValue.serverTimestamp(),
      });
      
      // Update note stats
      unawaited(_updateNoteStats());
    } catch (e) {
      // If Firestore delete fails, restore the note
      if (oldNote != null && noteIndex != -1) {
        _notes.insert(noteIndex, oldNote);
        _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      notifyListeners();
    }
      rethrow;
    }
  }

  Future<void> archiveNote(String id) async {
    // Optimistic UI update
    final noteIndex = _notes.indexWhere((n) => n.id == id);
    Note? oldNote;
    if (noteIndex != -1) {
      oldNote = _notes[noteIndex];
      _notes[noteIndex] = oldNote.copyWith(
        archived: true,
        archivedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      notifyListeners();
    }
    
    try {
      await _firestore.collection('notes').doc(id).update({
        'archived': true,
        'archivedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update note stats
      unawaited(_updateNoteStats());
    } catch (e) {
      // If Firestore update fails, revert optimistic update
      if (oldNote != null && noteIndex != -1) {
        _notes[noteIndex] = oldNote;
        _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      notifyListeners();
    }
      rethrow;
    }
  }

  Future<void> restoreNote(String id) async {
    // Optimistic UI update
    final noteIndex = _notes.indexWhere((n) => n.id == id);
    Note? oldNote;
    if (noteIndex != -1) {
      oldNote = _notes[noteIndex];
      _notes[noteIndex] = oldNote.copyWith(
        archived: false,
        archivedAt: null,
        updatedAt: DateTime.now(),
      );
      _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      notifyListeners();
    }
    
    try {
      await _firestore.collection('notes').doc(id).update({
        'archived': false,
        'archivedAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update note stats
      unawaited(_updateNoteStats());
    } catch (e) {
      // If Firestore update fails, revert optimistic update
      if (oldNote != null && noteIndex != -1) {
        _notes[noteIndex] = oldNote;
        _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> toggleFavorite(String id) async {
    final noteIndex = _notes.indexWhere((n) => n.id == id);
    if (noteIndex == -1) return;
    
    final note = _notes[noteIndex];
    final isFavorite = !note.favorite;
    final oldNote = note;
    
    // Optimistic UI update
    _notes[noteIndex] = note.copyWith(
      favorite: isFavorite,
      favoriteAt: isFavorite ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );
    _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
    
    try {
      await _firestore.collection('notes').doc(id).update({
        'favorite': isFavorite,
        'favoriteAt':
            isFavorite ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        debugPrint('✓ Favorite status updated in Firestore: $isFavorite');
      }
    } catch (e) {
      // If Firestore update fails, revert optimistic update
      _notes[noteIndex] = oldNote;
      _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      notifyListeners();
      if (kDebugMode) {
        debugPrint('✗ Failed to update favorite status: $e');
      }
      rethrow;
    }
  }

  Note? getNote(String id) {
    try {
      return _notes.firstWhere((note) => note.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    super.dispose();
  }
}
