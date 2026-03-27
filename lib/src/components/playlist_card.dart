import 'package:flutter/material.dart';
import 'package:rolify/data/audios.dart'; 
import 'package:rolify/entities/audio.dart';
import 'package:rolify/entities/playlist.dart';
import 'package:rolify/presentation_logic_holders/audio_handler.dart'; 
import 'package:rolify/presentation_logic_holders/audio_service_commands.dart';
import 'package:rolify/presentation_logic_holders/playing_sounds_singleton.dart';
import 'package:rolify/presentation_logic_holders/singletons/app_state.dart';
import 'package:rolify/root/edit_playlist.dart';
import 'package:rolify/root/all_playlist.dart'; 
import 'package:rolify/src/components/button.dart';
import 'package:rolify/src/components/player_card.dart';

import 'my_icons.dart';

class PlaylistCard extends StatefulWidget {
  final Playlist playlist;

  const PlaylistCard({Key? key, required this.playlist}) : super(key: key);

  @override
  PlaylistCardState createState() => PlaylistCardState();
}

class PlaylistCardState extends State<PlaylistCard> {
  int _localSessionId = 0;
  
  // BẢN VÁ: Luôn luôn mặc định khởi tạo là Thu Gọn (false)
  // Xóa bỏ hoàn toàn SharedPreferences gây xung đột logic!
  bool isExpanded = false; 
  
  bool _isActive = false;
  IconData _lastIcon = Icons.play_arrow; 

  IconData get _currentActionIcon {
    if (!_isActive) return Icons.play_arrow;

    bool isEnginePlaying = false;
    try {
      final myHandler = AppState().audioHandler as MyAudioHandler;
      for (var audio in widget.playlist.audios) {
        final player = myHandler.audioPlayers[audio.path];
        if (player != null && player.playing) {
          isEnginePlaying = true;
          break;
        }
      }
    } catch (_) {}

    if (!isEnginePlaying) return Icons.pause;
    return Icons.stop;
  }

  @override
  void initState() {
    super.initState();
    PlaylistGlobals.expandNotifier.addListener(_onGlobalExpandChanged);

    AppState().audioHandler.playbackState.listen((event) {
      if (mounted && _isActive) {
        bool hasPlayingAudio = false;
        for (var audio in widget.playlist.audios) {
          if (PlayingSounds().playingAudios.any((p) => p.path == audio.path)) {
            hasPlayingAudio = true;
            break;
          }
        }
        
        if (!hasPlayingAudio) {
          setState(() { _isActive = false; });
        } else {
          IconData newIcon = _currentActionIcon;
          if (newIcon != _lastIcon) {
            setState(() { _lastIcon = newIcon; });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    PlaylistGlobals.expandNotifier.removeListener(_onGlobalExpandChanged);
    super.dispose();
  }

  void _onGlobalExpandChanged() {
    if (mounted && isExpanded != PlaylistGlobals.expandNotifier.value) {
      setState(() => isExpanded = PlaylistGlobals.expandNotifier.value);
    }
  }

  // BẢN VÁ: Đổi trạng thái siêu tốc, không cần lưu vào CSDL
  void _toggleExpanded(bool val) {
    setState(() => isExpanded = val);
  }

  void onEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPlaylist(playlist: widget.playlist),
      ),
    );
  }

  void onTapList() async {
    List<Audio> freshDbAudios = await AudioData.getAllAudios();
    List<Audio> updatedAudios = widget.playlist.audios.map((oldAudio) {
      try {
        return freshDbAudios.firstWhere((a) => a.path == oldAudio.path);
      } catch (_) {
        return oldAudio;
      }
    }).toList();

    if (!mounted) return;

    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = isDarkMode ? const Color(0xff222222) : Colors.white;
    Color textColor = isDarkMode ? Colors.white : Colors.black87;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: textColor.withOpacity(0.2), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: MyIcons.back(),
                      onPressed: () => Navigator.pop(context),
                      color: textColor,
                    ),
                    Expanded(
                      child: Text(
                        widget.playlist.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Opacity(opacity: 0, child: IconButton(icon: MyIcons.back(), onPressed: () {})),
                  ],
                ),
              ),
              
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: updatedAudios.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text("Playlist trống", style: TextStyle(color: textColor.withOpacity(0.5))),
                      )
                    : GridView.builder(
                        shrinkWrap: true, 
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, 
                          crossAxisSpacing: 4, 
                          mainAxisSpacing: 4, 
                          mainAxisExtent: 125, 
                        ),
                        itemCount: updatedAudios.length,
                        itemBuilder: (context, index) {
                          return PlayerWidget(audio: updatedAudios[index]);
                        },
                      ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: MyButton(
                  icon: MyIcons.add(),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit();
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void togglePlay() {
    if (_isActive) {
      stopAllSoundInPlaylist();
      setState(() { 
        _isActive = false; 
        _lastIcon = Icons.play_arrow;
      });
    } else {
      playAllSoundInPlaylist();
      setState(() { 
        _isActive = true; 
        _lastIcon = Icons.stop;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _lastIcon = _currentActionIcon; 
    if (!isExpanded) return _buildCollapsed();
    return _buildExpanded();
  }

  Widget _buildCollapsed() {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color defaultBg = isDarkMode ? const Color(0xff222222) : Colors.white;
    Color baseColor = widget.playlist.color ?? defaultBg;
    
    Color bgColor = _isActive 
        ? (widget.playlist.color ?? Theme.of(context).colorScheme.primary).withOpacity(isDarkMode ? 0.6 : 0.2)
        : baseColor.withOpacity(isDarkMode ? 0.85 : 1.0);

    Color textColor = bgColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    return InkWell(
      onTap: togglePlay, 
      onLongPress: onEdit,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(_lastIcon, color: textColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.playlist.name,
                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${widget.playlist.audios.length} sounds',
                    style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.expand_more, color: textColor),
              onPressed: () => _toggleExpanded(true), 
            )
          ],
        ),
      ),
    );
  }

  Widget _buildExpanded() {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color defaultBg = isDarkMode ? const Color(0xff222222) : Colors.grey.shade100;
    Color baseColor = widget.playlist.color ?? defaultBg;
    
    Color bgColor = _isActive 
        ? (widget.playlist.color ?? Theme.of(context).colorScheme.primary).withOpacity(isDarkMode ? 0.6 : 0.2)
        : baseColor;

    Color textColor = bgColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    Widget nameBox = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          widget.playlist.name,
          style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 180, 
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: bgColor),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: textColor.withOpacity(0.3), width: 1.5),
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(Icons.expand_less, color: textColor),
                        onPressed: () => _toggleExpanded(false), 
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: onTapList, 
                        onLongPress: onEdit,
                        child: Container(
                          alignment: Alignment.center,
                          child: nameBox,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${widget.playlist.audios.length} sounds',
                        style: TextStyle(color: textColor.withOpacity(0.7), fontWeight: FontWeight.bold)
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: togglePlay, 
                            icon: Icon(_lastIcon, size: 28, color: textColor),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            onPressed: onEdit,
                            icon: Icon(Icons.edit, size: 22, color: textColor.withOpacity(0.8)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            onPressed: onTapList,
                            icon: Icon(Icons.list, size: 22, color: textColor.withOpacity(0.8)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void playAllSoundInPlaylist() async {
    PlayingSounds().isPlayingPlaylist.value = true;
    _localSessionId++;
    final currentSession = _localSessionId;
    final startGlobalStopGen = AudioServiceCommands.globalStopGeneration;

    for (final audio in widget.playlist.audios) {
      if (_localSessionId != currentSession) break;
      if (AudioServiceCommands.globalStopGeneration != startGlobalStopGen) break;

      bool isSoundPlaying = PlayingSounds().playingAudios.any((p) => p.path == audio.path);
      if (!isSoundPlaying) {
        AudioServiceCommands.play(audio);
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  void stopAllSoundInPlaylist() async {
    _localSessionId++;
    PlayingSounds().isPlayingPlaylist.value = false;
    for (final audio in widget.playlist.audios) {
      AudioServiceCommands.stop(audio);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}