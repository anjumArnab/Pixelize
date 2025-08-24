import 'package:flutter/material.dart';

class ImageSlot extends StatelessWidget {
  final bool hasImage;

  const ImageSlot({
    super.key,
    required this.hasImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
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
      child: hasImage
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              child: Icon(
                Icons.image,
                color: Colors.grey[400],
                size: 30,
              ),
            )
          : const SizedBox(),
    );
  }
}
