import 'package:flutter/material.dart';

class AddImageSlot extends StatelessWidget {
  final VoidCallback onTap;
  final bool showBorder;
  final String? tooltip;

  const AddImageSlot({
    Key? key,
    required this.onTap,
    this.showBorder = true,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget child = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: showBorder
              ? Border.all(
                  color: Colors.grey[300]!,
                  style: BorderStyle.solid,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: Colors.grey[600],
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );

    // Wrap with tooltip if provided
    if (tooltip != null) {
      child = Tooltip(
        message: tooltip!,
        child: child,
      );
    }

    return child;
  }
}
