// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/add_image_slot.dart';
import '../widgets/function_card.dart';
import '../widgets/image_slot.dart';
import '../services/image_service.dart';
import '../state/image_state_manager.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final ImageService _imageService = ImageService();
  final ImageStateManager _stateManager = ImageStateManager();

  @override
  void initState() {
    super.initState();
    _stateManager.addListener(_onImageStateChanged);
  }

  @override
  void dispose() {
    _stateManager.removeListener(_onImageStateChanged);
    super.dispose();
  }

  void _onImageStateChanged() {
    setState(() {});
  }

  Future<void> _pickImage() async {
    try {
      // Show dialog to choose between single and multiple images
      final bool? pickMultiple = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Images'),
          content: const Text('Do you want to pick multiple images?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Single Image'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Multiple Images'),
            ),
          ],
        ),
      );

      if (pickMultiple == null) return;

      if (pickMultiple) {
        // Pick multiple images
        final List<XFile> images =
            await _imageService.pickMultipleImagesFromGallery();
        if (images.isNotEmpty) {
          _stateManager.addImages(images);
        }
      } else {
        // Pick single image
        final XFile? image = await _imageService.pickImageFromGallery();
        if (image != null) {
          _stateManager.addImage(image);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    _stateManager.removeImageAt(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Center(
                child: Column(
                  children: [
                    Text(
                      'Pixelize',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Image Processing Made Simple',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Grid View for main functions
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
                  FunctionCard(
                    icon: Icons.compress,
                    title: 'Compress',
                    subtitle: 'Reduce file size',
                    onTap: () {
                      if (_stateManager.hasImages) {
                        Navigator.pushNamed(context, '/compress');
                      } else {
                        _pickImage();
                      }
                    },
                  ),
                  FunctionCard(
                    icon: Icons.crop,
                    title: 'Crop',
                    subtitle: 'Adjust dimensions',
                    onTap: () {
                      if (_stateManager.hasImages) {
                        Navigator.pushNamed(context, '/crop');
                      } else {
                        _pickImage();
                      }
                    },
                  ),
                  FunctionCard(
                    icon: Icons.transform,
                    title: 'Convert',
                    subtitle: 'Change format',
                    onTap: () {
                      if (_stateManager.hasImages) {
                        Navigator.pushNamed(context, '/convert');
                      } else {
                        _pickImage();
                      }
                    },
                  ),
                  FunctionCard(
                    icon: Icons.photo_size_select_large,
                    title: 'Resize',
                    subtitle: 'Scale dimensions',
                    onTap: () {
                      if (_stateManager.hasImages) {
                        Navigator.pushNamed(context, '/resize');
                      } else {
                        _pickImage();
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Recent section
              Row(
                children: [
                  const Text(
                    'Selected Images',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (_stateManager.hasImages) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(${_stateManager.imageCount})',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (_stateManager.hasImages)
                    TextButton(
                      onPressed: () {
                        _stateManager.clearImages();
                      },
                      child: Text(
                        'Clear All',
                        style: TextStyle(
                          color: Colors.red[600],
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  // Display selected images
                  ...List.generate(_stateManager.imageCount, (index) {
                    return ImageSlot(
                      hasImage: true,
                      imageFile: _stateManager.getImageAt(index),
                      onLongPress: () => _removeImage(index),
                      onTap: () => _pickImage(),
                    );
                  }),
                  AddImageSlot(onTap: _pickImage),
                ],
              ),

              const SizedBox(height: 20),

              // Instructions
              if (!_stateManager.hasImages)
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Select images to start processing',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
