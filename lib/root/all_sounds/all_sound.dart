import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:rolify/data/audios.dart';
import 'package:rolify/entities/audio.dart';
import 'package:rolify/presentation_logic_holders/audio_list_bloc/audio_list_bloc.dart';
import 'package:rolify/presentation_logic_holders/audio_list_bloc/audio_list_state.dart';
import 'package:rolify/presentation_logic_holders/event_bus/stop_all_event_bus.dart';
import 'package:rolify/presentation_logic_holders/playing_sounds_singleton.dart';
import 'package:rolify/presentation_logic_holders/singletons/app_state.dart';
import 'package:rolify/src/components/button.dart';
import 'package:rolify/src/components/my_icons.dart';
import 'package:rolify/src/components/player_card.dart';
import 'package:rolify/src/theme/texts.dart';

import 'search_bar.dart';
import 'global_controls.dart';

const _supportedExtensions = [
  'mp3',
  'wav',
  'ogg',
  'flac',
  'm4a',
  'aac',
  'wma',
  'opus'
];

class AllSound extends StatefulWidget {
  const AllSound({Key? key}) : super(key: key);

  @override
  AllSoundState createState() => AllSoundState();
}

class AllSoundState extends State<AllSound> with WidgetsBindingObserver {
  List<Audio> audios = [], filteredAudios = [];
  TextEditingController filterController = TextEditingController();
  FocusNode focusNode = FocusNode();
  bool pauseAll = true, audioToPauseExist = false, audioToReplayExist = false;

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
      }
    });
    eventBus.on<AudioPaused>().listen((event) {
      if (mounted) {
        setState(() {
          audioToPauseExist = PlayingSounds().playingAudios.isNotEmpty;
          audioToReplayExist = PlayingSounds().pausedAudios.isNotEmpty;
          pauseAll = audioToPauseExist;
        });
      }
    });
    initAudios();
  }

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
    await AudioData.addNewAssetsAudios(context);
    final allAudios = await AudioData.getAllAudios();
    allAudios
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (mounted) {
      setState(() {
        audios = allAudios;
        filteredAudios = allAudios;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AudioListBloc, AudioListState>(
      listener: (BuildContext context, state) {
        if (state is AudioListEdited) initAudios();
      },
      child: Stack(
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 56 * heightFactor,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Row(
                        children: <Widget>[
                          MySearchBar(
                            filterController: filterController,
                            focusNode: focusNode,
                            filterAudios: filterAudios,
                            resetTextFilter: resetTextFilter,
                          ),
                          const SizedBox(width: 8.0),
                          MyButton(
                            icon: MyIcons.add,
                            onTap: () => _showAddOptions(context),
                          )
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 148),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredAudios.length,
                      itemBuilder: (context, index) => PlayerWidget(
                        key: Key('${filteredAudios[index].path}_all_sounds'),
                        audio: filteredAudios[index],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  vertical: 16.0 * heightFactor, horizontal: 16.0),
              child: GlobalControls(
                  pauseAll: pauseAll,
                  playPauseEnabled: playPauseEnabled,
                  setPauseAll: (value) {
                    setState(() {
                      pauseAll = value;
                    });
                  }),
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

  filterAudios(BuildContext context) {
    List<Audio> newFilteredAudios = audios;
    if (filterController.text != '') {
      newFilteredAudios =
          filterAudiosByText(newFilteredAudios, filterController.text);
    }
    newFilteredAudios
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    setState(() {
      filteredAudios = newFilteredAudios;
    });
  }

  filterAudiosByText(List<Audio> audios, String text) {
    return audios
        .where((audio) => audio.name.toLowerCase().contains(text.toLowerCase()))
        .toList();
  }

  /// Show a bottom sheet with two options: pick file or enter path manually
  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: NeumorphicTheme.currentTheme(context).baseColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MyText.body('Add audio', fontWeight: FontWeight.bold),
              const SizedBox(height: 20),
              _OptionTile(
                icon: Icons.folder_open,
                title: 'Browse files',
                subtitle: 'Open file picker to select audio files',
                onTap: () {
                  Navigator.pop(ctx);
                  _openFileExplorer(context);
                },
              ),
              const SizedBox(height: 12),
              _OptionTile(
                icon: Icons.link,
                title: 'Enter file path',
                subtitle: 'Paste or type the full path to an audio file',
                onTap: () {
                  Navigator.pop(ctx);
                  _showPathInputDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// File picker: picks files by path reference (no cache copy)
  void _openFileExplorer(BuildContext context) async {
    List<PlatformFile>? paths;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: Theme.of(context).platform == TargetPlatform.android
            ? FileType.audio
            : FileType.custom,
        allowedExtensions:
            Theme.of(context).platform == TargetPlatform.android
                ? null
                : _supportedExtensions,
        allowMultiple: true,
        // Do NOT read bytes - just return the path reference
        withData: false,
        withReadStream: false,
      );
      paths = result?.files;
    } on PlatformException catch (e) {
      debugPrint("Unsupported operation $e");
    }
    if (!mounted || paths == null) return;
    await _addAudiosByPaths(
        paths.where((f) => f.path != null).map((f) => f.path!).toList());
  }

  /// Manual path input dialog
  void _showPathInputDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeumorphicTheme.currentTheme(context).baseColor,
        title: MyText.body('Enter file path', fontWeight: FontWeight.bold),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '/path/to/audio.mp3',
            hintStyle: TextStyle(
              color: NeumorphicTheme.currentTheme(context).disabledColor,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: (value) async {
            Navigator.pop(ctx);
            if (value.trim().isNotEmpty) {
              await _addAudiosByPaths([value.trim()]);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final path = controller.text.trim();
              Navigator.pop(ctx);
              if (path.isNotEmpty) {
                await _addAudiosByPaths([path]);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Add audio files by absolute path references (no copying to cache)
  Future<void> _addAudiosByPaths(List<String> paths) async {
    if (!mounted) return;
    final allAudios = await AudioData.getAllAudios();
    bool added = false;
    for (final path in paths) {
      final name = removeFileExtension(path);
      final audio = Audio(
        name: name,
        path: path,
        audioSource: LocalAudioSource.file,
      );
      if (allAudios.contains(audio) == false) {
        allAudios.add(audio);
        added = true;
      }
    }
    if (added && mounted) {
      AudioData.saveAllAudios(context, allAudios).then((_) {
        resetTextFilter(context);
      });
    }
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon,
                size: 32,
                color: NeumorphicTheme.currentTheme(context).accentColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText.body(title, fontWeight: FontWeight.w600),
                  MyText.caption(subtitle,
                      textType: TextType.secondary,
                      fontWeight: FontWeight.normal),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
