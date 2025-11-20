import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../models/tag_model.dart';
import '../theme/app_colors.dart';

class NoteCard extends StatefulWidget {
  final Note note;
  final bool archived;
  final VoidCallback? onTap;
  final bool isDarkMode;

  const NoteCard({
    super.key,
    required this.note,
    this.archived = false,
    this.onTap,
    this.isDarkMode = false,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  // Cache date formatting to avoid recomputing
  String? _cachedFormattedDate;
  DateTime? _cachedDate;

  String _formatDate(DateTime date) {
    // Return cached if same date (within same minute to account for time passing)
    final dateMinute = date.millisecondsSinceEpoch ~/ 60000;
    final cachedMinute = _cachedDate != null ? _cachedDate!.millisecondsSinceEpoch ~/ 60000 : null;
    
    if (cachedMinute != null && dateMinute == cachedMinute && _cachedFormattedDate != null) {
      return _cachedFormattedDate!;
    }

    final now = DateTime.now();
    final difference = now.difference(date);
    String formatted;

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          formatted = 'just now';
        } else {
          formatted = '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
        }
      } else {
        formatted = '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      }
    } else if (difference.inDays == 1) {
      formatted = 'yesterday';
    } else if (difference.inDays < 7) {
      formatted = '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      formatted = '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      formatted = '$months month${months == 1 ? '' : 's'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      formatted = '$years year${years == 1 ? '' : 's'} ago';
    }

    // Cache result
    _cachedDate = date;
    _cachedFormattedDate = formatted;
    return formatted;
  }

  Color _getTagColor(TagColor tagColor) {
    if (widget.isDarkMode) {
      switch (tagColor) {
        case TagColor.yellow:
          return AppColors.tagYellow;
        case TagColor.blue:
          return AppColors.tagBlue;
        case TagColor.green:
          return AppColors.tagGreen;
        case TagColor.red:
          return AppColors.tagRed;
        case TagColor.purple:
          return AppColors.tagPurple;
      }
    } else {
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
  }

  @override
  Widget build(BuildContext context) {
    final completedCount =
        widget.note.checklist.where((item) => item.completed).length;
    final totalCount = widget.note.checklist.length;
    final progressPercentage =
        totalCount > 0 ? (completedCount / totalCount) * 100 : 0.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _getTagColor(widget.note.tagColor),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? Colors.transparent
                : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.note.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (widget.note.favorite)
                    const Icon(
                      Icons.favorite,
                      size: 20,
                      color: Colors.red,
                    ),
                ],
              ),
              if (widget.note.checklist.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completedCount of $totalCount completed',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${progressPercentage.round()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.isDarkMode
                        ? Colors.white.withOpacity(0.4)
                        : Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressPercentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...widget.note.checklist.take(3).map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: item.completed
                                  ? AppColors.primary.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.8),
                              border: Border.all(
                                color: const Color(0xFF3A3A3A),
                                width: item.completed ? 1 : 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: item.completed
                                ? const Icon(
                                    Icons.check,
                                    size: 10,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.text,
                              style: TextStyle(
                                fontSize: 14,
                                decoration: item.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: item.completed
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                                fontWeight: item.completed
                                    ? FontWeight.normal
                                    : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
                if (widget.note.checklist.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(left: 26, top: 4),
                    child: Text(
                      '+${widget.note.checklist.length - 3} more items',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ] else if (widget.note.content != null && widget.note.content!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.note.content!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Divider(
                color: widget.isDarkMode
                    ? AppColors.primary.withOpacity(0.2)
                    : Colors.white.withOpacity(0.6),
                thickness: 1,
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(widget.note.updatedAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

