import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ImagePreviewWidget extends StatelessWidget {
  final File? imageFile;
  final Uint8List? imageBytes;
  final Uint8List? compressedBytes;
  final double Function(double)? calculateImageHeight;
  final bool showActionButtons;
  final VoidCallback? onCrop;
  final VoidCallback? onSave;
  final VoidCallback? onInfo;
  final VoidCallback? onRemove;
  final String? noImageText;
  final String? noImageSubtext;
  final bool isAnimated;
  final Color? backgroundColor;
  final Color? borderColor;

  const ImagePreviewWidget({
    super.key,
    this.imageFile,
    this.imageBytes,
    this.compressedBytes,
    this.calculateImageHeight,
    this.showActionButtons = false,
    this.onCrop,
    this.onSave,
    this.onInfo,
    this.onRemove,
    this.noImageText = 'No Image',
    this.noImageSubtext,
    this.isAnimated = false,
    this.backgroundColor,
    this.borderColor,
  });

  bool get _hasImage => imageFile != null || imageBytes != null;

  Widget _buildImage() {
    if (imageBytes != null) {
      // Use compressed bytes if available, otherwise use original bytes
      final bytesToShow = compressedBytes ?? imageBytes!;
      return Image.memory(
        bytesToShow,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    } else if (!kIsWeb && imageFile != null) {
      return Image.file(
        imageFile!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    }
    return _buildNoImageWidget();
  }

  Widget _buildErrorWidget() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[100],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          SizedBox(height: 8),
          Text(
            'Failed to load image',
            style: TextStyle(
              color: Colors.red,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoImageWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          showActionButtons ? Icons.add : Icons.image,
          size: showActionButtons ? 48 : 64,
          color: Colors.grey,
        ),
        const SizedBox(height: 8),
        Text(
          showActionButtons ? 'Add Image' : (noImageText ?? 'No Image'),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
        if (noImageSubtext != null || showActionButtons) ...[
          const SizedBox(height: 8),
          Text(
            noImageSubtext ?? 'Image will resize dynamically',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    if (!showActionButtons || !_hasImage) return const SizedBox.shrink();

    return Positioned(
      top: 8,
      right: 8,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Crop button (only show for mobile platforms)
          if (!kIsWeb && onCrop != null) ...[
            _buildActionButton(
              onTap: onCrop!,
              icon: Icons.crop,
              color: Colors.purple,
            ),
            const SizedBox(width: 8),
          ],
          // Save button
          if (onSave != null) ...[
            _buildActionButton(
              onTap: onSave!,
              icon: Icons.save,
              color: Colors.green,
            ),
            const SizedBox(width: 8),
          ],
          // Info button
          if (onInfo != null) ...[
            _buildActionButton(
              onTap: onInfo!,
              icon: Icons.info,
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
          ],
          // Remove button
          if (onRemove != null)
            _buildActionButton(
              onTap: onRemove!,
              icon: Icons.close,
              color: Colors.red,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;
        final imageHeight = _hasImage && calculateImageHeight != null
            ? calculateImageHeight!(containerWidth)
            : 200.0;

        final container = Container(
          width: double.infinity,
          height: imageHeight,
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor ?? Colors.grey[300]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            color: backgroundColor ??
                (showActionButtons ? Colors.grey[100] : Colors.white),
          ),
          child: _hasImage
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _buildImage(),
                    ),
                    _buildActionButtons(),
                  ],
                )
              : _buildNoImageWidget(),
        );

        if (isAnimated) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: imageHeight,
            child: Container(
              decoration: container.decoration,
              child: container.child,
            ),
          );
        }

        return container;
      },
    );
  }
}
