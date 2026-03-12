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

  @override
  void initState() {
    super.initState();
    initAudios();
    playlistNameController.text = widget.playlist.name;
    color = widget.playlist.color;
  }

  initAudios() {
    AudioData.getAllAudios().then((value) {
      setState(() {
        audios = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Playlist'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: savePlaylist,
          ),
          if (widget.playlist.name != '')
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: removePlaylist,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: playlistNameController,
                decoration: const InputDecoration(
                  labelText: 'Playlist Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            if (audios == null)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: audios!.length,
                  padding: const EdgeInsets.all(16),
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final audio = audios![index];
                    final isAdded = widget.playlist.audios.contains(audio);
                    return ListTile(
                      title: Text(audio.name),
                      subtitle: Text(audio.path, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: Icon(isAdded ? Icons.remove_circle : Icons.add_circle,
                            color: isAdded ? Colors.red : Colors.green),
                        onPressed: isAdded
                            ? () => removeSoundFromPlaylist(audio)
                            : () => addSoundToPlaylist(audio),
                      ),
                    );
                  },
                ),
              ),
          ],
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

  removeSoundFromPlaylist(Audio audio) {
    widget.playlist.audios.remove(audio);

    if (widget.playlist.audios.isEmpty) {
      removePlaylist();
    } else {
      PlaylistData.savePlaylist(context, widget.playlist).then((_) {
        initAudios();
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
