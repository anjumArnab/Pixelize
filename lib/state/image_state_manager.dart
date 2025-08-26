import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImageStateManager extends ChangeNotifier {
  static final ImageStateManager _instance = ImageStateManager._internal();
  factory ImageStateManager() => _instance;
  ImageStateManager._internal();

  final List<XFile> _selectedImages = [];

  List<XFile> get selectedImages => List.unmodifiable(_selectedImages);

  int get imageCount => _selectedImages.length;

  bool get hasImages => _selectedImages.isNotEmpty;

  /// Add a single image to the selection
  void addImage(XFile image) {
    _selectedImages.add(image);
    notifyListeners();
  }

  /// Add multiple images to the selection
  void addImages(List<XFile> images) {
    _selectedImages.addAll(images);
    notifyListeners();
  }

  /// Remove an image at specific index
  void removeImageAt(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages.removeAt(index);
      notifyListeners();
    }
  }

  /// Remove a specific image
  void removeImage(XFile image) {
    _selectedImages.remove(image);
    notifyListeners();
  }

  /// Clear all selected images
  void clearImages() {
    _selectedImages.clear();
    notifyListeners();
  }

  /// Replace image at specific index
  void replaceImageAt(int index, XFile newImage) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages[index] = newImage;
      notifyListeners();
    }
  }

  /// Get image at specific index
  XFile? getImageAt(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      return _selectedImages[index];
    }
    return null;
  }
}
