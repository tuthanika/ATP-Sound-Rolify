import 'package:flutter/material.dart';
import 'package:rolify/src/components/slider.dart';

class AudioSlider extends StatelessWidget {
  final bool isActive;
  final double value;
  final void Function(double value)? onChanged;

  const AudioSlider(
      {Key? key, this.isActive = false, this.value = 0, this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MySlider(
      activeColor: isActive ? theme.colorScheme.primary : theme.disabledColor,
      inactiveColor: isActive ? theme.colorScheme.primary.withOpacity(0.5) : theme.disabledColor.withOpacity(0.5),
      value: value,
      onChanged: onChanged,
    );
  }
}
