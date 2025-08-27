import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../state/image_state_manager.dart';
import '../services/image_service.dart';
import '../widgets/action_button.dart';
import '../widgets/image_slot.dart';

class ResizeImagePage extends StatefulWidget {
  const ResizeImagePage({super.key});

  @override
  State<ResizeImagePage> createState() => _ResizeImagePageState();
}

class _ResizeImagePageState extends State<ResizeImagePage> {
  bool isDimensionsSelected = true;
  bool lockAspectRatio = true;
  String algorithm = "Lanczos";
  bool _isProcessing = false;
  double _percentageValue = 50.0;

  final ImageStateManager _stateManager = ImageStateManager();
  final ImageService _imageService = ImageService();

  // Store resized images data
  List<Uint8List>? _resizedImages;
  List<Map<String, dynamic>>? _originalImageInfo;

  final TextEditingController widthController =
      TextEditingController(text: "1920");
  final TextEditingController heightController =
      TextEditingController(text: "1080");

  @override
  void initState() {
    super.initState();
    _stateManager.addListener(_onImageStateChanged);
    _loadImageInfo();

    // Listen to width/height changes for aspect ratio locking
    widthController.addListener(_onWidthChanged);
    heightController.addListener(_onHeightChanged);
  }

  @override
  void dispose() {
    _stateManager.removeListener(_onImageStateChanged);
    widthController.dispose();
    heightController.dispose();
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
        // Update default dimensions based on first image
        if (infoList.isNotEmpty) {
          widthController.text = infoList[0]['width'].toString();
          heightController.text = infoList[0]['height'].toString();
        }
      });
    } catch (e) {
      debugPrint('Error loading image info: $e');
    }
  }

  void _onWidthChanged() {
    if (lockAspectRatio &&
        _originalImageInfo != null &&
        _originalImageInfo!.isNotEmpty) {
      final originalWidth = _originalImageInfo![0]['width'];
      final originalHeight = _originalImageInfo![0]['height'];
      final aspectRatio = originalWidth / originalHeight;

      final newWidth = int.tryParse(widthController.text);
      if (newWidth != null) {
        final newHeight = (newWidth / aspectRatio).round();
        heightController.text = newHeight.toString();
      }
    }
  }

  void _onHeightChanged() {
    if (lockAspectRatio &&
        _originalImageInfo != null &&
        _originalImageInfo!.isNotEmpty) {
      final originalWidth = _originalImageInfo![0]['width'];
      final originalHeight = _originalImageInfo![0]['height'];
      final aspectRatio = originalWidth / originalHeight;

      final newHeight = int.tryParse(heightController.text);
      if (newHeight != null) {
        final newWidth = (newHeight * aspectRatio).round();
        widthController.text = newWidth.toString();
      }
    }
  }

  Future<void> _resizeImages() async {
    if (!_stateManager.hasImages) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      List<Uint8List> resized = await _imageService.batchProcessImages(
        _stateManager.selectedImages,
        (imageFile) {
          if (isDimensionsSelected) {
            final width = int.tryParse(widthController.text);
            final height = int.tryParse(heightController.text);

            return _imageService.resizeImage(
              imageFile,
              width: width,
              height: height,
              maintainAspectRatio: lockAspectRatio,
              algorithm: algorithm.toLowerCase(),
            );
          } else {
            return _imageService.resizeImage(
              imageFile,
              percentage: _percentageValue / 100,
              algorithm: algorithm.toLowerCase(),
            );
          }
        },
        onProgress: (current, total) {
          debugPrint('Resizing $current/$total');
        },
      );

      setState(() {
        _resizedImages = resized;
        _isProcessing = false;
      });

      // Navigate to export page with resized data
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/export',
          arguments: {
            'processedImages': _resizedImages,
            'originalImageInfo': _originalImageInfo,
            'operation': 'resized',
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
            content: Text('Error resizing images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _getPreviewInfo() {
    if (_originalImageInfo == null || _originalImageInfo!.isEmpty) {
      return {
        'originalWidth': 0,
        'originalHeight': 0,
        'originalMP': 0.0,
        'newWidth': 0,
        'newHeight': 0,
        'newMP': 0.0,
        'estimatedSize': 0.0,
      };
    }

    final originalInfo = _originalImageInfo![0];
    int newWidth, newHeight;

    if (isDimensionsSelected) {
      newWidth = int.tryParse(widthController.text) ?? originalInfo['width'];
      newHeight = int.tryParse(heightController.text) ?? originalInfo['height'];
    } else {
      newWidth = (originalInfo['width'] * _percentageValue / 100).round();
      newHeight = (originalInfo['height'] * _percentageValue / 100).round();
    }

    final newMP = (newWidth * newHeight) / 1000000;
    final originalSize = originalInfo['fileSizeMB'];
    final estimatedSize = originalSize *
        (newWidth * newHeight) /
        (originalInfo['width'] * originalInfo['height']);

    return {
      'originalWidth': originalInfo['width'],
      'originalHeight': originalInfo['height'],
      'originalMP': originalInfo['megapixels'],
      'newWidth': newWidth,
      'newHeight': newHeight,
      'newMP': newMP,
      'estimatedSize': estimatedSize,
    };
  }

  @override
  Widget build(BuildContext context) {
    final previewInfo = _getPreviewInfo();

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
          'Resize',
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
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selected Images count
                Text(
                  'Selected Images (${_stateManager.imageCount})',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),

                // Image slots row - Dynamic based on selected images
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...List.generate(_stateManager.imageCount, (index) {
                        return Padding(
                          padding: EdgeInsets.only(
                              right: index < _stateManager.imageCount - 1
                                  ? 12
                                  : 0),
                          child: ImageSlot(
                            hasImage: true,
                            imageFile: _stateManager.getImageAt(index),
                            onTap: () {
                              // Optional: Show image preview or options
                            },
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
                const SizedBox(height: 32),

                // Resize Method
                const Text(
                  'Resize Method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Method selection buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isDimensionsSelected = true;
                          });
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDimensionsSelected
                                ? Colors.black87
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDimensionsSelected
                                  ? Colors.black87
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'By Dimensions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isDimensionsSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isDimensionsSelected = false;
                          });
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: !isDimensionsSelected
                                ? Colors.black87
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: !isDimensionsSelected
                                  ? Colors.black87
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'By Percentage',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: !isDimensionsSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Input section
                if (isDimensionsSelected) ...[
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
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: TextField(
                                controller: widthController,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 16),
                                ),
                                onChanged: (value) {
                                  if (lockAspectRatio) {
                                    _onWidthChanged();
                                  }
                                },
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
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: TextField(
                                controller: heightController,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 16),
                                ),
                                onChanged: (value) {
                                  if (lockAspectRatio) {
                                    _onHeightChanged();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Lock aspect ratio
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
                                lockAspectRatio ? Colors.black87 : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: lockAspectRatio
                                  ? Colors.black87
                                  : Colors.grey[400]!,
                              width: 2,
                            ),
                          ),
                          child: lockAspectRatio
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Lock aspect ratio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Percentage input
                  const Text(
                    'Resize Percentage',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Scale',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              '${_percentageValue.round()}%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.black87,
                            inactiveTrackColor: Colors.grey[300],
                            thumbColor: Colors.black87,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _percentageValue,
                            min: 10,
                            max: 200,
                            onChanged: (value) {
                              setState(() {
                                _percentageValue = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Algorithm selection
                GestureDetector(
                  onTap: () => _showAlgorithmDialog(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Algorithm: $algorithm',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Size Preview
                const Text(
                  'Size Preview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Original: ${previewInfo['originalWidth']}×${previewInfo['originalHeight']} (${previewInfo['originalMP'].toStringAsFixed(1)} MP)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Resized: ${previewInfo['newWidth']}×${previewInfo['newHeight']} (${previewInfo['newMP'].toStringAsFixed(1)} MP)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Estimated size: ~${previewInfo['estimatedSize'].toStringAsFixed(1)} MB per image',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ActionButton(
                        text: 'Cancel',
                        onPressed: Navigator.canPop(context)
                            ? () => Navigator.pop(context)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ActionButton(
                        text: _isProcessing ? 'Resizing...' : 'Resize',
                        isPrimary: true,
                        onPressed: _stateManager.hasImages && !_isProcessing
                            ? _resizeImages
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20), // Extra padding at bottom
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAlgorithmDialog() {
    final algorithms = ['Lanczos', 'Linear', 'Cubic', 'Nearest', 'Average'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resize Algorithm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: algorithms
              .map((algo) => ListTile(
                    title: Text(algo),
                    leading: Radio<String>(
                      value: algo,
                      groupValue: algorithm,
                      onChanged: (value) {
                        setState(() {
                          algorithm = value!;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
