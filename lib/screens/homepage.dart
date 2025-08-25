// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../widgets/image_slot.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

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
                  _buildFunctionCard(
                    icon: Icons.compress,
                    title: 'Compress',
                    subtitle: 'Reduce file size',
                    onTap: () => Navigator.pushNamed(context, '/compress'),
                  ),
                  _buildFunctionCard(
                    icon: Icons.crop,
                    title: 'Crop',
                    subtitle: 'Adjust dimensions',
                    onTap: () => Navigator.pushNamed(context, '/crop'),
                  ),
                  _buildFunctionCard(
                    icon: Icons.transform,
                    title: 'Convert',
                    subtitle: 'Change format',
                    onTap: () => Navigator.pushNamed(context, '/convert'),
                  ),
                  _buildFunctionCard(
                    icon: Icons.photo_size_select_large,
                    title: 'Resize',
                    subtitle: 'Scale dimensions',
                    onTap: () => Navigator.pushNamed(context, '/resize'),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Recent section
              const Text(
                'Recent',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              // Recent images row
              Row(
                children: [
                  const ImageSlot(hasImage: true),
                  const SizedBox(width: 12),
                  const ImageSlot(hasImage: true),
                  const SizedBox(width: 12),
                  const ImageSlot(hasImage: false),
                  const SizedBox(width: 12),
                  const ImageSlot(hasImage: false),
                  const Spacer(),
                ],
              ),

              const SizedBox(height: 20),

              // Dots indicator
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 3,
                      backgroundColor: Colors.black87,
                    ),
                    SizedBox(width: 8),
                    CircleAvatar(
                      radius: 2,
                      backgroundColor: Colors.grey,
                    ),
                    SizedBox(width: 8),
                    CircleAvatar(
                      radius: 2,
                      backgroundColor: Colors.grey,
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

  Widget _buildFunctionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.black54,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
