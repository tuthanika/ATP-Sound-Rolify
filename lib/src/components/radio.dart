import 'package:flutter/material.dart';
import 'package:rolify/presentation_logic_holders/singletons/app_state.dart';

class MyRadio extends StatelessWidget {
  final bool value, big;
  final Function(bool value)? onChanged;
  final Widget icon;

  const MyRadio({
    Key? key,
    this.value = false,
    this.onChanged,
    required this.icon,
    this.big = false,
  }) : super(key: key);

  double get size => big ? 64.0 : 40.0;

  double get iconSize => big ? 40.0 : 24.0;

  EdgeInsets get padding => EdgeInsets.all((size - iconSize) / 2);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size * heightFactor,
      width: size * heightFactor,
      child: IconButton(
        icon: icon,
        padding: padding,
        isSelected: value,
        onPressed: () {
          if (onChanged != null) onChanged!(!value);
        },
        style: IconButton.styleFrom(
          backgroundColor: value ? Theme.of(context).colorScheme.primaryContainer : null,
        ),
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
    return Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;
  }
}
