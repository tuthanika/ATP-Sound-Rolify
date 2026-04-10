import 'dart:async';
import 'dart:io';

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
import 'package:rolify/presentation_logic_holders/audio_download_manager.dart';
import 'package:rolify/src/components/audio_slider.dart';
import 'package:rolify/src/components/radio.dart';
import 'package:rolify/src/theme/texts.dart';

import '../../presentation_logic_holders/playing_sounds_singleton.dart';
import 'marquee_text.dart';

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
  bool loopAudio = true, showVolumeSlider = false;
  bool isDownloading = false; // <-- THÊM BIẾN NÀY

  final List<StreamSubscription> _subscriptions = [];
  Timer? _volumeDebounce;

  bool get isPlaying => PlayingSounds().playingPathsSet.contains(widget.audio.path);

  @override
  void initState() {
    super.initState();
    
    _subscriptions.add(eventBus.on<OnAppResume>().listen((event) {
      if (mounted) setState(() {});
    }));
    _subscriptions.add(eventBus.on<AudioPlayed>().listen((event) {
      if (event.path == widget.audio.path && mounted) {
        setState(() {});
      }
    }));
    _subscriptions.add(eventBus.on<AudioPaused>().listen((event) {
      if (event.path == widget.audio.path && mounted) {
        setState(() {});
      }
    }));
    _subscriptions.add(eventBus.on<ToggleLoop>().listen((event) {
      if (event.path == widget.audio.path && mounted) {
        setState(() {
          loopAudio = event.value;
        });
      }
    }));
    _subscriptions.add(eventBus.on<VolumeChange>().listen((event) {
      if (event.path == widget.audio.path && mounted) {
        _updateLocalVolume(event.value);
      }
    }));

    _subscriptions.add(AppState().audioHandler.customEvent.listen((event) {
      if (!mounted) return;
      if (event['name'] == 'pauseAll' ||
          (event['name'] == 'audioEnded' &&
              event['audioPath'] == widget.audio.path)) {
        setState(() {});
        if (event['name'] == 'audioEnded') {
          // Fix for the original bug: auto-stop when sound naturally finishes
          stop();
        }
      }
    }));

    loopAudio = widget.audio.loopMode == LoopMode.one;
    currentVolume = widget.audio.volume;
    audioImage = widget.audio.image;
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
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _volumeDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: PlayingSounds().stateChangeNotifier,
      builder: (context, _, __) {
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
              Colors.black.withValues(alpha: 0.4),
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
        : Colors.black.withValues(alpha: 0.4);
    
    final Color playingBg = colorScheme.primary.withValues(alpha: 0.85);
    
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
          color: isPlaying ? colorScheme.primaryContainer.withValues(alpha: 0.6) : Colors.white24,
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
        if (isPlaying) {
          stop();
        } else {
          play();
        }
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
              if (isPlaying) {
                stop();
              } else {
                play(); // Đã gom tất cả logic tải vào hàm play()
              }
            },
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.zero,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildNameBox(), // UI Gốc
                  // Hiệu ứng Loading khi đang tải
                  if (isDownloading)
                    Container(
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.all(4),
                      child: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    )
                ],
              ),
            ),
          ),
        ),
        // Khối thanh trượt âm lượng (Giữ nguyên của bạn)
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
              color: Theme.of(context).brightness == Brightness.light && audioImage.isEmpty
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
        // Khối các nút bấm (Đã fix bug Edit)
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MyText.caption(
                '${(currentVolume * 100).round()}%',
                color: Colors.white70,
              ),
              
              // === ĐOẠN ĐƯỢC CẬP NHẬT FIX BUG ===
              IconButton(
                onPressed: () {
                  BlocProvider.of<AudioEditBloc>(context)
                      .add(EnableEditing(context, widget.audio));
                  
                  final isFirstRoute = ModalRoute.of(context)?.isFirst ?? true;
                  if (!isFirstRoute) {
                    Navigator.pop(context); // Tự đóng UI Folder để hiện UI Edit ở main app
                  }
                },
                icon: Icon(
                  Icons.edit,
                  size: 16,
                  color: Theme.of(context).brightness == Brightness.light && audioImage.isEmpty
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white70,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              // ===================================

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

    if (_volumeDebounce?.isActive ?? false) _volumeDebounce!.cancel();
    _volumeDebounce = Timer(const Duration(milliseconds: 400), () {
      final updatedAudio = widget.audio.copyFrom(volume: value);
      PlayingSounds().updateAudio(updatedAudio);
      AudioData.updateAudio(context, updatedAudio, refresh: false);
    });
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
    if (widget.audio.path.startsWith('http')) {
      setState(() => isDownloading = true); 
      // Chờ tải file xong mới ra lệnh phát
      await AudioFileManager.processPath(
          widget.audio.path, 
          widget.audio.name, 
          widget.audio.isOfflineMode
      );
      if (mounted) setState(() => isDownloading = false);
    }
    
    PlayingSounds().isPlayingPlaylist.value = false;
    AudioServiceCommands.play(widget.audio);
  }
}

// Thêm class model phụ để truyền dữ liệu
class AudioFolder {
  final String name;
  final List<Audio> audios;
  AudioFolder(this.name, this.audios);
}

// Giao diện Thẻ Folder
class FolderWidget extends StatelessWidget {
  final AudioFolder folder;
  final bool isCollapsedLayout;
  final VoidCallback onTapList;
  final VoidCallback onEdit; // <-- Thêm callback onEdit

  const FolderWidget({
    Key? key,
    required this.folder,
    this.isCollapsedLayout = false,
    required this.onTapList,
    required this.onEdit, // <-- Khởi tạo
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    
    final Color idleBg = isLight
        ? colorScheme.surfaceContainerHighest
        : Colors.black.withValues(alpha: 0.4);
    
    final textColor = isLight ? colorScheme.onSurface : Colors.white;

    Widget nameBox = Container(
      margin: isCollapsedLayout ? EdgeInsets.zero : const EdgeInsets.all(4.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: idleBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, color: textColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: MarqueeText(
              text: folder.name,
              autoShrink: false,
              style: TextStyle(
                height: 1.38,
                fontFamily: 'Rubik',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );

    if (isCollapsedLayout) {
      return InkWell(
        onTap: onTapList,
        onLongPress: onEdit, // <-- Bổ sung: Nhấn giữ tên nhóm để sửa ở chế độ thu gọn
        child: nameBox,
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: onTapList,
                onLongPress: onEdit, // <-- Nhấn giữ để sửa
                child: Container(
                  alignment: Alignment.center,
                  child: nameBox,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  '${folder.audios.length} sounds', 
                  style: TextStyle(color: textColor.withValues(alpha: 0.7), fontWeight: FontWeight.bold)
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // <-- Dàn đều 2 nút edit và list
                children: [
                  IconButton(
                    onPressed: onEdit, // <-- Nút sửa tên
                    icon: Icon(Icons.edit, size: 20, color: textColor.withValues(alpha: 0.8)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    onPressed: onTapList,
                    icon: Icon(Icons.list, size: 20, color: textColor.withValues(alpha: 0.8)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}