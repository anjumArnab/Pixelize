// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../widgets/action_button.dart';
import '../widgets/add_image_slot.dart';
import '../widgets/image_slot.dart';

class ConvertImagePage extends StatefulWidget {
  const ConvertImagePage({super.key});

  @override
  State<ConvertImagePage> createState() => _ConvertImagePageState();
}

class _ConvertImagePageState extends State<ConvertImagePage> {
  String selectedFormat = 'PNG';
  bool compressionInterlaced = false;

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
          'Convert',
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
                    // Selected Images section
                    Text(
                      'Selected Images (5)',
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

                    // Output Format section
                    const Text(
                      'Output Format',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Format options grid
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: _buildFormatCard(
                                    'JPEG', 'Smaller\nfile size', false)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildFormatCard(
                                    'PNG', 'Transparency\nsupport', true)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildFormatCard(
                                    'WebP', 'Modern\nformat', false)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: _buildFormatCard(
                                    'HEIC', 'iOS native\nhigh quality', false)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildFormatCard(
                                    'BMP', 'Uncompressed\nlarge size', false)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildFormatCard(
                                    'TIFF', 'Print\nstandard', false)),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // PNG Options section (conditional)
                    if (selectedFormat == 'PNG') ...[
                      const Text(
                        'PNG Options',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 15),

                      // PNG options container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
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
                        child: Column(
                          children: [
                            _buildToggleOption(
                                'Compression', compressionInterlaced, (value) {
                              setState(() {
                                compressionInterlaced = value;
                              });
                            }),
                            const SizedBox(height: 12),
                            _buildToggleOption('Interlaced', false, (value) {
                              // Handle interlaced toggle
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),
                    ],

                    // Output info
                    Text(
                      'Output: 5 PNG files (~8.2 MB total)',
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
                      text: 'Convert',
                      isPrimary: false,
                      onTap: () {
                        // Preview action
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

  Widget _buildFormatCard(String format, String description, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFormat = format;
        });
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[200]!,
          ),
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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                format,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white70 : Colors.grey[500],
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption(
      String title, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.black,
          activeTrackColor: Colors.grey[300],
          inactiveThumbColor: Colors.grey[400],
          inactiveTrackColor: Colors.grey[200],
        ),
      ],
    );
  }
}
