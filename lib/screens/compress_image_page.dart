// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import '../services/image_service.dart';
import '../widgets/action_button.dart';
import '../widgets/add_image_slot.dart';
import '../widgets/image_slot.dart';

class CompressImagePage extends StatefulWidget {
  const CompressImagePage({super.key});

  @override
  State<CompressImagePage> createState() => _CompressImagePageState();
}

class _CompressImagePageState extends State<CompressImagePage> {
  double quality = 80.0;
  List<File> selectedImages = [];
  List<ImageMetadata> imageMetadata = [];
  bool isLoading = false;
  final ImageService _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    // Initialize with some images if passed from previous screen
    _loadInitialImages();
  }

  void _loadInitialImages() async {
    // If images were passed via arguments, load them
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
  }

  double _calculateTotalOriginalSize() {
    return imageMetadata.fold(
        0.0, (sum, meta) => sum + (meta.fileSizeBytes / (1024 * 1024)));
  }

  double _calculateEstimatedCompressedSize() {
    final originalSize = _calculateTotalOriginalSize();
    // Rough estimation based on quality
    final compressionRatio = quality / 100.0;
    return originalSize * compressionRatio;
  }

  double _calculateSavedSize() {
    return _calculateTotalOriginalSize() - _calculateEstimatedCompressedSize();
  }

  Future<void> _processImages() async {
    if (selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select images to compress')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      List<File> compressedImages = [];
      List<ImageMetadata> originalMetadata = [...imageMetadata];
      List<ImageMetadata> compressedMetadata = [];

      for (int i = 0; i < selectedImages.length; i++) {
        final compressedImage = await _imageService
            .compressImage(selectedImages[i], quality: quality.round());
        compressedImages.add(compressedImage);

        final compressedMeta =
            await _imageService.getImageMetadata(compressedImage);
        compressedMetadata.add(compressedMeta);
      }

      // Navigate to export page with processing results
      Navigator.pushNamed(
        context,
        '/export',
        arguments: {
          'processedImages': compressedImages,
          'originalMetadata': originalMetadata,
          'processedMetadata': compressedMetadata,
          'operation': 'compress',
          'settings': {
            'quality': quality.round(),
          },
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing images: $e')),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
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
          'Compress',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
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

              const SizedBox(height: 15),

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

              const SizedBox(height: 30),

              // Quality section
              Text(
                'Quality',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),

              const SizedBox(height: 15),

              // Quality slider with percentage
              Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.black,
                        inactiveTrackColor: Colors.grey[300],
                        thumbColor: Colors.black,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 16),
                      ),
                      child: Slider(
                        value: quality,
                        min: 10,
                        max: 100,
                        onChanged: (value) {
                          setState(() {
                            quality = value;
                          });
                        },
                      ),
                    ),
                  ),
                  Container(
                    width: 50,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${quality.round()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Size Preview section
              if (imageMetadata.isNotEmpty) ...[
                Text(
                  'Size Preview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),

                const SizedBox(height: 12),

                // Size details
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
                          '${_calculateTotalOriginalSize().toStringAsFixed(1)} MB'),
                      const SizedBox(height: 8),
                      _buildSizeRow('Compressed:',
                          '${_calculateEstimatedCompressedSize().toStringAsFixed(1)} MB'),
                      const SizedBox(height: 8),
                      _buildSizeRow('Saved:',
                          '${_calculateSavedSize().toStringAsFixed(1)} MB'),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],

              const Spacer(),

              // Quality preset buttons
              Row(
                children: [
                  _buildPresetButton('Lossless', quality == 100.0),
                  const SizedBox(width: 12),
                  _buildPresetButton('Lossy', quality == 80.0),
                ],
              ),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      text: 'Preview',
                      isPrimary: false,
                      onTap: selectedImages.isEmpty
                          ? null
                          : () {
                              // Show preview dialog or navigate to preview screen
                              _showPreviewDialog();
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ActionButton(
                      text: isLoading ? 'Processing...' : 'Process',
                      isPrimary: false,
                      onTap: (isLoading || selectedImages.isEmpty)
                          ? null
                          : _processImages,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),
            ],
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
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (text == 'Lossy') {
            quality = 80.0;
          } else {
            quality = 100.0;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  void _showPreviewDialog() {
    if (selectedImages.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Compression Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quality: ${quality.round()}%'),
            const SizedBox(height: 8),
            Text('Images: ${selectedImages.length}'),
            const SizedBox(height: 8),
            Text(
                'Original Size: ${_calculateTotalOriginalSize().toStringAsFixed(1)} MB'),
            const SizedBox(height: 8),
            Text(
                'Estimated Size: ${_calculateEstimatedCompressedSize().toStringAsFixed(1)} MB'),
            const SizedBox(height: 8),
            Text('Space Saved: ${_calculateSavedSize().toStringAsFixed(1)} MB'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Cleanup any resources if needed
    super.dispose();
  }
}
