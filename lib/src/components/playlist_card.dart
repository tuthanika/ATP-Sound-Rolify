import 'package:flutter/material.dart';
import 'package:rolify/entities/audio.dart';
import 'package:rolify/entities/playlist.dart';
import 'package:rolify/root/all_sounds/search_bar.dart';
import 'package:rolify/presentation_logic_holders/audio_handler.dart';
import 'package:rolify/presentation_logic_holders/event_bus/stop_all_event_bus.dart';
import 'package:rolify/presentation_logic_holders/audio_service_commands.dart';
import 'package:rolify/presentation_logic_holders/singletons/app_state.dart';
import 'package:rolify/presentation_logic_holders/playing_sounds_singleton.dart';
import 'package:rolify/root/edit_playlist.dart';
import 'package:rolify/src/components/button.dart';
import 'package:rolify/src/components/player_card.dart';
import 'package:rolify/src/components/radio.dart';
import 'package:rolify/src/theme/texts.dart';

import 'auto_scroll_text.dart';
import 'my_icons.dart';

class PlaylistCard extends StatefulWidget {
  final Playlist playlist;

  const PlaylistCard({Key? key, required this.playlist}) : super(key: key);

  @override
  PlaylistCardState createState() => PlaylistCardState();
}

class PlaylistCardState extends State<PlaylistCard> {
  final duration = const Duration(milliseconds: 200);
  int _localSessionId = 0;
  
  // BẢN VÁ: Trạng thái thu gọn/mở rộng và trạng thái Đang Phát
  bool isExpanded = false;
  bool _isPlaying = false;

  void onEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPlaylist(playlist: widget.playlist),
      ),
    );
  }

  void onTapList() {
    // [Giữ nguyên logic showDialog cũ của bạn]
    bool showAudioList = true;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: const Color(0xff222222),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Container(color: widget.playlist.color),
                  Container(
                    color: const Color(0xff222222).withOpacity(0.8),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white38, width: 1.5),
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
                                      onPressed: () {
                                        if (showAudioList) {
                                          Navigator.pop(context);
                                        } else {
                                          setState(() => showAudioList = true);
                                        }
                                      }),
                                  Expanded(
                                    child: MyText.title(widget.playlist.name, textAlign: TextAlign.center),
                                  ),
                                  Opacity(opacity: 0, child: IconButton(icon: MyIcons.back(), onPressed: () {})),
                                ],
                              ),
                            ),
                            if (showAudioList)
                              SizedBox(
                                height: MediaQuery.of(context).size.height / 2,
                                child: ListView(
                                  children: widget.playlist.audios.map((audio) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: PlayerWidget(audio: audio, isPlaylist: true),
                                  )).toList(),
                                ),
                              )
                            else
                              SizedBox(
                                height: MediaQuery.of(context).size.height / 2,
                                child: const SearchBarWidget(),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: MyButton(
                                icon: MyIcons.add(),
                                text: 'Add sound',
                                onTap: () {
                                  if (showAudioList) {
                                    setState(() => showAudioList = false);
                                  } else {
                                    PlayingSounds().playlistEdit = widget.playlist;
                                    setState(() => showAudioList = true);
                                  }
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
          );
        },
      ),
    ).then((value) {
      PlayingSounds().playlistEdit = null;
    });
  }

  // BẢN VÁ: Hàm Toggle Play / Stop
  void togglePlay() {
    if (_isPlaying) {
      stopAllSoundInPlaylist();
    } else {
      playAllSoundInPlaylist();
    }
    setState(() { _isPlaying = !_isPlaying; });
  }

  @override
  Widget build(BuildContext context) {
    if (!isExpanded) return _buildCollapsed();
    return _buildExpanded();
  }

  // 1. GIAO DIỆN THU GỌN: Chạm phát ngay, y như thẻ Sound
  Widget _buildCollapsed() {
    Color baseColor = widget.playlist.color ?? Colors.grey[800]!;
    Color textColor = baseColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return InkWell(
      onTap: togglePlay, // Chạm vào tên thì phát/dừng
      onLongPress: onEdit,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: baseColor.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(_isPlaying ? Icons.stop : Icons.play_arrow, color: textColor, size: 28),
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
              onPressed: () => setState(() => isExpanded = true), // Nút mở rộng
            )
          ],
        ),
      ),
    );
  }

  // 2. GIAO DIỆN MỞ RỘNG: Hiển thị full chiều ngang, có các nút list, edit
  Widget _buildExpanded() {
    Color baseColor = widget.playlist.color ?? const Color(0xff222222);
    Color textColor = widget.playlist.color != null
        ? widget.playlist.color!.computeLuminance() > 0.5 ? Colors.black : Colors.white
        : Colors.white;

    Widget nameBox = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: widget.playlist.name.length > 15
          ? SizedBox(
              height: 30,
              child: AutoScrollText(
                text: widget.playlist.name,
                style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            )
          : Text(
              widget.playlist.name,
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
            ),
    );

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 180, // Chiều cao mở rộng vừa vặn
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: baseColor),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: textColor.withOpacity(0.5), width: 1.5),
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(Icons.expand_less, color: textColor),
                        onPressed: () => setState(() => isExpanded = false), // Nút thu gọn
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: onTapList, // Mở danh sách bài khi chạm giữa thẻ
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
                            onPressed: togglePlay, // Nút phát thủ công ở chế độ mở rộng
                            icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow, size: 28, color: textColor),
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