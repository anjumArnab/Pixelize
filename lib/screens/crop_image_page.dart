// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../widgets/action_button.dart';
import '../widgets/add_image_slot.dart';
import '../widgets/image_slot.dart';

class CropImagePage extends StatefulWidget {
  const CropImagePage({super.key});

  @override
  State<CropImagePage> createState() => _CropImagePageState();
}

class _CropImagePageState extends State<CropImagePage> {
  String selectedRatio = '16:9';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Crop',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selected Image section
                    Text(
                      'Selected Image',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Image selection grid
                    Row(
                      children: [
                        const ImageSlot(hasImage: true),
                        const SizedBox(width: 12),
                        const ImageSlot(hasImage: true),
                        const SizedBox(width: 12),
                        const ImageSlot(hasImage: true),
                        const SizedBox(width: 12),
                        const ImageSlot(hasImage: true),
                        const SizedBox(width: 12),
                        AddImageSlot(
                          onTap: () {
                            // Open image picker here
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // Image Preview section
                    Text(
                      'Image Preview',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Crop preview area
                    Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                        padding: const EdgeInsets.all(20),
                        child: Stack(
                          children: [
                            // Background area
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),

                            // Crop selection area
                            Center(
                              child: Container(
                                width: 200,
                                height: 120,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.black,
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

                                    // Dashed lines
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      child: CustomPaint(
                                        size: const Size(double.infinity, 120),
                                        painter: DashedLinePainter(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Aspect Ratio section
                    const Text(
                      'Aspect Ratio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Aspect ratio buttons
                    Row(
                      children: [
                        _buildRatioButton('1:1'),
                        const SizedBox(width: 10),
                        _buildRatioButton('16:9'),
                        const SizedBox(width: 10),
                        _buildRatioButton('4:3'),
                        const SizedBox(width: 10),
                        _buildRatioButton('Free'),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Output dimensions
                    Text(
                      'Output: 1920x1080 px',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom action buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      text: 'Preview',
                      isPrimary: false,
                      onTap: () {
                        // Preview action
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ActionButton(
                      text: 'Apply',
                      isPrimary: false,
                      onTap: () {
                        // Apply action
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerHandle(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: Offset(
          alignment.x * -4, // Offset to center on corner
          alignment.y * -4,
        ),
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.rectangle,
          ),
        ),
      ),
    );
  }

  Widget _buildRatioButton(String ratio) {
    final isSelected = selectedRatio == ratio;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRatio = ratio;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
          ),
        ),
        child: Text(
          ratio,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

// Custom painter for dashed lines in crop area
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 4.0;

    // Horizontal dashed lines
    for (int i = 1; i < 3; i++) {
      final y = size.height / 3 * i;
      double startX = 0;

      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(startX + dashWidth, y),
          paint,
        );
        startX += dashWidth + dashSpace;
      }
    }

    // Vertical dashed lines
    for (int i = 1; i < 3; i++) {
      final x = size.width / 3 * i;
      double startY = 0;

      while (startY < size.height) {
        canvas.drawLine(
          Offset(x, startY),
          Offset(x, startY + dashWidth),
          paint,
        );
        startY += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
