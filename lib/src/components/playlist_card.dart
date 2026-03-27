import 'package:flutter/material.dart';
import 'package:rolify/data/audios.dart'; 
import 'package:rolify/entities/audio.dart';
import 'package:rolify/entities/playlist.dart';
import 'package:rolify/root/all_sounds/search_bar.dart';
import 'package:rolify/presentation_logic_holders/audio_handler.dart'; 
import 'package:rolify/presentation_logic_holders/audio_service_commands.dart';
import 'package:rolify/presentation_logic_holders/playing_sounds_singleton.dart';
import 'package:rolify/presentation_logic_holders/singletons/app_state.dart';
import 'package:rolify/root/edit_playlist.dart';
import 'package:rolify/root/all_playlist.dart'; 
import 'package:rolify/src/components/button.dart';
import 'package:rolify/src/components/player_card.dart';
import 'package:rolify/src/components/radio.dart';
import 'package:rolify/src/theme/texts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auto_scroll_text.dart';
import 'my_icons.dart';

class PlaylistCard extends StatefulWidget {
  final Playlist playlist;

  const PlaylistCard({Key? key, required this.playlist}) : super(key: key);

  @override
  PlaylistCardState createState() => PlaylistCardState();
}

class PlaylistCardState extends State<PlaylistCard> {
  final duration = const Duration(milliseconds: 400);
  bool expanded = false, showAudioList = false;
  int _localSessionId = 0;
  List<Audio> filteredAudios = [];
  final TextEditingController filterController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  int sortMode = 0; 
  bool isCollapsedItems = true;

  @override
  void didUpdateWidget(covariant PlaylistCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playlist.audios != widget.playlist.audios) {
      _filterPlaylistSounds();
    }
  }

  @override
  void initState() {
    super.initState();
    filteredAudios = widget.playlist.audios;
    _loadSortMode();
    PlaylistGlobals.expandNotifier.addListener(_onGlobalExpandChanged);
    
    isExpanded = PlaylistGlobals.expandedPlaylists.contains(widget.playlist.name) 
        ? true 
        : PlaylistGlobals.expandNotifier.value;
  }

  @override
  void dispose() {
    PlaylistGlobals.expandNotifier.removeListener(_onGlobalExpandChanged);
    super.dispose();
  }

  void _onGlobalExpandChanged() {
    if (mounted) {
      bool val = PlaylistGlobals.expandNotifier.value;
      if (val && !expanded) {
        setState(() {
          expanded = true;
          showAudioList = true;
        });
      } else if (!val && expanded) {
        _collapse();
      }
    }
  }

  Future<void> _loadSortMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        sortMode = prefs.getInt('playlist_card_sort_${widget.playlist.name}') ?? 0;
        _filterPlaylistSounds();
      });
    }
  }

  void _cycleSort() async {
    setState(() {
      sortMode = (sortMode + 1) % 3;
      _filterPlaylistSounds();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('playlist_card_sort_${widget.playlist.name}', sortMode);
  }

  void _collapse() {
    if (!expanded) return;
    setState(() => expanded = false);
    Future.delayed(duration).then((_) {
      if (mounted && !expanded) setState(() => showAudioList = false);
    });
  }

  // BẢN VÁ TỐI THƯỢNG: Trích xuất logic .every() CHÍNH XÁC từ file code gốc bạn gửi!
  // Chỉ sáng màu khi TẤT CẢ các bài hát trong list đều đang nằm trong danh sách phát
  bool _isPlaylistPlaying() {
    if (widget.playlist.audios.isEmpty) return false;
    return widget.playlist.audios.every((playlistAudio) =>
        PlayingSounds().playingAudios.any((playing) => playing.path == playlistAudio.path)
    );
  }

  void _filterPlaylistSounds() {
    List<Audio> result = List<Audio>.from(widget.playlist.audios);
    if (filterController.text.isNotEmpty) {
      result = result.where((e) => e.name.toLowerCase().contains(filterController.text.toLowerCase())).toList();
    }
    if (sortMode == 0) {
      result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (sortMode == 1) {
      result.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    } else {
      result = result.reversed.toList();
    }
    setState(() => filteredAudios = result);
  }

  void onEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditPlaylist(playlist: widget.playlist)),
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

  double get maxHeight => MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - 160;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      // TUYỆT KỸ CHỐNG LAG: Chỉ theo dõi màu và nút Play, KHÔNG RENDER LẠI GRIDVIEW!
      child: ValueListenableBuilder<int>(
        valueListenable: PlayingSounds().stateChangeNotifier,
        builder: (context, _, child) {
          final currentlyPlaying = _isPlaylistPlaying();

          return AnimatedContainer(
            duration: duration,
            curve: Curves.ease,
            height: expanded ? maxHeight : 170,
            decoration: BoxDecoration(
              color: currentlyPlaying 
                  ? (widget.playlist.color ?? Theme.of(context).colorScheme.primary).withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.4 : 0.4)
                  : (widget.playlist.color?.withOpacity(0.2) ?? Theme.of(context).colorScheme.surfaceContainerHighest),
              borderRadius: const BorderRadius.all(Radius.circular(16.0)),
            ),
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 8.0),
            child: Stack(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              MyText.body(widget.playlist.name, fontWeight: FontWeight.w500),
                              ScrollText(audios: widget.playlist.audios),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        MyButton(
                          icon: MyIcons.edit(),
                          onTap: onEdit,
                        ),
                      ],
                    ),
                    if (showAudioList) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: MySearchBar(
                          filterController: filterController,
                          focusNode: focusNode,
                          filterAudios: (_) => _filterPlaylistSounds(),
                          resetTextFilter: (_) {
                            filterController.clear();
                            focusNode.unfocus();
                            _filterPlaylistSounds();
                          },
                          sortMode: sortMode,
                          onSortToggle: _cycleSort, 
                          isCollapsed: isCollapsedItems,
                          onLayoutToggle: () => setState(() => isCollapsedItems = !isCollapsedItems),
                          onAddTap: () {},
                          showAddButton: false,
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: isCollapsedItems ? 3.0 : 1.15,
                          ),
                          itemCount: filteredAudios.length,
                          itemBuilder: (context, index) {
                            final e = filteredAudios[index];
                            return PlayerWidget(
                              key: Key('${e.path}_playlist_${isCollapsedItems}'),
                              audio: e,
                              isCollapsedLayout: isCollapsedItems,
                              autoShrinkText: true,
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: 96,
                    child: AnimatedContainer(
                      duration: duration,
                      curve: Curves.ease,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                        boxShadow: expanded ? [
                          BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.2), blurRadius: 8, spreadRadius: 1)
                        ] : [],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: <Widget>[
                            Expanded(child: Container()),
                            MyRadio(
                              big: true,
                              icon: currentlyPlaying ? MyIcons.pauseBig() : MyIcons.playBig(),
                              value: currentlyPlaying,
                              onChanged: (value) {
                                if (value) {
                                  playAllSoundInPlaylist();
                                } else {
                                  stopAllSoundInPlaylist();
                                }
                              },
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: MyRadio(
                                    icon: MyIcons.playlistList(color: expanded ? Theme.of(context).colorScheme.primary : null),
                                    value: expanded,
                                    onChanged: (bool value) {
                                      if (value) {
                                        setState(() {
                                          expanded = true;
                                          showAudioList = true;
                                        });
                                      } else {
                                        _collapse();
                                      }
                                    },
                                  ),
                                ),
                              )
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          );
        }
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