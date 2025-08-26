import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../state/image_state_manager.dart';
import '../widgets/aspect_ratio_button.dart';
import '../widgets/action_button.dart';
import '../widgets/image_slot.dart';
import '../services/image_service.dart';

class CropImagePage extends StatefulWidget {
  const CropImagePage({super.key});

  @override
  State<CropImagePage> createState() => _CropImagePageState();
}

class _CropImagePageState extends State<CropImagePage> {
  String selectedRatio = '16:9';
  bool _isProcessing = false;
  List<Uint8List>? _croppedImages;
  List<Map<String, dynamic>>? _originalImageInfo;

  final ImageStateManager _stateManager = ImageStateManager();
  final ImageService _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    _stateManager.addListener(_onImageStateChanged);
    _loadImageInfo();
  }

  @override
  void dispose() {
    _stateManager.removeListener(_onImageStateChanged);
    super.dispose();
  }

  void _onImageStateChanged() {
    setState(() {});
    _loadImageInfo();
  }

  Future<void> _loadImageInfo() async {
    if (!_stateManager.hasImages) return;

    try {
      List<Map<String, dynamic>> infoList = [];
      for (var image in _stateManager.selectedImages) {
        var info = await _imageService.getImageInfo(image);
        infoList.add(info);
      }
      setState(() {
        _originalImageInfo = infoList;
      });
    } catch (e) {
      debugPrint('Error loading image info: $e');
    }
  }

  Future<void> _applyCrop() async {
    if (!_stateManager.hasImages) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      List<Uint8List> croppedImages = [];

      for (int i = 0; i < _stateManager.imageCount; i++) {
        final imageFile = _stateManager.getImageAt(i);
        if (imageFile == null) continue;

        // Get image info to calculate crop dimensions
        final imageInfo = await _imageService.getImageInfo(imageFile);
        final imageWidth = imageInfo['width'] as int;
        final imageHeight = imageInfo['height'] as int;

        // Calculate crop dimensions based on aspect ratio
        int cropWidth, cropHeight;
        int cropX = 0, cropY = 0;

        switch (selectedRatio) {
          case '1:1':
            final minDimension =
                imageWidth < imageHeight ? imageWidth : imageHeight;
            cropWidth = minDimension;
            cropHeight = minDimension;
            cropX = (imageWidth - cropWidth) ~/ 2;
            cropY = (imageHeight - cropHeight) ~/ 2;
            break;
          case '16:9':
            if (imageWidth / imageHeight > 16 / 9) {
              cropHeight = imageHeight;
              cropWidth = (cropHeight * 16 / 9).round();
              cropX = (imageWidth - cropWidth) ~/ 2;
            } else {
              cropWidth = imageWidth;
              cropHeight = (cropWidth * 9 / 16).round();
              cropY = (imageHeight - cropHeight) ~/ 2;
            }
            break;
          case '4:3':
            if (imageWidth / imageHeight > 4 / 3) {
              cropHeight = imageHeight;
              cropWidth = (cropHeight * 4 / 3).round();
              cropX = (imageWidth - cropWidth) ~/ 2;
            } else {
              cropWidth = imageWidth;
              cropHeight = (cropWidth * 3 / 4).round();
              cropY = (imageHeight - cropHeight) ~/ 2;
            }
            break;
          case 'Free':
          default:
            cropWidth = imageWidth;
            cropHeight = imageHeight;
            break;
        }

        // Perform the crop
        final croppedBytes = await _imageService.cropImage(
          imageFile,
          x: cropX,
          y: cropY,
          width: cropWidth,
          height: cropHeight,
          aspectRatio: selectedRatio.toLowerCase(),
        );

        croppedImages.add(croppedBytes);
      }

      setState(() {
        _croppedImages = croppedImages;
        _isProcessing = false;
      });

      // Navigate to export page with cropped images - Fixed data passing
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/export',
          arguments: {
            'processedImages': _croppedImages, // Changed from inconsistent key
            'originalImageInfo': _originalImageInfo,
            'operation': 'cropped', // Added operation type
          },
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cropping images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getOutputDimensions() {
    if (!_stateManager.hasImages) return '0×0 px';

    switch (selectedRatio) {
      case '1:1':
        return '1080×1080 px';
      case '16:9':
        return '1920×1080 px';
      case '4:3':
        return '1440×1080 px';
      case 'Free':
        return 'Original size';
      default:
        return '1920×1080 px';
    }
  }

  void _resetCrop() {
    setState(() {
      selectedRatio = '16:9';
      _croppedImages = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Crop',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected Image section
              Text(
                'Selected Images (${_stateManager.imageCount})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              // Image slots row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...List.generate(_stateManager.imageCount, (index) {
                      return Padding(
                        padding: EdgeInsets.only(
                            right:
                                index < _stateManager.imageCount - 1 ? 12 : 0),
                        child: ImageSlot(
                          hasImage: true,
                          imageFile: _stateManager.getImageAt(index),
                          onTap: () {},
                        ),
                      );
                    }),
                    if (_stateManager.imageCount == 0)
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No images selected',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Crop preview info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.crop,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crop Preview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Selected ratio: $selectedRatio',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Aspect Ratio section
              const Text(
                'Aspect Ratio',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              // Aspect ratio buttons
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    AspectRatioButton(
                      ratio: '1:1',
                      isSelected: selectedRatio == '1:1',
                      onPressed: () {
                        setState(() {
                          selectedRatio = '1:1';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    AspectRatioButton(
                      ratio: '16:9',
                      isSelected: selectedRatio == '16:9',
                      onPressed: () {
                        setState(() {
                          selectedRatio = '16:9';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    AspectRatioButton(
                      ratio: '4:3',
                      isSelected: selectedRatio == '4:3',
                      onPressed: () {
                        setState(() {
                          selectedRatio = '4:3';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    AspectRatioButton(
                      ratio: 'Free',
                      isSelected: selectedRatio == 'Free',
                      onPressed: () {
                        setState(() {
                          selectedRatio = 'Free';
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Output size
              Text(
                'Output: ${_getOutputDimensions()}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 32),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      text: 'Reset',
                      onPressed: _stateManager.hasImages ? _resetCrop : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ActionButton(
                      text: _isProcessing ? 'Processing...' : 'Apply Crop',
                      isPrimary: true,
                      onPressed: _stateManager.hasImages && !_isProcessing
                          ? _applyCrop
                          : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
