import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/cng_reading_item.dart';

class SourceSelectorDropdown extends StatefulWidget {
  final PrimarySourceMode selected;
  final ValueChanged<PrimarySourceMode> onChanged;

  const SourceSelectorDropdown({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<SourceSelectorDropdown> createState() => _SourceSelectorDropdownState();
}

class _SourceSelectorDropdownState extends State<SourceSelectorDropdown> {
  final OverlayPortalController _overlayController = OverlayPortalController();
  final LayerLink _layerLink = LayerLink();

  bool get _isOpen => _overlayController.isShowing;

  void _toggle() {
    _overlayController.toggle();
    setState(() {});
  }

  void _close() {
    if (_overlayController.isShowing) {
      _overlayController.hide();
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant SourceSelectorDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      if (_overlayController.isShowing) {
        _overlayController.hide();
      }
    }
  }

  @override
  void dispose() {
    if (_overlayController.isShowing) {
      _overlayController.hide();
    }
    super.dispose();
  }

  String get _buttonLabel {
    switch (widget.selected) {
      case PrimarySourceMode.nozzle1:
        return 'Nozzle 1';
      case PrimarySourceMode.nozzle2:
        return 'Nozzle 2';
      case PrimarySourceMode.nozzle3:
        return 'Nozzle 3';
      case PrimarySourceMode.nozzle4:
        return 'Nozzle 4';
      case PrimarySourceMode.meter:
        return 'Meter';
      case PrimarySourceMode.nozzle:
        return 'Nozzle 1';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (BuildContext context) {
          return Stack(
            children: [
              // 1. Transparent dismiss barrier: dismiss on outside tap
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _close,
                ),
              ),
              // 2. Floating popover positioned right below the button
              CompositedTransformFollower(
                link: _layerLink,
                targetAnchor: Alignment.bottomRight,
                followerAnchor: Alignment.topRight,
                offset: Offset(0, 6.h),
                child: _buildDropdownMenu(),
              ),
            ],
          );
        },
        child: Material(
          color: const Color(0xFF56BAA7),
          borderRadius: BorderRadius.circular(20.r),
          child: InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(20.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.selected == PrimarySourceMode.meter
                        ? Icons.speed_outlined
                        : Icons.local_gas_station_rounded,
                    color: Colors.white,
                    size: 14.sp,
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    _buttonLabel,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownMenu() {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 140.w,
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: const Color(0xFF56BAA7),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOption(
              label: 'Nozzle 1',
              icon: Icons.local_gas_station_outlined,
              isSelected: widget.selected == PrimarySourceMode.nozzle1 ||
                  widget.selected == PrimarySourceMode.nozzle,
              onTap: () {
                widget.onChanged(PrimarySourceMode.nozzle1);
                _close();
              },
            ),
            SizedBox(height: 4.h),
            _buildOption(
              label: 'Nozzle 2',
              icon: Icons.local_gas_station_outlined,
              isSelected: widget.selected == PrimarySourceMode.nozzle2,
              onTap: () {
                widget.onChanged(PrimarySourceMode.nozzle2);
                _close();
              },
            ),
            SizedBox(height: 4.h),
            _buildOption(
              label: 'Nozzle 3',
              icon: Icons.local_gas_station_outlined,
              isSelected: widget.selected == PrimarySourceMode.nozzle3,
              onTap: () {
                widget.onChanged(PrimarySourceMode.nozzle3);
                _close();
              },
            ),
            SizedBox(height: 4.h),
            _buildOption(
              label: 'Nozzle 4',
              icon: Icons.local_gas_station_outlined,
              isSelected: widget.selected == PrimarySourceMode.nozzle4,
              onTap: () {
                widget.onChanged(PrimarySourceMode.nozzle4);
                _close();
              },
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Divider(
                color: Colors.white.withValues(alpha: 0.35),
                height: 1,
              ),
            ),
            _buildOption(
              label: 'Meter',
              icon: Icons.speed_outlined,
              isSelected: widget.selected == PrimarySourceMode.meter,
              onTap: () {
                widget.onChanged(PrimarySourceMode.meter);
                _close();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6.r),
          border: isSelected
              ? Border.all(color: Colors.white, width: 1.2)
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 14.sp),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 13.sp,
              ),
          ],
        ),
      ),
    );
  }
}
