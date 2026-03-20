import 'package:flutter/material.dart';
import 'package:rolify/src/theme/texts.dart';

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool autoShrink;

  const MarqueeText({
    Key? key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.center,
    this.autoShrink = false,
  }) : super(key: key);

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _startScrolling() async {
    // Delay further to avoid UI lag during initial build
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    while (mounted) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          await _scrollController.animateTo(
            maxScroll,
            duration: Duration(milliseconds: maxScroll.toInt() * 40),
            curve: Curves.linear,
          );
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted) break;
          await _scrollController.animateTo(
            0,
            duration: const Duration(seconds: 1),
            curve: Curves.easeOut,
          );
        } else {
          // If no overflow, wait a bit before checking again (in case of dynamic changes)
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Enforce a finite width for the scaling logic to work correctly.
        // If constraints are infinite, we use a very large but finite number.
        final double availableWidth = constraints.maxWidth.isFinite 
            ? constraints.maxWidth 
            : MediaQuery.of(context).size.width;

        return SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Container(
            width: widget.autoShrink ? availableWidth : null,
            constraints: widget.autoShrink ? null : BoxConstraints(minWidth: availableWidth),
            alignment: Alignment.center,
            child: widget.autoShrink
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        widget.text,
                        style: widget.style,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      widget.text,
                      style: widget.style,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
