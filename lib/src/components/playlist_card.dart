import 'package:flutter/material.dart';
import 'package:rolify/entities/audio.dart';
import 'package:rolify/entities/playlist.dart';
import 'package:rolify/presentation_logic_holders/audio_service_commands.dart';
import 'package:rolify/presentation_logic_holders/playing_sounds_singleton.dart';
import 'package:rolify/presentation_logic_holders/singletons/app_state.dart';
import 'package:rolify/root/edit_playlist.dart';
import 'package:rolify/root/all_playlist.dart'; 
import 'package:rolify/src/components/button.dart';
import 'package:rolify/src/components/player_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'my_icons.dart';

class PlaylistCard extends StatefulWidget {
  final Playlist playlist;

  const PlaylistCard({Key? key, required this.playlist}) : super(key: key);

  @override
  PlaylistCardState createState() => PlaylistCardState();
}

class PlaylistCardState extends State<PlaylistCard> {
  int _localSessionId = 0;
  bool isExpanded = false;
  
  // BẢN VÁ TỐI THƯỢNG: Trả về đúng logic nguyên bản của bạn!
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadExpandedState();
    PlaylistGlobals.expandNotifier.addListener(_onGlobalExpandChanged);

    // ĐỒNG BỘ DUY NHẤT CẦN THIẾT: 
    // Nếu Widget ngoài màn hình bấm Stop (làm clear toàn bộ audio) -> Thẻ Playlist tự động nhả màu.
    AppState().audioHandler.playbackState.listen((event) {
      if (mounted) {
        if (PlayingSounds().playingAudios.isEmpty && _isPlaying) {
          setState(() { _isPlaying = false; });
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
    if (mounted) {
      setState(() => isExpanded = PlaylistGlobals.expandNotifier.value);
    }
  }

  Future<void> _loadExpandedState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        isExpanded = prefs.getBool('playlist_exp_${widget.playlist.name}') ?? false;
      });
    }
  }

  Future<void> _toggleExpanded(bool val) async {
    setState(() => isExpanded = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('playlist_exp_${widget.playlist.name}', val);
  }

  void onEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPlaylist(playlist: widget.playlist),
      ),
    );
  }

  void onTapList() {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = isDarkMode ? const Color(0xff222222) : Colors.white;
    Color textColor = isDarkMode ? Colors.white : Colors.black87;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.playlist.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 48), 
                ],
              ),
              const SizedBox(height: 12),
              
              if (widget.playlist.audios.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text("Playlist trống", style: TextStyle(color: textColor.withOpacity(0.5))),
                )
              else
                // BẢN VÁ UI DANH SÁCH: Cấu trúc bạn đã khen đúng + Ép giãn ngang
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5, 
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      // Lệnh VÀNG: Ép thẻ PlayerWidget bung hết chiều ngang, sửa dứt điểm lỗi tàng hình
                      crossAxisAlignment: CrossAxisAlignment.stretch, 
                      children: widget.playlist.audios.map((audio) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: PlayerWidget(audio: audio),
                      )).toList(),
                    ),
                  ),
                ),
                
              const SizedBox(height: 16),
              MyButton(
                icon: MyIcons.add(),
                onTap: () {
                  Navigator.pop(context);
                  onEdit();
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  // ĐÚNG LOGIC GỐC CỦA BẠN: Play là Play, Stop là Stop. 
  // Chạm lần 2 là Reset cờ, nhả màu ngay lập tức!
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
    PlayingSounds().isPlayingPlaylist.value = false;
    for (final audio in widget.playlist.audios) {
      AudioServiceCommands.stop(audio);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}