// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/action_button.dart';
import '../widgets/add_image_slot.dart';
import '../widgets/image_slot.dart';
import '../services/image_service.dart';

class CropImagePage extends StatefulWidget {
  const CropImagePage({super.key});

  @override
  State<CropImagePage> createState() => _CropImagePageState();
}

class _CropImagePageState extends State<CropImagePage> {
  String selectedRatio = '16:9';
  List<File> selectedImages = [];
  List<ImageMetadata> originalMetadata = [];
  int currentImageIndex = 0;
  bool isLoading = false;
  bool isProcessing = false;

  // Crop parameters
  double cropX = 0;
  double cropY = 0;
  double cropWidth = 200;
  double cropHeight = 120;

  final ImageService _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadArguments();
    });
  }

  void _loadArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      setState(() {
        selectedImages = List<File>.from(args['images'] ?? []);
        originalMetadata = List<ImageMetadata>.from(args['metadata'] ?? []);
      });

      if (selectedImages.isEmpty) {
        _pickImages();
      }
    } else {
      _pickImages();
    }
  }

  Future<void> _pickImages() async {
    setState(() {
      isLoading = true;
    });

    try {
      final List<File> images =
          await _imageService.pickMultipleImagesFromGallery(maxImages: 10);

      if (images.isNotEmpty) {
        final List<ImageMetadata> metadata = [];
        for (File image in images) {
          final ImageMetadata meta =
              await _imageService.getImageMetadata(image);
          metadata.add(meta);
        }

        setState(() {
          selectedImages = images;
          originalMetadata = metadata;
          _updateCropDimensionsForRatio();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _addMoreImages() async {
    try {
      final File? image = await _imageService.pickImageFromGallery();

      if (image != null) {
        final ImageMetadata metadata =
            await _imageService.getImageMetadata(image);

        setState(() {
          selectedImages.add(image);
          originalMetadata.add(metadata);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
      originalMetadata.removeAt(index);

      // Adjust current index if necessary
      if (currentImageIndex >= selectedImages.length &&
          selectedImages.isNotEmpty) {
        currentImageIndex = selectedImages.length - 1;
      } else if (selectedImages.isEmpty) {
        currentImageIndex = 0;
      }
    });
  }

  void _selectImage(int index) {
    setState(() {
      currentImageIndex = index;
      _updateCropDimensionsForRatio();
    });
  }

  void _updateCropDimensionsForRatio() {
    if (selectedImages.isEmpty || currentImageIndex >= originalMetadata.length)
      return;

    final ImageMetadata currentMeta = originalMetadata[currentImageIndex];
    final double imageWidth = currentMeta.width.toDouble();
    final double imageHeight = currentMeta.height.toDouble();

    // Calculate crop dimensions based on selected ratio
    double targetWidth, targetHeight;

    switch (selectedRatio) {
      case '1:1':
        final minDimension =
            imageWidth < imageHeight ? imageWidth : imageHeight;
        targetWidth = minDimension * 0.8;
        targetHeight = minDimension * 0.8;
        break;
      case '16:9':
        targetWidth = imageWidth * 0.8;
        targetHeight = targetWidth * 9 / 16;
        if (targetHeight > imageHeight * 0.8) {
          targetHeight = imageHeight * 0.8;
          targetWidth = targetHeight * 16 / 9;
        }
        break;
      case '4:3':
        targetWidth = imageWidth * 0.8;
        targetHeight = targetWidth * 3 / 4;
        if (targetHeight > imageHeight * 0.8) {
          targetHeight = imageHeight * 0.8;
          targetWidth = targetHeight * 4 / 3;
        }
        break;
      case 'Free':
        targetWidth = imageWidth * 0.6;
        targetHeight = imageHeight * 0.6;
        break;
      default:
        targetWidth = imageWidth * 0.6;
        targetHeight = imageHeight * 0.6;
    }

    setState(() {
      cropWidth = targetWidth;
      cropHeight = targetHeight;
      cropX = (imageWidth - targetWidth) / 2;
      cropY = (imageHeight - targetHeight) / 2;
    });
  }

  String _getOutputDimensions() {
    if (selectedImages.isEmpty || currentImageIndex >= selectedImages.length) {
      return 'No image selected';
    }
    return '${cropWidth.round()}x${cropHeight.round()} px';
  }

  Future<void> _previewCrop() async {
    if (selectedImages.isEmpty) return;

    // For now, just show a simple preview dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crop Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Current image: ${originalMetadata[currentImageIndex].fileName}'),
            const SizedBox(height: 8),
            Text('Crop area: ${cropX.round()}, ${cropY.round()}'),
            Text('Crop size: ${cropWidth.round()} x ${cropHeight.round()}'),
            Text('Aspect ratio: $selectedRatio'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _applyCrop() async {
    if (selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No images to crop')),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      List<File> croppedImages = [];
      List<ImageMetadata> croppedMetadata = [];

      for (int i = 0; i < selectedImages.length; i++) {
        final File originalImage = selectedImages[i];
        final ImageMetadata originalMeta = originalMetadata[i];

        // Calculate crop parameters for each image based on the current ratio
        double imgCropX, imgCropY, imgCropWidth, imgCropHeight;

        if (selectedRatio == 'Free') {
          // Use current crop dimensions
          imgCropX = cropX;
          imgCropY = cropY;
          imgCropWidth = cropWidth;
          imgCropHeight = cropHeight;
        } else {
          // Calculate proportional crop for the selected ratio
          final double imageWidth = originalMeta.width.toDouble();
          final double imageHeight = originalMeta.height.toDouble();

          switch (selectedRatio) {
            case '1:1':
              final minDimension =
                  imageWidth < imageHeight ? imageWidth : imageHeight;
              imgCropWidth = minDimension * 0.8;
              imgCropHeight = minDimension * 0.8;
              break;
            case '16:9':
              imgCropWidth = imageWidth * 0.8;
              imgCropHeight = imgCropWidth * 9 / 16;
              if (imgCropHeight > imageHeight * 0.8) {
                imgCropHeight = imageHeight * 0.8;
                imgCropWidth = imgCropHeight * 16 / 9;
              }
              break;
            case '4:3':
              imgCropWidth = imageWidth * 0.8;
              imgCropHeight = imgCropWidth * 3 / 4;
              if (imgCropHeight > imageHeight * 0.8) {
                imgCropHeight = imageHeight * 0.8;
                imgCropWidth = imgCropHeight * 4 / 3;
              }
              break;
            default:
              imgCropWidth = imageWidth * 0.6;
              imgCropHeight = imageHeight * 0.6;
          }

          imgCropX = (imageWidth - imgCropWidth) / 2;
          imgCropY = (imageHeight - imgCropHeight) / 2;
        }

        // Perform the crop
        final File croppedImage = await _imageService.cropImage(
          originalImage,
          x: imgCropX.round(),
          y: imgCropY.round(),
          width: imgCropWidth.round(),
          height: imgCropHeight.round(),
        );

        croppedImages.add(croppedImage);

        // Get metadata for cropped image
        final ImageMetadata croppedMeta =
            await _imageService.getImageMetadata(croppedImage);
        croppedMetadata.add(croppedMeta);
      }

      // Navigate to export page with cropped images
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/export',
          arguments: {
            'processedImages': croppedImages,
            'originalMetadata': originalMetadata,
            'processedMetadata': croppedMetadata,
            'operation': 'crop',
            'settings': {
              'aspectRatio': selectedRatio,
              'cropX': cropX.round(),
              'cropY': cropY.round(),
              'cropWidth': cropWidth.round(),
              'cropHeight': cropHeight.round(),
            },
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cropping images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Crop',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Selected Images section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Selected Images (${selectedImages.length})',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (selectedImages.isNotEmpty)
                                Text(
                                  'Current: ${currentImageIndex + 1}/${selectedImages.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          // Image selection grid
                          SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: selectedImages.length + 1,
                              itemBuilder: (context, index) {
                                if (index == selectedImages.length) {
                                  return AddImageSlot(
                                    onTap: _addMoreImages,
                                    tooltip: 'Add more images',
                                  );
                                }

                                final bool isSelected =
                                    index == currentImageIndex;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: isSelected
                                          ? Border.all(
                                              color: Colors.blue, width: 2)
                                          : null,
                                    ),
                                    child: ImageSlot(
                                      hasImage: true,
                                      imageFile: selectedImages[index],
                                      onTap: () => _selectImage(index),
                                      onRemove: selectedImages.length > 1
                                          ? () => _removeImage(index)
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Current Image Info
                          if (selectedImages.isNotEmpty &&
                              currentImageIndex < originalMetadata.length)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current: ${originalMetadata[currentImageIndex].fileName}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${originalMetadata[currentImageIndex].width} × ${originalMetadata[currentImageIndex].height} px • ${originalMetadata[currentImageIndex].fileSizeMB} MB',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 20),

                          // Image Preview section
                          Text(
                            'Crop Preview',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 15),

                          // Crop preview area
                          Container(
                            width: double.infinity,
                            height: 250,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Stack(
                                children: [
                                  // Background area
                                  Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: selectedImages.isNotEmpty &&
                                            currentImageIndex <
                                                selectedImages.length
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.file(
                                              selectedImages[currentImageIndex],
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey[400],
                                                  size: 48,
                                                );
                                              },
                                            ),
                                          )
                                        : Icon(
                                            Icons.image,
                                            color: Colors.grey[400],
                                            size: 48,
                                          ),
                                  ),

                                  // Crop selection area
                                  Center(
                                    child: Container(
                                      width: cropWidth /
                                          2, // Scale down for preview
                                      height: cropHeight / 2,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 2,
                                          style: BorderStyle.solid,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          // Corner handles
                                          _buildCornerHandle(Alignment.topLeft),
                                          _buildCornerHandle(
                                              Alignment.topRight),
                                          _buildCornerHandle(
                                              Alignment.bottomLeft),
                                          _buildCornerHandle(
                                              Alignment.bottomRight),

                                          // Dashed lines
                                          Positioned(
                                            top: 0,
                                            left: 0,
                                            right: 0,
                                            bottom: 0,
                                            child: CustomPaint(
                                              painter: DashedLinePainter(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Aspect Ratio section
                          const Text(
                            'Aspect Ratio',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),

                          const SizedBox(height: 15),

                          // Aspect ratio buttons
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _buildRatioButton('1:1'),
                              _buildRatioButton('16:9'),
                              _buildRatioButton('4:3'),
                              _buildRatioButton('Free'),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Output dimensions
                          Text(
                            'Output: ${_getOutputDimensions()}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // Bottom action buttons
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ActionButton(
                            text: 'Preview',
                            isPrimary: false,
                            onTap:
                                selectedImages.isNotEmpty ? _previewCrop : null,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ActionButton(
                            text: isProcessing ? 'Processing...' : 'Apply Crop',
                            isPrimary: true,
                            onTap: (isProcessing || selectedImages.isEmpty)
                                ? null
                                : _applyCrop,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCornerHandle(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: Offset(
          alignment.x * -4, // Offset to center on corner
          alignment.y * -4,
        ),
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.rectangle,
          ),
        ),
      ),
    );
  }

  Widget _buildRatioButton(String ratio) {
    final isSelected = selectedRatio == ratio;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRatio = ratio;
          _updateCropDimensionsForRatio();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
          ),
        ),
        child: Text(
          ratio,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

// Custom painter for dashed lines in crop area
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 4.0;

    // Horizontal dashed lines
    for (int i = 1; i < 3; i++) {
      final y = size.height / 3 * i;
      double startX = 0;

      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(startX + dashWidth, y),
          paint,
        );
        startX += dashWidth + dashSpace;
      }
    }

    // Vertical dashed lines
    for (int i = 1; i < 3; i++) {
      final x = size.width / 3 * i;
      double startY = 0;

      while (startY < size.height) {
        canvas.drawLine(
          Offset(x, startY),
          Offset(x, startY + dashWidth),
          paint,
        );
        startY += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
