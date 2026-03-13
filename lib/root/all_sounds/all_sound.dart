import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:rolify/data/audios.dart';
import 'package:rolify/entities/audio.dart';
import 'package:rolify/presentation_logic_holders/audio_list_bloc/audio_list_bloc.dart';
import 'package:rolify/presentation_logic_holders/audio_list_bloc/audio_list_state.dart';
import 'package:rolify/presentation_logic_holders/event_bus/stop_all_event_bus.dart';
import 'package:rolify/presentation_logic_holders/playing_sounds_singleton.dart';
import 'package:rolify/presentation_logic_holders/singletons/app_state.dart';
import 'package:rolify/root/info_page.dart';
import 'package:rolify/src/components/button.dart';
import 'package:rolify/src/components/my_icons.dart';
import 'package:rolify/src/components/player_card.dart';

import 'search_bar.dart';
import 'global_controls.dart';
import 'package:rolify/src/theme/texts.dart';

class AllSound extends StatefulWidget {
  const AllSound({Key? key}) : super(key: key);

  @override
  AllSoundState createState() => AllSoundState();
}

class AllSoundState extends State<AllSound> with WidgetsBindingObserver {
  static const platform = MethodChannel('rolify/file_picker');
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                      itemCount: (filteredAudios.length / 3).ceil(),
                      itemBuilder: (context, index) {
                        int start = index * 3;
                        int end = (index + 1) * 3;
                        if (end > filteredAudios.length) end = filteredAudios.length;
                        
                        List<Audio> rowAudios = filteredAudios.sublist(start, end);
                        
                        return Wrap(
                          children: rowAudios.map((e) => PlayerWidget(
                            key: Key('${e.path}_all_sounds'),
                            audio: e,
                          )).toList(),
                        );
                      },
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

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: NeumorphicTheme.baseColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: MyText.body('Add audio', fontWeight: FontWeight.bold),
              ),
              _OptionTile(
                icon: MyIcons.list(),
                title: 'Browse files',
                subtitle: 'Select audio from your storage',
                onTap: () {
                  Navigator.pop(context);
                  _pickFilesNative();
                },
              ),
              _OptionTile(
                icon: MyIcons.edit,
                title: 'Enter file path',
                subtitle: 'Manually input the local path',
                onTap: () {
                  Navigator.pop(context);
                  _showManualPathInput();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFilesNative() async {
    try {
      final List<dynamic>? result = await platform.invokeMethod('pickAudioFiles');
      if (result != null) {
        List<Map<String, String>> audioItems = [];
        for (var item in result) {
          if (item is Map) {
            audioItems.add({
              'name': item['name']?.toString() ?? '',
              'path': item['path']?.toString() ?? '',
            });
          }
        }
        if (audioItems.isNotEmpty) {
          _addAudiosWithNames(audioItems);
        }
      }
    } on PlatformException catch (e) {
      debugPrint("Error picking files: ${e.message}");
    }
  }

  void _showManualPathInput() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeumorphicTheme.baseColor(context),
        title: MyText.body('Enter file path', fontWeight: FontWeight.bold),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '/storage/emulated/0/Music/audio.mp3',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: MyText.body('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _addAudiosByPaths([controller.text]);
              }
              Navigator.pop(context);
            },
            child: MyText.body('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addAudiosByPaths(List<String> paths) async {
    final List<Map<String, String>> items = paths.map((path) => {
      'name': removeFileExtension(path),
      'path': path,
    }).toList();
    _addAudiosWithNames(items);
  }

  Future<void> _addAudiosWithNames(List<Map<String, String>> items) async {
    final allAudios = await AudioData.getAllAudios();
    bool added = false;
    
    for (var item in items) {
      final name = item['name']!;
      final path = item['path']!;
      
      final audio = Audio(
        name: name,
        path: path,
        audioSource: LocalAudioSource.file,
      );
      
      if (!allAudios.any((e) => e.path == audio.path)) {
        allAudios.add(audio);
        added = true;
      }
    }
    
    if (added) {
      await AudioData.saveAllAudios(context, allAudios);
      resetTextFilter(context);
    }
  }

  void resetTextFilter(BuildContext context) {
    focusNode.unfocus();
    filterController.clear();
    filterAudios(context);
  }

  filterAudios(BuildContext context) async {
    final allAudios = await AudioData.getAllAudios();

    List<Audio> newFilteredAudios = allAudios;
    if (filterController.text != '') {
      newFilteredAudios =
          filterAudiosByText(newFilteredAudios, filterController.text);
    }
    newFilteredAudios
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    
    if (mounted) {
      setState(() {
        filteredAudios = newFilteredAudios;
      });
    }
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

class _OptionTile extends StatelessWidget {
  final Widget icon;
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
    return ListTile(
      leading: Neumorphic(
        style: const NeumorphicStyle(
          boxShape: NeumorphicBoxShape.circle(),
          depth: 2,
        ),
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          width: 24,
          height: 24,
          child: icon,
        ),
      ),
      title: MyText.body(title, fontWeight: FontWeight.w600),
      subtitle: MyText.caption(subtitle, textType: TextType.secondary),
      onTap: onTap,
    );
  }
}

