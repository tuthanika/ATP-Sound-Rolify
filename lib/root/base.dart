import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:rolify/presentation_logic_holders/audio_edit_bloc/audio_edit_bloc.dart';
import 'package:rolify/presentation_logic_holders/audio_edit_bloc/audio_edit_state.dart';
import 'package:rolify/presentation_logic_holders/singletons/app_state.dart';
import 'package:rolify/presentation_logic_holders/singletons/theme_mode_controller.dart';
import 'package:rolify/root/info_page.dart';
import 'package:rolify/root/session_sounds.dart';
import 'package:rolify/root/sound_edit.dart';
import 'package:rolify/src/components/my_icons.dart';
import 'package:rolify/src/components/radio.dart';
import 'package:rolify/src/theme/texts.dart';

import 'all_playlist.dart';
import 'all_sounds/all_sound.dart';

const titles = ['Sounds', 'Session', 'Playlists', 'Rolify', 'Edit Sound'];

class Base extends StatefulWidget {
  const Base({Key? key}) : super(key: key);

  @override
  BaseState createState() => BaseState();
}

class BaseState extends State<Base> {
  int pageSelected = 0;
  int? previousPage;

  @override
  Widget build(BuildContext context) {
    AppState().deviceHeight = MediaQuery.of(context).size.height *
        MediaQuery.of(context).devicePixelRatio;
    AppState().deviceWidth = MediaQuery.of(context).size.width *
        MediaQuery.of(context).devicePixelRatio;
    return BlocListener<AudioEditBloc, AudioEditState>(
      listener: handleAudioEditing,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding:
                    const EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: MyText(
                        titles[pageSelected],
                        fontFamily: 'Inter-Regular',
                        fontSize: 26 * heightFactor,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        textOverflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    MyRadio(
                      value: pageSelected == 0,
                      onChanged: pageSelected <= 3 ? showSoundPage : null,
                      icon: MyIcons.list(color: _getIconColor(context, 0)),
                      customSize: 36.0,
                      customIconSize: 20.0,
                    ),
                    const SizedBox(width: 6.0),
                    MyRadio(
                      value: pageSelected == 1,
                      onChanged:
                          pageSelected <= 3 ? showSessionSoundPage : null,
                      icon: MyIcons.play(color: _getIconColor(context, 1)),
                      customSize: 36.0,
                      customIconSize: 20.0,
                    ),
                    const SizedBox(width: 6.0),
                    MyRadio(
                      value: pageSelected == 2,
                      onChanged: pageSelected <= 3 ? showPlaylistPage : null,
                      icon: MyIcons.playlist(color: _getIconColor(context, 2)),
                      customSize: 36.0,
                      customIconSize: 20.0,
                    ),
                    const SizedBox(width: 6.0),
                    MyRadio(
                      value: pageSelected == 3,
                      onChanged: pageSelected <= 3 ? showInfoPage : null,
                      icon: MyIcons.about(color: _getIconColor(context, 3)),
                      customSize: 36.0,
                      customIconSize: 20.0,
                    ),
                    const SizedBox(width: 6.0),
                    MyRadio(
                      value: Theme.of(context).brightness == Brightness.dark,
                      onChanged: toggleThemeMode,
                      icon: Icon(
                        Theme.of(context).brightness == Brightness.dark
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        color: _getThemeIconColor(context),
                        size: 20.0 * heightFactor,
                      ),
                      customSize: 36.0,
                      customIconSize: 20.0,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 16.0,
              ),
              Expanded(
                  child: IndexedStack(
                index: pageSelected,
                children: <Widget>[
                  const AllSound(),
                  const SessionSounds(),
                  const AllPlaylist(),
                  const InfoPage(),
                  SoundEdit(),
                ],
              ))
            ],
          ),
        ),
      ),
    );
  }

  Color? _getIconColor(BuildContext context, int pageNumber) {
    if (pageSelected > 3) {
      return Theme.of(context).disabledColor;
    }
    if (pageSelected == pageNumber) {
      return Theme.of(context).colorScheme.primary;
    }
    return null;
  }

  void handleAudioEditing(BuildContext context, state) {
    if (state is AudioEditing) {
      previousPage = pageSelected;
      changePage(4);
    }
    if (state is NoEditing && previousPage != null) {
      changePage(previousPage);
    }
  }

  showSoundPage(bool value) {
    if (value) {
      changePage(0);
    }
  }

  showSessionSoundPage(bool value) {
    if (value) {
      changePage(1);
    }
  }

  showPlaylistPage(bool value) {
    if (value) {
      changePage(2);
    }
  }

  showInfoPage(bool value) {
    if (value) {
      changePage(3);
    }
  }

  Color _getThemeIconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? Colors.amber : Colors.black54;
  }

  void toggleThemeMode(bool value) {
    ThemeModeController().toggle(Theme.of(context).brightness == Brightness.dark);
  }

  changePage(int? page) {
    if (page != null) {
      setState(() {
        pageSelected = page;
      });
    }
  }
}
