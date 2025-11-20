import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint, kDebugMode;

/// Provider for managing user settings with real-time Firestore syncing
class UserSettingsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _settingsSubscription;
  String? _userId;

  // User Settings State
  bool _onboardingCompleted = false;
  String _theme = 'light';
  bool _notificationsEnabled = true;
  String _defaultNoteType = 'note';
  int _noteCount = 0;
  int _archivedCount = 0;

  // Getters
  bool get onboardingCompleted => _onboardingCompleted;
  String get theme => _theme;
  bool get notificationsEnabled => _notificationsEnabled;
  String get defaultNoteType => _defaultNoteType;
  int get noteCount => _noteCount;
  int get archivedCount => _archivedCount;
  bool get isDarkMode => _theme == 'dark';
  String? get userId => _userId;

  /// Start listening to user settings changes in Firestore
  Future<void> startListening(String userId) async {
    if (_userId == userId && _settingsSubscription != null) return;

    _userId = userId;
    await _settingsSubscription?.cancel();

    _settingsSubscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen(
      (snapshot) {
        // Check if user is still logged in before processing
        if (_userId == null) {
          // User logged out, ignore this snapshot
          return;
        }
        
        if (snapshot.exists) {
          _updateFromFirestore(snapshot.data()!);
          notifyListeners();
        }
      },
      onError: (error) {
        // Ignore permission errors if user is logged out (userId is null)
        if (_userId == null) {
          // User logged out, silently ignore
          return;
        }
        
        if (kDebugMode) {
          debugPrint('User settings stream error: $error');
        }
      },
    );
  }

  /// Stop listening to changes
  Future<void> stopListening() async {
    // Set userId to null first to prevent permission errors in listener callbacks
    _userId = null;
    
    // Cancel subscription
    await _settingsSubscription?.cancel();
    _settingsSubscription = null;
  }

  /// Update local state from Firestore data
  void _updateFromFirestore(Map<String, dynamic> data) {
    _onboardingCompleted = data['onboardingCompleted'] as bool? ?? false;
    
    // Handle both old and new data structures
    if (data['preferences'] != null) {
      final prefs = data['preferences'] as Map<String, dynamic>;
      _theme = prefs['theme'] as String? ?? 'light';
      _defaultNoteType = prefs['defaultNoteType'] as String? ?? 'note';
      
      if (prefs['notifications'] != null) {
        final notif = prefs['notifications'] as Map<String, dynamic>;
        _notificationsEnabled = notif['enabled'] as bool? ?? true;
      }
    }
    
    // Handle notifications at root level (for backward compatibility)
    if (data['notifications'] != null) {
      final notif = data['notifications'] as Map<String, dynamic>;
      _notificationsEnabled = notif['enabled'] as bool? ?? true;
      if (notif['theme'] != null) {
        _theme = notif['theme'] as String? ?? 'light';
      }
    }
    
    if (data['stats'] != null) {
      final stats = data['stats'] as Map<String, dynamic>;
      _noteCount = stats['noteCount'] as int? ?? 0;
      _archivedCount = stats['archivedCount'] as int? ?? 0;
    }
  }

  /// Update theme preference in Firestore
  /// Supports both old structure (notifications.theme) and new structure (preferences.theme)
  Future<bool> updateTheme(String theme) async {
    if (_userId == null) return false;
    if (_theme == theme) return true; // No change needed

    try {
      // Update both structures for compatibility
      await _firestore.collection('users').doc(_userId).update({
        'preferences.theme': theme,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _theme = theme;
      notifyListeners();
      if (kDebugMode) {
        debugPrint('✓ Theme updated to $theme in Firestore');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('✗ Failed to update theme: $e');
      }
      return false;
    }
  }

  /// Toggle theme (light/dark)
  Future<bool> toggleTheme() async {
    final newTheme = _theme == 'light' ? 'dark' : 'light';
    return await updateTheme(newTheme);
  }

  /// Update notifications enabled/disabled
  /// Supports both old structure (notifications.enabled) and new structure (preferences.notifications.enabled)
  Future<bool> updateNotificationsEnabled(bool enabled) async {
    if (_userId == null) return false;
    if (_notificationsEnabled == enabled) return true; // No change needed

    try {
      // Update both structures for compatibility
      await _firestore.collection('users').doc(_userId).update({
        'preferences.notifications.enabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _notificationsEnabled = enabled;
      notifyListeners();
      if (kDebugMode) {
        debugPrint('✓ Notifications updated to $enabled in Firestore');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('✗ Failed to update notifications: $e');
      }
      return false;
    }
  }

  /// Mark onboarding as completed
  Future<bool> completeOnboarding() async {
    if (_userId == null) return false;
    if (_onboardingCompleted) return true; // Already completed

    try {
      await _firestore.collection('users').doc(_userId).update({
        'onboardingCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _onboardingCompleted = true;
      notifyListeners();
      if (kDebugMode) {
        debugPrint('✓ Onboarding marked as completed in Firestore');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('✗ Failed to complete onboarding: $e');
      }
      return false;
    }
  }

  /// Update note statistics (called by NotesProvider)
  Future<void> updateNoteStats({
    int? noteCount,
    int? archivedCount,
  }) async {
    if (_userId == null) return;

    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (noteCount != null) {
        updates['stats.noteCount'] = noteCount;
        _noteCount = noteCount;
      }

      if (archivedCount != null) {
        updates['stats.archivedCount'] = archivedCount;
        _archivedCount = archivedCount;
      }

      if (updates.length > 1) {
        // Only update if there are actual changes
        await _firestore.collection('users').doc(_userId).update(updates);
        notifyListeners();
        if (kDebugMode) {
          debugPrint('✓ Note stats updated in Firestore');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('✗ Failed to update note stats: $e');
      }
    }
  }

  /// Recalculate and update note stats from actual notes
  Future<void> recalculateNoteStats(String userId) async {
    try {
      // Get active notes count
      final activeNotesSnapshot = await _firestore
          .collection('notes')
          .where('ownerId', isEqualTo: userId)
          .where('archived', isEqualTo: false)
          .where('deletedAt', isNull: true)
          .get();

      // Get archived notes count
      final archivedNotesSnapshot = await _firestore
          .collection('notes')
          .where('ownerId', isEqualTo: userId)
          .where('archived', isEqualTo: true)
          .where('deletedAt', isNull: true)
          .get();

      await updateNoteStats(
        noteCount: activeNotesSnapshot.docs.length,
        archivedCount: archivedNotesSnapshot.docs.length,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('✗ Failed to recalculate note stats: $e');
      }
    }
  }

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    super.dispose();
  }
}

