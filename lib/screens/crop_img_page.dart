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

  double _getBorderRadius(double screenWidth) {
    return screenWidth > 600 ? 16.0 : 12.0;
  }

  double _getIconSize(double screenWidth) {
    if (screenWidth > 800) return 56.0;
    if (screenWidth > 600) return 52.0;
    return 48.0;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

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
          'Crop',
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
                      _buildSelectedImagesSection(availableWidth),

                      SizedBox(height: sectionSpacing),

                      // Crop preview info
                      _buildCropPreviewSection(availableWidth),

                      SizedBox(height: sectionSpacing),

                      // Aspect Ratio section
                      _buildAspectRatioSection(availableWidth),

                      SizedBox(height: sectionSpacing),

                      // Output size
                      _buildOutputSizeSection(availableWidth),

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

  Widget _buildCropPreviewSection(double screenWidth) {
    return Container(
      width: double.infinity,
      padding: _getCardPadding(screenWidth),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
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
          Icon(
            Icons.crop,
            size: _getIconSize(screenWidth),
            color: Colors.grey[400],
          ),
          SizedBox(height: screenWidth > 600 ? 12 : 8),
          Text(
            'Crop Preview',
            style: TextStyle(
              fontSize: _getFontSizeTitle(screenWidth),
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: screenWidth > 600 ? 6 : 4),
          Text(
            'Selected ratio: $selectedRatio',
            style: TextStyle(
              fontSize: _getFontSizeBody(screenWidth),
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAspectRatioSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aspect Ratio',
          style: TextStyle(
            fontSize: _getFontSizeTitle(screenWidth),
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),

        SizedBox(height: screenWidth > 600 ? 18 : 16),

        // Aspect ratio buttons - Responsive
        screenWidth > 800
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _buildAspectRatioButtons(screenWidth),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _buildAspectRatioButtons(screenWidth),
                ),
              ),
      ],
    );
  }

  List<Widget> _buildAspectRatioButtons(double screenWidth) {
    final aspectRatios = ['1:1', '16:9', '4:3', 'Free'];
    final spacing = _getCardSpacing(screenWidth);

    return aspectRatios.asMap().entries.map((entry) {
      int index = entry.key;
      String ratio = entry.value;

      return Padding(
        padding: EdgeInsets.only(
          right: index < aspectRatios.length - 1 ? spacing : 0,
        ),
        child: AspectRatioButton(
          ratio: ratio,
          isSelected: selectedRatio == ratio,
          onPressed: () {
            setState(() {
              selectedRatio = ratio;
            });
          },
        ),
      );
    }).toList();
  }

  Widget _buildOutputSizeSection(double screenWidth) {
    return Container(
      width: double.infinity,
      padding: _getCardPadding(screenWidth),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        'Output: ${_getOutputDimensions()}',
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
          )
        : Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ActionButton(
                  text: 'Reset',
                  onPressed: _stateManager.hasImages ? _resetCrop : null,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: double.infinity,
                child: ActionButton(
                  text: _isProcessing ? 'Processing...' : 'Apply Crop',
                  isPrimary: true,
                  onPressed: _stateManager.hasImages && !_isProcessing
                      ? _applyCrop
                      : null,
                ),
              ),
            ],
          );
  }
}
