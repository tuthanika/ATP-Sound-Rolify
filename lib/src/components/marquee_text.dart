import 'package:flutter/material.dart';
import 'package:rolify/presentation_logic_holders/singletons/theme_mode_controller.dart';
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
  bool _isVisible = true; // Track visibility state

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to TickerMode changes (triggered when IndexedStack hides/shows tab)
    _isVisible = TickerMode.of(context);
    
    // Instantly kill any running animation if the widget goes offstage
    if (!_isVisible && _scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.offset);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _startScrolling() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    while (mounted) {
      if (!mounted) break;

      // Sleep if hidden OR marquee is disabled in settings
      if (!_isVisible || !ThemeModeController().enableMarqueeText.value) {
        await Future.delayed(const Duration(seconds: 2));
        continue;
      }

      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          // Scroll forward
          await _scrollController.animateTo(
            maxScroll,
            duration: Duration(milliseconds: maxScroll.toInt() * 40),
            curve: Curves.linear,
          );
          
          // Check if visibility or settings changed mid-animation before waiting or scrolling back
          if (!mounted || !_isVisible || !ThemeModeController().enableMarqueeText.value) continue;
          
          await Future.delayed(const Duration(seconds: 1));
          
          if (!mounted || !_isVisible || !ThemeModeController().enableMarqueeText.value) continue;

          // Scroll back
          await _scrollController.animateTo(
            0,
            duration: const Duration(seconds: 1),
            curve: Curves.easeOut,
          );
        } else {
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeModeController().enableMarqueeText,
      builder: (context, isMarqueeEnabled, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Enforce a finite width for the scaling logic to work correctly.
            // If constraints are infinite, we use a number derived from the context size.
            final double availableWidth = constraints.maxWidth.isFinite 
                ? constraints.maxWidth 
                : MediaQuery.of(context).size.width;

            final bool shouldShrink = widget.autoShrink || !isMarqueeEnabled;

            return SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Container(
                width: shouldShrink ? availableWidth : null,
                constraints: shouldShrink ? null : BoxConstraints(minWidth: availableWidth),
                alignment: Alignment.center,
                child: shouldShrink
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
      },
    );
  }
}
