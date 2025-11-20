import 'package:flutter/material.dart';

class ChecklistItemWidget extends StatefulWidget {
  final String text;
  final bool completed;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onTextChange;
  final bool editable;

  const ChecklistItemWidget({
    super.key,
    required this.text,
    this.completed = false,
    this.onToggle,
    this.onDelete,
    this.onTextChange,
    this.editable = false,
  });

  @override
  State<ChecklistItemWidget> createState() => _ChecklistItemWidgetState();
}

class _ChecklistItemWidgetState extends State<ChecklistItemWidget> {
  late TextEditingController _controller;
  bool _isUpdatingFromParent = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
  }

  @override
  void didUpdateWidget(ChecklistItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update controller if text changed from parent (not from user typing)
    if (widget.text != oldWidget.text && !_isUpdatingFromParent) {
      final selection = _controller.selection;
      _controller.text = widget.text;
      // Restore cursor position if possible
      if (selection.isValid && selection.end <= widget.text.length) {
        _controller.selection = selection;
      } else if (widget.text.isNotEmpty) {
        _controller.selection = TextSelection.collapsed(offset: widget.text.length);
      }
    }
    _isUpdatingFromParent = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTextChange(String value) {
    _isUpdatingFromParent = true;
    widget.onTextChange?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: widget.onToggle,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: widget.completed
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
              border: Border.all(
                color: const Color(0xFF1E1E1E),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: widget.completed
                ? const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: widget.editable
              ? TextField(
                  controller: _controller,
                  onChanged: _handleTextChange,
                  style: TextStyle(
                    decoration: widget.completed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: widget.completed
                        ? const Color(0xFF6F6F6F)
                        : const Color(0xFF1E1E1E),
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                )
              : Text(
                  widget.text,
                  style: TextStyle(
                    decoration: widget.completed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: widget.completed
                        ? const Color(0xFF6F6F6F)
                        : const Color(0xFF1E1E1E),
                    fontSize: 14,
                  ),
                ),
        ),
        if (widget.editable && widget.onDelete != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: widget.onDelete,
            icon: const Icon(
              Icons.close,
              size: 16,
              color: Color(0xFF1E1E1E),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 16,
          ),
        ],
      ],
    );
  }
}

