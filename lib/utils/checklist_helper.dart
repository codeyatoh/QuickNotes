import '../models/note_model.dart';

/// Helper class for managing checklist operations.
/// 
/// This class provides static methods for common checklist operations
/// to avoid code duplication in create and edit note screens.
class ChecklistHelper {
  /// Adds a new empty checklist item to the list
  static List<ChecklistItem> addChecklistItem(List<ChecklistItem> checklist) {
    return [
      ...checklist,
      ChecklistItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '',
        completed: false,
      ),
    ];
  }

  /// Updates the text of a checklist item with the given id
  static List<ChecklistItem> updateChecklistItem(
    List<ChecklistItem> checklist,
    String id,
    String text,
  ) {
    return checklist.map((item) {
      if (item.id == id) {
        return item.copyWith(text: text);
      }
      return item;
    }).toList();
  }

  /// Deletes a checklist item with the given id
  static List<ChecklistItem> deleteChecklistItem(
    List<ChecklistItem> checklist,
    String id,
  ) {
    return checklist.where((item) => item.id != id).toList();
  }

  /// Toggles the completion status of a checklist item with the given id
  static List<ChecklistItem> toggleChecklistItem(
    List<ChecklistItem> checklist,
    String id,
  ) {
    return checklist.map((item) {
      if (item.id == id) {
        return item.copyWith(completed: !item.completed);
      }
      return item;
    }).toList();
  }
}
