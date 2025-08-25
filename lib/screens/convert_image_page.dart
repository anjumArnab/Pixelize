// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import '../services/image_service.dart';
import '../widgets/action_button.dart';
import '../widgets/add_image_slot.dart';
import '../widgets/image_slot.dart';

class ConvertImagePage extends StatefulWidget {
  const ConvertImagePage({super.key});

  @override
  State<ConvertImagePage> createState() => _ConvertImagePageState();
}

class _ConvertImagePageState extends State<ConvertImagePage> {
  String selectedFormat = 'PNG';
  bool compressionInterlaced = false;
  bool interlaced = false;
  List<File> selectedImages = [];
  List<ImageMetadata> imageMetadata = [];
  bool isLoading = false;
  final ImageService _imageService = ImageService();

  // Format descriptions
  final Map<String, String> formatDescriptions = {
    'JPEG': 'Smaller\nfile size',
    'PNG': 'Transparency\nsupport',
    'WebP': 'Modern\nformat',
    'HEIC': 'iOS native\nhigh quality',
    'BMP': 'Uncompressed\nlarge size',
    'TIFF': 'Print\nstandard',
  };

  @override
  void initState() {
    super.initState();
    _loadInitialImages();
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

  ImageFormat _getImageFormat(String formatName) {
    switch (formatName) {
      case 'JPEG':
        return ImageFormat.jpeg;
      case 'PNG':
        return ImageFormat.png;
      case 'WebP':
        return ImageFormat.webp;
      case 'HEIC':
        return ImageFormat.jpeg; // Fallback to JPEG for HEIC
      case 'BMP':
        return ImageFormat.bmp;
      case 'TIFF':
        return ImageFormat.tiff;
      default:
        return ImageFormat.png;
    }
  }

  double _calculateTotalOriginalSize() {
    return imageMetadata.fold(
        0.0, (sum, meta) => sum + (meta.fileSizeBytes / (1024 * 1024)));
  }

  double _estimateConvertedSize() {
    if (imageMetadata.isEmpty) return 0.0;

    // Rough size estimation based on format
    final originalSize = _calculateTotalOriginalSize();
    double multiplier;

    switch (selectedFormat) {
      case 'JPEG':
        multiplier = 0.3; // JPEG is typically smaller
        break;
      case 'PNG':
        multiplier = 1.5; // PNG is typically larger
        break;
      case 'WebP':
        multiplier = 0.25; // WebP is very efficient
        break;
      case 'BMP':
        multiplier = 3.0; // BMP is uncompressed
        break;
      case 'TIFF':
        multiplier = 2.0; // TIFF is large
        break;
      case 'HEIC':
        multiplier = 0.2; // HEIC is very efficient
        break;
      default:
        multiplier = 1.0;
    }

    return originalSize * multiplier;
  }

  Future<void> _convertImages() async {
    if (selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select images to convert')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      List<File> convertedImages = [];
      List<ImageMetadata> originalMetadata = [...imageMetadata];
      List<ImageMetadata> convertedMetadata = [];

      final ImageFormat targetFormat = _getImageFormat(selectedFormat);

      for (int i = 0; i < selectedImages.length; i++) {
        final convertedImage = await _imageService.convertImageFormat(
          selectedImages[i],
          format: targetFormat,
          quality: selectedFormat == 'JPEG' ? 90 : 100,
        );
        convertedImages.add(convertedImage);

        final convertedMeta =
            await _imageService.getImageMetadata(convertedImage);
        convertedMetadata.add(convertedMeta);
      }

      // Navigate to export page with conversion results
      Navigator.pushNamed(
        context,
        '/export',
        arguments: {
          'processedImages': convertedImages,
          'originalMetadata': originalMetadata,
          'processedMetadata': convertedMetadata,
          'operation': 'convert',
          'settings': {
            'format': selectedFormat,
            'compression': compressionInterlaced,
            'interlaced': interlaced,
          },
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error converting images: $e')),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showPreview() {
    if (selectedImages.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Conversion Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target Format: $selectedFormat'),
            const SizedBox(height: 8),
            Text('Images: ${selectedImages.length}'),
            const SizedBox(height: 8),
            Text(
                'Original Size: ${_calculateTotalOriginalSize().toStringAsFixed(1)} MB'),
            const SizedBox(height: 8),
            Text(
                'Estimated Size: ${_estimateConvertedSize().toStringAsFixed(1)} MB'),
            if (selectedFormat == 'PNG' && compressionInterlaced)
              const Text('\nPNG Compression: Enabled'),
            if (selectedFormat == 'PNG' && interlaced)
              const Text('PNG Interlaced: Enabled'),
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
          'Convert',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
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
                                right: index == selectedImages.length - 1
                                    ? 0
                                    : 12),
                            child: ImageSlot(
                              hasImage: true,
                              imageFile: selectedImages[index],
                              onRemove: () => _removeImage(index),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Output Format section
                    const Text(
                      'Output Format',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Format options grid
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: _buildFormatCard(
                                    'JPEG',
                                    formatDescriptions['JPEG']!,
                                    selectedFormat == 'JPEG')),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildFormatCard(
                                    'PNG',
                                    formatDescriptions['PNG']!,
                                    selectedFormat == 'PNG')),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildFormatCard(
                                    'WebP',
                                    formatDescriptions['WebP']!,
                                    selectedFormat == 'WebP')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: _buildFormatCard(
                                    'HEIC',
                                    formatDescriptions['HEIC']!,
                                    selectedFormat == 'HEIC')),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildFormatCard(
                                    'BMP',
                                    formatDescriptions['BMP']!,
                                    selectedFormat == 'BMP')),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildFormatCard(
                                    'TIFF',
                                    formatDescriptions['TIFF']!,
                                    selectedFormat == 'TIFF')),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // PNG Options section (conditional)
                    if (selectedFormat == 'PNG') ...[
                      const Text(
                        'PNG Options',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 15),

                      // PNG options container
                      Container(
                        width: double.infinity,
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
                          children: [
                            _buildToggleOption(
                                'Compression', compressionInterlaced, (value) {
                              setState(() {
                                compressionInterlaced = value;
                              });
                            }),
                            const SizedBox(height: 12),
                            _buildToggleOption('Interlaced', interlaced,
                                (value) {
                              setState(() {
                                interlaced = value;
                              });
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),
                    ],

                    // Output info
                    if (imageMetadata.isNotEmpty) ...[
                      Text(
                        'Output: ${selectedImages.length} $selectedFormat files (~${_estimateConvertedSize().toStringAsFixed(1)} MB total)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Size comparison
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
                            Text(
                              'Size Estimation',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildSizeRow('Original:',
                                '${_calculateTotalOriginalSize().toStringAsFixed(1)} MB'),
                            const SizedBox(height: 8),
                            _buildSizeRow('Converted ($selectedFormat):',
                                '${_estimateConvertedSize().toStringAsFixed(1)} MB'),
                          ],
                        ),
                      ),
                    ],

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
                      onTap: selectedImages.isEmpty ? null : _showPreview,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ActionButton(
                      text: isLoading ? 'Converting...' : 'Convert',
                      isPrimary: false,
                      onTap: (isLoading || selectedImages.isEmpty)
                          ? null
                          : _convertImages,
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

  Widget _buildFormatCard(String format, String description, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFormat = format;
        });
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[200]!,
          ),
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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                format,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white70 : Colors.grey[500],
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption(
      String title, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.black,
          activeTrackColor: Colors.grey[300],
          inactiveThumbColor: Colors.grey[400],
          inactiveTrackColor: Colors.grey[200],
        ),
      ],
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

  @override
  void dispose() {
    super.dispose();
  }
}
