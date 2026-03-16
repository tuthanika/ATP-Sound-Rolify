import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:rolify/data/playlist.dart';
import 'package:rolify/entities/audio.dart';
import 'package:rolify/entities/playlist.dart';
import 'package:rolify/src/components/button.dart';
import 'package:rolify/src/components/color_selection.dart';
import 'package:rolify/src/components/my_icons.dart';
import 'package:rolify/src/components/text_field.dart';
import 'package:rolify/src/theme/texts.dart';

class EditPlaylist extends StatefulWidget {
  final Playlist playlist;

  const EditPlaylist({Key? key, required this.playlist}) : super(key: key);

  @override
  EditPlaylistState createState() => EditPlaylistState();
}

class EditPlaylistState extends State<EditPlaylist> {
  final playlistNameController = TextEditingController();
  Color? color;

  @override
  void initState() {
    super.initState();
    playlistNameController.text = widget.playlist.name;
    color = widget.playlist.color;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeumorphicTheme.currentTheme(context).baseColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Neumorphic(
            style: NeumorphicStyle(
              boxShape: NeumorphicBoxShape.roundRect(
                  const BorderRadius.all(Radius.circular(16.0))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(child: MyText.title('Edit playlist')),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: MyIcons.close(),
                          )
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: MyTextField(
                              controller: playlistNameController,
                              hintText: 'Create a new playlist...',
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          MyButton(icon: MyIcons.done, onTap: savePlaylist),
                          const SizedBox(width: 12.0),
                          MyButton(icon: MyIcons.delete, onTap: removePlaylist),
                        ],
                      ),
                    ],
                  ),
                ),
                ColorSelection(
                  onChange: (value) {
                    setState(() {
                      color = color == value ? null : value;
                    });
                  },
                  colors: <Color>[
                    Colors.redAccent[100]!,
                    Colors.deepOrangeAccent[100]!,
                    Colors.amberAccent[100]!,
                    Colors.greenAccent[100]!,
                    Colors.cyanAccent[100]!,
                    Colors.blueAccent[100]!,
                    Colors.deepPurpleAccent[100]!,
                  ],
                  groupValue: color,
                ),
                if (widget.playlist.audios.isNotEmpty)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List.generate(
                          widget.playlist.audios.length,
                          (index) {
                            final audio = widget.playlist.audios[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: _AudioRow(
                                playlist: widget.playlist,
                                audio: audio,
                                onRemove: () => removeSoundFromPlaylist(audio),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  savePlaylist() async {
    await PlaylistData.removePlaylist(context, widget.playlist);
    if (widget.playlist.audios.isNotEmpty) {
      await PlaylistData.savePlaylist(
          context,
          widget.playlist
              .copyFrom(name: playlistNameController.text, color: color));
    }
    Navigator.pop(context);
  }

  removePlaylist() {
    PlaylistData.removePlaylist(context, widget.playlist);
    Navigator.pop(context);
  }

  addSoundToPlaylist(Audio audio) {
    widget.playlist.audios.add(audio);

    PlaylistData.savePlaylist(context, widget.playlist).then((_) {
      initAudios();
    });
  }

  void removeSoundFromPlaylist(Audio audio) {
  setState(() {
    widget.playlist.audios.remove(audio);
  });

  if (widget.playlist.audios.isEmpty) {
    removePlaylist();
  } else {
    PlaylistData.savePlaylist(context, widget.playlist);
  }
}
}

class _AudioRow extends StatelessWidget {
  const _AudioRow({
    Key? key,
    required this.playlist,
    required this.audio,
    required this.onRemove,
  }) : super(key: key);

  final Playlist playlist;
  final Audio audio;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MyText.body(
            audio.name,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16.0),
        MyButton(
          icon: MyIcons.playlistDelete,
          onTap: onRemove,
        ),
      ],
    );
  }
}