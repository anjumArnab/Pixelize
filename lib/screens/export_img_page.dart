import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'dart:io';
import '../state/image_state_manager.dart';
import '../widgets/action_button.dart';
import '../widgets/image_slot.dart';
import '../services/image_service.dart';

class ExportImagePage extends StatefulWidget {
  const ExportImagePage({super.key});

  @override
  State<ExportImagePage> createState() => _ExportImagePageState();
}

class _ExportImagePageState extends State<ExportImagePage> {
  String fileNamePattern = "[operation]_[original]_[date]";
  String saveLocation = "PhotosPixelized";
  bool _isSaving = false;
  bool _isSharing = false;

  // Data from route arguments
  List<Uint8List>? _processedImages;
  List<Map<String, dynamic>>? _originalImageInfo;
  String _operation = "processed";
  String? _outputFormat;

  final ImageStateManager _stateManager = ImageStateManager();
  final ImageService _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    _stateManager.addListener(_onImageStateChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _extractRouteArguments();
  }

  @override
  void dispose() {
    _stateManager.removeListener(_onImageStateChanged);
    super.dispose();
  }

  void _extractRouteArguments() {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (arguments != null) {
      setState(() {
        // Handle different key names from different pages
        _processedImages = arguments['processedImages'] as List<Uint8List>? ??
            arguments['convertedImages'] as List<Uint8List>?;
        _originalImageInfo =
            arguments['originalImageInfo'] as List<Map<String, dynamic>>?;
        _operation = arguments['operation'] as String? ?? "processed";
        _outputFormat = arguments['outputFormat'] as String?;

        // Update file name pattern based on operation
        _updateFileNamePattern();
      });
    }
  }

  void _updateFileNamePattern() {
    switch (_operation) {
      case 'compressed':
        fileNamePattern = "compressed_[original]_[date]";
        break;
      case 'converted':
        fileNamePattern = "converted_[original]_[date]";
        break;
      case 'cropped':
        fileNamePattern = "cropped_[original]_[date]";
        break;
      case 'resized':
        fileNamePattern = "resized_[original]_[date]";
        break;
      default:
        fileNamePattern = "[operation]_[original]_[date]";
        break;
    }
  }

  void _onImageStateChanged() {
    setState(() {});
  }

  double _getTotalOriginalSize() {
    if (_originalImageInfo == null) return 0.0;
    return _originalImageInfo!
        .fold(0.0, (sum, info) => sum + info['fileSizeMB']);
  }

  double _getTotalProcessedSize() {
    if (_processedImages == null) return 0.0;
    return _processedImages!
        .fold(0.0, (sum, bytes) => sum + (bytes.length / (1024 * 1024)));
  }

  Future<void> _saveAllImages() async {
    if (_processedImages == null || _processedImages!.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      List<String> savedPaths = [];

      for (int i = 0; i < _processedImages!.length; i++) {
        final originalImage = _stateManager.getImageAt(i);
        if (originalImage == null) continue;

        final fileName = _imageService.generateFileName(
          originalName: originalImage.name,
          operation: _operation,
          customPattern: fileNamePattern,
        );

        final savedPath = await _imageService.saveImageToStorage(
          _processedImages![i],
          fileName: fileName,
          folderName: saveLocation,
        );

        savedPaths.add(savedPath);
      }

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully saved ${savedPaths.length} images'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareImages() async {
    if (_processedImages == null || _processedImages!.isEmpty) return;

    setState(() {
      _isSharing = true;
    });

    try {
      // Save images to temporary files for sharing
      List<XFile> tempFiles = [];

      for (int i = 0; i < _processedImages!.length; i++) {
        final originalImage = _stateManager.getImageAt(i);
        if (originalImage == null) continue;

        final fileName = _imageService.generateFileName(
          originalName: originalImage.name,
          operation: _operation,
        );

        // Create temporary file
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsBytes(_processedImages![i]);

        tempFiles.add(XFile(tempFile.path));
      }

      // Share files
      await Share.shareXFiles(
        tempFiles,
        text: '${_operation.capitalize()} images from Pixelize',
      );

      setState(() {
        _isSharing = false;
      });
    } catch (e) {
      setState(() {
        _isSharing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getOperationDisplayName() {
    switch (_operation) {
      case 'compressed':
        return 'Compressed';
      case 'converted':
        return 'Converted';
      case 'cropped':
        return 'Cropped';
      case 'resized':
        return 'Resized';
      default:
        return 'Processed';
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

  EdgeInsets _getSmallCardPadding(double screenWidth) {
    if (screenWidth > 800) return const EdgeInsets.all(16.0);
    if (screenWidth > 600) return const EdgeInsets.all(14.0);
    return const EdgeInsets.all(12.0);
  }

  EdgeInsets _getFieldPadding(double screenWidth) {
    if (screenWidth > 600)
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    return const EdgeInsets.symmetric(horizontal: 14, vertical: 10);
  }

  double _getFontSizeTitle(double screenWidth) {
    if (screenWidth > 800) return 20.0;
    if (screenWidth > 600) return 19.0;
    return 18.0;
  }

  double _getFontSizeSubtitle(double screenWidth) {
    if (screenWidth > 800) return 16.0;
    if (screenWidth > 600) return 15.0;
    return 14.0;
  }

  double _getFontSizeBody(double screenWidth) {
    if (screenWidth > 800) return 16.0;
    if (screenWidth > 600) return 15.0;
    return 14.0;
  }

  double _getFontSizeCaption(double screenWidth) {
    if (screenWidth > 800) return 14.0;
    if (screenWidth > 600) return 13.0;
    return 12.0;
  }

  double _getBorderRadius(double screenWidth) {
    return screenWidth > 600 ? 16.0 : 12.0;
  }

  double _getSmallBorderRadius(double screenWidth) {
    return screenWidth > 600 ? 12.0 : 8.0;
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
    final originalSize = _getTotalOriginalSize();
    final processedSize = _getTotalProcessedSize();
    final savedSize = originalSize - processedSize;
    final reductionPercentage =
        originalSize > 0 ? ((savedSize / originalSize) * 100).round() : 0;
    final hasProcessedImages =
        _processedImages != null && _processedImages!.isNotEmpty;

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
          'Export',
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

                      // Processing summary card
                      _buildProcessingSummaryCard(availableWidth, originalSize,
                          processedSize, reductionPercentage, savedSize),

                      SizedBox(height: sectionSpacing),

                      // Export Settings
                      _buildExportSettingsSection(availableWidth),

                      SizedBox(height: sectionSpacing),

                      // Processing summary
                      _buildProcessingResultsCard(
                          availableWidth, originalSize, processedSize),

                      SizedBox(height: isLandscape ? 32 : 40),

                      // Action buttons
                      _buildActionButtons(
                          availableWidth, isLandscape, hasProcessedImages),

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
          '${_getOperationDisplayName()} Images (${_processedImages?.length ?? 0})',
          style: TextStyle(
            fontSize: _getFontSizeSubtitle(screenWidth),
            color: Colors.grey[600],
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
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.image_not_supported,
            size: _getIconSize(screenWidth),
            color: Colors.grey[400],
          ),
          SizedBox(height: screenWidth > 600 ? 12 : 8),
          Text(
            'No images processed',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: _getFontSizeBody(screenWidth),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingSummaryCard(
    double screenWidth,
    double originalSize,
    double processedSize,
    int reductionPercentage,
    double savedSize,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        boxShadow: screenWidth > 600
            ? [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Padding(
        padding: _getCardPadding(screenWidth),
        child: Column(
          children: [
            // File name preview
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: screenWidth > 600 ? 14 : 12,
                horizontal: screenWidth > 600 ? 16 : 12,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius:
                    BorderRadius.circular(_getSmallBorderRadius(screenWidth)),
              ),
              child: Text(
                _stateManager.hasImages
                    ? _imageService.generateFileName(
                        originalName:
                            _stateManager.getImageAt(0)?.name ?? 'image.jpg',
                        operation: _operation,
                        customPattern: fileNamePattern,
                      )
                    : 'No images',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _getFontSizeBody(screenWidth),
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),

            SizedBox(height: screenWidth > 600 ? 20 : 16),

            // Before/After size comparison - Responsive
            screenWidth > 600
                ? Row(
                    children: _buildSizeComparisonCards(
                        screenWidth, originalSize, processedSize),
                  )
                : Column(
                    children: [
                      ..._buildSizeComparisonCards(
                          screenWidth, originalSize, processedSize),
                    ]
                        .map((card) => Container(
                              width: double.infinity,
                              margin: EdgeInsets.only(bottom: 12),
                              child: card,
                            ))
                        .toList(),
                  ),

            SizedBox(height: screenWidth > 600 ? 16 : 12),

            // Size reduction percentage
            Text(
              savedSize >= 0
                  ? '$reductionPercentage% size reduction'
                  : '${reductionPercentage.abs()}% size increase',
              style: TextStyle(
                fontSize: _getFontSizeCaption(screenWidth) + 1,
                color: savedSize >= 0 ? Colors.green[600] : Colors.orange[600],
                fontWeight: FontWeight.w500,
              ),
            ),

            // Output format info if available
            if (_outputFormat != null) ...[
              SizedBox(height: screenWidth > 600 ? 10 : 8),
              Text(
                'Format: $_outputFormat',
                style: TextStyle(
                  fontSize: _getFontSizeCaption(screenWidth),
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSizeComparisonCards(
      double screenWidth, double originalSize, double processedSize) {
    final spacing = screenWidth > 600 ? 12.0 : 8.0;

    return [
      Expanded(
        child: Container(
          padding: _getSmallCardPadding(screenWidth),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius:
                BorderRadius.circular(_getSmallBorderRadius(screenWidth)),
          ),
          child: Column(
            children: [
              Text(
                'Before',
                style: TextStyle(
                  fontSize: _getFontSizeCaption(screenWidth),
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${originalSize.toStringAsFixed(1)} MB',
                style: TextStyle(
                  fontSize: _getFontSizeBody(screenWidth),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
      SizedBox(width: spacing),
      Expanded(
        child: Container(
          padding: _getSmallCardPadding(screenWidth),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius:
                BorderRadius.circular(_getSmallBorderRadius(screenWidth)),
          ),
          child: Column(
            children: [
              Text(
                'After',
                style: TextStyle(
                  fontSize: _getFontSizeCaption(screenWidth),
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${processedSize.toStringAsFixed(1)} MB',
                style: TextStyle(
                  fontSize: _getFontSizeBody(screenWidth),
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildExportSettingsSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Settings',
          style: TextStyle(
            fontSize: _getFontSizeTitle(screenWidth),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),

        SizedBox(height: screenWidth > 600 ? 20 : 16),

        // File Name Pattern
        Text(
          'File Name Pattern',
          style: TextStyle(
            fontSize: _getFontSizeBody(screenWidth),
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),

        SizedBox(height: screenWidth > 600 ? 10 : 8),

        GestureDetector(
          onTap: () => _showPatternDialog(),
          child: Container(
            width: double.infinity,
            padding: _getFieldPadding(screenWidth),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(_getBorderRadius(screenWidth)),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    fileNamePattern,
                    style: TextStyle(
                      fontSize: _getFontSizeBody(screenWidth),
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(Icons.edit,
                    size: screenWidth > 600 ? 18 : 16, color: Colors.grey[600]),
              ],
            ),
          ),
        ),

        SizedBox(height: screenWidth > 600 ? 24 : 20),

        // Save Location
        Text(
          'Save Location',
          style: TextStyle(
            fontSize: _getFontSizeBody(screenWidth),
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),

        SizedBox(height: screenWidth > 600 ? 10 : 8),

        GestureDetector(
          onTap: () => _showLocationDialog(),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(_getBorderRadius(screenWidth)),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: _getFieldPadding(screenWidth),
                    child: Text(
                      saveLocation,
                      style: TextStyle(
                        fontSize: _getFontSizeBody(screenWidth),
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: screenWidth > 600 ? 16 : 14),
                  child: Icon(
                    Icons.folder,
                    size: screenWidth > 600 ? 18 : 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingResultsCard(
      double screenWidth, double originalSize, double processedSize) {
    return Container(
      width: double.infinity,
      padding: _getCardPadding(screenWidth),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total: ${_processedImages?.length ?? 0} images ${_operation}',
            style: TextStyle(
              fontSize: _getFontSizeBody(screenWidth),
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Space saved: ${originalSize.toStringAsFixed(1)} MB → ${processedSize.toStringAsFixed(1)} MB',
            style: TextStyle(
              fontSize: _getFontSizeBody(screenWidth),
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      double screenWidth, bool isLandscape, bool hasProcessedImages) {
    return screenWidth > 800 && !isLandscape
        ? Row(
            children: [
              Expanded(
                child: ActionButton(
                  text: _isSharing ? 'Sharing...' : 'Share',
                  onPressed: hasProcessedImages && !_isSharing && !_isSaving
                      ? _shareImages
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ActionButton(
                  text: _isSaving ? 'Saving...' : 'Save All',
                  isPrimary: true,
                  onPressed: hasProcessedImages && !_isSaving && !_isSharing
                      ? _saveAllImages
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
                  text: _isSharing ? 'Sharing...' : 'Share',
                  onPressed: hasProcessedImages && !_isSharing && !_isSaving
                      ? _shareImages
                      : null,
                ),
              ),
              SizedBox(height: screenWidth > 600 ? 16 : 12),
              SizedBox(
                width: double.infinity,
                child: ActionButton(
                  text: _isSaving ? 'Saving...' : 'Save All',
                  isPrimary: true,
                  onPressed: hasProcessedImages && !_isSaving && !_isSharing
                      ? _saveAllImages
                      : null,
                ),
              ),
            ],
          );
  }

  void _showPatternDialog() {
    final patterns = [
      '[operation]_[original]_[date]',
      'compressed_[original]_[date]',
      '[original]_[operation]',
      'pixelize_[original]',
      '[date]_[original]',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Name Pattern'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose a naming pattern for your ${_operation} images:'),
            const SizedBox(height: 16),
            ...patterns.map((pattern) => _buildPatternOption(pattern)),
          ],
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

  Widget _buildPatternOption(String pattern) {
    return ListTile(
      title: Text(pattern),
      leading: Radio<String>(
        value: pattern,
        groupValue: fileNamePattern,
        onChanged: (value) {
          setState(() {
            fileNamePattern = value!;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showLocationDialog() {
    final locations = [
      'PhotosPixelized',
      'CompressedImages',
      'ProcessedImages',
      'Downloads',
      'Pictures',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose where to save your ${_operation} images:'),
            const SizedBox(height: 16),
            ...locations.map((location) => _buildLocationOption(location)),
          ],
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

  Widget _buildLocationOption(String location) {
    return ListTile(
      title: Text(location),
      leading: Radio<String>(
        value: location,
        groupValue: saveLocation,
        onChanged: (value) {
          setState(() {
            saveLocation = value!;
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
