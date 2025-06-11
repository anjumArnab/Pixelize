// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../widgets/img_preview_widget.dart';

class CompressImageScreen extends StatefulWidget {
  final File? imageFile;
  final Uint8List? webImageBytes;
  final String imageName;

  const CompressImageScreen({
    super.key,
    this.imageFile,
    this.webImageBytes,
    required this.imageName,
  });

  @override
  State<CompressImageScreen> createState() => _CompressImageScreenState();
}

class _CompressImageScreenState extends State<CompressImageScreen> {
  File? _imageFile;
  Uint8List? _imageBytes;
  Uint8List? _compressedBytes;
  bool _isInitializing = true;
  bool _isCompressing = false;
  String? _errorMessage;
  double? _imageAspectRatio;

  // Compression settings
  double _quality = 70.0;
  int _originalSize = 0;
  int _compressedSize = 0;

  @override
  void initState() {
    super.initState();
    _initializeImage();
  }

  Future<void> _initializeImage() async {
    try {
      if (kIsWeb) {
        // Web handling
        if (widget.webImageBytes != null) {
          _imageBytes = widget.webImageBytes;
          _originalSize = widget.webImageBytes!.length;
          await _calculateAspectRatio();
        } else {
          _errorMessage = 'No image provided';
          return;
        }
      } else {
        // Mobile handling - simplified logic
        if (widget.imageFile != null) {
          _imageFile = widget.imageFile;
          _imageBytes = await widget.imageFile!.readAsBytes();
          _originalSize = _imageBytes!.length;
          await _calculateAspectRatio();
        } else if (widget.webImageBytes != null) {
          // This case shouldn't happen on mobile, but handle it anyway
          _imageBytes = widget.webImageBytes;
          _originalSize = widget.webImageBytes!.length;
          await _calculateAspectRatio();
        } else {
          _errorMessage = 'No image provided';
          return;
        }
      }

      // Auto-compress on initialization
      if (_imageBytes != null) {
        await _compressImage();
      }
    } catch (e) {
      _errorMessage = 'Failed to initialize image: $e';
      debugPrint('Error initializing image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _calculateAspectRatio() async {
    if (_imageBytes != null) {
      try {
        // Decode image to get dimensions
        final image = await decodeImageFromList(_imageBytes!);
        _imageAspectRatio = image.width / image.height;
      } catch (e) {
        debugPrint('Error calculating aspect ratio: $e');
        _imageAspectRatio = 1.0; // Default to square
      }
    }
  }

  Future<void> _compressImage() async {
    if (_imageBytes == null) return;

    setState(() {
      _isCompressing = true;
    });

    try {
      Uint8List? result;

      if (kIsWeb) {
        // For web, use FlutterImageCompress.compressWithList
        result = await FlutterImageCompress.compressWithList(
          _imageBytes!,
          quality: _quality.round(),
          format: CompressFormat.jpeg,
        );
      } else {
        //  Mobile compression - better handling
        if (_imageFile != null) {
          final targetPath = path.join(
            (await getTemporaryDirectory()).path,
            'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );

          final compressedFile = await FlutterImageCompress.compressAndGetFile(
            _imageFile!.absolute.path,
            targetPath,
            quality: _quality.round(),
            format: CompressFormat.jpeg,
          );

          if (compressedFile != null) {
            result = await compressedFile.readAsBytes();
          }
        } else {
          // Fallback: use compressWithList for mobile if no file available
          result = await FlutterImageCompress.compressWithList(
            _imageBytes!,
            quality: _quality.round(),
            format: CompressFormat.jpeg,
          );
        }
      }

      if (result != null) {
        setState(() {
          _compressedBytes = result;
          _compressedSize = result!.length;
        });
      }
    } catch (e) {
      debugPrint('Error compressing image: $e');
      _showErrorSnackBar('Failed to compress image: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isCompressing = false;
        });
      }
    }
  }

  void _onQualityChanged(double value) {
    setState(() {
      _quality = value;
    });

    // Debounce compression to avoid too many calls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_quality == value) {
        _compressImage();
      }
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes} B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  void _saveCompressedImage() {
    if (_compressedBytes != null) {
      Navigator.pop(context, _compressedBytes);
    } else {
      _showErrorSnackBar('No compressed image available');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  double _calculateImageHeight(double containerWidth) {
    if (_imageAspectRatio == null) return 200;

    // Calculate height based on aspect ratio
    double calculatedHeight = containerWidth / _imageAspectRatio!;

    // Set constraints: minimum 150px, maximum 300px
    calculatedHeight = calculatedHeight.clamp(150.0, 300.0);

    return calculatedHeight;
  }

  @override
  void dispose() {
    // Clean up temporary file if it was created
    if (!kIsWeb && _imageFile != null && _imageFile!.path.contains('temp_')) {
      try {
        _imageFile?.delete();
      } catch (e) {
        debugPrint('Error deleting temp file in dispose: $e');
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Compress'),
        backgroundColor: const Color(0xFFE53E3E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isInitializing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFE53E3E),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading image...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53E3E),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Preview Section
                      ImagePreviewWidget(
                        imageBytes: _imageBytes,
                        compressedBytes: _compressedBytes,
                        calculateImageHeight: _calculateImageHeight,
                        showActionButtons: false,
                        backgroundColor: Colors.white,
                        noImageText: 'No Image',
                      ),

                      const SizedBox(height: 30),

                      // Quality Section
                      const Text(
                        'Quality',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Quality Slider
                      Row(
                        children: [
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: const Color(0xFFE53E3E),
                                inactiveTrackColor: Colors.grey[300],
                                thumbColor: const Color(0xFFE53E3E),
                                overlayColor:
                                    const Color(0xFFE53E3E).withOpacity(0.2),
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 12,
                                ),
                                trackHeight: 4,
                              ),
                              child: Slider(
                                value: _quality,
                                min: 10,
                                max: 100,
                                divisions: 90,
                                onChanged: _onQualityChanged,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Quality Percentage
                      Text(
                        '${_quality.round()}%',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // File Size Information
                      if (_originalSize > 0) ...[
                        Row(
                          children: [
                            const Text(
                              'Original: ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _formatFileSize(_originalSize),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(
                                width: 16), // Space between original and new
                            const Text(
                              'New: ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFFE53E3E),
                              ),
                            ),
                            Text(
                              _compressedSize > 0
                                  ? _formatFileSize(_compressedSize)
                                  : 'Compressing...',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFFE53E3E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _isCompressing ? null : _saveCompressedImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53E3E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: _isCompressing
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Compressing...',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'Save',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }
}
