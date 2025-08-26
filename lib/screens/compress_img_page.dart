import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../widgets/action_button.dart';
import '../widgets/image_slot.dart';
import '../state/image_state_manager.dart';
import '../services/image_service.dart';

class CompressImagePage extends StatefulWidget {
  const CompressImagePage({super.key});

  @override
  State<CompressImagePage> createState() => _CompressImagePageState();
}

class _CompressImagePageState extends State<CompressImagePage> {
  double _qualityValue = 80.0;
  bool _isLossless = false;
  bool _isProcessing = false;
  final ImageStateManager _stateManager = ImageStateManager();
  final ImageService _imageService = ImageService();

  // Store processed images data
  List<Uint8List>? _processedImages;
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

  Future<void> _compressImages() async {
    if (!_stateManager.hasImages) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      List<Uint8List> compressed = await _imageService.batchProcessImages(
        _stateManager.selectedImages,
        (imageFile) => _imageService.compressImage(
          imageFile,
          quality: _qualityValue.round(),
          lossless: _isLossless,
        ),
        onProgress: (current, total) {
          // Could show progress indicator here
          debugPrint('Processing $current/$total');
        },
      );

      setState(() {
        _processedImages = compressed;
        _isProcessing = false;
      });

      // Navigate to export page with compressed data
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/export',
          arguments: {
            'processedImages': _processedImages,
            'originalImageInfo': _originalImageInfo,
            'operation': 'compressed',
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
            content: Text('Error compressing images: $e'),
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

  double _getEstimatedCompressedSize() {
    if (_isLossless)
      return _getTotalOriginalSize() *
          0.7; // Lossless typically 70% of original
    return _getTotalOriginalSize() * (_qualityValue / 100);
  }

  @override
  Widget build(BuildContext context) {
    final originalSize = _getTotalOriginalSize();
    final estimatedSize = _getEstimatedCompressedSize();
    final savedSize = originalSize - estimatedSize;

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
          'Compress',
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

              // Quality section
              const Text(
                'Quality',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              // Quality slider (only show if not lossless)
              if (!_isLossless) ...[
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
                            '${_qualityValue.round()}%',
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
                          value: _qualityValue,
                          min: 10,
                          max: 100,
                          onChanged: (value) {
                            setState(() {
                              _qualityValue = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Size Preview section
              const Text(
                'Size Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              // Size preview container
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
                    _buildSizeRow(
                        'Original:',
                        _stateManager.hasImages
                            ? '${originalSize.toStringAsFixed(1)} MB'
                            : 'No images'),
                    const SizedBox(height: 8),
                    _buildSizeRow(
                        'Compressed:',
                        _stateManager.hasImages
                            ? '${estimatedSize.toStringAsFixed(1)} MB'
                            : 'No images'),
                    const SizedBox(height: 8),
                    _buildSizeRow(
                        'Saved:',
                        _stateManager.hasImages
                            ? '${savedSize.toStringAsFixed(1)} MB'
                            : 'No images'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Lossless/Lossy toggle
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isLossless = true),
                              child: Container(
                                height: 36,
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: _isLossless
                                      ? Colors.black87
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Center(
                                  child: Text(
                                    'Lossless',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _isLossless
                                          ? Colors.white
                                          : Colors.black54,
                                      fontWeight: _isLossless
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isLossless = false),
                              child: Container(
                                height: 36,
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: !_isLossless
                                      ? Colors.black87
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Center(
                                  child: Text(
                                    'Lossy',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: !_isLossless
                                          ? Colors.white
                                          : Colors.black54,
                                      fontWeight: !_isLossless
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      text: 'Preview',
                      onPressed: _stateManager.hasImages && !_isProcessing
                          ? () {
                              // Handle preview action
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Preview functionality coming soon')),
                              );
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ActionButton(
                      text: _isProcessing ? 'Processing...' : 'Process',
                      isPrimary: true,
                      onPressed: _stateManager.hasImages && !_isProcessing
                          ? _compressImages
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

  Widget _buildSizeRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
