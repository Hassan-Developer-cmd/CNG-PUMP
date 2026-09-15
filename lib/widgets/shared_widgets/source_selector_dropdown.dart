import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/cng_reading_item.dart';

// The mode pill trigger that opens a small popover letting the user pick
// between Nozzle and Meter mode. The pill's own label always reflects
// whichever mode is currently active — "Meter" when Meter mode is
// selected, "Nozzle" when Nozzle mode is selected — rather than a static
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
  final GlobalKey _anchorKey = GlobalKey();

  String get _currentLabel {
    return widget.selected == PrimarySourceMode.meter
        ? AppConstants.meterLabel
        : AppConstants.nozzleLabel;
  }

  Future<void> _openMenu(BuildContext context, GlobalKey anchorKey) async {
    final RenderBox button =
        anchorKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset topLeft = button.localToGlobal(
      Offset(0, button.size.height + 6),
      ancestor: overlay,
    );
    final Offset bottomRight = button.localToGlobal(
      button.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );

    final RelativeRect position = RelativeRect.fromLTRB(
      topLeft.dx,
      topLeft.dy,
      overlay.size.width - bottomRight.dx,
      0,
    );

    final PrimarySourceMode? picked = await showMenu<PrimarySourceMode>(
      context: context,
      position: position,
      color: AppColors.lightTeal,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.primaryTeal, width: 1),
      ),
      constraints: const BoxConstraints(minWidth: 150),
      items: [
        _buildMenuItem(PrimarySourceMode.nozzle, AppConstants.nozzleLabel),
        _buildMenuItem(PrimarySourceMode.meter, AppConstants.meterLabel),
      ],
    );

    if (picked != null) {
      widget.onChanged(picked);
    }
  }

  PopupMenuItem<PrimarySourceMode> _buildMenuItem(
    PrimarySourceMode mode,
    String label,
  ) {
    final bool isSelected = mode == widget.selected;
    return PopupMenuItem<PrimarySourceMode>(
      value: mode,
      padding: EdgeInsets.zero,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      key: _anchorKey,
      color: AppColors.primaryTeal,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openMenu(context, _anchorKey),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _currentLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_up, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
