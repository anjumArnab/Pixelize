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

  int _getFormatGridCrossAxisCount(double screenWidth) {
    if (screenWidth > 1000) return 6; // Large desktop - single row
    if (screenWidth > 600) return 3; // Tablet - same as mobile
    return 3; // Mobile
  }

  double _getFormatGridChildAspectRatio(double screenWidth) {
    if (screenWidth > 1000) return 1.0; // More square on large screens
    return 1.2; // Default ratio for smaller screens
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final estimatedSize = _getEstimatedOutputSize();

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
          'Convert',
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
                  maxWidth: availableWidth > 1000 ? 900 : double.infinity,
                ),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selected Images section
                      _buildSelectedImagesSection(availableWidth),

                      SizedBox(height: sectionSpacing),

                      // Output Format section
                      _buildOutputFormatSection(availableWidth),

                      SizedBox(height: sectionSpacing),

                      // Format-specific options
                      if (selectedFormat == 'PNG')
                        _buildPngOptionsSection(availableWidth, sectionSpacing),

                      if (selectedFormat == 'JPEG')
                        _buildJpegOptionsSection(
                            availableWidth, sectionSpacing),

                      // Output info
                      _buildOutputInfo(availableWidth, estimatedSize),

                      SizedBox(height: sectionSpacing),

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

  Widget _buildSelectedImagesSection(double screenWidth) {
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

  Widget _buildOutputFormatSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Output Format',
          style: TextStyle(
            fontSize: _getFontSizeTitle(screenWidth),
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),

        SizedBox(height: screenWidth > 600 ? 18 : 16),

        // Format grid - Responsive
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: _getFormatGridCrossAxisCount(screenWidth),
          crossAxisSpacing: screenWidth > 600 ? 16 : 12,
          mainAxisSpacing: screenWidth > 600 ? 16 : 12,
          childAspectRatio: _getFormatGridChildAspectRatio(screenWidth),
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
      ],
    );
  }

  Widget _buildPngOptionsSection(double screenWidth, double sectionSpacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PNG Options',
          style: TextStyle(
            fontSize: _getFontSizeTitle(screenWidth),
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: screenWidth > 600 ? 18 : 16),
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
              SizedBox(height: screenWidth > 600 ? 20 : 16),
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
        SizedBox(height: sectionSpacing),
      ],
    );
  }

  Widget _buildJpegOptionsSection(double screenWidth, double sectionSpacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'JPEG Options',
          style: TextStyle(
            fontSize: _getFontSizeTitle(screenWidth),
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: screenWidth > 600 ? 18 : 16),
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
                    '${jpegQuality}%',
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
        SizedBox(height: sectionSpacing),
      ],
    );
  }

  Widget _buildOutputInfo(double screenWidth, double estimatedSize) {
    return Container(
      width: double.infinity,
      padding: _getCardPadding(screenWidth),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(screenWidth > 600 ? 16 : 12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        _stateManager.hasImages
            ? 'Output: ${_stateManager.imageCount} ${selectedFormat} files (~${estimatedSize.toStringAsFixed(1)} MB total)'
            : 'Output: No images selected',
        style: TextStyle(
          fontSize: _getFontSizeBody(screenWidth),
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
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
                  text: _isProcessing ? 'Converting...' : 'Convert',
                  isPrimary: true,
                  onPressed: _stateManager.hasImages && !_isProcessing
                      ? _convertImages
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
                  text: _isProcessing ? 'Converting...' : 'Convert',
                  isPrimary: true,
                  onPressed: _stateManager.hasImages && !_isProcessing
                      ? _convertImages
                      : null,
                ),
              ),
            ],
          );
  }
}
