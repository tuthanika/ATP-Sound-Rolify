import 'package:flutter/material.dart';

class NeumorphicThemeData {
  final Color baseColor;
  final Color disabledColor;
  final Color accentColor;
  final Color variantColor;
  final double intensity;
  final double depth;
  final LightSource lightSource;

  const NeumorphicThemeData({
    required this.baseColor,
    this.disabledColor = const Color(0xFF7B7B7B),
    required this.accentColor,
    required this.variantColor,
    this.intensity = 1,
    this.depth = 0,
    this.lightSource = LightSource.topLeft,
  });
}

enum LightSource { topLeft }
enum NeumorphicShape { concave }

class NeumorphicTheme extends StatelessWidget {
  final ThemeMode themeMode;
  final NeumorphicThemeData darkTheme;
  final NeumorphicThemeData theme;
  final Widget child;

  const NeumorphicTheme({
    super.key,
    required this.themeMode,
    required this.darkTheme,
    required this.theme,
    required this.child,
  });

  static _NeumorphicThemeScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_NeumorphicThemeScope>();

  static NeumorphicThemeData currentTheme(BuildContext context) =>
      of(context)?.data ?? _fromColorScheme(Theme.of(context).colorScheme);

  static bool isUsingDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static Color baseColor(BuildContext context) => currentTheme(context).baseColor;

  static NeumorphicThemeData _fromColorScheme(ColorScheme cs) => NeumorphicThemeData(
        baseColor: cs.surface,
        disabledColor: cs.onSurfaceVariant,
        accentColor: cs.primary,
        variantColor: cs.secondary,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
    final data = isDark ? darkTheme : theme;
    return _NeumorphicThemeScope(data: data, isUsingDark: isDark, child: child);
  }
}

class _NeumorphicThemeScope extends InheritedWidget {
  final NeumorphicThemeData data;
  final bool isUsingDark;

  const _NeumorphicThemeScope({required this.data, required this.isUsingDark, required super.child});

  @override
  bool updateShouldNotify(covariant _NeumorphicThemeScope oldWidget) =>
      data != oldWidget.data || isUsingDark != oldWidget.isUsingDark;
}

class NeumorphicBoxShape {
  final BorderRadius? borderRadius;
  final bool isCircle;
  const NeumorphicBoxShape.circle() : borderRadius = null, isCircle = true;
  const NeumorphicBoxShape.roundRect(this.borderRadius) : isCircle = false;
}

class NeumorphicStyle {
  final NeumorphicBoxShape? boxShape;
  final Color? color;
  final bool? disableDepth;
  final double? depth;
  final NeumorphicShape? shape;
  final Color? shadowLightColor;

  const NeumorphicStyle({
    this.boxShape,
    this.color,
    this.disableDepth,
    this.depth,
    this.shape,
    this.shadowLightColor,
  });
}

class Neumorphic extends StatelessWidget {
  final NeumorphicStyle style;
  final EdgeInsetsGeometry? padding;
  final Duration? duration;
  final Curve? curve;
  final Widget child;

  const Neumorphic({super.key, this.style = const NeumorphicStyle(), this.padding, this.duration, this.curve, required this.child});

  @override
  Widget build(BuildContext context) {
    final isCircle = style.boxShape?.isCircle == true;
    final radius = isCircle
        ? null
        : (style.boxShape?.borderRadius ?? BorderRadius.circular(16));
    final decoration = BoxDecoration(
      color: style.color ?? Colors.transparent,
      shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: isCircle ? null : radius,
    );

    final content = padding == null ? child : Padding(padding: padding!, child: child);
    final clippedContent = isCircle
        ? ClipOval(child: content)
        : ClipRRect(borderRadius: radius ?? BorderRadius.zero, child: content);

    if (duration != null) {
      return AnimatedContainer(
        duration: duration!,
        curve: curve ?? Curves.linear,
        decoration: decoration,
        child: clippedContent,
      );
    }

    return DecoratedBox(decoration: decoration, child: clippedContent);
  }
}

class NeumorphicButton extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onPressed;
  final NeumorphicStyle style;
  final Widget child;

  const NeumorphicButton({super.key, this.padding, this.onPressed, this.style = const NeumorphicStyle(), required this.child});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: padding,
      style: IconButton.styleFrom(
        shape: style.boxShape?.isCircle == true ? const CircleBorder() : RoundedRectangleBorder(borderRadius: style.boxShape?.borderRadius ?? BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      icon: child,
    );
  }
}

class NeumorphicRadioStyle {
  final NeumorphicBoxShape? boxShape;
  final double? intensity;
  const NeumorphicRadioStyle({this.boxShape, this.intensity});
}

class NeumorphicRadio<T> extends StatelessWidget {
  final NeumorphicRadioStyle style;
  final EdgeInsetsGeometry? padding;
  final T value;
  final T groupValue;
  final ValueChanged<T?>? onChanged;
  final Widget child;

  const NeumorphicRadio({super.key, this.style = const NeumorphicRadioStyle(), this.padding, required this.value, required this.groupValue, this.onChanged, required this.child});

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return IconButton(
      padding: padding,
      onPressed: onChanged == null ? null : () => onChanged!(value),
      style: IconButton.styleFrom(
        backgroundColor: selected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceVariant,
        shape: style.boxShape?.isCircle == true ? const CircleBorder() : RoundedRectangleBorder(borderRadius: style.boxShape?.borderRadius ?? BorderRadius.circular(12)),
      ),
      icon: child,
    );
  }
}

class ProgressStyle {
  final bool disableDepth;
  final double depth;
  final BorderRadius borderRadius;
  final Color accent;
  final Color variant;

  const ProgressStyle({this.disableDepth = false, this.depth = 0, this.borderRadius = const BorderRadius.all(Radius.circular(10)), required this.accent, required this.variant});
}

class NeumorphicProgress extends StatelessWidget {
  final Duration duration;
  final double percent;
  final double height;
  final ProgressStyle style;

  const NeumorphicProgress({super.key, required this.duration, required this.percent, required this.height, required this.style});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: style.borderRadius,
      child: LinearProgressIndicator(
        minHeight: height,
        value: percent,
        backgroundColor: style.accent.withOpacity(0.3),
        valueColor: AlwaysStoppedAnimation(style.variant),
      ),
    );
  }
}
