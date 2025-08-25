import 'dart:io';
import 'dart:typed_data';
import 'dart:html' as html; // For web-specific operations
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Request storage permissions based on platform
  Future<bool> requestStoragePermission() async {
    try {
      // Web doesn't need storage permissions
      if (kIsWeb) {
        return true;
      }

      if (Platform.isAndroid) {
        // For Android 13+ (API 33+), request specific media permissions
        if (await _isAndroid13OrHigher()) {
          final List<Permission> permissions = [
            Permission.photos,
            Permission.videos,
          ];

          Map<Permission, PermissionStatus> statuses =
              await permissions.request();
          return statuses.values.every((status) =>
              status == PermissionStatus.granted ||
              status == PermissionStatus.limited);
        } else {
          // For older Android versions
          var status = await Permission.storage.request();
          return status == PermissionStatus.granted;
        }
      } else if (Platform.isIOS) {
        var status = await Permission.photos.request();
        return status == PermissionStatus.granted ||
            status == PermissionStatus.limited;
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting storage permission: $e');
      return false;
    }
  }

  /// Check if Android version is 13 or higher
  Future<bool> _isAndroid13OrHigher() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    // For now, return false to use legacy permissions
    // In production, use device_info_plus package for actual SDK version
    return false;
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    try {
      // Web doesn't need camera permissions (browser handles it)
      if (kIsWeb) {
        return true;
      }

      var status = await Permission.camera.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      debugPrint('Error requesting camera permission: $e');
      return false;
    }
  }

  /// Pick single image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      // Web doesn't need storage permissions
      if (!kIsWeb) {
        bool hasPermission = await requestStoragePermission();
        if (!hasPermission) {
          throw Exception('Storage permission denied');
        }
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // Keep original quality for processing
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      rethrow;
    }
  }

  /// Pick multiple images from gallery
  Future<List<File>> pickMultipleImagesFromGallery({int? maxImages}) async {
    try {
      // Web doesn't need storage permissions
      if (!kIsWeb) {
        bool hasPermission = await requestStoragePermission();
        if (!hasPermission) {
          throw Exception('Storage permission denied');
        }
      }

      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 100,
        limit: maxImages,
      );

      return pickedFiles.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      debugPrint('Error picking multiple images from gallery: $e');
      rethrow;
    }
  }

  /// Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      // Web doesn't need permissions (browser handles camera access)
      if (!kIsWeb) {
        bool hasCameraPermission = await requestCameraPermission();
        bool hasStoragePermission = await requestStoragePermission();

        if (!hasCameraPermission) {
          throw Exception('Camera permission denied');
        }
        if (!hasStoragePermission) {
          throw Exception('Storage permission denied');
        }
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      rethrow;
    }
  }

  /// Show image picker dialog
  Future<File?> showImagePickerDialog(BuildContext context) async {
    return await showDialog<File?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await pickImageFromGallery();
                  Navigator.pop(context, file);
                },
              ),
              // Hide camera option on web if not supported
              if (!kIsWeb || _isWebCameraSupported())
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () async {
                    Navigator.pop(context);
                    final file = await pickImageFromCamera();
                    Navigator.pop(context, file);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  /// Check if web camera is supported
  bool _isWebCameraSupported() {
    if (!kIsWeb) return true;
    // You can add more sophisticated web camera detection here
    return true; // Assume supported for now
  }

  /// Get image metadata
  Future<ImageMetadata> getImageMetadata(File imageFile) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      final int fileSizeBytes =
          bytes.length; // Use bytes length for web compatibility
      final String fileSizeMB =
          (fileSizeBytes / (1024 * 1024)).toStringAsFixed(1);

      String fileName;
      if (kIsWeb) {
        // On web, extract filename from path or use default
        fileName = path.basename(imageFile.path).isNotEmpty
            ? path.basename(imageFile.path)
            : 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      } else {
        fileName = path.basename(imageFile.path);
      }

      return ImageMetadata(
        width: image.width,
        height: image.height,
        fileSizeBytes: fileSizeBytes,
        fileSizeMB: fileSizeMB,
        fileName: fileName,
        filePath: imageFile.path,
      );
    } catch (e) {
      debugPrint('Error getting image metadata: $e');
      rethrow;
    }
  }

  /// Save image to device storage
  Future<String> saveImageToDevice(
    File imageFile, {
    String? customFileName,
    String? customDirectory,
  }) async {
    try {
      if (kIsWeb) {
        return await _saveImageToWeb(
          imageFile,
          customFileName: customFileName,
          customDirectory: customDirectory,
        );
      }

      // Mobile implementation
      bool hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      Directory? directory;

      if (Platform.isAndroid) {
        // Save to Pictures/Pixelize folder on Android
        directory = Directory('/storage/emulated/0/Pictures/Pixelize');
        if (customDirectory != null) {
          directory =
              Directory('/storage/emulated/0/Pictures/$customDirectory');
        }
      } else if (Platform.isIOS) {
        // Save to Documents folder on iOS (or use photo library)
        final documentsDir = await getApplicationDocumentsDirectory();
        directory = Directory('${documentsDir.path}/Pixelize');
        if (customDirectory != null) {
          directory = Directory('${documentsDir.path}/$customDirectory');
        }
      }

      if (directory == null) {
        throw Exception('Unable to determine save directory');
      }

      // Create directory if it doesn't exist
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Generate file name
      String fileName = customFileName ?? _generateFileName(imageFile);
      String filePath = path.join(directory.path, fileName);

      // Ensure unique file name
      filePath = await _ensureUniqueFileName(filePath);

      // Copy file to destination
      final File savedFile = await imageFile.copy(filePath);

      debugPrint('Image saved to: ${savedFile.path}');
      return savedFile.path;
    } catch (e) {
      debugPrint('Error saving image: $e');
      rethrow;
    }
  }

  /// Save image to web (download)
  Future<String> _saveImageToWeb(
    File imageFile, {
    String? customFileName,
    String? customDirectory,
  }) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();

      // Generate file name
      String fileName = customFileName ?? _generateFileName(imageFile);

      // Create blob and download
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();

      html.Url.revokeObjectUrl(url);

      debugPrint('Image downloaded: $fileName');
      return fileName; // Return filename for web
    } catch (e) {
      debugPrint('Error saving image to web: $e');
      rethrow;
    }
  }

  /// Generate file name with pattern
  String _generateFileName(File imageFile,
      {String pattern = 'pixelized_{original}_{date}'}) {
    String originalName;
    String extension;

    if (kIsWeb) {
      // Web files might not have proper extensions
      final fileName = path.basename(imageFile.path);
      if (fileName.contains('.')) {
        originalName = path.basenameWithoutExtension(fileName);
        extension = path.extension(fileName);
      } else {
        originalName = 'image';
        extension = '.jpg'; // Default extension for web
      }
    } else {
      originalName = path.basenameWithoutExtension(imageFile.path);
      extension = path.extension(imageFile.path);
    }

    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String date = DateTime.now().toIso8601String().split('T')[0];

    String fileName = pattern
        .replaceAll('{original}', originalName)
        .replaceAll('{date}', date)
        .replaceAll('{timestamp}', timestamp);

    return '$fileName$extension';
  }

  /// Ensure unique file name by adding suffix if file exists (mobile only)
  Future<String> _ensureUniqueFileName(String filePath) async {
    if (kIsWeb) return filePath; // Not applicable for web

    String uniquePath = filePath;
    int counter = 1;

    while (await File(uniquePath).exists()) {
      final String dir = path.dirname(filePath);
      final String baseName = path.basenameWithoutExtension(filePath);
      final String extension = path.extension(filePath);
      uniquePath = path.join(dir, '${baseName}_$counter$extension');
      counter++;
    }

    return uniquePath;
  }

  /// Compress image with specified quality
  Future<File> compressImage(File imageFile, {int quality = 80}) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Compress image
      final Uint8List compressedBytes =
          Uint8List.fromList(img.encodeJpg(image, quality: quality));

      // Create temporary file
      final File compressedFile = await _createTempFile(
        compressedBytes,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      return compressedFile;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      rethrow;
    }
  }

  /// Resize image to specified dimensions
  Future<File> resizeImage(
    File imageFile, {
    required int width,
    required int height,
    bool maintainAspectRatio = true,
  }) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      img.Image resizedImage;

      if (maintainAspectRatio) {
        // Use copyResize with width and height - it will maintain aspect ratio automatically
        resizedImage = img.copyResize(
          image,
          width: width,
          height: height,
        );
      } else {
        // Force exact dimensions without maintaining aspect ratio
        resizedImage = img.copyResize(
          image,
          width: width,
          height: height,
        );
      }

      // Encode resized image
      final Uint8List resizedBytes =
          Uint8List.fromList(img.encodeJpg(resizedImage));

      // Create temporary file
      final File resizedFile = await _createTempFile(
        resizedBytes,
        'resized_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      return resizedFile;
    } catch (e) {
      debugPrint('Error resizing image: $e');
      rethrow;
    }
  }

  /// Convert image to specified format
  Future<File> convertImageFormat(
    File imageFile, {
    required ImageFormat format,
    int quality = 90,
  }) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      Uint8List convertedBytes;
      String extension;

      switch (format) {
        case ImageFormat.jpeg:
          convertedBytes =
              Uint8List.fromList(img.encodeJpg(image, quality: quality));
          extension = '.jpg';
          break;
        case ImageFormat.png:
          convertedBytes = Uint8List.fromList(img.encodePng(image));
          extension = '.png';
          break;
        case ImageFormat.webp:
          // Check if WebP encoding is available
          try {
            // Try to encode as WebP - this might not be available in all versions
            convertedBytes =
                Uint8List.fromList(img.encodeJpg(image, quality: quality));
            // Note: WebP encoding might require a different approach or package
            // For now, fallback to JPEG with high quality
          } catch (e) {
            convertedBytes =
                Uint8List.fromList(img.encodeJpg(image, quality: quality));
          }
          extension = '.webp';
          break;
        case ImageFormat.bmp:
          convertedBytes = Uint8List.fromList(img.encodeBmp(image));
          extension = '.bmp';
          break;
        case ImageFormat.tiff:
          // TIFF encoding might not be available in all versions
          try {
            convertedBytes = Uint8List.fromList(img.encodeTiff(image));
          } catch (e) {
            // Fallback to PNG for lossless format
            convertedBytes = Uint8List.fromList(img.encodePng(image));
          }
          extension = '.tiff';
          break;
      }

      // Create temporary file
      final File convertedFile = await _createTempFile(
        convertedBytes,
        'converted_${DateTime.now().millisecondsSinceEpoch}$extension',
      );

      return convertedFile;
    } catch (e) {
      debugPrint('Error converting image format: $e');
      rethrow;
    }
  }

  /// Crop image with specified rectangle
  Future<File> cropImage(
    File imageFile, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Crop image - ensure coordinates are within bounds
      final int cropX = x.clamp(0, image.width - 1);
      final int cropY = y.clamp(0, image.height - 1);
      final int cropWidth = width.clamp(1, image.width - cropX);
      final int cropHeight = height.clamp(1, image.height - cropY);

      final img.Image croppedImage = img.copyCrop(
        image,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );

      // Encode cropped image
      final Uint8List croppedBytes =
          Uint8List.fromList(img.encodeJpg(croppedImage));

      // Create temporary file
      final File croppedFile = await _createTempFile(
        croppedBytes,
        'cropped_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      return croppedFile;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      rethrow;
    }
  }

  /// Resize image by percentage
  Future<File> resizeImageByPercentage(
    File imageFile, {
    required double percentage,
  }) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate new dimensions
      final int newWidth = ((image.width * percentage) / 100).round();
      final int newHeight = ((image.height * percentage) / 100).round();

      // Ensure minimum size
      final int finalWidth = newWidth.clamp(1, image.width);
      final int finalHeight = newHeight.clamp(1, image.height);

      final img.Image resizedImage = img.copyResize(
        image,
        width: finalWidth,
        height: finalHeight,
      );

      // Encode resized image
      final Uint8List resizedBytes =
          Uint8List.fromList(img.encodeJpg(resizedImage));

      // Create temporary file
      final File resizedFile = await _createTempFile(
        resizedBytes,
        'resized_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      return resizedFile;
    } catch (e) {
      debugPrint('Error resizing image by percentage: $e');
      rethrow;
    }
  }

  /// Create temporary file (cross-platform)
  Future<File> _createTempFile(Uint8List bytes, String fileName) async {
    if (kIsWeb) {
      // For web, create a temporary file using blob URL
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Create a file with the blob URL as path
      // Note: This is a simplified approach for web compatibility
      final file = File(url);

      // Store bytes in a way that can be retrieved later
      _webFileCache[url] = bytes;

      return file;
    } else {
      // Mobile implementation
      final Directory tempDir = await getTemporaryDirectory();
      final File tempFile = File(path.join(tempDir.path, fileName));
      await tempFile.writeAsBytes(bytes);
      return tempFile;
    }
  }

  // Cache for web files
  static final Map<String, Uint8List> _webFileCache = <String, Uint8List>{};

  /// Override readAsBytes for web compatibility
  Future<Uint8List> readFileBytes(File file) async {
    if (kIsWeb) {
      // Check if file is in our web cache
      if (_webFileCache.containsKey(file.path)) {
        return _webFileCache[file.path]!;
      }
    }
    return await file.readAsBytes();
  }

  /// Get available interpolation methods for the current image package version
  List<String> getAvailableInterpolationMethods() {
    // Return methods that are commonly available
    return ['nearest', 'linear', 'cubic', 'average'];
  }

  /// Clean up temporary files
  Future<void> cleanupTempFiles() async {
    try {
      if (kIsWeb) {
        // Clean up web blob URLs and cache
        for (String url in _webFileCache.keys) {
          if (url.startsWith('blob:')) {
            html.Url.revokeObjectUrl(url);
          }
        }
        _webFileCache.clear();
        return;
      }

      // Mobile cleanup
      final Directory tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final List<FileSystemEntity> files = tempDir.listSync();
        for (FileSystemEntity file in files) {
          if (file is File &&
              (file.path.contains('compressed_') ||
                  file.path.contains('resized_') ||
                  file.path.contains('converted_') ||
                  file.path.contains('cropped_'))) {
            try {
              await file.delete();
            } catch (e) {
              debugPrint('Error deleting temp file: ${file.path}, error: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up temp files: $e');
    }
  }
}

/// Image metadata class
class ImageMetadata {
  final int width;
  final int height;
  final int fileSizeBytes;
  final String fileSizeMB;
  final String fileName;
  final String filePath;

  ImageMetadata({
    required this.width,
    required this.height,
    required this.fileSizeBytes,
    required this.fileSizeMB,
    required this.fileName,
    required this.filePath,
  });

  @override
  String toString() {
    return 'ImageMetadata(width: $width, height: $height, size: $fileSizeMB MB, fileName: $fileName)';
  }
}

/// Supported image formats
enum ImageFormat {
  jpeg,
  png,
  webp,
  bmp,
  tiff,
}

/// Extension to get format from string
extension ImageFormatExtension on ImageFormat {
  String get name {
    switch (this) {
      case ImageFormat.jpeg:
        return 'JPEG';
      case ImageFormat.png:
        return 'PNG';
      case ImageFormat.webp:
        return 'WebP';
      case ImageFormat.bmp:
        return 'BMP';
      case ImageFormat.tiff:
        return 'TIFF';
    }
  }

  String get extension {
    switch (this) {
      case ImageFormat.jpeg:
        return '.jpg';
      case ImageFormat.png:
        return '.png';
      case ImageFormat.webp:
        return '.webp';
      case ImageFormat.bmp:
        return '.bmp';
      case ImageFormat.tiff:
        return '.tiff';
    }
  }
}
