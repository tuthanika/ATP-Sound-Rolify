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
import 'package:rolify/data/playlist.dart';

import 'my_icons.dart';

class PlaylistCard extends StatefulWidget {
  final Playlist playlist;

  const PlaylistCard({Key? key, required this.playlist}) : super(key: key);

  @override
  PlaylistCardState createState() => PlaylistCardState();
}

class PlaylistCardState extends State<PlaylistCard> {
  int _localSessionId = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Đọc trạng thái mở rộng trực tiếp từ Sổ Tay, không cần listener
  bool get isExpanded {
    if (PlaylistGlobals.expandedPlaylists.contains(widget.playlist.name)) return true;
    return PlaylistGlobals.expandNotifier.value;
  }

  void _toggleExpanded(bool val) {
    setState(() {
      if (val) {
        PlaylistGlobals.expandedPlaylists.add(widget.playlist.name);
      } else {
        PlaylistGlobals.expandedPlaylists.remove(widget.playlist.name);
      }
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
    final playingPaths = PlayingSounds().playingPathsNotifier.value;
    final bool isPlayingNow = widget.playlist.audios.isNotEmpty && 
                              widget.playlist.audios.every((a) => playingPaths.contains(a.path));
    if (isPlayingNow) {
      stopAllSoundInPlaylist();
    } else {
      playAllSoundInPlaylist();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: PlayingSounds().playingPathsNotifier,
      builder: (context, playingPaths, _) {
        // TỐI ƯU HỎA TỐC: Gom các vòng lặp checking trạng thái vào 1 pass duy nhất
        bool showsAsActive = widget.playlist.audios.isNotEmpty;
        bool anyPlaying = false;
        
        // Chỉ check nếu playlist có audio, tránh lãng phí O(N) vô ích
        if (showsAsActive) {
          for (final a in widget.playlist.audios) {
            final bool isPathPlaying = playingPaths.contains(a.path);
            if (!isPathPlaying) {
              showsAsActive = false;
              break; // Chỉ cần 1 cái không phát là coi như playlist chưa "Active" (theo quy tắc all-or-nothing)
            }
            anyPlaying = true; 
          }
        }
        
        final IconData actionIcon = showsAsActive 
            ? (anyPlaying ? Icons.stop : Icons.pause) 
            : Icons.play_arrow;

        if (!isExpanded) return _buildCollapsed(showsAsActive, actionIcon);
        return _buildExpanded(showsAsActive, actionIcon);
      }
    );
  }

  // TỐI ƯU RENDER: Cache luminance và đơn giản hóa cây Widget cho máy yếu (Note 3)
  Widget _buildCollapsed(bool isActive, IconData actionIcon) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color defaultBg = isDarkMode ? const Color(0xff222222) : Colors.white;
    Color baseColor = widget.playlist.color ?? defaultBg;
    
    // TỐI ƯU: Tránh tính toán độ sáng (luminance) nhiều lần trong 1 build frame
    Color bgColor = isActive 
        ? (widget.playlist.color ?? Theme.of(context).colorScheme.primary).withOpacity(isDarkMode ? 0.6 : 0.2)
        : baseColor.withOpacity(isDarkMode ? 0.85 : 1.0);

    // Dùng threshold đơn giản nếu luminance quá lag, nhưng ở đây ta cache lại biến
    final luminance = bgColor.computeLuminance();
    Color textColor = luminance > 0.5 ? Colors.black87 : Colors.white;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: EdgeInsets.zero,
      color: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: togglePlay, 
        onLongPress: onEdit,
        child: Container( // Thay SizedBox bằng Container để nhẹ hơn (máy cổ)
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(actionIcon, color: textColor, size: 28),
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
      ),
    );
  }

  Widget _buildExpanded(bool isActive, IconData actionIcon) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color defaultBg = isDarkMode ? const Color(0xff222222) : Colors.grey.shade100;
    Color baseColor = widget.playlist.color ?? defaultBg;
    
    Color bgColor = isActive 
        ? (widget.playlist.color ?? Theme.of(context).colorScheme.primary).withOpacity(isDarkMode ? 0.6 : 0.2)
        : baseColor;

    final luminance = bgColor.computeLuminance();
    Color textColor = luminance > 0.5 ? Colors.black87 : Colors.white;

    return Container(
      height: 180, 
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        margin: EdgeInsets.zero,
        color: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container( // Giảm bớt 1 lớp Stack nếu không cần thiết
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            // Giảm độ phức tạp của border cho GPU đời cũ
            border: Border.all(color: textColor.withOpacity(0.2), width: 1),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // Spacer cho cân đối nút bên phải
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        widget.playlist.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.expand_less, color: textColor),
                    onPressed: () => _toggleExpanded(false), 
                  ),
                ],
              ),
              Expanded(
                child: InkWell(
                  onTap: onTapList, 
                  onLongPress: onEdit,
                  child: Center(
                    child: Text(
                      '${widget.playlist.audios.length} sounds',
                      style: TextStyle(color: textColor.withOpacity(0.8), fontWeight: FontWeight.w500)
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildIconButton(actionIcon, 28, textColor, togglePlay),
                    _buildIconButton(Icons.edit, 22, textColor.withOpacity(0.8), onEdit),
                    _buildIconButton(Icons.list, 22, textColor.withOpacity(0.8), onTapList),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, double size, Color color, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap, 
      icon: Icon(icon, size: size, color: color),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(),
    );
  }

  void playAllSoundInPlaylist() async {
    // Tự động tìm index của playlist hiện tại để đồng nhất với Widget logic
    final allPlaylists = await PlaylistData.getAllPlaylist();
    final index = allPlaylists.indexWhere((p) => p.name == widget.playlist.name);
    
    if (index != -1) {
      AppState().audioHandler.customAction('play_playlist', {'id': index.toString()});
    }
  }

  void stopAllSoundInPlaylist() async {
    final allPlaylists = await PlaylistData.getAllPlaylist();
    final index = allPlaylists.indexWhere((p) => p.name == widget.playlist.name);
    
    if (index != -1) {
      // Logic toggle trong AudioHandler sẽ tự stop nếu đã active
      AppState().audioHandler.customAction('play_playlist', {'id': index.toString()});
    }
  }
}