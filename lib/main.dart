import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const ImgPicker());
}

class ImgPicker extends StatelessWidget {
  const ImgPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Image Picker",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurpleAccent),
        useMaterial3: true,
      ),
      home: ImagePickerScreen(),
    );
  }
}

class ImagePickerScreen extends StatefulWidget {
  const ImagePickerScreen({super.key});

  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  File? image;
  List<File> images = [];

  Future<void> _captureImageFromCamera() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        image = File(pickedFile.path);
      });
    } else {
      print('No image selected.');
    }
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        image = File(pickedFile.path);
      });
    } else {
      print('No image selected.');
    }
  }

  Future<void> _multiPickImageFromGallery() async {
    final pickedFiles = await ImagePicker().pickMultiImage();

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        images = pickedFiles.map((file) => File(file.path)).toList();
      });
    } else {
      print('No images selected.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        centerTitle: true,
        title: const Text("Image Picker"),
      ),
      body: Center(
        child: images.isEmpty
            ? const Text("No Images Selected")
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // Number of images per row
                  crossAxisSpacing: 4.0,
                  mainAxisSpacing: 4.0,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Image.file(images[index]);
                },
              ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: _multiPickImageFromGallery,
            foregroundColor: Colors.white, // Icon color
            backgroundColor: Colors.deepPurpleAccent, // Button color
            shape: const StadiumBorder(),
            child: const Icon(Icons.photo_library), // Oval shape
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            onPressed: _captureImageFromCamera,
            foregroundColor: Colors.white, // Icon color
            backgroundColor: Colors.deepPurpleAccent, // Button color
            shape: const StadiumBorder(),
            child: const Icon(Icons.camera_alt), // Oval shape
          ),
        ],
      ),
    );
  }
}
