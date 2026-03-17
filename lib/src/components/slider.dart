import 'package:flutter/material.dart';

typedef NeumorphicSliderListener = void Function(double percent);

@immutable
class MySliderStyle {
  final Color? accent;
  final Color? variant;

  const MySliderStyle({this.accent, this.variant});
}

class MySlider extends StatelessWidget {
  final MySliderStyle style;
  final double min;
  final double value;
  final double max;
  final NeumorphicSliderListener? onChanged;
  final NeumorphicSliderListener? onChangeStart;
  final NeumorphicSliderListener? onChangeEnd;

  const MySlider({
    super.key,
    this.style = const MySliderStyle(),
    this.min = 0,
    this.value = 0,
    this.max = 10,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: style.variant ?? Theme.of(context).colorScheme.primary,
        inactiveTrackColor:
            style.accent ?? Theme.of(context).colorScheme.surfaceContainerHighest,
        thumbColor: Theme.of(context).colorScheme.primary,
      ),
      child: Slider(
        min: min,
        max: max,
        value: value.clamp(min, max),
        onChanged: onChanged,
        onChangeStart: onChangeStart,
        onChangeEnd: onChangeEnd,
      ),
    );
  }
}
