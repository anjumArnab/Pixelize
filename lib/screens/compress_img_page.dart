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

  // Responsive helper methods
  double _getHorizontalPadding(double screenWidth) {
    if (screenWidth > 1200) return 40.0; // Large desktop
    if (screenWidth > 800) return 30.0; // Tablet
    return 20.0; // Mobile
  }

  double _getSectionSpacing(double screenWidth, bool isLandscape) {
    if (isLandscape) return screenWidth > 800 ? 24.0 : 20.0;
    return screenWidth > 800 ? 32.0 : 28.0;
  }

  double _getCardSpacing(double screenWidth) {
    return screenWidth > 600 ? 16.0 : 12.0;
  }

  EdgeInsets _getCardPadding(double screenWidth) {
    if (screenWidth > 800) return const EdgeInsets.all(20.0);
    if (screenWidth > 600) return const EdgeInsets.all(18.0);
    return const EdgeInsets.all(16.0);
  }

  double _getFontSizeTitle(double screenWidth) {
    if (screenWidth > 800) return 18.0;
    if (screenWidth > 600) return 17.0;
    return 16.0;
  }

  double _getFontSizeBody(double screenWidth) {
    if (screenWidth > 800) return 16.0;
    if (screenWidth > 600) return 15.0;
    return 14.0;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final originalSize = _getTotalOriginalSize();
    final estimatedSize = _getEstimatedCompressedSize();
    final savedSize = originalSize - estimatedSize;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black87,
            size: screenWidth > 600 ? 24 : 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Compress',
          style: TextStyle(
            color: Colors.black87,
            fontSize: screenWidth > 600 ? 20 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final horizontalPadding = _getHorizontalPadding(availableWidth);
            final sectionSpacing =
                _getSectionSpacing(availableWidth, isLandscape);

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isLandscape ? 16.0 : 20.0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: availableWidth > 1000 ? 800 : double.infinity,
                ),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selected Images section
                      _buildSelectedImagesSection(availableWidth, isLandscape),

                      SizedBox(height: sectionSpacing),

                      // Quality section
                      _buildQualitySection(availableWidth),

                      SizedBox(height: sectionSpacing),

                      // Size Preview section
                      _buildSizePreviewSection(
                        availableWidth,
                        originalSize,
                        estimatedSize,
                        savedSize,
                      ),

                      SizedBox(height: sectionSpacing),

                      // Lossless/Lossy toggle
                      _buildCompressionToggle(availableWidth),

                      SizedBox(height: isLandscape ? 32 : 40),

                      // Action buttons
                      _buildActionButtons(availableWidth, isLandscape),

                      // Extra padding to ensure no overflow
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectedImagesSection(double screenWidth, bool isLandscape) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Images (${_stateManager.imageCount})',
          style: TextStyle(
            fontSize: _getFontSizeTitle(screenWidth),
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),

        SizedBox(height: screenWidth > 600 ? 18 : 16),

        // Image slots row - Dynamic based on selected images
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...List.generate(_stateManager.imageCount, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < _stateManager.imageCount - 1
                        ? _getCardSpacing(screenWidth)
                        : 0,
                  ),
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
                _buildNoImagesPlaceholder(screenWidth),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoImagesPlaceholder(double screenWidth) {
    final isLargeScreen = screenWidth > 600;

    return Center(
      child: Column(
        children: [
          Icon(
            Icons.image_not_supported,
            size: isLargeScreen ? 56 : 48,
            color: Colors.grey[400],
          ),
          SizedBox(height: isLargeScreen ? 12 : 8),
          Text(
            'No images selected',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: _getFontSizeBody(screenWidth),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualitySection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quality',
          style: TextStyle(
            fontSize: _getFontSizeTitle(screenWidth),
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),

        SizedBox(height: screenWidth > 600 ? 18 : 16),

        // Quality slider (only show if not lossless)
        if (!_isLossless)
          Container(
            padding: _getCardPadding(screenWidth),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screenWidth > 600 ? 16 : 12),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: screenWidth > 600
                  ? [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quality',
                      style: TextStyle(
                        fontSize: _getFontSizeBody(screenWidth),
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      '${_qualityValue.round()}%',
                      style: TextStyle(
                        fontSize: _getFontSizeBody(screenWidth),
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenWidth > 600 ? 8 : 4),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.black87,
                    inactiveTrackColor: Colors.grey[300],
                    thumbColor: Colors.black87,
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: screenWidth > 600 ? 10 : 8,
                    ),
                    trackHeight: screenWidth > 600 ? 5 : 4,
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
    );
  }

  Widget _buildSizePreviewSection(
    double screenWidth,
    double originalSize,
    double estimatedSize,
    double savedSize,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Size Preview',
          style: TextStyle(
            fontSize: _getFontSizeTitle(screenWidth),
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),

        SizedBox(height: screenWidth > 600 ? 18 : 16),

        // Size preview container
        Container(
          width: double.infinity,
          padding: _getCardPadding(screenWidth),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(screenWidth > 600 ? 16 : 12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: screenWidth > 600
                ? [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSizeRow(
                'Original:',
                _stateManager.hasImages
                    ? '${originalSize.toStringAsFixed(1)} MB'
                    : 'No images',
                screenWidth,
              ),
              SizedBox(height: screenWidth > 600 ? 12 : 8),
              _buildSizeRow(
                'Compressed:',
                _stateManager.hasImages
                    ? '${estimatedSize.toStringAsFixed(1)} MB'
                    : 'No images',
                screenWidth,
              ),
              SizedBox(height: screenWidth > 600 ? 12 : 8),
              _buildSizeRow(
                'Saved:',
                _stateManager.hasImages
                    ? '${savedSize.toStringAsFixed(1)} MB'
                    : 'No images',
                screenWidth,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompressionToggle(double screenWidth) {
    final isLargeScreen = screenWidth > 600;
    final toggleHeight = isLargeScreen ? 48.0 : 40.0;
    final borderRadius = toggleHeight / 2;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: toggleHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: isLargeScreen
                  ? [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isLossless = true),
                    child: Container(
                      height: toggleHeight - 4,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: _isLossless ? Colors.black87 : Colors.grey[100],
                        borderRadius: BorderRadius.circular(borderRadius - 2),
                      ),
                      child: Center(
                        child: Text(
                          'Lossless',
                          style: TextStyle(
                            fontSize: _getFontSizeBody(screenWidth),
                            color: _isLossless ? Colors.white : Colors.black54,
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
                      height: toggleHeight - 4,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: !_isLossless ? Colors.black87 : Colors.grey[100],
                        borderRadius: BorderRadius.circular(borderRadius - 2),
                      ),
                      child: Center(
                        child: Text(
                          'Lossy',
                          style: TextStyle(
                            fontSize: _getFontSizeBody(screenWidth),
                            color: !_isLossless ? Colors.white : Colors.black54,
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
    );
  }

  Widget _buildActionButtons(double screenWidth, bool isLandscape) {
    return screenWidth > 800 && !isLandscape
        ? Row(
            children: [
              Expanded(
                child: ActionButton(
                  text: 'Preview',
                  onPressed: _stateManager.hasImages && !_isProcessing
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Preview functionality coming soon')),
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
          )
        : Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ActionButton(
                  text: 'Preview',
                  onPressed: _stateManager.hasImages && !_isProcessing
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Preview functionality coming soon')),
                          );
                        }
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ActionButton(
                  text: _isProcessing ? 'Processing...' : 'Process',
                  isPrimary: true,
                  onPressed: _stateManager.hasImages && !_isProcessing
                      ? _compressImages
                      : null,
                ),
              ),
            ],
          );
  }

  Widget _buildSizeRow(String label, String value, double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: _getFontSizeBody(screenWidth),
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: _getFontSizeBody(screenWidth),
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
