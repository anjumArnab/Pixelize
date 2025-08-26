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

  @override
  Widget build(BuildContext context) {
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Export',
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
                // Processed Images count
                Text(
                  '${_getOperationDisplayName()} Images (${_processedImages?.length ?? 0})',
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
                                'No images processed',
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

                // Processing summary card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // File name preview
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _stateManager.hasImages
                                ? _imageService.generateFileName(
                                    originalName:
                                        _stateManager.getImageAt(0)?.name ??
                                            'image.jpg',
                                    operation: _operation,
                                    customPattern: fileNamePattern,
                                  )
                                : 'No images',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Before/After size comparison
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Before',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${originalSize.toStringAsFixed(1)} MB',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'After',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${processedSize.toStringAsFixed(1)} MB',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Size reduction percentage
                        Text(
                          savedSize >= 0
                              ? '$reductionPercentage% size reduction'
                              : '${reductionPercentage.abs()}% size increase',
                          style: TextStyle(
                            fontSize: 13,
                            color: savedSize >= 0
                                ? Colors.green[600]
                                : Colors.orange[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        // Output format info if available
                        if (_outputFormat != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Format: $_outputFormat',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Export Settings
                const Text(
                  'Export Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // File Name Pattern
                Text(
                  'File Name Pattern',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    // Show pattern selection dialog
                    _showPatternDialog();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            fileNamePattern,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Icon(Icons.edit, size: 16, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Save Location
                Text(
                  'Save Location',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    // Show location selection dialog
                    _showLocationDialog();
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Text(
                              saveLocation,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.folder,
                          size: 16,
                          color: Colors.grey[600],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Processing summary
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
                        'Total: ${_processedImages?.length ?? 0} images ${_operation}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Space saved: ${originalSize.toStringAsFixed(1)} MB → ${processedSize.toStringAsFixed(1)} MB',
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
                        text: _isSharing ? 'Sharing...' : 'Share',
                        onPressed:
                            hasProcessedImages && !_isSharing && !_isSaving
                                ? _shareImages
                                : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ActionButton(
                        text: _isSaving ? 'Saving...' : 'Save All',
                        isPrimary: true,
                        onPressed:
                            hasProcessedImages && !_isSaving && !_isSharing
                                ? _saveAllImages
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
