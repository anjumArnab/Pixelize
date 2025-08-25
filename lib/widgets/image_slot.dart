// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';

class ImageSlot extends StatelessWidget {
  final bool hasImage;
  final File? imageFile;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const ImageSlot({
    super.key,
    required this.hasImage,
    this.imageFile,
    this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Stack(
          children: [
            // Image content
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: hasImage && imageFile != null
                  ? Image.file(
                      imageFile!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[200],
                          ),
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey[400],
                            size: 24,
                          ),
                        );
                      },
                    )
                  : hasImage
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
            ),

            // Remove button (only show if there's an image and onRemove is provided)
            if (hasImage && onRemove != null)
              Positioned(
                top: -2,
                right: -2,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.red[500],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
