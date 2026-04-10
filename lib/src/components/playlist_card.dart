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
  final int dbIndex;
  final ValueNotifier<bool> isScrolling;

  const PlaylistCard({
    Key? key, 
    required this.playlist, 
    required this.dbIndex,
    required this.isScrolling,
  }) : super(key: key);

  @override
  PlaylistCardState createState() => PlaylistCardState();
}

class PlaylistCardState extends State<PlaylistCard> {
  Color _inactiveTextColor = Colors.white;
  Color _activeTextColor = Colors.white;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateColors();
  }

  @override
  void didUpdateWidget(PlaylistCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playlist.color != widget.playlist.color) {
      _calculateColors();
    }
  }

  void _calculateColors() {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color defaultBg = isDarkMode ? const Color(0xff222222) : Colors.white;
    Color baseColor = widget.playlist.color ?? defaultBg;
    
    // Calculate for Inactive
    Color inactiveBg = baseColor.withOpacity(isDarkMode ? 0.85 : 1.0);
    _inactiveTextColor = inactiveBg.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    // Calculate for Active
    Color activeBg = (widget.playlist.color ?? Theme.of(context).colorScheme.primary)
        .withOpacity(isDarkMode ? 0.6 : 0.2);
    _activeTextColor = activeBg.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Đọc trạng thái mở rộng trực tiếp từ Sổ Tay
  bool get isExpanded {
    if (PlaylistGlobals.expandedPlaylists.contains(widget.playlist.name)) return true;
    return PlaylistGlobals.expandNotifier.value;
  }

  void _toggleExpanded(bool val) {
    if (widget.isScrolling.value) return;
    setState(() {
      if (val) {
        PlaylistGlobals.expandedPlaylists.add(widget.playlist.name);
      } else {
        PlaylistGlobals.expandedPlaylists.remove(widget.playlist.name);
      }
    });
  }

  void onEdit() {
    if (widget.isScrolling.value) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPlaylist(playlist: widget.playlist),
      ),
    );
  }

  void onTapList() async {
    if (widget.isScrolling.value) return;

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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
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
                      mainAxisSize: MainAxisSize.min,
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
                              const Opacity(opacity: 0, child: IconButton(icon: Icon(Icons.arrow_back), onPressed: null)),
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
    if (widget.isScrolling.value) return; 
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
    return RepaintBoundary(
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: PlayingSounds().playingPathsNotifier,
        builder: (context, playingPaths, _) {
          bool showsAsActive = widget.playlist.audios.isNotEmpty;
          bool anyPlaying = false;
          
          if (showsAsActive) {
            for (final a in widget.playlist.audios) {
              final bool isPathPlaying = playingPaths.contains(a.path);
              if (!isPathPlaying) {
                showsAsActive = false;
                break;
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
      ),
    );
  }

  Widget _buildCollapsed(bool isActive, IconData actionIcon) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color defaultBg = isDarkMode ? const Color(0xff222222) : Colors.white;
    Color baseColor = widget.playlist.color ?? defaultBg;
    
    Color bgColor = isActive 
        ? (widget.playlist.color ?? Theme.of(context).colorScheme.primary).withOpacity(isDarkMode ? 0.6 : 0.2)
        : baseColor.withOpacity(isDarkMode ? 0.85 : 1.0);

    Color textColor = isActive ? _activeTextColor : _inactiveTextColor;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.none,
        child: InkWell(
          onTap: togglePlay, 
          onLongPress: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Container(
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

    Color textColor = isActive ? _activeTextColor : _inactiveTextColor;

    return Container(
      height: 180, 
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.none,
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: textColor.withOpacity(0.2), width: 1),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
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

  void playAllSoundInPlaylist() {
    AppState().audioHandler.customAction('play_playlist', {'id': widget.dbIndex.toString()});
  }

  void stopAllSoundInPlaylist() {
    AppState().audioHandler.customAction('play_playlist', {'id': widget.dbIndex.toString()});
  }
}
