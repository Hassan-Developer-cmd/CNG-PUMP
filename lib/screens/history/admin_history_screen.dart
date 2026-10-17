import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/history_provider.dart';
import '../../widgets/shared_widgets/custom_app_bar.dart';

/// Dynamic URL resolver function as specified in requirement 3
String resolveImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final cleanPath = path.startsWith('/') ? path : '/$path';
  return 'http://192.168.1.8:5000$cleanPath';
}

/// Admin Capture History Screen
/// Fetches all capture records across all stations and operators via:
/// GET http://192.168.1.8:5000/api/v1/capture/getAllCaptureHistory
class AdminHistoryScreen extends StatefulWidget {
  const AdminHistoryScreen({super.key});

  @override
  State<AdminHistoryScreen> createState() => _AdminHistoryScreenState();
}

class _AdminHistoryScreenState extends State<AdminHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch all capture history records on screen load if not already loaded or in error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<HistoryProvider>(context, listen: false);
        if (provider.allCaptureList.isEmpty && provider.captureError == null) {
          provider.fetchAllCaptures();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: CustomCurvedAppBar(
        title: 'All Capture History',
        showBackButton: canPop,
        showLogo: !canPop,
        onBackPressed: canPop ? () => Navigator.of(context).pop() : null,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header Bar
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ADMIN AUDIT SESSIONS',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.figmaEmerald,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Complete ledger of all operator captures and watermarks',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Consumer<HistoryProvider>(
                    builder: (_, provider, __) {
                      final count = provider.allCaptureList.length;
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.badgeActiveBg,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          '$count Records',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.figmaDarkGreen,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Main Content with RefreshIndicator
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => Provider.of<HistoryProvider>(context, listen: false)
                    .fetchAllCaptures(showLoading: false),
                color: AppColors.figmaEmerald,
                child: Consumer<HistoryProvider>(
                  builder: (context, provider, _) {
                    // 1. Loading State
                    if (provider.isLoadingCaptures) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.figmaEmerald),
                        ),
                      );
                    }

                    // 2. Error State with Retry Button
                    if (provider.captureError != null) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: 500.h,
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_off_rounded,
                                size: 54.sp,
                                color: const Color(0xFFDC2626),
                              ),
                              SizedBox(height: 14.h),
                              Text(
                                provider.captureError!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 18.h),
                              ElevatedButton.icon(
                                onPressed: () => Provider.of<HistoryProvider>(context, listen: false)
                                    .fetchAllCaptures(),
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.figmaEmerald,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // 3. Empty State
                    if (provider.allCaptureList.isEmpty) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: 500.h,
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 68.w,
                                height: 68.h,
                                decoration: const BoxDecoration(
                                  color: AppColors.lightTeal,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.history_rounded,
                                  size: 34.sp,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'No capture records found',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'Completed audit sessions across all stations will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // 4. Populated State: Display Audit Session Cards
                    final items = provider.allCaptureList;
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => SizedBox(height: 14.h),
                      itemBuilder: (context, index) {
                        final rawItem = items[index];
                        return _AdminCaptureSessionCard(
                          session: rawItem is Map<String, dynamic>
                              ? rawItem
                              : (rawItem is Map
                                  ? rawItem.map((k, v) => MapEntry(k.toString(), v))
                                  : <String, dynamic>{}),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Audit Session Card for Admin History Screen
class _AdminCaptureSessionCard extends StatelessWidget {
  final Map<String, dynamic> session;

  const _AdminCaptureSessionCard({required this.session});

  // Extract Operator details
  String get operatorDisplayName {
    final op = session['operatorName'] ??
        session['username'] ??
        (session['operator'] is Map ? (session['operator']['name'] ?? session['operator']['username']) : null) ??
        (session['user'] is Map ? (session['user']['name'] ?? session['user']['username']) : null) ??
        session['userId'] ??
        session['operatorId'] ??
        'Unknown Operator';
    return op.toString();
  }

  // Extract Station Name
  String get stationDisplayName {
    final st = session['stationName'] ??
        (session['station'] is Map ? (session['station']['name'] ?? session['station']['stationName']) : null) ??
        session['station'] ??
        (session['pump'] is Map ? session['pump']['name'] : null) ??
        session['pump'] ??
        session['stationId'] ??
        'CNG Station';
    return st.toString();
  }

  // Format timestamp (date & time)
  String get formattedTimestamp {
    final raw = session['createdAt'] ?? session['timestamp'] ?? session['dateTime'] ?? session['date'];
    if (raw == null) return '';
    DateTime? dt;
    if (raw is DateTime) {
      dt = raw;
    } else if (raw is String) {
      dt = DateTime.tryParse(raw);
    }
    if (dt == null) return raw.toString();

    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');

    return '$day/$month/${dt.year}  $hour:$minute:$second $period';
  }

  // Capture type: "meter" or "nozzle" with nozzle number
  String get captureTypeBadge {
    final rawMode = (session['mode'] ?? session['captureType'] ?? session['type'] ?? session['modeName'] ?? 'meter').toString();
    final isNozzle = rawMode.toLowerCase().contains('nozzle');

    String? nozzleNumber = session['nozzleNumber']?.toString() ?? session['nozzle']?.toString();
    if (nozzleNumber == null && isNozzle) {
      final match = RegExp(r'\d+').firstMatch(rawMode);
      if (match != null) {
        nozzleNumber = match.group(0);
      }
    }

    if (isNozzle) {
      return nozzleNumber != null && nozzleNumber.isNotEmpty
          ? 'Nozzle $nozzleNumber'
          : 'Nozzle';
    }
    return 'Meter';
  }

  bool get isMeter => captureTypeBadge.toLowerCase() == 'meter';

  // Extract all images from session object
  List<Map<String, String>> get extractedImages {
    final List<Map<String, String>> results = [];

    // 1. Array of images: session['images'] or session['photos']
    final rawList = session['images'] ?? session['photos'] ?? session['uploadedImages'];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map) {
          final path = (item['url'] ?? item['path'] ?? item['imageUrl'] ?? item['imagePath'])?.toString() ?? '';
          final label = (item['label'] ?? item['imageType'] ?? item['type'] ?? item['name'] ?? 'Photo').toString();
          if (path.isNotEmpty || label.isNotEmpty) {
            results.add({'url': path, 'label': label});
          }
        } else if (item is String && item.isNotEmpty) {
          results.add({'url': item, 'label': 'Photo'});
        }
      }
    } else if (rawList is Map) {
      rawList.forEach((k, v) {
        if (v is String && v.isNotEmpty) {
          results.add({'url': v, 'label': k.toString()});
        } else if (v is Map) {
          final path = (v['url'] ?? v['path'] ?? v['imageUrl'])?.toString() ?? '';
          results.add({'url': path, 'label': k.toString()});
        }
      });
    }

    // 2. Direct keys: vb1, vs1, digitalMachine, counter, microMotion, rFlow
    const knownKeys = ['vb1', 'vs1', 'digitalMachine', 'counter', 'microMotion', 'rFlow'];
    for (final key in knownKeys) {
      if (session[key] != null && !results.any((r) => r['label']?.toLowerCase() == key.toLowerCase())) {
        final val = session[key];
        if (val is String && val.isNotEmpty) {
          results.add({'url': val, 'label': key});
        } else if (val is Map) {
          final path = (val['url'] ?? val['path'] ?? val['imageUrl'])?.toString() ?? '';
          results.add({'url': path, 'label': key});
        }
      }
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final images = extractedImages;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10.r,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Row: Station Icon, Station Name & Mode Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36.w,
                height: 36.h,
                decoration: BoxDecoration(
                  color: AppColors.lightTeal,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.local_gas_station_rounded,
                  size: 20.sp,
                  color: AppColors.primaryTeal,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stationDisplayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 12.sp, color: AppColors.textMuted),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            'Op: $operatorDisplayName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // Capture Type Badge (Meter vs Nozzle)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isMeter ? const Color(0xFFE0F2FE) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isMeter ? const Color(0xFF0284C7) : const Color(0xFF16A34A),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  captureTypeBadge,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: isMeter ? const Color(0xFF0369A1) : const Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // 2. Image Gallery Grid
          _buildImageGalleryGrid(context, images),

          SizedBox(height: 12.h),

          // 3. Footer Row: Timestamp & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 13.sp, color: AppColors.textMuted),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        formattedTimestamp.isNotEmpty ? formattedTimestamp : 'Recorded',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 11, color: Color(0xFF059669)),
                    SizedBox(width: 3.w),
                    Text(
                      'CAPTURED',
                      style: TextStyle(
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build the Image Gallery Grid
  Widget _buildImageGalleryGrid(BuildContext context, List<Map<String, String>> images) {
    if (images.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_camera_back_outlined, size: 16.sp, color: AppColors.textMuted),
              SizedBox(width: 6.w),
              Text(
                'No images captured',
                style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    final int crossAxisCount = images.length == 1 ? 1 : (images.length == 2 ? 2 : 3);
    final double childAspectRatio = images.length == 1 ? 1.8 : 1.0;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final img = images[index];
        final rawPath = img['url'] ?? '';
        final resolvedUrl = resolveImageUrl(rawPath);
        final label = img['label'] ?? 'Image';

        return _buildThumbnailItem(context, resolvedUrl: resolvedUrl, label: label);
      },
    );
  }

  Widget _buildThumbnailItem(
    BuildContext context, {
    required String resolvedUrl,
    required String label,
  }) {
    return GestureDetector(
      onTap: () {
        // Tapping any image opens interactive full-screen viewer (InteractiveViewer)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InteractiveFullScreenImageViewer(
              imageUrl: resolvedUrl,
              label: label,
              operatorName: operatorDisplayName,
              stationName: stationDisplayName,
              timestamp: formattedTimestamp,
              captureType: captureTypeBadge,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: AppColors.primaryTeal.withValues(alpha: 0.35),
            width: 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Network image with loading indicator and broken image fallback
              if (resolvedUrl.isNotEmpty)
                Image.network(
                  resolvedUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white70),
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      _buildBrokenImageFallback(label),
                )
              else
                _buildBrokenImageFallback(label),

              // 2. Bottom Label Pill
              Positioned(
                left: 6.w,
                bottom: 6.h,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // 3. Top-Right Zoom Hint Icon
              Positioned(
                right: 6.w,
                top: 6.h,
                child: Container(
                  padding: EdgeInsets.all(3.r),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fullscreen_rounded,
                    color: Colors.white,
                    size: 13.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrokenImageFallback(String label) {
    return Container(
      color: const Color(0xFF1E293B),
      padding: EdgeInsets.all(6.r),
      child: Center(
        child: Icon(Icons.photo_outlined, size: 24.sp, color: Colors.white54),
      ),
    );
  }
}

/// Interactive Fullscreen Image Viewer with InteractiveViewer
class InteractiveFullScreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String label;
  final String operatorName;
  final String stationName;
  final String timestamp;
  final String captureType;

  const InteractiveFullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.label,
    required this.operatorName,
    required this.stationName,
    required this.timestamp,
    required this.captureType,
  });

  @override
  State<InteractiveFullScreenImageViewer> createState() =>
      _InteractiveFullScreenImageViewerState();
}

class _InteractiveFullScreenImageViewerState
    extends State<InteractiveFullScreenImageViewer> {
  final TransformationController _transformationController =
      TransformationController();
  bool _showControls = true;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _zoomIn() {
    final current = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (current * 1.5).clamp(1.0, 6.0);
    _transformationController.value =
        Matrix4.diagonal3Values(newScale, newScale, 1.0);
  }

  void _zoomOut() {
    final current = _transformationController.value.getMaxScaleOnAxis();
    final newScale = (current / 1.5).clamp(1.0, 6.0);
    _transformationController.value =
        Matrix4.diagonal3Values(newScale, newScale, 1.0);
  }

  void _handleDoubleTap() {
    final current = _transformationController.value.getMaxScaleOnAxis();
    if (current > 1.2) {
      _resetZoom();
    } else {
      _transformationController.value =
          Matrix4.diagonal3Values(2.5, 2.5, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            // 1. InteractiveViewer viewport for full-screen pan and pinch-to-zoom
            GestureDetector(
              onTap: () {
                setState(() {
                  _showControls = !_showControls;
                });
              },
              onDoubleTap: _handleDoubleTap,
              child: Center(
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.5,
                  maxScale: 6.0,
                  boundaryMargin: const EdgeInsets.all(40),
                  clipBehavior: Clip.none,
                  child: widget.imageUrl.isNotEmpty
                      ? Image.network(
                          widget.imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              _buildHighResPlaceholder(),
                        )
                      : _buildHighResPlaceholder(),
                ),
              ),
            ),

            // 2. Animated Top Bar
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
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.timestamp.isNotEmpty ? widget.timestamp : 'Audit Photo',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
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

            // 3. Animated Bottom Bar
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
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: const Color(0xFF56BAA7).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.captureType,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
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
                          Text(
                            'Op: ${widget.operatorName}',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighResPlaceholder() {
    return Container(
      width: 320.w,
      height: 420.h,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF334155), width: 3),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_rounded, size: 48, color: Colors.white54),
            const SizedBox(height: 12),
            Text(
              'Inspection: ${widget.label}',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              widget.imageUrl,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
