import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:rolify/entities/audio.dart';
import 'package:rolify/presentation_logic_holders/audio_list_bloc/audio_list_bloc.dart';
import 'package:rolify/presentation_logic_holders/audio_list_bloc/audio_list_state.dart';
import 'package:rolify/presentation_logic_holders/event_bus/stop_all_event_bus.dart';
import 'package:rolify/presentation_logic_holders/playing_sounds_singleton.dart';
import 'package:rolify/presentation_logic_holders/singletons/theme_mode_controller.dart';
import 'package:rolify/presentation_logic_holders/singletons/app_state.dart';
import 'package:rolify/root/info_page.dart';
import 'package:rolify/src/components/player_card.dart';

import 'all_sounds/global_controls.dart';
import 'all_sounds/search_bar.dart';

class SessionSounds extends StatefulWidget {
  const SessionSounds({Key? key}) : super(key: key);

  @override
  SessionSoundsState createState() => SessionSoundsState();
}

class SessionSoundsState extends State<SessionSounds>
    with WidgetsBindingObserver {
  List<Audio> filteredAudios = [];
  TextEditingController filterController = TextEditingController();
  FocusNode focusNode = FocusNode();
  bool pauseAll = true, audioToPauseExist = false, audioToReplayExist = false;
  int sortMode = 0; // 0: A-Z, 1: Newest (playing order)

  bool get playPauseEnabled =>
      (pauseAll && audioToPauseExist) ||
      (pauseAll == false && audioToReplayExist);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    eventBus.on<AudioPlayed>().listen((event) {
      if (mounted) {
        setState(() {
          audioToPauseExist = PlayingSounds().playingAudios.isNotEmpty;
          audioToReplayExist = PlayingSounds().pausedAudios.isNotEmpty;
          pauseAll = audioToPauseExist;
        });
        filterAudios(context);
      }
    });
    eventBus.on<AudioPaused>().listen((event) {
      if (mounted) {
        setState(() {
          audioToPauseExist = PlayingSounds().playingAudios.isNotEmpty;
          audioToReplayExist = PlayingSounds().pausedAudios.isNotEmpty;
          pauseAll = audioToPauseExist;
        });
        filterAudios(context);
      }
    });
    initAudios();
  }

  bool isExpanded = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      eventBus.fire(OnAppResume());
    }
  }

  @override
  dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> initAudios() async {
    setState(() {
      filteredAudios = PlayingSounds().playingAudios;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AudioListBloc, AudioListState>(
      listener: (BuildContext context, state) {
        if (state is AudioListEdited) initAudios();
      },
      child: Stack(
        children: <Widget>[
          ValueListenableBuilder<bool>(
            valueListenable: ThemeModeController().isCollapsed,
            builder: (context, isCollapsed, _) {
              return Column(
                children: <Widget>[
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 4.0, left: 12.0, right: 12.0, bottom: 0.0),
                    child: MySearchBar(
                      filterController: filterController,
                      focusNode: focusNode,
                      filterAudios: filterAudios,
                      resetTextFilter: resetTextFilter,
                      sortMode: sortMode,
                      onSortToggle: () {
                        setState(() {
                          sortMode = sortMode == 0 ? 1 : 0;
                          filterAudios(context);
                        });
                      },
                      isCollapsed: isCollapsed,
                      onLayoutToggle: () {
                        ThemeModeController().setCollapsed(!isCollapsed);
                      },
                      onAddTap: () {},
                      showAddButton: false,
                    ),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: PlayingSounds().stateChangeNotifier,
                    builder: (context, _, __) {
                      final Set<Audio> uniqueSessionAudios = {};
                      uniqueSessionAudios.addAll(PlayingSounds().playingAudios);
                      uniqueSessionAudios.addAll(PlayingSounds().pausedAudios);
                      
                      final allAudios = uniqueSessionAudios.toList();
                      List<Audio> currentFiltered = allAudios;
                      if (filterController.text.isNotEmpty) {
                        currentFiltered = currentFiltered.where((audio) => 
                          audio.name.toLowerCase().contains(filterController.text.toLowerCase())
                        ).toList();
                      }
                      if (sortMode == 0) {
                        currentFiltered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                      } else {
                        currentFiltered = currentFiltered.reversed.toList();
                      }

                      return Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.only(bottom: 148, top: 0, left: 12, right: 12),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: isCollapsed ? 3.0 : 1.15,
                          ),
                          itemCount: currentFiltered.length,
                          itemBuilder: (context, index) {
                            final e = currentFiltered[index];
                            return PlayerWidget(
                              key: Key('${e.path}_session'),
                              audio: e,
                              isCollapsedLayout: isCollapsed,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  vertical: 16.0 * heightFactor, horizontal: 16.0),
              child: ValueListenableBuilder<int>(
                valueListenable: PlayingSounds().stateChangeNotifier,
                builder: (context, _, __) {
                  return GlobalControls(
                      isExpanded: isExpanded,
                      onExpandChanged: (val) => setState(() => isExpanded = val),
                      pauseAll: PlayingSounds().playingAudios.isNotEmpty,
                      playPauseEnabled: PlayingSounds().playingAudios.isNotEmpty || PlayingSounds().pausedAudios.isNotEmpty,
                      setPauseAll: (value) {
                        setState(() {
                          pauseAll = value;
                        });
                      });
                }
              ),
            ),
          )
        ],
      ),
    );
  }

  void resetTextFilter(BuildContext context) {
    focusNode.unfocus();
    filterController.clear();
    filterAudios(context);
  }

  filterAudios(BuildContext context) async {
    final Set<Audio> uniqueSessionAudios = {};
    uniqueSessionAudios.addAll(PlayingSounds().playingAudios);
    uniqueSessionAudios.addAll(PlayingSounds().pausedAudios);
    
    final allAudios = uniqueSessionAudios.toList();

    List<Audio> newFilteredAudios = allAudios;
    if (filterController.text != '') {
      newFilteredAudios =
          filterAudiosByText(newFilteredAudios, filterController.text);
    }
    if (sortMode == 0) {
      newFilteredAudios
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      // Newest First (most recently played)
      newFilteredAudios = newFilteredAudios.reversed.toList();
    }
    setState(() {
      filteredAudios = newFilteredAudios;
    });
  }

  filterAudiosByText(List<Audio> audios, String text) {
    return audios
        .where((audio) => audio.name.toLowerCase().contains(text.toLowerCase()))
        .toList();
  }

  void navigateToInfo() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const InfoPage()));
  }
}
