import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/cng_reading_item.dart';

/// The "Select Nozzle ▲" pill trigger that opens a small popover letting
/// the user pick between Nozzle and Meter mode for the primary reading
/// card on the Dashboard.
class SourceSelectorDropdown extends StatefulWidget {
  final PrimarySourceMode selected;
  final ValueChanged<PrimarySourceMode> onChanged;

  const SourceSelectorDropdown({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<SourceSelectorDropdown> createState() =>
      _SourceSelectorDropdownState();
}

class _SourceSelectorDropdownState extends State<SourceSelectorDropdown> {
  final GlobalKey _anchorKey = GlobalKey();

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
            color: isSelected
                ? AppColors.primaryTeal
                : AppColors.borderLight,
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
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppConstants.selectSourceLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_drop_up, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
