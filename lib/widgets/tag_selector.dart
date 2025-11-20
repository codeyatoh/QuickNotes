import 'package:flutter/material.dart';
import '../models/tag_model.dart';
import '../theme/app_colors.dart';

class TagSelector extends StatelessWidget {
  final TagColor selectedTag;
  final ValueChanged<TagColor> onChanged;

  const TagSelector({
    super.key,
    required this.selectedTag,
    required this.onChanged,
  });

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

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: TagColor.values.map((tag) {
        final isSelected = selectedTag == tag;
        return GestureDetector(
          onTap: () => onChanged(tag),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getTagColor(tag),
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: Colors.grey.shade400,
                      width: 2,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

