import 'package:flutter/material.dart';
import 'package:rolify/src/components/slider.dart';

class AudioSlider extends StatelessWidget {
  final bool isActive;
  final double value;
  final void Function(double value)? onChanged;

  const AudioSlider({
    super.key,
    this.isActive = false,
    this.value = 0,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => MySlider(
        style: MySliderStyle(
          accent: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          variant: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
        min: 0.0,
        max: 1.0,
        value: value,
        onChanged: onChanged,
      );
}
