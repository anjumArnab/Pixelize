// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pixelize/widgets/add_image_slot.dart';
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

  // Responsive helper methods
  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth > 1200) return 4; // Large desktop
    if (screenWidth > 800) return 3; // Tablet landscape
    if (screenWidth > 600) return 2; // Tablet portrait / small desktop
    return 2; // Mobile
  }

  double _getChildAspectRatio(double screenWidth) {
    if (screenWidth > 800) return 2.2; // Desktop/Tablet - more rectangular
    return 2.5; // Mobile - slightly more square
  }

  double _getHorizontalPadding(double screenWidth) {
    if (screenWidth > 1200) return 40.0; // Large desktop
    if (screenWidth > 800) return 30.0; // Tablet
    return 20.0; // Mobile
  }

  double _getFontSizeTitle(double screenWidth) {
    if (screenWidth > 800) return 32.0; // Desktop/Tablet
    return 24.0; // Mobile
  }

  double _getFontSizeSubtitle(double screenWidth) {
    if (screenWidth > 800) return 16.0; // Desktop/Tablet
    return 14.0; // Mobile
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final horizontalPadding = _getHorizontalPadding(availableWidth);

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isLandscape ? 16.0 : 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header - Responsive sizing
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Pixelize',
                          style: TextStyle(
                            fontSize: _getFontSizeTitle(availableWidth),
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: isLandscape ? 2 : 4),
                        Text(
                          'Image Processing Made Simple',
                          style: TextStyle(
                            fontSize: _getFontSizeSubtitle(availableWidth),
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isLandscape ? 24 : 40),

                  // Grid View for main functions - Responsive
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: availableWidth > 1000 ? 800 : double.infinity,
                    ),
                    child: Center(
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: _getCrossAxisCount(availableWidth),
                        crossAxisSpacing: availableWidth > 600 ? 16 : 12,
                        mainAxisSpacing: availableWidth > 600 ? 16 : 12,
                        childAspectRatio: _getChildAspectRatio(availableWidth),
                        children: [
                          _buildFunctionCard(
                            icon: Icons.compress,
                            title: 'Compress',
                            subtitle: 'Reduce file size',
                            screenWidth: availableWidth,
                            onTap: () {
                              if (_stateManager.hasImages) {
                                Navigator.pushNamed(context, '/compress');
                              } else {
                                _pickImage();
                              }
                            },
                          ),
                          _buildFunctionCard(
                            icon: Icons.crop,
                            title: 'Crop',
                            subtitle: 'Adjust dimensions',
                            screenWidth: availableWidth,
                            onTap: () {
                              if (_stateManager.hasImages) {
                                Navigator.pushNamed(context, '/crop');
                              } else {
                                _pickImage();
                              }
                            },
                          ),
                          _buildFunctionCard(
                            icon: Icons.transform,
                            title: 'Convert',
                            subtitle: 'Change format',
                            screenWidth: availableWidth,
                            onTap: () {
                              if (_stateManager.hasImages) {
                                Navigator.pushNamed(context, '/convert');
                              } else {
                                _pickImage();
                              }
                            },
                          ),
                          _buildFunctionCard(
                            icon: Icons.photo_size_select_large,
                            title: 'Resize',
                            subtitle: 'Scale dimensions',
                            screenWidth: availableWidth,
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
                    ),
                  ),

                  SizedBox(height: isLandscape ? 24 : 40),

                  // Selected Images section - Responsive
                  _buildSelectedImagesSection(availableWidth, isLandscape),

                  SizedBox(height: isLandscape ? 16 : 20),

                  // Instructions - Responsive
                  if (!_stateManager.hasImages)
                    _buildEmptyState(availableWidth),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectedImagesSection(double screenWidth, bool isLandscape) {
    return Column(
      children: [
        // Header row
        Row(
          children: [
            Flexible(
              child: Text(
                'Selected Images',
                style: TextStyle(
                  fontSize: screenWidth > 600 ? 20 : 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            if (_stateManager.hasImages) ...[
              const SizedBox(width: 8),
              Text(
                '(${_stateManager.imageCount})',
                style: TextStyle(
                  fontSize: screenWidth > 600 ? 18 : 16,
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
                    fontSize: screenWidth > 600 ? 16 : 14,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Images row - Responsive
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Display selected images
              ...List.generate(_stateManager.imageCount, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: screenWidth > 600 ? 16 : 12,
                  ),
                  child: ImageSlot(
                    hasImage: true,
                    imageFile: _stateManager.getImageAt(index),
                    onLongPress: () => _removeImage(index),
                    onTap: () => _pickImage,
                  ),
                );
              }),
              // Add image slot
              AddImageSlot(onTap: _pickImage),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(double screenWidth) {
    final isLargeScreen = screenWidth > 600;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth > 800 ? 80 : 20,
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: isLargeScreen ? 80 : 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: isLargeScreen ? 20 : 16),
            Text(
              'Tap the + button to add images',
              style: TextStyle(
                fontSize: isLargeScreen ? 18 : 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isLargeScreen ? 12 : 8),
            Text(
              'Select images to start processing',
              style: TextStyle(
                fontSize: isLargeScreen ? 16 : 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showNoImagesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Images Selected'),
        content:
            const Text('Please select images first before using this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage();
            },
            child: const Text('Pick Images'),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required double screenWidth,
    required VoidCallback onTap,
  }) {
    final isLargeScreen = screenWidth > 600;
    final cardPadding = isLargeScreen ? 20.0 : 16.0;
    final iconSize = isLargeScreen ? 48.0 : 40.0;
    final iconContainerSize = isLargeScreen ? 24.0 : 20.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isLargeScreen ? 16 : 12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(isLargeScreen ? 12 : 8),
              ),
              child: Icon(
                icon,
                color: Colors.black54,
                size: iconContainerSize,
              ),
            ),
            SizedBox(width: isLargeScreen ? 16 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isLargeScreen ? 18 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isLargeScreen ? 14 : 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: isLargeScreen ? 24 : 20,
            ),
          ],
        ),
      ),
    );
  }
}
