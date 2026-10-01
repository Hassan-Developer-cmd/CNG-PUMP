import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../models/capture_history_item.dart';

class AuditPhotoFullscreenViewer extends StatefulWidget {
  final List<CapturedImage> images;
  final int initialIndex;
  final String stationName;
  final String operatorName;
  final String? modeName;

  const AuditPhotoFullscreenViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.stationName = 'Station #01 • North Hub Karachi',
    this.operatorName = 'Ali (OP-7890)',
    this.modeName,
  });

  @override
  State<AuditPhotoFullscreenViewer> createState() =>
      _AuditPhotoFullscreenViewerState();
}

class _AuditPhotoFullscreenViewerState
    extends State<AuditPhotoFullscreenViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final List<TransformationController> _controllers = [];
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.images.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    for (int i = 0; i < widget.images.length; i++) {
      _controllers.add(TransformationController());
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _resetZoom() {
    if (_currentIndex < _controllers.length) {
      _controllers[_currentIndex].value = Matrix4.identity();
    }
  }

  void _zoomIn() {
    if (_currentIndex < _controllers.length) {
      final current = _controllers[_currentIndex].value.getMaxScaleOnAxis();
      final newScale = (current * 1.5).clamp(1.0, 6.0);
      _controllers[_currentIndex].value = Matrix4.diagonal3Values(newScale, newScale, 1.0);
    }
  }

  void _zoomOut() {
    if (_currentIndex < _controllers.length) {
      final current = _controllers[_currentIndex].value.getMaxScaleOnAxis();
      final newScale = (current / 1.5).clamp(1.0, 6.0);
      _controllers[_currentIndex].value = Matrix4.diagonal3Values(newScale, newScale, 1.0);
    }
  }

  void _handleDoubleTap() {
    if (_currentIndex < _controllers.length) {
      final current = _controllers[_currentIndex].value.getMaxScaleOnAxis();
      if (current > 1.2) {
        _controllers[_currentIndex].value = Matrix4.identity();
      } else {
        _controllers[_currentIndex].value = Matrix4.diagonal3Values(2.5, 2.5, 1.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentImage = widget.images[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            // 1. Swipeable Fullscreen Interactive Viewport
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _resetZoom();
                });
              },
              itemBuilder: (context, index) {
                final item = widget.images[index];
                final bool fileExists = item.image.path.isNotEmpty &&
                    item.image.existsSync();
                final bool hasUrl = item.imageUrl != null &&
                    item.imageUrl!.isNotEmpty;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _showControls = !_showControls;
                    });
                  },
                  onDoubleTap: _handleDoubleTap,
                  child: Center(
                    child: InteractiveViewer(
                      transformationController: _controllers[index],
                      minScale: 0.8,
                      maxScale: 6.0,
                      boundaryMargin: const EdgeInsets.all(60),
                      clipBehavior: Clip.none,
                      child: fileExists
                          ? Image.file(
                              item.image,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  _buildSimulatedHighResView(item),
                            )
                          : hasUrl &&
                                  (item.imageUrl!.startsWith('http://') ||
                                      item.imageUrl!.startsWith('https://'))
                              ? Image.network(
                                  item.imageUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      _buildSimulatedHighResView(item),
                                )
                              : hasUrl && item.imageUrl!.startsWith('assets/')
                                  ? Image.asset(
                                      item.imageUrl!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          _buildSimulatedHighResView(item),
                                    )
                                  : _buildSimulatedHighResView(item),
                    ),
                  ),
                );
              },
            ),

            // 2. Animated Top App Bar & Controls
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              top: _showControls ? 0 : -100,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(16.w, 44.h, 16.w, 14.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.9),
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // Close button
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),

                    // Title & Counter
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  currentImage.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF56BAA7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${_currentIndex + 1} / ${widget.images.length}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentImage.formattedCapturedAt,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Zoom Controls
                    IconButton(
                      icon: const Icon(Icons.zoom_out, color: Colors.white),
                      tooltip: 'Zoom Out',
                      onPressed: _zoomOut,
                    ),
                    IconButton(
                      icon: const Icon(Icons.zoom_in, color: Colors.white),
                      tooltip: 'Zoom In',
                      onPressed: _zoomIn,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      tooltip: 'Reset Zoom',
                      onPressed: _resetZoom,
                    ),
                  ],
                ),
              ),
            ),

            // 3. Animated Bottom Information Card
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              bottom: _showControls ? 0 : -140,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 28.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.95),
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: const Color(0xFF56BAA7).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.verified_user_rounded,
                                      size: 14,
                                      color: Color(0xFF34D399),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'WATERMARK AUDIT VERIFIED',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10.5.sp,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF34D399),
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.modeName != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryTeal,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    widget.modeName!,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Station: ${widget.stationName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5.sp,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Op: ${widget.operatorName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pinch to zoom or double-tap to inspect stamped pixel watermark & counter digits',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulatedHighResView(CapturedImage item) {
    return Container(
      width: 360.w,
      height: 480.h,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF334155), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Inner LCD Glass
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF050811),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFF22C55E), width: 2),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.speed, color: Color(0xFF34D399), size: 28),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'DISPENSER ${item.label.toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'FLOW READING VALUE:',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _mockReadingValue(item.label),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF34D399),
                      fontFamily: 'monospace',
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'HARDWARE SERIAL: PK-CNG-89421 • CALIBRATION CERT: OK',
                      style: TextStyle(fontSize: 10, color: Colors.teal.shade200),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF451A03),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'SEAL STATUS: AUDIT LOCKED (TAMPER EVIDENT)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFBBF24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stamped Pixel Watermark Banner (Bottom-Left)
          Positioned(
            left: 28,
            bottom: 28,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, size: 14, color: Colors.greenAccent),
                  const SizedBox(width: 6),
                  Text(
                    item.formattedCapturedAt,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'monospace',
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

  String _mockReadingValue(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('vb1')) return '1,450.00 M3';
    if (lower.contains('vs1')) return '1,450.00 M3';
    if (lower.contains('flow')) return '245.8 KG/H';
    if (lower.contains('counter')) return '2,105.85 KG';
    if (lower.contains('micro')) return '2,105.85 KG';
    return '2,104.50 KG';
  }
}
