import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/note_card.dart';
import '../../providers/notes_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/navigation_util.dart';
import '../../models/note_model.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<NotesProvider, ThemeProvider>(
      builder: (context, notesProvider, themeProvider, _) {
        final isDarkMode = themeProvider.isDarkMode;

        // Use Selector to only rebuild when notes or archived status changes
        return Selector<NotesProvider, List<Note>>(
          selector: (_, provider) => provider.notes,
          builder: (context, notes, _) {
            final archivedNotes = notes.where((note) => note.archived).toList();

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
                  title: const Text(
                    'Archive',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                body: Selector<NotesProvider, bool>(
                  selector: (_, provider) => provider.isLoading,
                  builder: (context, isLoading, _) {
                    return isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : archivedNotes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.archive,
                                  size: 48,
                                  color: AppColors.lightGray,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Your archive is empty.',
                                  style: TextStyle(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: archivedNotes.length,
                            key: const PageStorageKey('archived_notes_list'),
                            itemBuilder: (context, index) {
                              final note = archivedNotes[index];
                              return NoteCard(
                                key: ValueKey(note.id),
                                note: note,
                                archived: true,
                                isDarkMode: isDarkMode,
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                    '/note/${note.id}',
                                  );
                                },
                              );
                            },
                          );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
