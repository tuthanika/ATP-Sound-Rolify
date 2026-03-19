import 'package:flutter/material.dart';
import 'package:rolify/presentation_logic_holders/singletons/app_state.dart';

class MyRadio extends StatelessWidget {
  final bool value, big;
  final Function(bool value)? onChanged;
  final Widget icon;
  final double? customSize;
  final double? customIconSize;

  const MyRadio({
    Key? key,
    this.value = false,
    this.onChanged,
    required this.icon,
    this.big = false,
    this.customSize,
    this.customIconSize,
  }) : super(key: key);

  double get size => customSize ?? (big ? 64.0 : 40.0);
  double get iconSize => customIconSize ?? (big ? 40.0 : 24.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: size * heightFactor,
      width: size * heightFactor,
      child: IconButton(
        iconSize: iconSize,
        isSelected: value,
        style: IconButton.styleFrom(
            backgroundColor: value ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
            foregroundColor: value ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
        ),
        onPressed: onChanged == null ? null : () => onChanged!(!value),
        icon: icon,
        selectedIcon: icon,
      ),
    );
  }

  Color getIconColor(BuildContext context) {
    if (onChanged == null) {
      return Theme.of(context).disabledColor;
    }
    if (value) {
      return Theme.of(context).colorScheme.primary;
    }
    return Theme.of(context).colorScheme.onSurface;
  }
}
