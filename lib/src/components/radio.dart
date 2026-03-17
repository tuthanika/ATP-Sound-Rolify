import 'package:flutter/material.dart';
import 'package:rolify/presentation_logic_holders/singletons/app_state.dart';

class MyRadio extends StatelessWidget {
  final bool value, big;
  final Function(bool value)? onChanged;
  final Widget icon;
  final double? customSize;
  final double? customIconSize;

  const MyRadio({
    super.key,
    this.value = false,
    this.onChanged,
    required this.icon,
    this.big = false,
    this.customSize,
    this.customIconSize,
  });

  double get size => customSize ?? (big ? 64.0 : 40.0);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size * heightFactor,
      width: size * heightFactor,
      child: IconButton(
        onPressed: onChanged == null ? null : () => onChanged!(!value),
        style: IconButton.styleFrom(
          backgroundColor: value
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceVariant,
        ),
        icon: icon,
      ),
    );
  }
}
