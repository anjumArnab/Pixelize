import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../services/image_service.dart';
import '../widgets/action_button.dart';
import '../widgets/image_slot.dart';

class ExportImagePage extends StatefulWidget {
  const ExportImagePage({super.key});

  @override
  State<ExportImagePage> createState() => _ExportImagePageState();
}

class _ExportImagePageState extends State<ExportImagePage> {
  late TextEditingController fileNameController;
  late TextEditingController saveLocationController;

  List<File> processedImages = [];
  List<ImageMetadata> originalMetadata = [];
  List<ImageMetadata> processedMetadata = [];
  String operation = 'process';
  Map<String, dynamic> settings = {};
  int selectedImageIndex = 0;
  bool isLoading = false;

  final ImageService _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    fileNameController =
        TextEditingController(text: 'pixelized_{original}_{date}');
    saveLocationController = TextEditingController(text: '/Photos/Pixelize/');

    // Load arguments passed from processing page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadArguments();
    });
  }

  void _loadArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      setState(() {
        processedImages = args['processedImages'] ?? [];
        originalMetadata = args['originalMetadata'] ?? [];
        processedMetadata = args['processedMetadata'] ?? [];
        operation = args['operation'] ?? 'process';
        settings = args['settings'] ?? {};

        // Update file name pattern based on operation
        fileNameController.text = '${operation}ed_{original}_{date}';
      });
    }
  }

  String _getOperationDisplayName() {
    switch (operation) {
      case 'compress':
        return 'Compressed';
      case 'resize':
        return 'Resized';
      case 'convert':
        return 'Converted';
      case 'crop':
        return 'Cropped';
      default:
        return 'Processed';
    }
  }

  double _calculateTotalOriginalSize() {
    return originalMetadata.fold(
        0.0, (sum, meta) => sum + (meta.fileSizeBytes / (1024 * 1024)));
  }

  double _calculateTotalProcessedSize() {
    return processedMetadata.fold(
        0.0, (sum, meta) => sum + (meta.fileSizeBytes / (1024 * 1024)));
  }

  double _calculateSpaceSaved() {
    return _calculateTotalOriginalSize() - _calculateTotalProcessedSize();
  }

  double _calculateSizeReduction() {
    final original = _calculateTotalOriginalSize();
    if (original == 0) return 0;
    return ((_calculateSpaceSaved() / original) * 100);
  }

  Future<void> _saveAllImages() async {
    if (processedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No images to save')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      List<String> savedPaths = [];

      for (int i = 0; i < processedImages.length; i++) {
        final originalFileName = originalMetadata[i].fileName;
        final customFileName = _generateFileName(originalFileName, i);

        final savedPath = await _imageService.saveImageToDevice(
          processedImages[i],
          customFileName: customFileName,
          customDirectory: saveLocationController.text.replaceAll('/', ''),
        );

        savedPaths.add(savedPath);
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully saved ${savedPaths.length} images'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Clean up temporary files
      await _imageService.cleanupTempFiles();

      // Navigate back to home
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _generateFileName(String originalFileName, int index) {
    final pattern = fileNameController.text;
    final nameWithoutExt = originalFileName.split('.').first;
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final date = DateTime.now().toIso8601String().split('T')[0];

    return pattern
        .replaceAll('{original}', nameWithoutExt)
        .replaceAll('{date}', date)
        .replaceAll('{timestamp}', timestamp)
        .replaceAll('{index}', (index + 1).toString());
  }

  Future<void> _shareImages() async {
    if (processedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No images to share')),
      );
      return;
    }

    try {
      final List<XFile> xFiles =
          processedImages.map((file) => XFile(file.path)).toList();

      await Share.shareXFiles(
        xFiles,
        text: '${_getOperationDisplayName()} images using Pixelize app',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing images: $e')),
        );
      }
    }
  }

  void _showImageDetails(int index) {
    if (index >= processedImages.length ||
        index >= originalMetadata.length ||
        index >= processedMetadata.length) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File: ${originalMetadata[index].fileName}'),
            const SizedBox(height: 8),
            Text(
                'Original: ${originalMetadata[index].width}×${originalMetadata[index].height} (${originalMetadata[index].fileSizeMB} MB)'),
            const SizedBox(height: 8),
            Text(
                '${_getOperationDisplayName()}: ${processedMetadata[index].width}×${processedMetadata[index].height} (${processedMetadata[index].fileSizeMB} MB)'),
            const SizedBox(height: 8),
            // Operation-specific details
            if (operation == 'compress' && settings['quality'] != null)
              Text('Quality: ${settings['quality']}%'),
            if (operation == 'resize') ...[
              Text(
                  'Method: ${settings['method'] == 'dimensions' ? 'By Dimensions' : 'By Percentage'}'),
              if (settings['method'] == 'dimensions' &&
                  settings['width'] != null &&
                  settings['height'] != null)
                Text('Target: ${settings['width']}×${settings['height']} px')
              else if (settings['method'] == 'percentage' &&
                  settings['percentage'] != null)
                Text('Percentage: ${settings['percentage']}%'),
              if (settings['lockAspectRatio'] == true)
                Text('Aspect ratio: Locked'),
            ],
            if (operation == 'convert') ...[
              Text('Format: ${settings['format'] ?? 'Unknown'}'),
              if (settings['compression'] == true)
                Text('PNG Compression: Enabled'),
              if (settings['interlaced'] == true)
                Text('PNG Interlaced: Enabled'),
            ],
            // Crop-specific details
            if (operation == 'crop') ...[
              Text('Aspect Ratio: ${settings['aspectRatio'] ?? 'Custom'}'),
              if (settings['cropX'] != null && settings['cropY'] != null)
                Text(
                    'Crop Position: ${settings['cropX']}, ${settings['cropY']}'),
              if (settings['cropWidth'] != null &&
                  settings['cropHeight'] != null)
                Text(
                    'Crop Size: ${settings['cropWidth']}×${settings['cropHeight']} px'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back,
              color: Colors.grey[800],
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Export',
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Processed Images Section
                Text(
                  '${_getOperationDisplayName()} Images (${processedImages.length})',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // Images Row
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: processedImages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(
                            right:
                                index == processedImages.length - 1 ? 0 : 12),
                        child: ImageSlot(
                          hasImage: true,
                          imageFile: processedImages[index],
                          onTap: () {
                            setState(() {
                              selectedImageIndex = index;
                            });
                            _showImageDetails(index);
                          },
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Selected Image Details
                if (processedImages.isNotEmpty &&
                    selectedImageIndex < originalMetadata.length &&
                    selectedImageIndex < processedMetadata.length)
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
                        Text(
                          originalMetadata[selectedImageIndex].fileName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'Before',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${originalMetadata[selectedImageIndex].fileSizeMB} MB',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${originalMetadata[selectedImageIndex].width}×${originalMetadata[selectedImageIndex].height}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'After',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${processedMetadata[selectedImageIndex].fileSizeMB} MB',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${processedMetadata[selectedImageIndex].width}×${processedMetadata[selectedImageIndex].height}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (originalMetadata[selectedImageIndex].fileSizeBytes >
                            processedMetadata[selectedImageIndex].fileSizeBytes)
                          Text(
                            '${(((originalMetadata[selectedImageIndex].fileSizeBytes - processedMetadata[selectedImageIndex].fileSizeBytes) / originalMetadata[selectedImageIndex].fileSizeBytes) * 100).toStringAsFixed(0)}% size reduction',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[600],
                            ),
                          )
                        else if (processedMetadata[selectedImageIndex]
                                .fileSizeBytes >
                            originalMetadata[selectedImageIndex].fileSizeBytes)
                          Text(
                            '${(((processedMetadata[selectedImageIndex].fileSizeBytes - originalMetadata[selectedImageIndex].fileSizeBytes) / originalMetadata[selectedImageIndex].fileSizeBytes) * 100).toStringAsFixed(0)}% size increase',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[600],
                            ),
                          )
                        else
                          Text(
                            'No size change',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Export Settings
                Text(
                  'Export Settings',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // File Name Pattern
                Text(
                  'File Name Pattern',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: fileNameController,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      hintText: 'Use {original}, {date}, {timestamp}, {index}',
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Save Location
                Text(
                  'Save Location',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: saveLocationController,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: const Icon(
                          Icons.folder,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Processing Summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total: ${processedImages.length} images processed',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_calculateSpaceSaved() > 0)
                        Text(
                          'Space saved: ${_calculateTotalOriginalSize().toStringAsFixed(1)} MB → ${_calculateTotalProcessedSize().toStringAsFixed(1)} MB (${_calculateSizeReduction().toStringAsFixed(1)}% reduction)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[600],
                          ),
                        )
                      else if (_calculateSpaceSaved() < 0)
                        Text(
                          'Size increase: ${_calculateTotalOriginalSize().toStringAsFixed(1)} MB → ${_calculateTotalProcessedSize().toStringAsFixed(1)} MB',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[600],
                          ),
                        )
                      else
                        Text(
                          'Size unchanged: ${_calculateTotalOriginalSize().toStringAsFixed(1)} MB',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      // Operation-specific summary details
                      if (operation == 'compress' &&
                          settings['quality'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Compression quality: ${settings['quality']}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (operation == 'resize') ...[
                        const SizedBox(height: 4),
                        if (settings['method'] == 'dimensions' &&
                            settings['width'] != null &&
                            settings['height'] != null)
                          Text(
                            'Resize method: ${settings['width']}×${settings['height']} px${settings['lockAspectRatio'] == true ? ' (aspect ratio locked)' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          )
                        else if (settings['method'] == 'percentage' &&
                            settings['percentage'] != null)
                          Text(
                            'Resize method: ${settings['percentage']}% scale',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                      if (operation == 'convert' &&
                          settings['format'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Converted to: ${settings['format']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      // Crop-specific summary details
                      if (operation == 'crop') ...[
                        const SizedBox(height: 4),
                        Text(
                          'Aspect ratio: ${settings['aspectRatio'] ?? 'Custom'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (settings['cropWidth'] != null &&
                            settings['cropHeight'] != null)
                          Text(
                            'Crop dimensions: ${settings['cropWidth']}×${settings['cropHeight']} px',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Bottom Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ActionButton(
                        text: 'Share',
                        isPrimary: false,
                        onTap: processedImages.isEmpty ? null : _shareImages,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ActionButton(
                        text: isLoading ? 'Saving...' : 'Save All',
                        isPrimary: true,
                        onTap: (isLoading || processedImages.isEmpty)
                            ? null
                            : _saveAllImages,
                      ),
                    ),
                  ],
                ),

                // Extra bottom padding to avoid overflow
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    fileNameController.dispose();
    saveLocationController.dispose();
    super.dispose();
  }
}
