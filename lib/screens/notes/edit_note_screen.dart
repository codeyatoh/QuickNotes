import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/tag_selector.dart';
import '../../widgets/checklist_item.dart';
import '../../providers/notes_provider.dart';
import '../../models/tag_model.dart';
import '../../models/note_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/toast_util.dart';
import '../../utils/navigation_util.dart';  
import '../../utils/checklist_helper.dart';

class EditNoteScreen extends StatefulWidget {
  final String noteId;

  const EditNoteScreen({super.key, required this.noteId});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late TagColor _tagColor;
  late bool _isChecklistMode;
  late List<ChecklistItem> _checklist;
  Note? _note;

  @override
  void initState() {
    super.initState();
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    _note = notesProvider.getNote(widget.noteId);
    
    if (_note != null) {
      _titleController = TextEditingController(text: _note!.title);
      _contentController = TextEditingController(text: _note!.content ?? '');
      _tagColor = _note!.tagColor;
      _checklist = List.from(_note!.checklist);
      _isChecklistMode = _note!.checklist.isNotEmpty;
    } else {
      _titleController = TextEditingController();
      _contentController = TextEditingController();
      _tagColor = TagColor.blue;
      _checklist = [];
      _isChecklistMode = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_titleController.text.trim().isEmpty || _note == null) return;

    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    
    try {
      await notesProvider.updateNote(
      _note!.id,
      title: _titleController.text.trim(),
      content: _contentController.text.trim().isEmpty
          ? null
          : _contentController.text.trim(),
      tagColor: _tagColor,
      checklist: _isChecklistMode ? _checklist : [],
    );

      if (mounted) {
        // Get root navigator context before navigating (widget will be unmounted after navigation)
        final rootNavigator = Navigator.of(context, rootNavigator: true);
        final rootContext = rootNavigator.context;
        
        // Navigate immediately for faster UX (don't wait for popup)
        Navigator.of(context).pop();
        
        // Show success message on home screen after navigation
        Future.delayed(const Duration(milliseconds: 300), () {
          // Use root context which remains valid even after widget unmounts
          try {
            ToastUtil.showSuccess(
              rootContext,
              title: 'Note Updated!',
              message: 'Your changes have been saved successfully.',
              buttonText: 'Done',
              duration: const Duration(seconds: 2),
            );
          } catch (e) {
            // Silently fail if context is no longer valid
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.showError(
          context,
          title: 'Error',
          message: 'Failed to update note. Please try again.',
        );
      }
    }
  }

  void _addChecklistItem() {
    setState(() {
      _checklist = ChecklistHelper.addChecklistItem(_checklist);
    });
  }

  void _updateChecklistItem(String id, String text) {
    setState(() {
      _checklist = ChecklistHelper.updateChecklistItem(_checklist, id, text);
    });
  }

  void _deleteChecklistItem(String id) {
    setState(() {
      _checklist = ChecklistHelper.deleteChecklistItem(_checklist, id);
    });
  }

  void _toggleChecklistItem(String id) {
    setState(() {
      _checklist = ChecklistHelper.toggleChecklistItem(_checklist, id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_note == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          NavigationUtil.safePopOrNavigate(context, '/home');
        }
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => NavigationUtil.safePopOrNavigate(context, '/home'),
        ),
        actions: [
          TextButton(
            onPressed: _handleSave,
            child: Text(
              'Save',
              style: TextStyle(
                color: _titleController.text.trim().isEmpty
                    ? Colors.grey
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TagSelector(
                  selectedTag: _tagColor,
                  onChanged: (tag) {
                    setState(() {
                      _tagColor = tag;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isChecklistMode = false;
                        });
                      },
                      icon: const Icon(Icons.format_align_left, size: 16),
                      label: const Text('Note'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_isChecklistMode
                            ? AppColors.textPrimary
                            : Colors.grey.shade100,
                        foregroundColor: !_isChecklistMode
                            ? Colors.white
                            : AppColors.textPrimary,
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isChecklistMode = true;
                        });
                      },
                      icon: const Icon(Icons.list, size: 16),
                      label: const Text('Checklist'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isChecklistMode
                            ? AppColors.textPrimary
                            : Colors.grey.shade100,
                        foregroundColor: _isChecklistMode
                            ? Colors.white
                            : AppColors.textPrimary,
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isChecklistMode
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ..._checklist.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ChecklistItemWidget(
                              text: item.text,
                              completed: item.completed,
                              onToggle: () => _toggleChecklistItem(item.id),
                              onTextChange: (text) =>
                                  _updateChecklistItem(item.id, text),
                              onDelete: () => _deleteChecklistItem(item.id),
                              editable: true,
                            ),
                          )),
                      TextButton.icon(
                        onPressed: _addChecklistItem,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add item'),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Start writing...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      ),
    );
  }
}

