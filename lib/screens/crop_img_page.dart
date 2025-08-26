import 'package:flutter/material.dart';
import '../state/image_state_manager.dart';
import '../widgets/action_button.dart';
import '../widgets/image_slot.dart';

class AspectRatioButton extends StatelessWidget {
  final String ratio;
  final bool isSelected;
  final VoidCallback onPressed;

  const AspectRatioButton({
    super.key,
    required this.ratio,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black87 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          ratio,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class CropPreviewWidget extends StatelessWidget {
  const CropPreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Stack(
        children: [
          // Background image area
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          // Crop overlay
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black87,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Stack(
                  children: [
                    // Corner handles
                    _buildCornerHandle(Alignment.topLeft),
                    _buildCornerHandle(Alignment.topRight),
                    _buildCornerHandle(Alignment.bottomLeft),
                    _buildCornerHandle(Alignment.bottomRight),
                    // Dotted lines
                    Positioned(
                      top: 0,
                      left: 20,
                      right: 20,
                      child: _buildDottedLine(isHorizontal: true),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 20,
                      right: 20,
                      child: _buildDottedLine(isHorizontal: true),
                    ),
                    Positioned(
                      top: 20,
                      bottom: 20,
                      left: 0,
                      child: _buildDottedLine(isHorizontal: false),
                    ),
                    Positioned(
                      top: 20,
                      bottom: 20,
                      right: 0,
                      child: _buildDottedLine(isHorizontal: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerHandle(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.black87,
          border: Border.all(color: Colors.white, width: 1),
        ),
      ),
    );
  }

  Widget _buildDottedLine({required bool isHorizontal}) {
    return CustomPaint(
      size: Size(
        isHorizontal ? double.infinity : 1,
        isHorizontal ? 1 : double.infinity,
      ),
      painter: DottedLinePainter(isHorizontal: isHorizontal),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final bool isHorizontal;

  DottedLinePainter({required this.isHorizontal});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1;

    const dashWidth = 3.0;
    const dashSpace = 3.0;

    if (isHorizontal) {
      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, 0),
          Offset(startX + dashWidth, 0),
          paint,
        );
        startX += dashWidth + dashSpace;
      }
    } else {
      double startY = 0;
      while (startY < size.height) {
        canvas.drawLine(
          Offset(0, startY),
          Offset(0, startY + dashWidth),
          paint,
        );
        startY += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CropImagePage extends StatefulWidget {
  const CropImagePage({super.key});

  @override
  State<CropImagePage> createState() => _CropImagePageState();
}

class _CropImagePageState extends State<CropImagePage> {
  String selectedRatio = '16:9';

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

  @override
  Widget build(BuildContext context) {
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
          'Crop',
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected Image section
              Text(
                'Selected Images (${_stateManager.imageCount})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
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
                            right:
                                index < _stateManager.imageCount - 1 ? 12 : 0),
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
                              'No images selected',
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

              // Image Preview section
              const Text(
                'Image Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),

              // Crop preview widget
              const CropPreviewWidget(),

              const SizedBox(height: 24),

              // Aspect Ratio section
              const Text(
                'Aspect Ratio',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              // Aspect ratio buttons
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    AspectRatioButton(
                      ratio: '1:1',
                      isSelected: selectedRatio == '1:1',
                      onPressed: () {
                        setState(() {
                          selectedRatio = '1:1';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    AspectRatioButton(
                      ratio: '16:9',
                      isSelected: selectedRatio == '16:9',
                      onPressed: () {
                        setState(() {
                          selectedRatio = '16:9';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    AspectRatioButton(
                      ratio: '4:3',
                      isSelected: selectedRatio == '4:3',
                      onPressed: () {
                        setState(() {
                          selectedRatio = '4:3';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    AspectRatioButton(
                      ratio: 'Free',
                      isSelected: selectedRatio == 'Free',
                      onPressed: () {
                        setState(() {
                          selectedRatio = 'Free';
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Output size
              const Text(
                'Output: 1920×1080 px',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 32),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      text: 'Reset',
                      onPressed: () {
                        setState(() {
                          selectedRatio = '16:9';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ActionButton(
                      text: 'Apply',
                      isPrimary: true,
                      onPressed: () {
                        // Handle apply action
                      },
                    ),
                  ),
                ],
              ),

              // Extra padding to ensure no overflow
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
