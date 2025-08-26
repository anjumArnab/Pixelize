import 'package:flutter/material.dart';

class AddImageSlot extends StatelessWidget {
  final VoidCallback onTap;

  const AddImageSlot({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68, // 35% bigger
        height: 68, // 35% bigger
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          Icons.add,
          color: Colors.grey[400],
          size: 30, // scaled up
        ),
      ),
    );
  }
}
