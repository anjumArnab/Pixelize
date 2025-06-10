// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:get_storage/get_storage.dart';
import '../widgets/img_button.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  File? _selectedImage;
  Uint8List? _webImage;
  final ImagePicker _picker = ImagePicker();
  double? _imageAspectRatio;
  Map<String, dynamic>? _imageMetadata;
  final GetStorage _storage = GetStorage();

  @override
  void initState() {
    super.initState();
    _loadSavedImage();
  }

  Future<void> _loadSavedImage() async {
    try {
      // Load saved image data
      final savedImageData = _storage.read('saved_image');
      final savedMetadata = _storage.read('image_metadata');

      if (savedImageData != null) {
        if (kIsWeb) {
          // For web, image is stored as base64 string
          final bytes = base64Decode(savedImageData);
          final imageProvider = MemoryImage(bytes);
          await _getImageDimensions(imageProvider);

          setState(() {
            _webImage = bytes;
            _imageMetadata = savedMetadata != null
                ? Map<String, dynamic>.from(savedMetadata)
                : null;
          });
        } else {
          // For mobile, check if file still exists at saved path
          final file = File(savedImageData);
          if (await file.exists()) {
            final imageProvider = FileImage(file);
            await _getImageDimensions(imageProvider);

            setState(() {
              _selectedImage = file;
              _imageMetadata = savedMetadata != null
                  ? Map<String, dynamic>.from(savedMetadata)
                  : null;
            });
          } else {
            // File no longer exists, clear saved data
            _clearSavedData();
          }
        }
      }
    } catch (e) {
      // print('Error loading saved image: $e');
      _clearSavedData();
    }
  }

  Future<void> _saveImageData() async {
    try {
      if (kIsWeb && _webImage != null) {
        // For web, save image as base64 string
        final base64String = base64Encode(_webImage!);
        await _storage.write('saved_image', base64String);
      } else if (_selectedImage != null) {
        // For mobile, save file path
        await _storage.write('saved_image', _selectedImage!.path);
      }

      // Save metadata
      if (_imageMetadata != null) {
        await _storage.write('image_metadata', _imageMetadata);
      }

      _showSnackBar('Image saved successfully!');
    } catch (e) {
      // print('Error saving image: $e');
      _showSnackBar('Error saving image: $e');
    }
  }

  Future<void> _clearSavedData() async {
    try {
      await _storage.remove('saved_image');
      await _storage.remove('image_metadata');
    } catch (e) {
      // print('Error clearing saved data: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        await _processSelectedImage(image);
      }
    } catch (e) {
      _showSnackBar('Error picking image from gallery: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        await _processSelectedImage(image);
      }
    } catch (e) {
      _showSnackBar('Error taking picture: $e');
    }
  }

  Future<void> _processSelectedImage(XFile image) async {
    if (kIsWeb) {
      // For web platform
      final bytes = await image.readAsBytes();
      final imageProvider = MemoryImage(bytes);
      await _getImageDimensions(imageProvider);
      await _extractImageMetadata(bytes, image);
      setState(() {
        _webImage = bytes;
        _selectedImage = null;
      });
    } else {
      // For mobile platforms
      final file = File(image.path);
      final imageProvider = FileImage(file);
      await _getImageDimensions(imageProvider);
      final bytes = await file.readAsBytes();
      await _extractImageMetadata(bytes, image);
      setState(() {
        _selectedImage = file;
        _webImage = null;
      });
    }
  }

  Future<void> _extractImageMetadata(Uint8List bytes, XFile image) async {
    try {
      // Decode image using the image package
      img.Image? decodedImage = img.decodeImage(bytes);

      if (decodedImage != null) {
        // Get file stats
        int fileSize = bytes.length;

        setState(() {
          _imageMetadata = {
            'width': decodedImage.width,
            'height': decodedImage.height,
            'channels': decodedImage.numChannels,
            'format': _getImageFormat(image.name),
            'fileSize': _formatFileSize(fileSize),
            'fileSizeBytes': fileSize,
            'hasAlpha': decodedImage.hasAlpha,
            'aspectRatio':
                (decodedImage.width / decodedImage.height).toStringAsFixed(2),
            'fileName': image.name,
            'path': kIsWeb ? 'Web Upload' : image.path,
            'megapixels': ((decodedImage.width * decodedImage.height) / 1000000)
                .toStringAsFixed(1),
            'savedAt': DateTime.now().toIso8601String(),
          };
        });
      }
    } catch (e) {
      // print('Error extracting image metadata: $e');
    }
  }

  String _getImageFormat(String fileName) {
    String extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'JPEG';
      case 'png':
        return 'PNG';
      case 'gif':
        return 'GIF';
      case 'bmp':
        return 'BMP';
      case 'webp':
        return 'WebP';
      default:
        return extension.toUpperCase();
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _getImageDimensions(ImageProvider imageProvider) async {
    final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
    final Completer<void> completer = Completer<void>();

    stream.addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        final int width = info.image.width;
        final int height = info.image.height;
        _imageAspectRatio = width / height;
        completer.complete();
      }),
    );

    await completer.future;
  }

  double _calculateImageHeight(double containerWidth) {
    if (_imageAspectRatio == null) return 200;

    // Calculate height based on aspect ratio
    double calculatedHeight = containerWidth / _imageAspectRatio!;

    // Set constraints: minimum 150px, maximum 300px (reduced for better mobile experience)
    calculatedHeight = calculatedHeight.clamp(150.0, 300.0);

    return calculatedHeight;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _webImage = null;
      _imageAspectRatio = null;
      _imageMetadata = null;
    });

    // Clear saved data when image is removed
    _clearSavedData();
    _showSnackBar('Image removed and cleared from storage');
  }

  void _showImageMetadataDialog() {
    if (_imageMetadata == null) {
      _showSnackBar('Image metadata not available');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Text('Image Metadata'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMetadataRow(
                    'File Name', _imageMetadata!['fileName'] ?? 'Unknown'),
                _buildMetadataRow('Dimensions',
                    '${_imageMetadata!['width']} × ${_imageMetadata!['height']} pixels'),
                _buildMetadataRow('Format', _imageMetadata!['format']),
                _buildMetadataRow('File Size', _imageMetadata!['fileSize']),
                _buildMetadataRow(
                    'Megapixels', '${_imageMetadata!['megapixels']} MP'),
                _buildMetadataRow(
                    'Aspect Ratio', '${_imageMetadata!['aspectRatio']}:1'),
                _buildMetadataRow(
                    'Color Channels', _imageMetadata!['channels'].toString()),
                _buildMetadataRow('Has Transparency',
                    _imageMetadata!['hasAlpha'] ? 'Yes' : 'No'),
                if (!kIsWeb) _buildMetadataRow('Path', _imageMetadata!['path']),
                if (_imageMetadata!['savedAt'] != null)
                  _buildMetadataRow(
                      'Saved At',
                      DateTime.parse(_imageMetadata!['savedAt'])
                          .toString()
                          .split('.')[0]),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
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
        title: const Text('Pixelize'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Dynamic Image Display Area
              LayoutBuilder(
                builder: (context, constraints) {
                  final containerWidth = constraints.maxWidth;
                  final imageHeight =
                      (_selectedImage != null || _webImage != null)
                          ? _calculateImageHeight(containerWidth)
                          : 200.0;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: imageHeight,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: (_selectedImage != null || _webImage != null)
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: kIsWeb
                                    ? Image.memory(
                                        _webImage!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.contain,
                                      )
                                    : Image.file(
                                        _selectedImage!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.contain,
                                      ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Save button
                                    GestureDetector(
                                      onTap: _saveImageData,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.8),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.save,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Info button
                                    GestureDetector(
                                      onTap: _showImageMetadataDialog,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.8),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.info,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Close button
                                    GestureDetector(
                                      onTap: _removeImage,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.8),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'Add Image',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Image will resize dynamically',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Gallery and Camera Buttons
              Row(
                children: [
                  Expanded(
                    child: ImageButton(
                      onPressed: _pickImageFromGallery,
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      backgroundColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ImageButton(
                      onPressed: _pickImageFromCamera,
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
