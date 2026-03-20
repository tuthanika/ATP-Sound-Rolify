import 'package:flutter/material.dart';

import '../../presentation_logic_holders/audio_service_commands.dart';
import '../../presentation_logic_holders/playing_sounds_singleton.dart';
import '../../presentation_logic_holders/singletons/app_state.dart';
import '../../src/components/audio_slider.dart';
import '../../src/components/button.dart';
import '../../src/components/my_icons.dart';
import '../../src/components/radio.dart';

import '../../src/theme/texts.dart';

class GlobalControls extends StatefulWidget {
  final bool isExpanded;
  final ValueChanged<bool> onExpandChanged;
  final bool pauseAll;
  final bool playPauseEnabled;
  final Function(bool value) setPauseAll;

  const GlobalControls({
    Key? key,
    required this.isExpanded,
    required this.onExpandChanged,
    required this.pauseAll,
    required this.playPauseEnabled,
    required this.setPauseAll,
  }) : super(key: key);

  @override
  State<GlobalControls> createState() => _GlobalControlsState();
}

class _GlobalControlsState extends State<GlobalControls> {

  IconData getVolumeIcon(double volume) {
    if (volume == 0) return Icons.volume_off;
    if (volume <= 0.25) return Icons.volume_mute;
    if (volume <= 0.5) return Icons.volume_down;
    return Icons.volume_up;
  }

  void cycleVolume() {
    double current = PlayingSounds().masterVolume;
    double next;
    if (current == 0) next = 0.25;
    else if (current <= 0.25) next = 0.5;
    else if (current <= 0.5) next = 1.0;
    else next = 0;
    
    setMasterVolume(next);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        if (details.delta.dy < -10 && !widget.isExpanded) {
          widget.onExpandChanged(true);
        } else if (details.delta.dy > 10 && widget.isExpanded) {
          widget.onExpandChanged(false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
            vertical: 12.0 * heightFactor, horizontal: 16.0),
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (!widget.isExpanded) _buildCollapsedUI() else _buildExpandedUI(),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedUI() {
    return Center(
      child: Container(
        width: 200 * heightFactor,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: cycleVolume,
              icon: Icon(getVolumeIcon(PlayingSounds().masterVolume)),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => widget.onExpandChanged(true),
              icon: const Icon(Icons.keyboard_arrow_up),
            ),
            MyRadio(
              big: false,
              icon: widget.pauseAll ? MyIcons.pause() : MyIcons.play(),
              value: widget.pauseAll,
              onChanged: (value) {
                if (!widget.playPauseEnabled) return;
                if (value) playAllSound(); else pauseAllSound();
                widget.setPauseAll(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedUI() {
    return Container(
      width: 280 * heightFactor,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => widget.onExpandChanged(false),
                icon: const Icon(Icons.keyboard_arrow_down),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(getVolumeIcon(PlayingSounds().masterVolume), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AudioSlider(
                                isActive: true,
                                value: PlayingSounds().masterVolume,
                                onChanged: setMasterVolume,
                              ),
                              MyText.caption(
                                '${(PlayingSounds().masterVolume * 100).round()}%',
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withOpacity(0.8),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 60), // allocate space to prevent slider overlap with buttons
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MyRadio(
                  customSize: 40,
                  customIconSize: 24,
                  icon: widget.pauseAll ? MyIcons.pause() : MyIcons.play(),
                  value: widget.pauseAll,
                  onChanged: (value) {
                    if (!widget.playPauseEnabled) return;
                    if (value)
                      playAllSound();
                    else
                      pauseAllSound();
                    widget.setPauseAll(value);
                  },
                ),
                const SizedBox(height: 8),
                MyRadio(
                  customSize: 40,
                  customIconSize: 24,
                  icon: MyIcons.stop(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  value: false,
                  onChanged: (_) {
                    stopAllSound();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void playAllSound() async {
    await AppState().audioHandler.play();
  }

  void pauseAllSound() async {
    await AppState().audioHandler.pause();
  }

  void stopAllSound() async {
    await AppState().audioHandler.stop();
  }

  void setMasterVolume(double value) async {
    setState(() {
      PlayingSounds().masterVolume = value;
    });

    final playingAudios = PlayingSounds().playingAudios;
    for (final audio in playingAudios) {
      AudioServiceCommands.setVolume(
          audio, audio.volume * PlayingSounds().masterVolume,
          global: true);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}
