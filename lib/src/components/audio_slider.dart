import 'package:flutter/material.dart';
import 'package:rolify/src/components/slider.dart';

class AudioSlider extends StatelessWidget {
  final bool isActive;
  final double value;
  final void Function(double value)? onChanged;
  final Color? color;

  const AudioSlider(
      {Key? key,
      this.isActive = false,
      this.value = 0,
      this.onChanged,
      this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor =
        color ?? (isActive ? theme.colorScheme.primary : theme.disabledColor);
    return MySlider(
      style: MySliderStyle(
        accent: accentColor,
        variant: accentColor.withOpacity(0.3),
      ),
      min: 0.0,
      max: 1.0,
      height: 12,
      value: value,
      onChanged: onChanged,
    );
  }
}
