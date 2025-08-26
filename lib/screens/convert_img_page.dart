import 'package:flutter/material.dart';
import '../state/image_state_manager.dart';
import '../widgets/action_button.dart';
import '../widgets/format_button.dart';
import '../widgets/image_slot.dart';
import '../widgets/png_option_row.dart';

class ConvertImagePage extends StatefulWidget {
  const ConvertImagePage({super.key});

  @override
  State<ConvertImagePage> createState() => _ConvertImagePageState();
}

class _ConvertImagePageState extends State<ConvertImagePage> {
  String selectedFormat = 'PNG';
  bool compressionEnabled = true;
  bool interlacedEnabled = false;

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

  final List<Map<String, String>> formats = [
    {'format': 'JPEG', 'description': 'Small size'},
    {'format': 'PNG', 'description': 'Transparent'},
    {'format': 'WebP', 'description': 'Modern format'},
    {'format': 'HEIC', 'description': 'iOS format\nHigh quality'},
    {'format': 'BMP', 'description': 'Windows\nLarge size'},
    {'format': 'TIFF', 'description': 'Print\nLossless'},
  ];

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
          'Convert',
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
              // Selected Images section
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

              const SizedBox(height: 32),

              // Output Format section
              const Text(
                'Output Format',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              // Format grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: formats
                    .map((format) => FormatButton(
                          format: format['format']!,
                          description: format['description']!,
                          isSelected: selectedFormat == format['format'],
                          onPressed: () {
                            setState(() {
                              selectedFormat = format['format']!;
                            });
                          },
                        ))
                    .toList(),
              ),

              const SizedBox(height: 32),

              // PNG Options section (only show when PNG is selected)
              if (selectedFormat == 'PNG') ...[
                const Text(
                  'PNG Options',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      PngOptionRow(
                        title: 'Compression',
                        subtitle: 'Reduce file size',
                        value: compressionEnabled,
                        onChanged: (value) {
                          setState(() {
                            compressionEnabled = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      PngOptionRow(
                        title: 'Interlaced',
                        subtitle: 'Progressive loading',
                        value: interlacedEnabled,
                        onChanged: (value) {
                          setState(() {
                            interlacedEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Output info
              Text(
                'Output: 5 PNG files (~6.2 MB total)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 32),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      text: 'Preview',
                      onPressed: () {
                        // Handle preview action
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ActionButton(
                      text: 'Convert',
                      isPrimary: true,
                      onPressed: () {
                        // Handle convert action
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
