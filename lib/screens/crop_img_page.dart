import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CropImageScreen extends StatefulWidget {
  final File? imageFile;
  final Uint8List? webImageBytes;
  final String imageName;

  const CropImageScreen({
    super.key,
    this.imageFile,
    this.webImageBytes,
    required this.imageName,
  });

  @override
  State<CropImageScreen> createState() => _CropImageScreenState();
}

class _CropImageScreenState extends State<CropImageScreen> {
  File? _imageFile;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _errorMessage;

  // Aspect ratio presets
  CropAspectRatio? _selectedAspectRatio =
      const CropAspectRatio(ratioX: 4, ratioY: 3);
  final List<Map<String, dynamic>> _aspectRatios = [
    {'label': '1:1', 'ratio': const CropAspectRatio(ratioX: 1, ratioY: 1)},
    {'label': '4:3', 'ratio': const CropAspectRatio(ratioX: 4, ratioY: 3)},
    {'label': '16:9', 'ratio': const CropAspectRatio(ratioX: 16, ratioY: 9)},
    {'label': '3:4', 'ratio': const CropAspectRatio(ratioX: 3, ratioY: 4)},
    {'label': 'Free', 'ratio': null},
  ];

  @override
  void initState() {
    super.initState();
    _initializeImageFile();
  }

  Future<void> _initializeImageFile() async {
    try {
      if (kIsWeb) {
        // For web, show message that cropping is not supported
        if (widget.webImageBytes != null) {
          _errorMessage =
              'Image cropping is not fully supported on web platform. Please use the mobile app for advanced cropping features.';
        } else {
          _errorMessage = 'No image provided';
        }
      } else if (widget.imageFile != null) {
        // For mobile platforms, use the provided file
        _imageFile = widget.imageFile;
      } else if (widget.webImageBytes != null) {
        // For mobile platform with bytes, create temp file
        await _createTempFileFromBytes();
      } else {
        _errorMessage = 'No image provided';
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

  Future<void> _createTempFileFromBytes() async {
    try {
      if (widget.webImageBytes == null) {
        throw Exception('No image bytes provided');
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = widget.imageName.contains('.')
          ? widget.imageName
          : '${widget.imageName}.png';
      final tempFile = File(path.join(tempDir.path, 'temp_$fileName'));

      await tempFile.writeAsBytes(widget.webImageBytes!);

      // Verify the file was created successfully
      if (await tempFile.exists()) {
        _imageFile = tempFile;
      } else {
        throw Exception('Failed to create temporary file');
      }
    } catch (e) {
      debugPrint('Error creating temp file: $e');
      throw e;
    }
  }

  void _selectAspectRatio(CropAspectRatio? ratio) {
    setState(() {
      _selectedAspectRatio = ratio;
    });
  }

  Future<void> _cropImage() async {
    if (kIsWeb) {
      _showErrorSnackBar('Cropping is not supported on web platform');
      return;
    }

    if (_imageFile == null) {
      _showErrorSnackBar('No image available to crop');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _imageFile!.path,
        aspectRatio: _selectedAspectRatio,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.purple,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: Colors.purple,
            backgroundColor: Colors.white,
            statusBarColor: Colors.purple,
            cropGridColor: Colors.white.withOpacity(0.5),
            cropFrameColor: Colors.purple,
            initAspectRatio: _selectedAspectRatio != null
                ? CropAspectRatioPreset.ratio4x3
                : CropAspectRatioPreset.original,
            lockAspectRatio: _selectedAspectRatio != null,
            showCropGrid: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
            aspectRatioLockEnabled: _selectedAspectRatio != null,
            resetAspectRatioEnabled: true,
            aspectRatioPickerButtonHidden: false,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: false,
          ),
        ],
      );

      if (croppedFile != null) {
        // Read the cropped file and return as bytes
        final croppedBytes = await croppedFile.readAsBytes();

        // Clean up temporary file if it was created
        if (_imageFile!.path.contains('temp_')) {
          try {
            await _imageFile?.delete();
          } catch (e) {
            debugPrint('Error deleting temp file: $e');
          }
        }

        if (mounted) {
          Navigator.pop(context, croppedBytes);
        }
      } else {
        // User cancelled cropping
        debugPrint('Cropping was cancelled by user');
      }
    } catch (e) {
      debugPrint('Error cropping image: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to crop image: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Crop Image'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isInitializing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.purple,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading image...',
                    style: TextStyle(color: Colors.white),
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
                        Icon(
                          kIsWeb ? Icons.web : Icons.error_outline,
                          color: kIsWeb ? Colors.orange : Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (kIsWeb) ...[
                          const Text(
                            'Alternative: You can use online image editors or try the mobile version of this app.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                        ],
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Image Preview
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.purple, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: kIsWeb && widget.webImageBytes != null
                              ? Image.memory(
                                  widget.webImageBytes!,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image,
                                            color: Colors.red,
                                            size: 64,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Failed to load image',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : _imageFile != null
                                  ? Image.file(
                                      _imageFile!,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.broken_image,
                                                color: Colors.red,
                                                size: 64,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Failed to load image',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    )
                                  : const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey,
                                            size: 64,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'No image available',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                        ),
                      ),
                    ),

                    // Controls
                    if (!kIsWeb) // Only show controls for mobile platforms
                      Container(
                        color: Colors.grey[900],
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Aspect ratio selection
                            const Text(
                              'Select Aspect Ratio',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Aspect ratio buttons
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: _aspectRatios.map((aspectRatio) {
                                  final isSelected = _selectedAspectRatio ==
                                      aspectRatio['ratio'];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: GestureDetector(
                                      onTap: () => _selectAspectRatio(
                                          aspectRatio['ratio']),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.purple
                                              : Colors.grey[700],
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          aspectRatio['label'],
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Crop button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _cropImage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isLoading
                                    ? const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                            'Cropping...',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        'Crop Image',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}
