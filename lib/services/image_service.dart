import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Picks a single image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      // Request permission for gallery access
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        bool hasPermission = await _requestGalleryPermission();
        if (!hasPermission) {
          throw Exception('Gallery permission denied');
        }
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 100,
      );

      return image;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      rethrow;
    }
  }

  /// Picks multiple images from gallery
  Future<List<XFile>> pickMultipleImagesFromGallery({int? maxImages}) async {
    try {
      // Request permission for gallery access
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        bool hasPermission = await _requestGalleryPermission();
        if (!hasPermission) {
          throw Exception('Gallery permission denied');
        }
      }

      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 100,
      );

      // Limit number of images if specified
      if (maxImages != null && images.length > maxImages) {
        return images.take(maxImages).toList();
      }

      return images;
    } catch (e) {
      debugPrint('Error picking multiple images from gallery: $e');
      rethrow;
    }
  }

  /// Picks image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      // Request camera permission
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        bool hasPermission = await _requestCameraPermission();
        if (!hasPermission) {
          throw Exception('Camera permission denied');
        }
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 100,
      );

      return image;
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      rethrow;
    }
  }

  /// Compresses image with specified quality and options
  Future<Uint8List> compressImage(
    XFile imageFile, {
    int quality = 80,
    bool lossless = false,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if max dimensions specified
      if (maxWidth != null || maxHeight != null) {
        originalImage = img.copyResize(
          originalImage,
          width: maxWidth,
          height: maxHeight,
          interpolation: img.Interpolation.cubic,
        );
      }

      // Encode based on compression type
      List<int> compressedBytes;
      if (lossless) {
        compressedBytes = img.encodePng(originalImage);
      } else {
        compressedBytes = img.encodeJpg(originalImage, quality: quality);
      }

      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      debugPrint('Error compressing image: $e');
      rethrow;
    }
  }

  /// Crops image to specified dimensions and aspect ratio
  Future<Uint8List> cropImage(
    XFile imageFile, {
    required int x,
    required int y,
    required int width,
    required int height,
    String aspectRatio = 'free',
  }) async {
    try {
      Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate crop dimensions based on aspect ratio
      int cropWidth = width;
      int cropHeight = height;

      if (aspectRatio != 'free') {
        final ratio = _getAspectRatioValues(aspectRatio);
        if (ratio != null) {
          double targetRatio = ratio['width']! / ratio['height']!;
          double currentRatio = width / height;

          if (currentRatio > targetRatio) {
            cropWidth = (height * targetRatio).round();
          } else {
            cropHeight = (width / targetRatio).round();
          }
        }
      }

      // Ensure crop dimensions don't exceed image bounds
      cropWidth = cropWidth.clamp(1, originalImage.width - x);
      cropHeight = cropHeight.clamp(1, originalImage.height - y);

      img.Image croppedImage = img.copyCrop(
        originalImage,
        x: x,
        y: y,
        width: cropWidth,
        height: cropHeight,
      );

      List<int> encodedBytes = img.encodePng(croppedImage);
      return Uint8List.fromList(encodedBytes);
    } catch (e) {
      debugPrint('Error cropping image: $e');
      rethrow;
    }
  }

  /// Resizes image by dimensions or percentage
  Future<Uint8List> resizeImage(
    XFile imageFile, {
    int? width,
    int? height,
    double? percentage,
    bool maintainAspectRatio = true,
    String algorithm = 'lanczos',
  }) async {
    try {
      Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      int targetWidth;
      int targetHeight;

      if (percentage != null) {
        // Resize by percentage
        targetWidth = (originalImage.width * percentage).round();
        targetHeight = (originalImage.height * percentage).round();
      } else if (width != null || height != null) {
        // Resize by dimensions
        if (maintainAspectRatio) {
          double aspectRatio = originalImage.width / originalImage.height;
          if (width != null && height == null) {
            targetWidth = width;
            targetHeight = (width / aspectRatio).round();
          } else if (height != null && width == null) {
            targetHeight = height;
            targetWidth = (height * aspectRatio).round();
          } else {
            targetWidth = width!;
            targetHeight = height!;
          }
        } else {
          targetWidth = width ?? originalImage.width;
          targetHeight = height ?? originalImage.height;
        }
      } else {
        throw Exception('Either dimensions or percentage must be specified');
      }

      // Get interpolation method
      img.Interpolation interpolation = _getInterpolationMethod(algorithm);

      img.Image resizedImage = img.copyResize(
        originalImage,
        width: targetWidth,
        height: targetHeight,
        interpolation: interpolation,
      );

      List<int> encodedBytes = img.encodePng(resizedImage);
      return Uint8List.fromList(encodedBytes);
    } catch (e) {
      debugPrint('Error resizing image: $e');
      rethrow;
    }
  }

  /// Converts image to specified format
  Future<Uint8List> convertImage(
    XFile imageFile, {
    required String outputFormat,
    int quality = 95,
    bool pngCompression = true,
    bool pngInterlaced = false,
  }) async {
    try {
      Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      List<int> convertedBytes;

      switch (outputFormat.toUpperCase()) {
        case 'JPEG':
        case 'JPG':
          convertedBytes = img.encodeJpg(originalImage, quality: quality);
          break;
        case 'PNG':
          convertedBytes = img.encodePng(
            originalImage,
            level: pngCompression ? 6 : 0,
          );
          break;
        case 'WEBP':
          // WebP encoding is not available in the image package
          // Convert to PNG as fallback
          convertedBytes = img.encodePng(originalImage);
          break;
        case 'BMP':
          convertedBytes = img.encodeBmp(originalImage);
          break;
        case 'TIFF':
          convertedBytes = img.encodeTiff(originalImage);
          break;
        case 'GIF':
          convertedBytes = img.encodeGif(originalImage);
          break;
        default:
          throw Exception('Unsupported output format: $outputFormat');
      }

      return Uint8List.fromList(convertedBytes);
    } catch (e) {
      debugPrint('Error converting image: $e');
      rethrow;
    }
  }

  /// Saves processed image to device storage
  Future<String> saveImageToStorage(
    Uint8List imageBytes, {
    required String fileName,
    String? customPath,
    String folderName = 'Pixelize',
  }) async {
    try {
      String filePath;

      if (kIsWeb) {
        // Web platform - trigger download
        await _saveToWebDownloads(imageBytes, fileName);
        return 'Downloaded: $fileName';
      } else {
        // Mobile platforms
        bool hasPermission = await _requestStoragePermission();
        if (!hasPermission) {
          throw Exception('Storage permission denied');
        }

        Directory directory;
        if (customPath != null) {
          directory = Directory(customPath);
        } else {
          if (Platform.isAndroid) {
            directory = Directory('/storage/emulated/0/Pictures/$folderName');
          } else {
            Directory appDir = await getApplicationDocumentsDirectory();
            directory = Directory('${appDir.path}/$folderName');
          }
        }

        // Create directory if it doesn't exist
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        filePath = path.join(directory.path, fileName);
        File file = File(filePath);
        await file.writeAsBytes(imageBytes);

        // Add to gallery on Android
        if (Platform.isAndroid) {
          await _addToGallery(filePath);
        }
      }

      return filePath;
    } catch (e) {
      debugPrint('Error saving image: $e');
      rethrow;
    }
  }

  /// Gets image information
  Future<Map<String, dynamic>> getImageInfo(XFile imageFile) async {
    try {
      Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      int fileSizeBytes = imageBytes.length;
      double fileSizeMB = fileSizeBytes / (1024 * 1024);

      return {
        'width': image.width,
        'height': image.height,
        'channels': image.numChannels,
        'fileSizeBytes': fileSizeBytes,
        'fileSizeMB': double.parse(fileSizeMB.toStringAsFixed(2)),
        'format': _getImageFormat(imageFile.path),
        'aspectRatio': image.width / image.height,
        'megapixels': double.parse(
            ((image.width * image.height) / 1000000).toStringAsFixed(1)),
      };
    } catch (e) {
      debugPrint('Error getting image info: $e');
      rethrow;
    }
  }

  /// Batch process multiple images
  Future<List<Uint8List>> batchProcessImages(
    List<XFile> imageFiles,
    Future<Uint8List> Function(XFile) processor, {
    Function(int, int)? onProgress,
  }) async {
    List<Uint8List> results = [];

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        Uint8List processed = await processor(imageFiles[i]);
        results.add(processed);
        onProgress?.call(i + 1, imageFiles.length);
      } catch (e) {
        debugPrint('Error processing image ${i + 1}: $e');
        rethrow;
      }
    }

    return results;
  }

  // Private helper methods

  Future<bool> _requestGalleryPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.isGranted ||
          await Permission.photos.isGranted ||
          await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.photos,
      ].request();

      return statuses.values
          .any((status) => status == PermissionStatus.granted);
    } else if (Platform.isIOS) {
      PermissionStatus status = await Permission.photos.request();
      return status == PermissionStatus.granted;
    }
    return true;
  }

  Future<bool> _requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.manageExternalStorage,
      ].request();

      return statuses.values
          .any((status) => status == PermissionStatus.granted);
    } else if (Platform.isIOS) {
      PermissionStatus status = await Permission.photosAddOnly.request();
      return status == PermissionStatus.granted;
    }
    return true;
  }

  Future<void> _saveToWebDownloads(Uint8List bytes, String fileName) async {
    try {
      // Create blob and trigger download
      final html = '''
        <script>
          const bytes = [${bytes.join(',')}];
          const blob = new Blob([new Uint8Array(bytes)], {type: 'image/png'});
          const url = URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = '$fileName';
          a.click();
          URL.revokeObjectURL(url);
        </script>
      ''';

      // This would need platform channel implementation for web
      // For now, throw to indicate web download needs additional setup
      throw UnimplementedError(
          'Web download requires additional platform setup');
    } catch (e) {
      debugPrint('Error saving to web downloads: $e');
      rethrow;
    }
  }

  Future<void> _addToGallery(String filePath) async {
    try {
      // Platform channel to add image to Android gallery
      const platform = MethodChannel('com.pixelize.gallery');
      await platform.invokeMethod('addToGallery', {'path': filePath});
    } catch (e) {
      debugPrint('Error adding to gallery: $e');
    }
  }

  Map<String, double>? _getAspectRatioValues(String aspectRatio) {
    switch (aspectRatio) {
      case '1:1':
        return {'width': 1.0, 'height': 1.0};
      case '16:9':
        return {'width': 16.0, 'height': 9.0};
      case '4:3':
        return {'width': 4.0, 'height': 3.0};
      case '3:2':
        return {'width': 3.0, 'height': 2.0};
      default:
        return null;
    }
  }

  img.Interpolation _getInterpolationMethod(String algorithm) {
    switch (algorithm.toLowerCase()) {
      case 'linear':
        return img.Interpolation.linear;
      case 'cubic':
        return img.Interpolation.cubic;
      case 'nearest':
        return img.Interpolation.nearest;
      case 'average':
        return img.Interpolation.average;
      case 'lanczos':
      default:
        return img.Interpolation.cubic; // Use cubic as fallback for lanczos
    }
  }

  String _getImageFormat(String filePath) {
    String extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'JPEG';
      case '.png':
        return 'PNG';
      case '.webp':
        return 'WebP';
      case '.bmp':
        return 'BMP';
      case '.gif':
        return 'GIF';
      case '.tiff':
      case '.tif':
        return 'TIFF';
      default:
        return 'Unknown';
    }
  }

  /// Generate filename with pattern
  String generateFileName({
    required String originalName,
    required String operation,
    String? customPattern,
  }) {
    String baseName = path.basenameWithoutExtension(originalName);
    String extension = path.extension(originalName);
    DateTime now = DateTime.now();
    String timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

    if (customPattern != null) {
      return customPattern
              .replaceAll('[original]', baseName)
              .replaceAll('[operation]', operation)
              .replaceAll('[date]', timestamp) +
          extension;
    }

    return '${operation}_${baseName}_$timestamp$extension';
  }

  /// Cleanup temporary files
  Future<void> cleanupTempFiles() async {
    try {
      if (!kIsWeb) {
        Directory tempDir = await getTemporaryDirectory();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up temp files: $e');
    }
  }
}
