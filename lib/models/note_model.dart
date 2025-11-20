import 'package:cloud_firestore/cloud_firestore.dart';
import 'tag_model.dart';

class ChecklistItem {
  final String id;
  final String text;
  final bool completed;

  ChecklistItem({
    required this.id,
    required this.text,
    this.completed = false,
  });

  ChecklistItem copyWith({
    String? id,
    String? text,
    bool? completed,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'completed': completed,
    };
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] as String? ?? '',
      text: map['text'] as String? ?? '',
      completed: map['completed'] as bool? ?? false,
    );
  }
}

class Note {
  final String id;
  final String ownerId;
  final String title;
  final String? content;
  final List<ChecklistItem> checklist;
  final TagColor tagColor;
  final bool favorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool archived;
  final DateTime? archivedAt;
  final DateTime? favoriteAt;
  final DateTime? deletedAt;
  final DateTime? reminderAt;
  final int? pinWeight;

  Note({
    required this.id,
    required this.ownerId,
    required this.title,
    this.content,
    this.checklist = const [],
    required this.tagColor,
    this.favorite = false,
    required this.createdAt,
    required this.updatedAt,
    this.archived = false,
    this.archivedAt,
    this.favoriteAt,
    this.deletedAt,
    this.reminderAt,
    this.pinWeight,
  });

  Note copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? content,
    List<ChecklistItem>? checklist,
    TagColor? tagColor,
    bool? favorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? archived,
    DateTime? archivedAt,
    DateTime? favoriteAt,
    DateTime? deletedAt,
    DateTime? reminderAt,
    int? pinWeight,
  }) {
    return Note(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      content: content ?? this.content,
      checklist: checklist ?? this.checklist,
      tagColor: tagColor ?? this.tagColor,
      favorite: favorite ?? this.favorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archived: archived ?? this.archived,
      archivedAt: archivedAt ?? this.archivedAt,
      favoriteAt: favoriteAt ?? this.favoriteAt,
      deletedAt: deletedAt ?? this.deletedAt,
      reminderAt: reminderAt ?? this.reminderAt,
      pinWeight: pinWeight ?? this.pinWeight,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'title': title,
      'type': checklist.isNotEmpty ? 'checklist' : 'note',
      'content': content,
      'checklist': checklist.map((item) => item.toMap()).toList(),
      'color': tagColor.hex,
      'favorite': favorite,
      'favoriteAt': favoriteAt?.toIso8601String(),
      'archived': archived,
      'archivedAt': archivedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'reminderAt': reminderAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'pinWeight': pinWeight,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return null;
    }

    final checklistData = (map['checklist'] as List<dynamic>? ?? [])
        .map((item) {
          if (item is Map<String, dynamic>) {
            return ChecklistItem.fromMap(item);
          }
          if (item is Map) {
            return ChecklistItem.fromMap(Map<String, dynamic>.from(item));
          }
          return ChecklistItem(id: '', text: '');
        })
        .toList();

    final createdAt = _parseDate(map['createdAt']) ?? DateTime.now();
    final updatedAt = _parseDate(map['updatedAt']) ?? createdAt;

    return Note(
      id: map['id'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      content: map['content'] as String?,
      checklist: checklistData,
      tagColor: _tagColorFromColorString(map['color'] as String?),
      favorite: map['favorite'] as bool? ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
      archived: map['archived'] as bool? ?? false,
      archivedAt: _parseDate(map['archivedAt']),
      favoriteAt: _parseDate(map['favoriteAt']),
      deletedAt: _parseDate(map['deletedAt']),
      reminderAt: _parseDate(map['reminderAt']),
      pinWeight: map['pinWeight'] as int?,
    );
  }

  static TagColor _tagColorFromColorString(String? value) {
    if (value == null) return TagColor.blue;
    try {
      return TagColor.values.firstWhere(
        (tag) => tag.hex.toLowerCase() == value.toLowerCase(),
      );
    } catch (_) {
      return TagColor.blue;
    }
  }
}

