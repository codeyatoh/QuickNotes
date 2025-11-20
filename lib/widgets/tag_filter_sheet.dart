import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tag_model.dart';
import '../theme/app_colors.dart';

class TagFilterSheet extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final TagColor? activeTag;
  final ValueChanged<TagColor?> onSelectTag;

  const TagFilterSheet({
    super.key,
    required this.isOpen,
    required this.onClose,
    this.activeTag,
    required this.onSelectTag,
  });

  @override
  State<TagFilterSheet> createState() => _TagFilterSheetState();
}

class _TagFilterSheetState extends State<TagFilterSheet>
    with SingleTickerProviderStateMixin {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => setState(() => _isVisible = true));
  }

  Color _getTagColor(TagColor tagColor) {
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
  }

  void _handleTagSelect(TagColor tag) {
    widget.onSelectTag(widget.activeTag == tag ? null : tag);
    _dismiss();
  }

  void _handleClearFilters() {
    widget.onSelectTag(null);
    _dismiss();
  }

  void _dismiss() {
    setState(() => _isVisible = false);
    Future.delayed(const Duration(milliseconds: 200), widget.onClose);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _dismiss,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: _isVisible ? 1 : 0,
        child: GestureDetector(
          onTap: () {},
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              offset: _isVisible ? Offset.zero : const Offset(0, 0.2),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _isVisible ? 1 : 0,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filter by Tag',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: _handleClearFilters,
                            child: Text(
                              'Clear',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 20,
                        runSpacing: 24,
                        alignment: WrapAlignment.center,
                        children: TagColor.values.map((tag) {
                          final isSelected = widget.activeTag == tag;
                          return GestureDetector(
                            onTap: () => _handleTagSelect(tag),
                            child: Column(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: _getTagColor(tag),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.textPrimary
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.textPrimary
                                                  .withOpacity(0.15),
                                              blurRadius: 12,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  tag.label,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

