import 'dart:async'; 
import 'package:flutter/material.dart';
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
import 'package:rolify/data/audios.dart';

import 'my_icons.dart';

class PlaylistCard extends StatefulWidget {
  final Playlist playlist;

  const PlaylistCard({Key? key, required this.playlist}) : super(key: key);

  @override
  PlaylistCardState createState() => PlaylistCardState();
}

// BẢN VÁ: Gỡ bỏ hoàn toàn KeepAlive. Chống mất trạng thái bằng Sổ Tay (expandedPlaylists)
class PlaylistCardState extends State<PlaylistCard> {
  int _localSessionId = 0;
  bool isExpanded = false; 

  // GIỮ NGUYÊN LOGIC TRẠNG THÁI CHUẨN CỦA BẠN
  bool get _isPlaying {
    if (widget.playlist.audios.isEmpty) return false;
    final playingPaths = PlayingSounds().playingAudios.map((p) => p.path).toSet();
    return widget.playlist.audios.every((a) => playingPaths.contains(a.path));
  }

  IconData get _currentActionIcon {
    if (!_isPlaying) return Icons.play_arrow;

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
    
    // Đọc trạng thái từ Sổ tay. Nếu chưa có thì lấy theo cờ Toàn cục.
    isExpanded = PlaylistGlobals.expandedPlaylists.contains(widget.playlist.name) 
        ? true 
        : PlaylistGlobals.expandNotifier.value;

    PlayingSounds().stateChangeNotifier.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    PlaylistGlobals.expandNotifier.removeListener(_onGlobalExpandChanged);
    PlayingSounds().stateChangeNotifier.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onGlobalExpandChanged() {
    if (mounted) {
      bool val = PlaylistGlobals.expandNotifier.value;
      setState(() {
        isExpanded = val;
        // Đồng bộ vào sổ tay
        if (val) PlaylistGlobals.expandedPlaylists.add(widget.playlist.name);
        else PlaylistGlobals.expandedPlaylists.remove(widget.playlist.name);
      });
    }
  }

  void _toggleExpanded(bool val) {
    setState(() {
      isExpanded = val;
      // Ghi chép vào sổ tay để nhớ kể cả khi thẻ bị cuộn mất
      if (val) PlaylistGlobals.expandedPlaylists.add(widget.playlist.name);
      else PlaylistGlobals.expandedPlaylists.remove(widget.playlist.name);
    });
  }

  void onEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPlaylist(playlist: widget.playlist),
      ),
    );
  }

  // BẢN VÁ UI DANH SÁCH: Cấu trúc Dialog y hệt code gốc của bạn (tránh 2 khung chồng)
  // Kèm theo GridView 2 cột với khoảng cách siêu nhỏ (1/2) như bạn mong muốn!
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
        backgroundColor: Colors.transparent, // Phải trong suốt để Stack tự do bo góc
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // BẢN VÁ TỐI THƯỢNG: Dùng Positioned.fill để ép lớp nền 1 ôm khít đúng bằng lớp danh sách bên trên!
              Positioned.fill(
                child: Container(color: widget.playlist.color ?? Colors.grey[800]),
              ),
              Container(
                color: bgColor.withOpacity(0.8),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: textColor.withOpacity(0.3), width: 1.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Lệnh vàng ép khung thu nhỏ theo List
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
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
                                  shrinkWrap: true, // Xóa khoảng trống thừa trong Grid
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2, 
                                    crossAxisSpacing: 4, 
                                    mainAxisSpacing: 4, 
                                    mainAxisExtent: 140, 
                                  ),
                                  itemCount: updatedAudios.length,
                                  itemBuilder: (context, index) {
                                    return PlayerWidget(audio: updatedAudios[index]);
                                  },
                                ),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.all(12.0),
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
              )
            ],
          ),
        ),
      ),
    );
  }

  void togglePlay() {
    if (_isPlaying) {
      stopAllSoundInPlaylist();
    } else {
      playAllSoundInPlaylist();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isExpanded) return _buildCollapsed();
    return _buildExpanded();
  }

  Widget _buildCollapsed() {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color defaultBg = isDarkMode ? const Color(0xff222222) : Colors.white;
    Color baseColor = widget.playlist.color ?? defaultBg;
    
    Color bgColor = _isPlaying 
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
            Icon(_currentActionIcon, color: textColor, size: 28), // Icon thẩm mỹ
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
    
    Color bgColor = _isPlaying 
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
                            icon: Icon(_currentActionIcon, size: 28, color: textColor),
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
    for (final audio in widget.playlist.audios) {
      AudioServiceCommands.stop(audio);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}