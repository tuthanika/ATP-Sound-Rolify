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
  final duration = const Duration(milliseconds: 500);
  bool isPlaying = false, expanded = false, showAudioList = false;
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
  }

  bool _isPlaylistPlaying() {
    return widget.playlist.audios.any((a) =>
        PlayingSounds().playingAudios.any((p) => p.path == a.path));
  }

  void _filterPlaylistSounds() {
    List<Audio> result = List<Audio>.from(widget.playlist.audios);
    if (filterController.text.isNotEmpty) {
      result = result.where((e) => e.name.toLowerCase().contains(filterController.text.toLowerCase())).toList();
    }
    if (sortMode == 0) {
      result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      // Newest First (last added to playlist)
      result = result.reversed.toList();
    }
    setState(() {
      filteredAudios = result;
    });
  }

  double get maxHeight =>
      MediaQuery.of(context).size.height -
      MediaQuery.of(context).padding.top -
      160;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.ease,
        height: expanded ? maxHeight : 170,
        child: Container(
          decoration: BoxDecoration(
            color: widget.playlist.color?.withOpacity(0.2) ?? Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.all(Radius.circular(16.0)),
          ),
          padding: const EdgeInsets.only(
              top: 16.0, left: 16.0, right: 16.0, bottom: 8.0),
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
                            MyText.body(
                              widget.playlist.name,
                              fontWeight: FontWeight.w500,
                            ),
                            ScrollText(
                              audios: widget.playlist.audios,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      MyButton(
                        icon: MyIcons.edit(),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    EditPlaylist(playlist: widget.playlist))),
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
                        onSortToggle: () {
                          setState(() {
                            sortMode = sortMode == 0 ? 1 : 0;
                            _filterPlaylistSounds();
                          });
                        },
                        isCollapsed: isCollapsedItems,
                        onLayoutToggle: () {
                          setState(() {
                            isCollapsedItems = !isCollapsedItems;
                          });
                        },
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
                  height: 96 * heightFactor,
                  child: AnimatedContainer(
                    duration: duration,
                    curve: Curves.ease,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                      boxShadow: expanded ? [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ] : [],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: <Widget>[
                          Expanded(child: Container()),
                          ValueListenableBuilder(
                            valueListenable: PlayingSounds().stateChangeNotifier,
                            builder: (context, _, __) {
                              final currentlyPlaying = _isPlaylistPlaying();
                              return MyRadio(
                                big: true,
                                icon: currentlyPlaying
                                    ? MyIcons.pauseBig()
                                    : MyIcons.playBig(),
                                value: currentlyPlaying,
                                onChanged: (value) {
                                  if (value) {
                                    playAllSoundInPlaylist();
                                  } else {
                                    stopAllSoundInPlaylist();
                                  }
                                },
                              );
                            },
                          ),
                          Expanded(
                              child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: MyRadio(
                                icon: MyIcons.playlistList(
                                    color: expanded
                                        ? Theme.of(context)
                                            .colorScheme.primary
                                        : null),
                                value: expanded,
                                onChanged: (bool value) {
                                  if (value) {
                                    setState(() {
                                      expanded = true;
                                      showAudioList = true;
                                    });
                                  } else {
                                    setState(() {
                                      expanded = false;
                                    });

                                    Future.delayed(duration).then((_) {
                                      setState(() {
                                        showAudioList = false;
                                      });
                                    });
                                  }
                                },
                              ),
                            ),
                          ))
                        ],
                      ),
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

  void playAllSoundInPlaylist() async {
    PlayingSounds().isPlayingPlaylist.value = true;
    _localSessionId++;
    final currentSession = _localSessionId;
    final startGlobalStopGen = AudioServiceCommands.globalStopGeneration;

    for (final audio in widget.playlist.audios) {
      if (_localSessionId != currentSession) break;
      if (AudioServiceCommands.globalStopGeneration != startGlobalStopGen) break;
      
      AudioServiceCommands.play(audio);
      await Future.delayed(const Duration(milliseconds: 100));
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
