import 'package:flutter/material.dart';
import 'package:rolify/presentation_logic_holders/singletons/app_state.dart';

class MyButton extends StatelessWidget {
  final bool big;
  final VoidCallback? onTap;
  final Widget? icon;

  const MyButton({super.key, this.onTap, this.icon, this.big = false});

  double get size => big ? 64.0 : 40.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size * heightFactor,
      width: size * heightFactor,
      child: IconButton(
        onPressed: onTap,
        icon: icon ?? const SizedBox.shrink(),
      ),
    );
  }
}
