import 'package:flutter/material.dart';
import '../widgets/action_button.dart';
import '../widgets/image_slot.dart';

class ExportImagePage extends StatelessWidget {
  const ExportImagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row with Back Arrow and Title
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Export",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Processed Images Section (using ImageSlot)
              Row(
                children: const [
                  ImageSlot(hasImage: true),
                  SizedBox(width: 12),
                  ImageSlot(hasImage: false),
                  SizedBox(width: 12),
                  ImageSlot(hasImage: false),
                ],
              ),
              const SizedBox(height: 20),

              // Selected Image Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    const Text(
                      "image_001.jpg",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        Column(
                          children: [
                            Text("Before"),
                            SizedBox(height: 4),
                            Text("2.4 MB",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            Text("After"),
                            SizedBox(height: 4),
                            Text("1.2 MB",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "50% size reduction",
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Export Settings
              const Text(
                "Export Settings",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // File Name Pattern
              TextField(
                decoration: InputDecoration(
                  labelText: "File Name Pattern",
                  hintText: "compressed_{original}_{date}",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Save Location
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: "Save Location",
                        hintText: "/Photos/Pixelize/",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.folder_open),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Summary
              const Text(
                "Total: 3 images processed\nSpace saved: 3.6 MB → 1.8 MB",
                style: TextStyle(color: Colors.grey),
              ),

              const Spacer(),

              // Bottom Buttons
              Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      text: "Share",
                      isPrimary: false,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ActionButton(
                      text: "Save All",
                      isPrimary: true,
                      onTap: () {},
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
