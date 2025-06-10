import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
      setState(() {
        _webImage = bytes;
        _selectedImage = null;
      });
    } else {
      // For mobile platforms
      final file = File(image.path);
      final imageProvider = FileImage(file);
      await _getImageDimensions(imageProvider);
      setState(() {
        _selectedImage = file;
        _webImage = null;
      });
    }
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
    });
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
                                        fit: BoxFit
                                            .contain, // Changed to contain for better aspect ratio
                                      )
                                    : Image.file(
                                        _selectedImage!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit
                                            .contain, // Changed to contain for better aspect ratio
                                      ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: _removeImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.8),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(
                                            0.2,
                                          ),
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

              // Image Info Display (when image is selected)
              if (_selectedImage != null || _webImage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _imageAspectRatio != null
                              ? 'Aspect Ratio: ${_imageAspectRatio!.toStringAsFixed(2)}:1'
                              : 'Loading image info...',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Gallery and Camera Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library, size: 20),
                      label: const Text(
                        'Gallery',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImageFromCamera,
                      icon: const Icon(Icons.camera_alt, size: 20),
                      label: const Text(
                        'Camera',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
