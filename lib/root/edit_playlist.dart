import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:rolify/data/audios.dart';
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
  List<Audio>? audios;
  Color? color;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    playlistNameController.text = widget.playlist.name;
    color = widget.playlist.color;
    
    // Delay initialization to avoid blocking the navigation animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () => initAudios());
    });
  }

  void initAudios() async {
    try {
      final value = await AudioData.getAllAudios();
      if (mounted) {
        setState(() {
          audios = value;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading audios in EditPlaylist: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeumorphicTheme.currentTheme(context).baseColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Neumorphic(
                style: NeumorphicStyle(
                  boxShape: NeumorphicBoxShape.roundRect(
                      const BorderRadius.all(Radius.circular(16.0))),
                ),
                child: Padding(
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
                              hintText: 'Playlist name',
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          MyButton(icon: MyIcons.done, onTap: savePlaylist),
                          if (widget.playlist.name.isNotEmpty) ...[
                            const SizedBox(width: 12.0),
                            MyButton(
                                icon: MyIcons.delete, onTap: removePlaylist),
                          ]
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      ColorSelection(
                        onChange: (value) {
                          setState(() {
                            color = color == value ? null : value;
                          });
                        },
                        colors: const <Color>[
                          Color(0xFFFF8A80), // Colors.redAccent[100]
                          Color(0xFFFF9E80), // Colors.deepOrangeAccent[100]
                          Color(0xFFFFD180), // Colors.amberAccent[100]
                          Color(0xFFB9F6CA), // Colors.greenAccent[100]
                          Color(0xFF84FFFF), // Colors.cyanAccent[100]
                          Color(0xFF82B1FF), // Colors.blueAccent[100]
                          Color(0xFFB388FF), // Colors.deepPurpleAccent[100]
                        ],
                        groupValue: color,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (audios == null || audios!.isEmpty)
                        ? const Center(child: Text('No audios found'))
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            itemCount: audios!.length,
                            itemBuilder: (context, index) {
                              final audio = audios![index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: _AudioRow(
                                  playlist: widget.playlist,
                                  audio: audio,
                                  onAdd: () => addSoundToPlaylist(audio),
                                  onRemove: () => removeSoundFromPlaylist(audio),
                                ),
                              );
                            },
                          ),
              )
            ],
          ),
        ),
      ),
    );
  }

  savePlaylist() async {
    final name = playlistNameController.text.trim();
    if (name.isEmpty) return;

    await PlaylistData.removePlaylist(context, widget.playlist);
    if (widget.playlist.audios.isNotEmpty) {
      await PlaylistData.savePlaylist(
          context,
          widget.playlist.copyFrom(name: name, color: color));
    }
    Navigator.pop(context);
  }

  removePlaylist() {
    PlaylistData.removePlaylist(context, widget.playlist);
    Navigator.pop(context);
  }

  void addSoundToPlaylist(Audio audio) {
    setState(() {
      widget.playlist.audios.add(audio);
    });

    PlaylistData.savePlaylist(context, widget.playlist).then((_) {
      // Data saved, UI updated locally via setState
    });
  }

  void removeSoundFromPlaylist(Audio audio) {
    setState(() {
      widget.playlist.audios.remove(audio);
    });

    if (widget.playlist.audios.isEmpty) {
      removePlaylist();
    } else {
      PlaylistData.savePlaylist(context, widget.playlist).then((_) {
        // Data saved, UI updated locally via setState
      });
    }
  }
}

class _AudioRow extends StatelessWidget {
  const _AudioRow({
    Key? key,
    required this.playlist,
    required this.audio,
    required this.onAdd,
    required this.onRemove,
  }) : super(key: key);

  final Playlist playlist;
  final Audio audio;
  final Function() onAdd, onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: MyText.body(
            audio.name,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(
          width: 16.0,
        ),
        MyButton(
          icon: playlist.audios.contains(audio)
              ? MyIcons.playlistDelete
              : MyIcons.playlistAdd,
          onTap: playlist.audios.contains(audio) ? onRemove : onAdd,
        ),
      ],
    );
  }
}
