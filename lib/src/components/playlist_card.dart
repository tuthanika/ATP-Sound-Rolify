import 'package:flutter/material.dart';
import 'package:rolify/data/audios.dart'; 
import 'package:rolify/data/playlist.dart';
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
  bool isExpanded = false; 
  String? _playlistGlobalId;

  PlaylistPlaybackState get _playbackState {
    final playlistPaths = widget.playlist.audios.map((a) => a.path).toSet();
    final hasAnyPlaying = PlayingSounds().playingAudios.any((a) => playlistPaths.contains(a.path));
    final hasAnyPaused = PlayingSounds().pausedAudios.any((a) => playlistPaths.contains(a.path));

    final hasGlobalActiveId = _playlistGlobalId != null &&
        PlayingSounds().activePlaylistIds.contains(_playlistGlobalId);
    if (!hasGlobalActiveId) return PlaylistPlaybackState.stopped;

    if (hasAnyPlaying) return PlaylistPlaybackState.playing;
    if (hasAnyPaused) return PlaylistPlaybackState.paused;

    return PlaylistPlaybackState.stopped;
  }

  bool get _isActive => _playbackState != PlaylistPlaybackState.stopped;

  IconData get _currentActionIcon {
    switch (_playbackState) {
      case PlaylistPlaybackState.playing:
        return Icons.stop;
      case PlaylistPlaybackState.paused:
        return Icons.pause;
      case PlaylistPlaybackState.stopped:
        return Icons.play_arrow;
    }
  }

  @override
  void initState() {
    super.initState();
    PlaylistGlobals.expandNotifier.addListener(_onGlobalExpandChanged);
    
    isExpanded = PlaylistGlobals.expandedPlaylists.contains(widget.playlist.name) 
        ? true 
        : PlaylistGlobals.expandNotifier.value;

    PlayingSounds().stateChangeNotifier.addListener(_onSystemStateChanged);
    PlayingSounds().isPlayingPlaylist.addListener(_onSystemStateChanged);
    PlayingSounds().activePlaylistIdsNotifier.addListener(_onSystemStateChanged);
    _resolvePlaylistGlobalId();
  }

  @override
  void dispose() {
    PlaylistGlobals.expandNotifier.removeListener(_onGlobalExpandChanged);
    PlayingSounds().stateChangeNotifier.removeListener(_onSystemStateChanged);
    PlayingSounds().isPlayingPlaylist.removeListener(_onSystemStateChanged);
    PlayingSounds().activePlaylistIdsNotifier.removeListener(_onSystemStateChanged);
    super.dispose();
  }

  void _onSystemStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _resolvePlaylistGlobalId() async {
    final allPlaylists = await PlaylistData.getAllPlaylist();
    final index = allPlaylists.indexWhere((p) => p.name == widget.playlist.name);
    if (!mounted) return;
    setState(() {
      _playlistGlobalId = index >= 0 ? index.toString() : null;
    });
  }

  void _onGlobalExpandChanged() {
    if (mounted) {
      bool val = PlaylistGlobals.expandNotifier.value;
      setState(() {
        isExpanded = val;
        if (val) PlaylistGlobals.expandedPlaylists.add(widget.playlist.name);
        else PlaylistGlobals.expandedPlaylists.remove(widget.playlist.name);
      });
    }
  }

  void _toggleExpanded(bool val) {
    setState(() {
      isExpanded = val;
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
    if (_playlistGlobalId != null) {
      AppState().audioHandler.customAction('play_playlist', {"id": _playlistGlobalId});
      return;
    }

    if (_isActive) stopAllSoundInPlaylist();
    else playAllSoundInPlaylist();
  }

  @override
  void didUpdateWidget(covariant PlaylistCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playlist.name != widget.playlist.name) {
      _resolvePlaylistGlobalId();
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
    
    Color bgColor = _isActive 
        ? (widget.playlist.color ?? Theme.of(context).colorScheme.primary).withOpacity(isDarkMode ? 0.6 : 0.2)
        : baseColor.withOpacity(isDarkMode ? 0.85 : 1.0);

    Color textColor = bgColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    return InkWell(
      onTap: () => _toggleExpanded(true),
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
            IconButton(
              onPressed: togglePlay,
              icon: Icon(_currentActionIcon, color: textColor, size: 28),
              splashRadius: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            const SizedBox(width: 8),
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
    if (mounted) setState(() {});
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
    if (mounted) setState(() {});
    for (final audio in widget.playlist.audios) {
      AudioServiceCommands.stop(audio);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}

enum PlaylistPlaybackState { stopped, paused, playing }
