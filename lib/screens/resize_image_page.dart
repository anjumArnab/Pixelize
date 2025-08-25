// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import '../services/image_service.dart';
import '../widgets/action_button.dart';
import '../widgets/add_image_slot.dart';
import '../widgets/image_slot.dart';

class ResizeImagePage extends StatefulWidget {
  const ResizeImagePage({super.key});

  @override
  State<ResizeImagePage> createState() => _ResizeImagePageState();
}

class _ResizeImagePageState extends State<ResizeImagePage> {
  bool isByDimensions = true;
  bool lockAspectRatio = true;
  double percentageValue = 50.0;

  List<File> selectedImages = [];
  List<ImageMetadata> imageMetadata = [];
  bool isLoading = false;

  final ImageService _imageService = ImageService();
  final TextEditingController widthController =
      TextEditingController(text: '1920');
  final TextEditingController heightController =
      TextEditingController(text: '1080');
  final TextEditingController percentageController =
      TextEditingController(text: '50');

  @override
  void initState() {
    super.initState();
    _loadInitialImages();

    // Listen to width changes to maintain aspect ratio
    widthController.addListener(_onWidthChanged);
    heightController.addListener(_onHeightChanged);
    percentageController.addListener(_onPercentageChanged);
  }

  void _loadInitialImages() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is List<File>) {
      setState(() {
        selectedImages = args;
      });
      await _loadImageMetadata();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (selectedImages.isEmpty) {
      _loadInitialImages();
    }
  }

  Future<void> _loadImageMetadata() async {
    if (selectedImages.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      List<ImageMetadata> metadata = [];
      for (File image in selectedImages) {
        final meta = await _imageService.getImageMetadata(image);
        metadata.add(meta);
      }
      setState(() {
        imageMetadata = metadata;
        isLoading = false;
      });

      // Set initial dimensions based on first image
      if (metadata.isNotEmpty) {
        _updateDimensionsFromFirstImage();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading image metadata: $e')),
        );
      }
    }
  }

  void _updateDimensionsFromFirstImage() {
    if (imageMetadata.isNotEmpty) {
      final firstImage = imageMetadata[0];
      setState(() {
        widthController.text = firstImage.width.toString();
        heightController.text = firstImage.height.toString();
      });
    }
  }

  void _onWidthChanged() {
    if (lockAspectRatio && imageMetadata.isNotEmpty) {
      final width = int.tryParse(widthController.text) ?? 0;
      if (width > 0) {
        final aspectRatio = imageMetadata[0].width / imageMetadata[0].height;
        final newHeight = (width / aspectRatio).round();
        heightController.removeListener(_onHeightChanged);
        heightController.text = newHeight.toString();
        heightController.addListener(_onHeightChanged);
      }
    }
  }

  void _onHeightChanged() {
    if (lockAspectRatio && imageMetadata.isNotEmpty) {
      final height = int.tryParse(heightController.text) ?? 0;
      if (height > 0) {
        final aspectRatio = imageMetadata[0].width / imageMetadata[0].height;
        final newWidth = (height * aspectRatio).round();
        widthController.removeListener(_onWidthChanged);
        widthController.text = newWidth.toString();
        widthController.addListener(_onWidthChanged);
      }
    }
  }

  void _onPercentageChanged() {
    final percentage = double.tryParse(percentageController.text) ?? 50.0;
    setState(() {
      percentageValue = percentage.clamp(1.0, 500.0);
    });
  }

  Future<void> _addImage() async {
    try {
      final File? newImage = await _imageService.showImagePickerDialog(context);
      if (newImage != null) {
        setState(() {
          selectedImages.add(newImage);
        });
        await _loadImageMetadata();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding image: $e')),
        );
      }
    }
  }

  Future<void> _addMultipleImages() async {
    try {
      final List<File> newImages =
          await _imageService.pickMultipleImagesFromGallery();
      if (newImages.isNotEmpty) {
        setState(() {
          selectedImages.addAll(newImages);
        });
        await _loadImageMetadata();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding images: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
      if (imageMetadata.length > index) {
        imageMetadata.removeAt(index);
      }
    });

    // Update dimensions if we removed the first image
    if (index == 0 && imageMetadata.isNotEmpty) {
      _updateDimensionsFromFirstImage();
    }
  }

  double _calculateTotalOriginalSize() {
    return imageMetadata.fold(
        0.0, (sum, meta) => sum + (meta.fileSizeBytes / (1024 * 1024)));
  }

  double _calculateEstimatedResizedSize() {
    if (imageMetadata.isEmpty) return 0.0;

    double totalEstimatedSize = 0.0;

    for (var meta in imageMetadata) {
      double ratio;

      if (isByDimensions) {
        final targetWidth = int.tryParse(widthController.text) ?? meta.width;
        final targetHeight = int.tryParse(heightController.text) ?? meta.height;
        final originalPixels = meta.width * meta.height;
        final targetPixels = targetWidth * targetHeight;
        ratio = targetPixels / originalPixels;
      } else {
        final percentage = double.tryParse(percentageController.text) ?? 100.0;
        ratio = (percentage * percentage) /
            10000; // Square because it affects both width and height
      }

      // Estimate file size based on pixel ratio (rough approximation)
      final estimatedSize = (meta.fileSizeBytes * ratio) / (1024 * 1024);
      totalEstimatedSize += estimatedSize;
    }

    return totalEstimatedSize;
  }

  String _getTargetDimensionsString() {
    if (imageMetadata.isEmpty) return 'Unknown';

    if (isByDimensions) {
      final width =
          int.tryParse(widthController.text) ?? imageMetadata[0].width;
      final height =
          int.tryParse(heightController.text) ?? imageMetadata[0].height;
      final megapixels = ((width * height) / 1000000).toStringAsFixed(1);
      return '$width×$height ($megapixels MP)';
    } else {
      final percentage = double.tryParse(percentageController.text) ?? 100.0;
      final originalWidth = imageMetadata[0].width;
      final originalHeight = imageMetadata[0].height;
      final newWidth = ((originalWidth * percentage) / 100).round();
      final newHeight = ((originalHeight * percentage) / 100).round();
      final megapixels = ((newWidth * newHeight) / 1000000).toStringAsFixed(1);
      return '$newWidth×$newHeight ($megapixels MP)';
    }
  }

  Future<void> _resizeImages() async {
    if (selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select images to resize')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      List<File> resizedImages = [];
      List<ImageMetadata> originalMetadata = [...imageMetadata];
      List<ImageMetadata> resizedMetadata = [];

      for (int i = 0; i < selectedImages.length; i++) {
        File resizedImage;

        if (isByDimensions) {
          final width =
              int.tryParse(widthController.text) ?? imageMetadata[i].width;
          final height =
              int.tryParse(heightController.text) ?? imageMetadata[i].height;

          resizedImage = await _imageService.resizeImage(
            selectedImages[i],
            width: width,
            height: height,
            maintainAspectRatio: lockAspectRatio,
          );
        } else {
          final percentage =
              double.tryParse(percentageController.text) ?? 100.0;
          resizedImage = await _imageService.resizeImageByPercentage(
            selectedImages[i],
            percentage: percentage,
          );
        }

        resizedImages.add(resizedImage);

        final resizedMeta = await _imageService.getImageMetadata(resizedImage);
        resizedMetadata.add(resizedMeta);
      }

      // Navigate to export page with resize results
      Navigator.pushNamed(
        context,
        '/export',
        arguments: {
          'processedImages': resizedImages,
          'originalMetadata': originalMetadata,
          'processedMetadata': resizedMetadata,
          'operation': 'resize',
          'settings': {
            'method': isByDimensions ? 'dimensions' : 'percentage',
            'width': isByDimensions ? int.tryParse(widthController.text) : null,
            'height':
                isByDimensions ? int.tryParse(heightController.text) : null,
            'percentage': !isByDimensions
                ? double.tryParse(percentageController.text)
                : null,
            'lockAspectRatio': lockAspectRatio,
            'algorithm': 'Lanczos',
          },
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resizing images: $e')),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showPreviewDialog() {
    if (selectedImages.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resize Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Method: ${isByDimensions ? "By Dimensions" : "By Percentage"}'),
            const SizedBox(height: 8),
            if (isByDimensions) ...[
              Text(
                  'Target Size: ${widthController.text}×${heightController.text} px'),
              Text('Aspect Ratio: ${lockAspectRatio ? "Locked" : "Free"}'),
            ] else ...[
              Text('Percentage: ${percentageController.text}%'),
            ],
            const SizedBox(height: 8),
            Text('Images: ${selectedImages.length}'),
            const SizedBox(height: 8),
            Text(
                'Original Size: ${_calculateTotalOriginalSize().toStringAsFixed(1)} MB'),
            const SizedBox(height: 8),
            Text(
                'Estimated Size: ${_calculateEstimatedResizedSize().toStringAsFixed(1)} MB'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Resize',
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selected Images Section
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
                      TextButton(
                        onPressed: _addMultipleImages,
                        child: Text(
                          'Add More',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Image selection grid
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedImages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == selectedImages.length) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: AddImageSlot(
                            onTap: _addImage,
                          ),
                        );
                      }

                      return Padding(
                        padding: EdgeInsets.only(
                            right: index == selectedImages.length - 1 ? 0 : 12),
                        child: ImageSlot(
                          hasImage: true,
                          imageFile: selectedImages[index],
                          onRemove: () => _removeImage(index),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Resize Method Section
                Text(
                  'Resize Method',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              isByDimensions = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isByDimensions
                                  ? Colors.black
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'By Dimensions',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isByDimensions
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              isByDimensions = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !isByDimensions
                                  ? Colors.black
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'By Percentage',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: !isByDimensions
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Input Fields Section
                if (isByDimensions) ...[
                  // Dimensions input
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Width (px)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: TextField(
                                controller: widthController,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Height (px)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: TextField(
                                controller: heightController,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Lock Aspect Ratio
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            lockAspectRatio = !lockAspectRatio;
                          });
                        },
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color:
                                lockAspectRatio ? Colors.black : Colors.white,
                            border: Border.all(
                              color: lockAspectRatio
                                  ? Colors.black
                                  : Colors.grey[400]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: lockAspectRatio
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Lock aspect ratio',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Percentage input
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resize Percentage',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextField(
                          controller: percentageController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            suffixText: '%',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 8),

                Text(
                  'Algorithm: Lanczos',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),

                const SizedBox(height: 24),

                // Size Preview Section
                if (imageMetadata.isNotEmpty) ...[
                  Text(
                    'Size Preview',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSizeRow('Original:',
                            '${imageMetadata[0].width}×${imageMetadata[0].height} (${((imageMetadata[0].width * imageMetadata[0].height) / 1000000).toStringAsFixed(1)} MP)'),
                        const SizedBox(height: 8),
                        _buildSizeRow('Resized:', _getTargetDimensionsString()),
                        const SizedBox(height: 8),
                        _buildSizeRow('File size:',
                            '~${_calculateEstimatedResizedSize().toStringAsFixed(1)} MB total'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                const SizedBox(height: 8),

                // Bottom Buttons
                Row(
                  children: [
                    Expanded(
                      child: ActionButton(
                        text: 'Preview',
                        isPrimary: false,
                        onTap:
                            selectedImages.isEmpty ? null : _showPreviewDialog,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ActionButton(
                        text: isLoading ? 'Resizing...' : 'Resize',
                        isPrimary: false,
                        onTap: (isLoading || selectedImages.isEmpty)
                            ? null
                            : _resizeImages,
                      ),
                    ),
                  ],
                ),

                // Extra bottom padding to avoid overflow
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSizeRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    widthController.dispose();
    heightController.dispose();
    percentageController.dispose();
    super.dispose();
  }
}
