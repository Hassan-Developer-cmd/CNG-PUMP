import 'dart:io';

class ImageTextModel {
  final int index;
  File? image;
  String extractedText;
  bool isLoading;
  String? error;

  ImageTextModel({
    required this.index,
    this.image,
    this.extractedText = '',
    this.isLoading = false,
    this.error,
  });
}
