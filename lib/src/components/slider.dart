import 'package:flutter/material.dart';

typedef MySliderListener = void Function(double percent);
typedef NeumorphicSliderListener = void Function(double percent); // Compatibility

@immutable
class MySliderStyle {
  final BorderRadius borderRadius;
  final double? depth;
  final bool? disableDepth;
  final Color? accent;
  final Color? variant;

  const MySliderStyle({
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.depth,
    this.disableDepth,
    this.accent,
    this.variant,
  });
}

class MySlider extends StatelessWidget {
  final MySliderStyle style;
  final double min;
  final double value;
  final double max;
  final double height;
  final MySliderListener? onChanged;
  final MySliderListener? onChangeStart;
  final MySliderListener? onChangeEnd;
  final Widget? thumb;

  const MySlider({
    Key? key,
    this.style = const MySliderStyle(),
    this.min = 0,
    this.value = 0,
    this.max = 10,
    this.height = 15,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.thumb,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: height / 2,
        activeTrackColor: style.accent,
        inactiveTrackColor: style.variant,
        thumbColor: style.accent,
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
