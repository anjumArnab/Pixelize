import 'package:flutter/material.dart';
import '../widgets/action_button.dart';
import '../widgets/image_slot.dart';
import '../state/image_state_manager.dart';

class CompressImagePage extends StatefulWidget {
  const CompressImagePage({super.key});

  @override
  State<CompressImagePage> createState() => _CompressImagePageState();
}

class _CompressImagePageState extends State<CompressImagePage> {
  double _qualityValue = 80.0;
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
          'Compress',
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

              // Quality section
              const Text(
                'Quality',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              // Quality slider
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Quality',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          '${_qualityValue.round()}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.black87,
                        inactiveTrackColor: Colors.grey[300],
                        thumbColor: Colors.black87,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 8),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _qualityValue,
                        min: 0,
                        max: 100,
                        onChanged: (value) {
                          setState(() {
                            _qualityValue = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Size Preview section
              const Text(
                'Size Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              // Size preview container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSizeRow('Original:',
                        _stateManager.hasImages ? '2.4 MB' : 'No images'),
                    const SizedBox(height: 8),
                    _buildSizeRow(
                        'Compressed:',
                        _stateManager.hasImages
                            ? '${(2.4 * (_qualityValue / 100)).toStringAsFixed(1)} MB'
                            : 'No images'),
                    const SizedBox(height: 8),
                    _buildSizeRow(
                        'Saved:',
                        _stateManager.hasImages
                            ? '${(2.4 - (2.4 * (_qualityValue / 100))).toStringAsFixed(1)} MB'
                            : 'No images'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Lossless/Lossy toggle
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 36,
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Center(
                                child: Text(
                                  'Lossless',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 36,
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Center(
                                child: Text(
                                  'Lossy',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      text: 'Preview',
                      onPressed: _stateManager.hasImages
                          ? () {
                              // Handle preview action
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ActionButton(
                      text: 'Process',
                      isPrimary: true,
                      onPressed: _stateManager.hasImages
                          ? () {
                              // Handle process action
                            }
                          : null,
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

  Widget _buildSizeRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
