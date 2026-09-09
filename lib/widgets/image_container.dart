import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/text_comparison_provider.dart';

class ImageInputContainer extends StatefulWidget {
  final int index;
  final String hintText;

  const ImageInputContainer({
    super.key,
    required this.index,
    this.hintText = 'Extracted text will appear here...',
  });

  @override
  State<ImageInputContainer> createState() => _ImageInputContainerState();
}

class _ImageInputContainerState extends State<ImageInputContainer> {
  late final TextEditingController _textController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 100,
      );
      if (image == null) {
        return;
      }

      final File imageFile = File(image.path);

      if (!mounted) return;

      await context.read<TextComparisonProvider>().setImage(
        widget.index,
        imageFile,
      );
    } catch (e) {
      debugPrint('Camera Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TextComparisonProvider>(
      builder: (context, provider, child) {
        final File? selectedImage = provider.getImage(widget.index);
        final String extractedText = provider.getText(widget.index);
        final bool isLoading = provider.getLoading(widget.index);
        final String? error = provider.getError(widget.index);

        // Keep controller synced with provider when OCR finishes or updates
        if (_textController.text != extractedText && !isLoading) {
          _textController.value = TextEditingValue(
            text: extractedText,
            selection: TextSelection.collapsed(offset: extractedText.length),
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE CONTAINER
              GestureDetector(
                onTap: isLoading ? null : _takePicture,
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade400, width: 1),
                  ),
                  child: selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            selectedImage,
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.camera_alt_outlined, size: 30),
                            SizedBox(height: 8),
                            Text(
                              'Take Picture',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // LABEL & EDIT HINT
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Extracted Text ${widget.index + 1}:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (extractedText.isNotEmpty && !isLoading)
                    Text(
                      'Tap to edit if needed',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.blue.shade700,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 6),

              // EDITABLE OCR TEXT FIELD
              TextField(
                controller: _textController,
                maxLines: 3,
                enabled: !isLoading,
                onChanged: (newText) {
                  provider.setText(widget.index, newText);
                },
                decoration: InputDecoration(
                  hintText: isLoading
                      ? 'Extracting text...'
                      : error ?? widget.hintText,
                  hintStyle: TextStyle(
                    color: error != null
                        ? Colors.red.shade400
                        : Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.blue,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              // LOADING
              if (isLoading) ...[
                const SizedBox(height: 10),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        );
      },
    );
  }
}
