// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../widgets/action_button.dart';
import '../widgets/add_image_slot.dart';
import '../widgets/image_slot.dart';

class CompressImagePage extends StatefulWidget {
  const CompressImagePage({super.key});

  @override
  State<CompressImagePage> createState() => _CompressImagePageState();
}

class _CompressImagePageState extends State<CompressImagePage> {
  double quality = 80.0;
  List<String> selectedImages = [];

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
          'Compress',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected Images section
              Text(
                'Selected Images (3)',
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
                  AddImageSlot(
                    onTap: () {
                      // Open image picker here
                    },
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Quality section
              Text(
                'Quality',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),

              const SizedBox(height: 15),

              // Quality slider with percentage
              Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.black,
                        inactiveTrackColor: Colors.grey[300],
                        thumbColor: Colors.black,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 16),
                      ),
                      child: Slider(
                        value: quality,
                        min: 10,
                        max: 100,
                        onChanged: (value) {
                          setState(() {
                            quality = value;
                          });
                        },
                      ),
                    ),
                  ),
                  Container(
                    width: 50,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${quality.round()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Size Preview section
              Text(
                'Size Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),

              const SizedBox(height: 12),

              // Size details
              Container(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSizeRow('Original:', '2.4 MB'),
                    const SizedBox(height: 8),
                    _buildSizeRow('Compressed:', '1.2 MB'),
                    const SizedBox(height: 8),
                    _buildSizeRow('Saved:', '1.2 MB'),
                  ],
                ),
              ),

              const Spacer(),

              // Quality preset buttons
              Row(
                children: [
                  _buildPresetButton('Lossless', false),
                  const SizedBox(width: 12),
                  _buildPresetButton('Lossy', true),
                ],
              ),

              const SizedBox(height: 20),

              // Action buttons
              Row(
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: ActionButton(
                      text: 'Process',
                      isPrimary: false,
                      onTap: () {
                        // Process action
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSizeRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (text == 'Lossy') {
            quality = 80.0;
          } else {
            quality = 100.0;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
          ),
        ),
        child: Text(
          text,
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
