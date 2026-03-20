import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rolify/data/audios.dart';
import 'package:rolify/entities/audio.dart';
import 'package:rolify/presentation_logic_holders/audio_edit_bloc/audio_edit_bloc.dart';
import 'package:rolify/presentation_logic_holders/audio_edit_bloc/audio_edit_event.dart';
import 'package:rolify/presentation_logic_holders/audio_handler.dart';
import 'package:rolify/presentation_logic_holders/audio_service_commands.dart';
import 'package:rolify/presentation_logic_holders/event_bus/stop_all_event_bus.dart';
import 'package:rolify/presentation_logic_holders/singletons/app_state.dart';
import 'package:rolify/src/components/audio_slider.dart';
import 'package:rolify/src/components/button.dart';
import 'package:rolify/src/components/radio.dart';
import 'package:rolify/src/theme/texts.dart';

import '../../presentation_logic_holders/playing_sounds_singleton.dart';
import 'dropdown_image.dart';
import 'marquee_text.dart';
import 'my_icons.dart';

class PlayerWidget extends StatefulWidget {
  final Audio audio;
  final bool isCollapsedLayout;
  final bool autoShrinkText;

  const PlayerWidget({
    Key? key,
    required this.audio,
    this.isCollapsedLayout = false,
    this.autoShrinkText = false,
  }) : super(key: key);

  @override
  PlayerWidgetState createState() => PlayerWidgetState();
}

class PlayerWidgetState extends State<PlayerWidget> {
  double currentVolume = 0.0;
  late String audioImage;
  bool loopAudio = true, isPlaying = false, showVolumeSlider = false;

  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _initData();
    
    eventBus.on<OnAppResume>().listen((event) {
      checkIfIsPlaying();
    });
    eventBus.on<AudioPlayed>().listen((event) {
      if (event.path == widget.audio.path && mounted) {
        setState(() {
          isPlaying = true;
        });
      }
    });
    eventBus.on<AudioPaused>().listen((event) {
      if (event.path == widget.audio.path && mounted) {
        setState(() {
          isPlaying = false;
        });
      }
    });
    eventBus.on<ToggleLoop>().listen((event) {
      if (event.path == widget.audio.path && mounted) {
        setState(() {
          loopAudio = event.value;
        });
      }
    });
    eventBus.on<VolumeChange>().listen((event) {
      if (event.path == widget.audio.path && mounted) {
        _updateLocalVolume(event.value);
      }
    });

    AppState().audioHandler.customEvent.listen((event) {
      if (!mounted) return;
      if (event['name'] == 'pauseAll' ||
          (event['name'] == 'audioEnded' &&
              event['audioPath'] == widget.audio.path)) {
        setState(() {
          isPlaying = false;
        });
        if (event['name'] == 'audioEnded') {
          // Fix for the original bug: auto-stop when sound naturally finishes
          stop();
        }
      }
    });

    loopAudio = widget.audio.loopMode == LoopMode.one;
    currentVolume = widget.audio.volume;
    audioImage = widget.audio.image;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      checkIfIsPlaying();
    });
  }

  void _updateLocalVolume(double value) {
    double volume;
    if (PlayingSounds().masterVolume == 0) {
      volume = value;
    } else {
      volume = value / PlayingSounds().masterVolume;
    }
    if (volume != 0) {
      setState(() => currentVolume = volume);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _initData() {
    isPlaying = PlayingSounds().playingAudios.any((e) => e.path == widget.audio.path);
  }

  void checkIfIsPlaying() {
    final status = PlayingSounds().playingAudios.any((e) => e.path == widget.audio.path);
    if (status != isPlaying && mounted) {
      setState(() {
        isPlaying = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: PlayingSounds().stateChangeNotifier,
      builder: (context, _, __) {
        checkIfIsPlaying(); // Re-check on every global state change
        
        // Lazy Image Loading: Only even instantiate the provider if not collapsed
        DecorationImage? decorationImage;
        if (!widget.isCollapsedLayout && audioImage.isNotEmpty) {
          final ImageProvider provider = audioImage.startsWith('assets/')
              ? AssetImage(audioImage)
              : FileImage(File(audioImage)) as ImageProvider;
          decorationImage = DecorationImage(
            image: provider,
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.4),
              BlendMode.darken,
            ),
          );
        }

        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: widget.isCollapsedLayout ? 0 : 2,
          color: widget.isCollapsedLayout ? Colors.transparent : null,
          margin: widget.isCollapsedLayout ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.isCollapsedLayout ? 20 : 16)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              image: decorationImage,
              color: (widget.isCollapsedLayout || audioImage.isEmpty)
                  ? Theme.of(context).colorScheme.surfaceContainer
                  : null,
            ),
            child: widget.isCollapsedLayout ? _buildCollapsed() : _buildExpanded(),
          ),
        );
      }
    );
  }

  Widget _buildNameBox() {
    final colorScheme = Theme.of(context).colorScheme;
    final isCollapsed = widget.isCollapsedLayout;
    
    // Theme-aware colors for better visibility and playing state
    final Color idleBg = Theme.of(context).brightness == Brightness.light
        ? colorScheme.surfaceContainerHighest
        : Colors.black.withOpacity(0.4);
    
    final Color playingBg = colorScheme.primary.withOpacity(0.85);
    
    final Color textColor = isPlaying 
        ? colorScheme.onPrimary 
        : (Theme.of(context).brightness == Brightness.light ? colorScheme.onSurface : Colors.white);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: isCollapsed ? EdgeInsets.zero : const EdgeInsets.all(4.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isPlaying ? playingBg : idleBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPlaying ? colorScheme.primaryContainer.withOpacity(0.6) : Colors.white24,
          width: 1.5,
        ),
      ),
      child: MarqueeText(
        text: widget.audio.name,
        autoShrink: widget.autoShrinkText,
        style: TextStyle(
          height: 1.38,
          fontFamily: 'Rubik',
          fontSize: 16 * heightFactor,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildCollapsed() {
    return InkWell(
      onTap: () {
        if (isPlaying) stop(); else play();
      },
      child: _buildNameBox(),
    );
  }

  Widget _buildExpanded() {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: InkWell(
            onTap: () {
              if (isPlaying) stop(); else play();
            },
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.zero,
              child: _buildNameBox(),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: AudioSlider(
              isActive: isPlaying,
              value: currentVolume,
              onChanged: (value) {
                setVolume(context, value);
              },
              // High contrast for light mode
              color: Theme.of(context).brightness == Brightness.light && audioImage.isEmpty
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white.withOpacity(0.9),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText.caption(
                '${(currentVolume * 100).round()}%',
                color: Colors.white70,
              ),
              IconButton(
                onPressed: () => BlocProvider.of<AudioEditBloc>(context)
                    .add(EnableEditing(context, widget.audio)),
                icon: const Icon(Icons.edit, size: 16, color: Colors.white70),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              MyRadio(
                icon: Icon(
                  Icons.loop,
                  size: 16,
                  color: loopAudio ? Theme.of(context).colorScheme.primary : Colors.white70,
                ),
                value: loopAudio,
                onChanged: toggleLoop,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void setVolume(BuildContext context, double value) {
    setState(() {
      currentVolume = value;
    });
    AudioServiceCommands.setVolume(
        widget.audio, value * PlayingSounds().masterVolume);

    final updatedAudio = widget.audio.copyFrom(volume: value);
    PlayingSounds().updateAudio(updatedAudio);
    AudioData.updateAudio(context, updatedAudio, refresh: false);
  }

  toggleLoop(value) {
    setState(() {
      loopAudio = value;
    });
    AudioServiceCommands.setLoop(value, widget.audio);
    AudioData.updateAudio(context,
        widget.audio.copyFrom(loopMode: value ? LoopMode.one : LoopMode.off),
        refresh: false);
  }

  Future<void> checkVolume() async {
    double volume = await AudioServiceCommands.getVolume(widget.audio);
    setState(() {
      currentVolume = volume;
    });
  }

  Future<void> checkLoop() async {
    bool isLoop = await AudioServiceCommands.getLoop(widget.audio);
    loopAudio = isLoop;
    if (mounted) {
      setState(() {});
    }
  }

  void stop() {
    AudioServiceCommands.stop(widget.audio);
  }

  Future<void> play() async {
    PlayingSounds().isPlayingPlaylist.value = false;
    AudioServiceCommands.play(widget.audio);
  }
}
