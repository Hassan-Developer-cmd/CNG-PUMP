import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../widgets/camera/camera_control_bar.dart';
import '../../widgets/camera/camera_viewfinder_frame.dart';

class CameraScreen extends StatefulWidget {
  final String? title;

  const CameraScreen({super.key, this.title});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isInitializing = true;
  String? _errorMessage;
  bool _isFlashOn = false;
  bool _isCapturing = false;

  late final AnimationController _animController;
  late final Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _laserAnimation = Tween<double>(begin: 0.08, end: 0.92).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _animController.repeat(reverse: true);

    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _startCameraController(_cameras[_selectedCameraIndex]);
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _errorMessage = 'No camera hardware detected on this device.';
          });
        }
        return;
      }

      final backIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      _selectedCameraIndex = backIndex != -1 ? backIndex : 0;

      await _startCameraController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      debugPrint('[CameraScreen] Error listing cameras: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Could not access device camera: $e';
        });
      }
    }
  }

  Future<void> _startCameraController(
    CameraDescription cameraDescription,
  ) async {
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = cameraController;

    try {
      await cameraController.initialize();
      try {
        await cameraController.setFocusMode(FocusMode.auto);
      } catch (_) {
        // Some devices don't support explicit auto focus calls
      }
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = null;
          _isFlashOn = false;
        });
      }
    } catch (e) {
      debugPrint('[CameraScreen] Camera controller initialization error: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Camera initialization failed: $e';
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final bool newFlash = !_isFlashOn;
      await _controller!.setFlashMode(
        newFlash ? FlashMode.torch : FlashMode.off,
      );
      if (mounted) {
        setState(() {
          _isFlashOn = newFlash;
        });
      }
    } catch (e) {
      debugPrint('[CameraScreen] Flash mode error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flashlight is not supported on this camera'),
          ),
        );
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isCapturing) return;

    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _selectedCameraIndex = nextIndex;

    setState(() {
      _isInitializing = true;
      _isFlashOn = false;
    });

    await _controller?.dispose();
    await _startCameraController(_cameras[_selectedCameraIndex]);
  }

  /// Extra margin (as a fraction of the visible scan window's own
  /// width/height) added ONLY to the region that gets cropped and sent to
  /// OCR. The on-screen viewfinder box the user aligns to is NOT resized —
  /// this purely gives the OCR crop a little breathing room so digits or a
  /// decimal point sitting right at the edge of the frame (which the user
  /// can't perfectly judge by eye) aren't chopped off.
  static const double _ocrCropPadding = 0.22;

  /// Inflates [scanWindow] by [_ocrCropPadding] on every side. This is what
  /// actually gets cropped out of the full-resolution photo for OCR — the
  /// visible frame drawn on screen keeps using the original [scanWindow]
  /// unchanged.
  Rect _paddedOcrWindow(Rect scanWindow) {
    final double padX = scanWindow.width * _ocrCropPadding;
    final double padY = scanWindow.height * _ocrCropPadding;
    return Rect.fromLTRB(
      scanWindow.left - padX,
      scanWindow.top - padY,
      scanWindow.right + padX,
      scanWindow.bottom + padY,
    );
  }

  /// Crops the captured full-sensor image down to the (padded) scanner
  /// window bounding box. Accounts for screen aspect ratio, BoxFit.cover
  /// display scaling, and EXIF orientation.
  Future<File> _cropImageToScanWindow(
    XFile photo,
    Rect scanWindow,
    Size screenSize,
  ) async {
    try {
      final Uint8List bytes = await photo.readAsBytes();
      img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return File(photo.path);
      }

      // Bake orientation to handle camera sensor rotation (EXIF)
      decoded = img.bakeOrientation(decoded);

      final double imageWidth = decoded.width.toDouble();
      final double imageHeight = decoded.height.toDouble();

      final double imageRatio = imageWidth / imageHeight;
      final double screenRatio = screenSize.width / screenSize.height;

      double scale;
      double offsetX = 0;
      double offsetY = 0;

      if (screenRatio < imageRatio) {
        // Screen is taller than image aspect ratio (preview fits height)
        scale = screenSize.height / imageHeight;
        offsetX = (imageWidth * scale - screenSize.width) / 2;
      } else {
        // Screen is wider than image aspect ratio (preview fits width)
        scale = screenSize.width / imageWidth;
        offsetY = (imageHeight * scale - screenSize.height) / 2;
      }

      // Map screen coordinates to image pixels
      final int cropX = ((scanWindow.left + offsetX) / scale).round().clamp(
        0,
        decoded.width - 1,
      );
      final int cropY = ((scanWindow.top + offsetY) / scale).round().clamp(
        0,
        decoded.height - 1,
      );
      final int cropW = (scanWindow.width / scale).round().clamp(
        1,
        decoded.width - cropX,
      );
      final int cropH = (scanWindow.height / scale).round().clamp(
        1,
        decoded.height - cropY,
      );

      final img.Image cropped = img.copyCrop(
        decoded,
        x: cropX,
        y: cropY,
        width: cropW,
        height: cropH,
      );

      final List<int> encodedBytes = img.encodeJpg(cropped, quality: 100);
      final Directory tempDir = Directory.systemTemp;
      final String targetPath =
          '${tempDir.path}/cropped_meter_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final File resultFile = File(targetPath);
      await resultFile.writeAsBytes(encodedBytes);

      debugPrint(
        '[CameraScreen] Cropped image to scan window: $cropW x $cropH at ($cropX, $cropY)',
      );
      return resultFile;
    } catch (e, st) {
      debugPrint('[CameraScreen] Error cropping image: $e\n$st');
      return File(photo.path);
    }
  }

  Future<void> _takePicture(Rect scanWindow, Size screenSize) async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile photo = await _controller!.takePicture();
      // scanWindow is the exact box the user sees and aligned to; we crop a
      // slightly larger area around it (see _paddedOcrWindow) so the OCR
      // service gets the full digits/decimal point even if the user's
      // alignment was a few pixels off — without changing the size of the
      // frame that's actually shown on screen.
      final Rect ocrWindow = _paddedOcrWindow(scanWindow);
      final File croppedFile = await _cropImageToScanWindow(
        photo,
        ocrWindow,
        screenSize,
      );

      if (mounted) {
        Navigator.of(context).pop(croppedFile);
      }
    } catch (e) {
      debugPrint('[CameraScreen] Error taking picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to take picture: $e')));
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isCapturing) return;

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 100,
      );

      if (photo != null && mounted) {
        Navigator.of(context).pop(File(photo.path));
      }
    } catch (e) {
      debugPrint('[CameraScreen] Gallery pick error: $e');
    }
  }

  Widget _buildCameraPreview() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return Container(color: Colors.black);
    }

    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: 1080,
            height: 1080 * controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String screenTitle = widget.title ?? AppConstants.scanMeterTitle;
    final Size screenSize = MediaQuery.of(context).size;

    // Responsive scanner window geometry matching reference screenshot
    final double windowWidth = screenSize.width * 0.88;
    const double windowHeight = 230.0;
    final double windowLeft = (screenSize.width - windowWidth) / 2;
    // Slightly offset vertically to balance space between top pill and bottom controls
    final double windowTop = (screenSize.height - windowHeight) / 2 - 30;
    final Rect scanWindowRect = Rect.fromLTWH(
      windowLeft,
      windowTop,
      windowWidth,
      windowHeight,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Live Camera Feed or Fallback Background
          if (!_isInitializing && _errorMessage == null)
            _buildCameraPreview()
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primaryTeal, Color(0xFF044840)],
                ),
              ),
            ),

          // Layer 2: Dark Mask Overlay Outside Scanner Square (matching reference image)
          if (!_isInitializing && _errorMessage == null)
            CustomPaint(
              size: screenSize,
              painter: ScannerOverlayPainter(
                scanWindow: scanWindowRect,
                overlayColor: const Color(0xE802352C), // Dark teal scrim
                borderRadius: 8.0,
              ),
            ),

          // Layer 3: Scanner Frame (Corner Brackets & Animated Laser Line)
          if (!_isInitializing && _errorMessage == null)
            Positioned.fromRect(
              rect: scanWindowRect,
              child: Stack(
                children: [
                  // Corner Brackets
                  CustomPaint(
                    size: Size.infinite,
                    painter: CornerBracketsPainter(),
                  ),

                  // Animated Horizontal Scan Laser Line
                  AnimatedBuilder(
                    animation: _laserAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: windowHeight * _laserAnimation.value,
                        left: 8,
                        right: 8,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 1.5,
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.9),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

          // Layer 4: "Align display within frame" Pill Guide
          if (!_isInitializing && _errorMessage == null)
            Positioned(
              top: scanWindowRect.top - 52,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    AppConstants.alignDisplayPrompt,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),

          // Layer 5: Top Bar & Bottom Controls (or Loading / Error State)
          SafeArea(
            child: Column(
              children: [
                // Top Bar with Close, Title, and Flashlight
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        screenTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isFlashOn
                              ? Icons.flashlight_on
                              : Icons.flashlight_off_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                        tooltip: 'Toggle Flashlight',
                        onPressed: (_controller?.value.isInitialized ?? false)
                            ? _toggleFlash
                            : null,
                      ),
                    ],
                  ),
                ),

                // Middle area: Loading or Error States (if camera unavailable)
                Expanded(
                  child: Center(
                    child: _isInitializing
                        ? const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 16),
                              Text(
                                'Starting camera...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        : _errorMessage != null
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.videocam_off_outlined,
                                  size: 54,
                                  color: Colors.white70,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _initializeCamera,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryTeal,
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(Icons.refresh, size: 18),
                                      label: const Text('Retry'),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton.icon(
                                      onPressed: _pickFromGallery,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(
                                          color: Colors.white,
                                        ),
                                      ),
                                      icon: const Icon(Icons.history, size: 18),
                                      label: const Text('Gallery'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),

                // Bottom Control Bar
                CameraControlBar(
                  onCapture: () => _takePicture(scanWindowRect, screenSize),
                  onHistoryOrGallery: _pickFromGallery,
                  onSwitchCamera: _cameras.length > 1 ? _switchCamera : null,
                  isCapturing: _isCapturing,
                ),
              ],
            ),
          ),

          // Layer 6: Capturing & Cropping Loading Overlay
          if (_isCapturing)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Capturing...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom painter that masks everything OUTSIDE the scanner window.
class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final Color overlayColor;
  final double borderRadius;

  ScannerOverlayPainter({
    required this.scanWindow,
    required this.overlayColor,
    this.borderRadius = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final windowPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(scanWindow, Radius.circular(borderRadius)),
      );

    // Subtract the scan window from the full-screen background
    final cutPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      windowPath,
    );

    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(cutPath, paint);
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanWindow != scanWindow ||
        oldDelegate.overlayColor != overlayColor;
  }
}
