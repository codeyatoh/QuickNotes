import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../widgets/note_card.dart';
import '../../widgets/tag_filter_sheet.dart';
import '../../providers/notes_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/constants.dart';
import '../../theme/app_colors.dart';
import '../../models/note_model.dart';
import '../../models/tag_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Memoize filtered notes to avoid recomputing on every build
  List<Note> _cachedFilteredNotes = [];
  TagColor? _lastActiveTag;
  List<Note> _lastNotes = [];

  List<Note> _getFilteredNotes(List<Note> notes, TagColor? activeTag) {
    // Return cached if inputs haven't changed
    if (notes == _lastNotes && activeTag == _lastActiveTag) {
      return _cachedFilteredNotes;
    }

    final activeNotes = notes.where((note) => !note.archived).toList();
    final filtered = activeTag != null
        ? activeNotes.where((note) => note.tagColor == activeTag).toList()
        : activeNotes;

    // Cache results
    _lastNotes = notes;
    _lastActiveTag = activeTag;
    _cachedFilteredNotes = filtered;

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<NotesProvider, ThemeProvider>(
      builder: (context, notesProvider, themeProvider, _) {
    final isDarkMode = themeProvider.isDarkMode;
        final filteredNotes = _getFilteredNotes(
          notesProvider.notes,
          notesProvider.activeTag,
        );

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF2A2D3E) : Colors.white,
      body: Container(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                bottom: 12,
              ),
              color: isDarkMode ? const Color(0xFF2A2D3E) : Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          AppConstants.logoAssetPath,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.network(
                              AppConstants.logoUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'QuickNotes',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color:
                              isDarkMode ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/settings');
                        },
                        icon: Icon(
                          Icons.settings,
                          color: isDarkMode
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/archive');
                        },
                        icon: Icon(
                          Icons.archive,
                          color: isDarkMode
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Content
            Selector<NotesProvider, TagColor?>(
              selector: (_, provider) => provider.activeTag,
              builder: (context, activeTag, _) {
                if (activeTag == null) return const SizedBox.shrink();
                return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Filtered by tag • ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        color: isDarkMode
                            ? const Color(0xFFB8BCCF)
                            : AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        notesProvider.setActiveTag(null);
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                );
              },
            ),
            Selector<NotesProvider, bool>(
              selector: (_, provider) => provider.isLoading,
              builder: (context, isLoading, _) {
                return Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredNotes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.note,
                            size: 48,
                            color: isDarkMode
                                ? const Color(0xFF4A4E63)
                                : AppColors.lightGray,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notes yet — tap + to add.',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w300,
                              color: isDarkMode
                                  ? const Color(0xFFB8BCCF)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredNotes.length,
                          // Add keys for better performance
                          key: const PageStorageKey('notes_list'),
                      itemBuilder: (context, index) {
                            final note = filteredNotes[index];
                        return NoteCard(
                              key: ValueKey(note.id), // Key for ListView optimization
                              note: note,
                          isDarkMode: isDarkMode,
                          onTap: () {
                            Navigator.of(context).pushNamed(
                                  '/note/${note.id}',
                            );
                          },
                        );
                      },
                    ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                  builder: (context) => Selector<NotesProvider, TagColor?>(
                    selector: (_, provider) => provider.activeTag,
                    builder: (context, activeTag, _) => TagFilterSheet(
                  isOpen: true,
                  onClose: () => Navigator.of(context).pop(),
                      activeTag: activeTag,
                  onSelectTag: (tag) {
                    notesProvider.setActiveTag(tag);
                  },
                    ),
                ),
              );
            },
            backgroundColor: Colors.white,
            elevation: 2,
            shape: const CircleBorder(),
            child: Icon(
              Icons.filter_list,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/create');
            },
            backgroundColor: const Color(0xFF2D2D2D),
            elevation: 3,
            shape: const CircleBorder(),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }
}

