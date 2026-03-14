import 'package:flutter/material.dart';

class MySlider extends StatelessWidget {
  final double min;
  final double value;
  final double max;
  final void Function(double)? onChanged;
  final Color? activeColor;
  final Color? inactiveColor;

  const MySlider({
    Key? key,
    this.min = 0,
    this.value = 0,
    this.max = 1.0,
    this.onChanged,
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 12.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        onChanged: onChanged,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
      ),
    );
  }
}
