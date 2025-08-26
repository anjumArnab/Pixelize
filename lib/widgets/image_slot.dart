import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageSlot extends StatelessWidget {
  final bool hasImage;
  final XFile? imageFile;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  const ImageSlot({
    super.key,
    required this.hasImage,
    this.imageFile,
    this.onLongPress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 68, // increased by 35%
        height: 68, // increased by 35%
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
        child: hasImage && imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 135, // also increased by 35%
                  height: 135,
                  child: kIsWeb
                      ? Image.network(
                          imageFile!.path,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.image,
                                color: Colors.grey[400],
                                size: 40, // icon also a bit larger
                              ),
                            );
                          },
                        )
                      : Image.file(
                          File(imageFile!.path),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.image,
                                color: Colors.grey[400],
                                size: 40,
                              ),
                            );
                          },
                        ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                child: Icon(
                  Icons.image,
                  color: Colors.grey[400],
                  size: 40, // increased
                ),
              ),
      ),
    );
  }
}
