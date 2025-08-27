import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../state/image_state_manager.dart';
import '../services/image_service.dart';
import '../widgets/action_button.dart';
import '../widgets/format_button.dart';
import '../widgets/image_slot.dart';
import '../widgets/png_option_row.dart';

class ConvertImagePage extends StatefulWidget {
  const ConvertImagePage({super.key});

  @override
  State<ConvertImagePage> createState() => _ConvertImagePageState();
}

class _ConvertImagePageState extends State<ConvertImagePage> {
  String selectedFormat = 'PNG';
  bool compressionEnabled = true;
  bool interlacedEnabled = false;
  bool _isProcessing = false;
  int jpegQuality = 95;

  final ImageStateManager _stateManager = ImageStateManager();
  final ImageService _imageService = ImageService();

  // Store converted images data
  List<Uint8List>? _convertedImages;
  List<Map<String, dynamic>>? _originalImageInfo;

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

  Future<void> _convertImages() async {
    if (!_stateManager.hasImages) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      List<Uint8List> converted = await _imageService.batchProcessImages(
        _stateManager.selectedImages,
        (imageFile) => _imageService.convertImage(
          imageFile,
          outputFormat: selectedFormat,
          quality: jpegQuality,
          pngCompression: compressionEnabled,
          pngInterlaced: interlacedEnabled,
        ),
        onProgress: (current, total) {
          debugPrint('Converting $current/$total');
        },
      );

      setState(() {
        _convertedImages = converted;
        _isProcessing = false;
      });

      // Navigate to export page with converted data
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/export',
          arguments: {
            'convertedImages': _convertedImages,
            'originalImageInfo': _originalImageInfo,
            'operation': 'converted',
            'outputFormat': selectedFormat,
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
            content: Text('Error converting images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _getTotalOriginalSize() {
    if (_originalImageInfo == null) return 0.0;
    return _originalImageInfo!
        .fold(0.0, (sum, info) => sum + info['fileSizeMB']);
  }

  double _getEstimatedOutputSize() {
    if (_originalImageInfo == null) return 0.0;

    double totalSize = _getTotalOriginalSize();

    switch (selectedFormat) {
      case 'JPEG':
        return totalSize *
            (jpegQuality / 100) *
            0.8; // JPEG is typically smaller
      case 'PNG':
        return totalSize *
            (compressionEnabled ? 0.9 : 1.1); // PNG can be larger or smaller
      case 'WebP':
        return totalSize * 0.7; // WebP is typically smaller
      case 'BMP':
        return totalSize * 3.0; // BMP is much larger
      case 'TIFF':
        return totalSize * 1.2; // TIFF is typically larger
      case 'HEIC':
        return totalSize * 0.6; // HEIC is very efficient
      default:
        return totalSize;
    }
  }

  final List<Map<String, String>> formats = [
    {'format': 'JPEG', 'description': 'Small size'},
    {'format': 'PNG', 'description': 'Transparent'},
    {'format': 'WebP', 'description': 'Modern format'},
    {'format': 'HEIC', 'description': 'iOS format\nHigh quality'},
    {'format': 'BMP', 'description': 'Windows\nLarge size'},
    {'format': 'TIFF', 'description': 'Print\nLossless'},
  ];

  @override
  Widget build(BuildContext context) {
    final estimatedSize = _getEstimatedOutputSize();

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
          'Convert',
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
              // Selected Images section
              Text(
                'Selected Images (${_stateManager.imageCount})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
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
                            right:
                                index < _stateManager.imageCount - 1 ? 12 : 0),
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

              // Output Format section
              const Text(
                'Output Format',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              // Format grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: formats
                    .map((format) => FormatButton(
                          format: format['format']!,
                          description: format['description']!,
                          isSelected: selectedFormat == format['format'],
                          onPressed: () {
                            setState(() {
                              selectedFormat = format['format']!;
                            });
                          },
                        ))
                    .toList(),
              ),

              const SizedBox(height: 32),

              // Format-specific options
              if (selectedFormat == 'PNG') ...[
                const Text(
                  'PNG Options',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      PngOptionRow(
                        title: 'Compression',
                        subtitle: 'Reduce file size',
                        value: compressionEnabled,
                        onChanged: (value) {
                          setState(() {
                            compressionEnabled = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      PngOptionRow(
                        title: 'Interlaced',
                        subtitle: 'Progressive loading',
                        value: interlacedEnabled,
                        onChanged: (value) {
                          setState(() {
                            interlacedEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              if (selectedFormat == 'JPEG') ...[
                const Text(
                  'JPEG Options',
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
                            'Quality',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            '${jpegQuality}%',
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
                          value: jpegQuality.toDouble(),
                          min: 10,
                          max: 100,
                          onChanged: (value) {
                            setState(() {
                              jpegQuality = value.round();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Output info
              Text(
                _stateManager.hasImages
                    ? 'Output: ${_stateManager.imageCount} ${selectedFormat} files (~${estimatedSize.toStringAsFixed(1)} MB total)'
                    : 'Output: No images selected',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: ActionButton(
                      text: _isProcessing ? 'Converting...' : 'Convert',
                      isPrimary: true,
                      onPressed: _stateManager.hasImages && !_isProcessing
                          ? _convertImages
                          : null,
                    ),
                  ),
                ],
              ),

              // Extra padding to ensure no overflow
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
