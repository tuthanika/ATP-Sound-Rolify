import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

import '../../data/playlist.dart';
import '../../entities/playlist.dart';
import '../../presentation_logic_holders/audio_service_commands.dart';
import '../../presentation_logic_holders/playing_sounds_singleton.dart';
import '../../presentation_logic_holders/singletons/app_state.dart';
import '../../src/components/audio_slider.dart';
import '../../src/components/button.dart';
import '../../src/components/my_icons.dart';
import '../../src/components/radio.dart';

class GlobalControls extends StatefulWidget {
  final bool pauseAll;
  final bool playPauseEnabled;
  final Function(bool value) setPauseAll;

  const GlobalControls({
    Key? key,
    required this.pauseAll,
    required this.playPauseEnabled,
    required this.setPauseAll,
  }) : super(key: key);

  @override
  State<GlobalControls> createState() => _GlobalControlsState();
}

class _GlobalControlsState extends State<GlobalControls> {
  @override
  Widget build(BuildContext context) {
    return Neumorphic(
      curve: Curves.ease,
      style: NeumorphicStyle(
        boxShape: NeumorphicBoxShape.roundRect(
            const BorderRadius.all(Radius.circular(12.0))),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
            vertical: 16.0 * heightFactor, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: MyButton(
                        icon: MyIcons.star,
                        onTap: _saveCurrentMixAsPlaylist,
                      ),
                    ),
                  ),
                ),
                MyRadio(
                    big: true,
                    icon: widget.pauseAll
                        ? MyIcons.pauseBig(
                            color: widget.playPauseEnabled
                                ? null
                                : NeumorphicTheme.currentTheme(context)
                                    .disabledColor)
                        : MyIcons.playBig(
                            color: widget.playPauseEnabled
                                ? null
                                : NeumorphicTheme.currentTheme(context)
                                    .disabledColor),
                    value: widget.pauseAll,
                    onChanged: (value) {
                      if (!widget.playPauseEnabled) return;

                      if (value) {
                        playAllSound();
                      } else {
                        pauseAllSound();
                      }
                      widget.setPauseAll(value);
                    }),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14 * heightFactor),
            AudioSlider(
              isActive: true,
              value: PlayingSounds().masterVolume,
              onChanged: setMasterVolume,
            )
          ],
        ),
      ),
    );
  }

  Future<void> _saveCurrentMixAsPlaylist() async {
  final playingAudios = PlayingSounds().playingAudios.toList();

  if (playingAudios.isEmpty) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No sounds are currently playing'),
      ),
    );
    return;
  }

  final playlistName = await _showPlaylistNameDialog(
    defaultName: 'New Playlist',
  );

  if (playlistName == null) return;

  final trimmedName = playlistName.trim();
  if (trimmedName.isEmpty) return;

  final playlist = Playlist(
    name: trimmedName,
    audios: playingAudios,
  );

  await PlaylistData.savePlaylist(context, playlist);

  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Playlist "$trimmedName" saved'),
    ),
  );
}

Future<String?> _showPlaylistNameDialog({
  required String defaultName,
}) async {
  final controller = TextEditingController(text: defaultName);

  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Save playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Playlist name',
          ),
          onSubmitted: (value) {
            Navigator.of(dialogContext).pop(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );

  controller.dispose();
  return result;
}

  void playAllSound() async {
    final pausedAudios = PlayingSounds().pausedAudios.toList();
    for (final audio in pausedAudios) {
      PlayingSounds().replayAudio(audio);
      AudioServiceCommands.play(audio);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void pauseAllSound() async {
    final playingAudios = PlayingSounds().playingAudios.toList();
    for (final audio in playingAudios) {
      PlayingSounds().pauseAudio(audio);
      AudioServiceCommands.stop(audio);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void setMasterVolume(double value) async {
    setState(() {
      PlayingSounds().masterVolume = value;
    });

    final playingAudios = PlayingSounds().playingAudios;
    for (final audio in playingAudios) {
      AudioServiceCommands.setVolume(
          audio, audio.volume * PlayingSounds().masterVolume,
          global: true);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}
