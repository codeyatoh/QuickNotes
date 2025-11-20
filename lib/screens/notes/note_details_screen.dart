import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:provider/provider.dart';
import '../../widgets/checklist_item.dart';
import '../../providers/notes_provider.dart';
import '../../models/tag_model.dart';
import '../../models/note_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/async_util.dart';
import '../../utils/navigation_util.dart';

class NoteDetailsScreen extends StatefulWidget {
  final String noteId;

  const NoteDetailsScreen({super.key, required this.noteId});

  @override
  State<NoteDetailsScreen> createState() => _NoteDetailsScreenState();
}

class _NoteDetailsScreenState extends State<NoteDetailsScreen> {
  Color _getTagColor(TagColor tagColor) {
    switch (tagColor) {
      case TagColor.yellow:
        return AppColors.tagYellowLight;
      case TagColor.blue:
        return AppColors.tagBlueLight;
      case TagColor.green:
        return AppColors.tagGreenLight;
      case TagColor.red:
        return AppColors.tagRedLight;
      case TagColor.purple:
        return AppColors.tagPurpleLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use Selector to only rebuild when the specific note changes
    return Selector<NotesProvider, Note?>(
      selector: (_, provider) => provider.getNote(widget.noteId),
      builder: (context, note, _) {
        final notesProvider = Provider.of<NotesProvider>(context, listen: false);

        if (note == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          NavigationUtil.safePopOrNavigate(context, '/home');
        }
      });
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
      backgroundColor: _getTagColor(note.tagColor),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => NavigationUtil.safePopOrNavigate(context, '/home'),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onSelected: (value) async {
              final notesProvider = Provider.of<NotesProvider>(context, listen: false);
              switch (value) {
                case 'favorite':
                  notesProvider.toggleFavorite(note.id).then((_) {
                    // Favorite status will update automatically via Firestore listener
                  }).catchError((e) {
                    if (kDebugMode) {
                      debugPrint('Failed to toggle favorite: $e');
                    }
                  });
                  break;
                case 'archive':
                  if (note.archived) {
                    await notesProvider.restoreNote(note.id);
                  } else {
                    await notesProvider.archiveNote(note.id);
                  }
                  // Pop the menu, then navigate back if needed
                  if (mounted) {
                    final navigator = Navigator.maybeOf(context);
                    if (navigator != null && navigator.canPop()) {
                      navigator.pop(); // Pop the menu
                    }
                  }
                  break;
                case 'delete':
                  await notesProvider.deleteNote(note.id);
                  // Pop the menu, then navigate back
                  if (mounted) {
                    final navigator = Navigator.maybeOf(context);
                    if (navigator != null && navigator.canPop()) {
                      navigator.pop(); // Pop the menu
                      // Small delay before popping screen to ensure menu is closed
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (mounted) {
                          final nav = Navigator.maybeOf(context);
                          if (nav != null && nav.canPop()) {
                            nav.pop(); // Pop the screen
                          } else {
                            Navigator.of(context).pushReplacementNamed('/home');
                          }
                        }
                      });
                    } else {
                      Navigator.of(context).pushReplacementNamed('/home');
                    }
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              if (!note.archived)
                PopupMenuItem(
                  value: 'favorite',
                  child: Row(
                    children: [
                      Icon(
                        note.favorite ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(note.favorite
                          ? 'Remove from Favorites'
                          : 'Add to Favorites'),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(
                      note.archived ? Icons.unarchive : Icons.archive,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(note.archived ? 'Unarchive Note' : 'Archive Note'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Delete Note', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (note.checklist.isNotEmpty) ...[
              const SizedBox(height: 24),
              ...note.checklist.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ChecklistItemWidget(
                      text: item.text,
                      completed: item.completed,
                      onToggle: () {
                        final updatedChecklist = note.checklist.map((i) {
                          if (i.id == item.id) {
                            return i.copyWith(completed: !i.completed);
                          }
                          return i;
                        }).toList();
                          unawaited(
                        notesProvider.updateNote(
                          note.id,
                          checklist: updatedChecklist,
                            ),
                        );
                      },
                    ),
                  )),
            ],
            if (note.content != null && note.content!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(color: AppColors.lightGray),
              const SizedBox(height: 16),
              Text(
                note.content!,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: !note.archived
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/edit/${note.id}');
              },
              backgroundColor: const Color(0xFF2D2D2D),
              elevation: 3,
              shape: const CircleBorder(),
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 22,
              ),
            )
          : null,
      ),
      );
      },
    );
  }
}

