import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:rolify/data/audios.dart';
import 'package:rolify/entities/audio.dart';
import 'package:rolify/presentation_logic_holders/audio_list_bloc/audio_list_bloc.dart';
import 'package:rolify/presentation_logic_holders/audio_list_bloc/audio_list_state.dart';
import 'package:rolify/presentation_logic_holders/audio_list_bloc/audio_list_event.dart';
import 'package:rolify/presentation_logic_holders/event_bus/stop_all_event_bus.dart';
import 'package:rolify/presentation_logic_holders/playing_sounds_singleton.dart';
import 'package:rolify/presentation_logic_holders/singletons/app_state.dart';
import 'package:rolify/presentation_logic_holders/singletons/theme_mode_controller.dart';

import 'package:rolify/src/components/button.dart';
import 'package:rolify/src/components/my_icons.dart';
import 'package:rolify/src/components/player_card.dart'; // import FolderWidget và PlayerWidget

import 'search_bar.dart';
import 'global_controls.dart';
import 'package:rolify/src/theme/texts.dart';

class AllSound extends StatefulWidget {
  final String? folderName; // <-- Cho phép nhận folderName

  const AllSound({Key? key, this.folderName}) : super(key: key);

  @override
  AllSoundState createState() => AllSoundState();
}

class AllSoundState extends State<AllSound> with WidgetsBindingObserver {
  static const platform = MethodChannel('rolify/file_picker');
  
  // Đổi List<Audio> thành List<dynamic> để chứa cả Audio và AudioFolder
  List<dynamic> items = [], filteredItems = []; 
  
  TextEditingController filterController = TextEditingController();
  FocusNode focusNode = FocusNode();
  bool pauseAll = true, audioToPauseExist = false, audioToReplayExist = false;
  final ValueNotifier<bool> isControlsExpanded = ValueNotifier(false);

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

    List<dynamic> initialItems = [];
    if (widget.folderName == null) {
      // Màn hình chính: Nhóm các folder lại
      Map<String, List<Audio>> folders = {};
      List<Audio> standalones = [];
      for (var a in allAudios) {
        if (a.folderName != null && a.folderName!.isNotEmpty) {
          folders.putIfAbsent(a.folderName!, () => []).add(a);
        } else {
          standalones.add(a);
        }
      }
      initialItems.addAll(standalones);
      folders.forEach((key, val) => initialItems.add(AudioFolder(key, val)));
    } else {
      // Màn hình trong Folder: Chỉ lấy file thuộc folder
      initialItems = allAudios.where((a) => a.folderName == widget.folderName).toList();
    }

    _sortItems(initialItems);
    
    if (mounted) {
      setState(() {
        items = initialItems;
        filteredItems = initialItems;
      });
    }
  }

  void _sortItems(List<dynamic> list) {
    final mode = ThemeModeController().sortMode.value;
    if (mode == 0) {
      list.sort((a, b) {
        String nameA = a is AudioFolder ? a.name : (a as Audio).name;
        String nameB = b is AudioFolder ? b.name : (b as Audio).name;
        return nameA.toLowerCase().compareTo(nameB.toLowerCase());
      });
    } else {
      final reversed = list.reversed.toList();
      list.clear();
      list.addAll(reversed);
    }
  }

  filterAudios(BuildContext context) async {
    final allAudios = await AudioData.getAllAudios();
    List<dynamic> newFiltered = [];

    if (widget.folderName == null) {
      Map<String, List<Audio>> folders = {};
      List<Audio> standalones = [];
      for (var a in allAudios) {
        if (a.folderName != null && a.folderName!.isNotEmpty) {
          folders.putIfAbsent(a.folderName!, () => []).add(a);
        } else {
          standalones.add(a);
        }
      }
      newFiltered.addAll(standalones);
      folders.forEach((key, val) => newFiltered.add(AudioFolder(key, val)));
    } else {
      newFiltered = allAudios.where((a) => a.folderName == widget.folderName).toList();
    }

    if (filterController.text.isNotEmpty) {
      newFiltered = newFiltered.where((item) {
        String name = item is AudioFolder ? item.name : (item as Audio).name;
        return name.toLowerCase().contains(filterController.text.toLowerCase());
      }).toList();
    }

    _sortItems(newFiltered);
    
    if (mounted) {
      setState(() {
        filteredItems = newFiltered;
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
          Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (details) {
              if (isControlsExpanded.value) {
                isControlsExpanded.value = false;
              }
              focusNode.unfocus();
            },
            child: Column(
              children: <Widget>[
                Padding(
                  padding:
                      const EdgeInsets.only(top: 4.0, left: 12.0, right: 12.0, bottom: 0.0),
                  child: ValueListenableBuilder<int>(
                    valueListenable: ThemeModeController().sortMode,
                    builder: (context, sortMode, _) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: ThemeModeController().isCollapsed,
                        builder: (context, isCollapsed, _) {
                          return MySearchBar(
                            filterController: filterController,
                            focusNode: focusNode,
                            filterAudios: filterAudios,
                            resetTextFilter: resetTextFilter,
                            sortMode: sortMode,
                            onSortToggle: () {
                              final nextMode = (sortMode + 1) % 2;
                              ThemeModeController().setSortMode(nextMode);
                              initAudios();
                            },
                            isCollapsed: isCollapsed,
                            onLayoutToggle: () {
                              ThemeModeController()
                                  .setCollapsed(!isCollapsed);
                            },
                            onAddTap: () => _showAddOptions(context),
                          );
                        },
                      );
                    },
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: ThemeModeController().isCollapsed,
                    builder: (context, isCollapsed, _) {
                      return GridView.builder(
                        padding: const EdgeInsets.only(bottom: 148, top: 0, left: 12, right: 12),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: isCollapsed ? 3.0 : 1.15,
                        ),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          
                          // Trả về Widget tương ứng với loại Data
                          Widget childWidget = const SizedBox.shrink();
                          String itemKey = '';

                          // 1. Dựng UI thẻ như bình thường
                          if (item is Audio) {
                            itemKey = item.path;
                            childWidget = PlayerWidget(
                              key: Key('${item.path}_all_sounds'),
                              audio: item,
                              isCollapsedLayout: isCollapsed,
                            );
                          } else if (item is AudioFolder) {
                            itemKey = item.name;
                            childWidget = FolderWidget(
                              folder: item,
                              isCollapsedLayout: isCollapsed,
                              onEdit: () => _renameFolder(item.name), // Gọi hàm đổi tên trực tiếp trên thẻ
                              onTapList: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Scaffold(
                                      appBar: AppBar(
                                        title: Text(item.name),
                                        backgroundColor: Theme.of(context).colorScheme.surface,
                                        elevation: 0,
                                        actions: [
                                          IconButton(
                                            icon: const Icon(Icons.edit), // Nút đổi tên trên Appbar (trong Folder)
                                            onPressed: () async {
                                              final newName = await _renameFolder(item.name);
                                              // Nếu đổi tên thành công, tự thoát ra ngoài để cập nhật lại danh sách gốc
                                              if (newName != null && context.mounted) {
                                                Navigator.pop(context); 
                                              }
                                            },
                                          )
                                        ],
                                      ),
                                      body: AllSound(folderName: item.name),
                                    ),
                                  ),
                                );
                              },
                            );
                          }

                          // 2. NẾU Ở CHẾ ĐỘ THU GỌN: Bọc thêm Dismissible để vuốt xóa
                          if (isCollapsed && childWidget is! SizedBox) {
                            return Dismissible(
                              key: Key('dismiss_$itemKey'),
                              direction: DismissDirection.endToStart, // Chỉ cho vuốt từ Phải sang Trái
                              background: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.error,
                                  borderRadius: BorderRadius.circular(20), // Bo góc cho khớp với thẻ
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20.0),
                                child: const Icon(Icons.delete_outline, color: Colors.white),
                              ),
                              confirmDismiss: (direction) async {
                                final isFolder = item is AudioFolder;
                                final name = isFolder ? item.name : (item as Audio).name;
                                
                                // Hiện hộp thoại xác nhận trước khi xóa
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Theme.of(context).colorScheme.surface,
                                    title: const Text('Xác nhận xóa'),
                                    content: Text('Bạn có chắc chắn muốn xóa ${isFolder ? 'nhóm' : 'âm thanh'} "$name" không?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Hủy'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (direction) {
                                _deleteItem(item); // Gọi hàm xóa đã tạo ở trên
                              },
                              child: childWidget,
                            );
                          }

                          // Nếu ở chế độ phóng to, trả về thẻ bình thường không cho vuốt
                          return childWidget;
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isControlsExpanded,
            builder: (context, isExpanded, _) {
              return Align(
                alignment: Alignment.bottomCenter,
                child: ValueListenableBuilder<int>(
                  valueListenable: PlayingSounds().stateChangeNotifier,
                  builder: (context, _, __) {
                    return GlobalControls(
                      isExpanded: isExpanded,
                      onExpandChanged: (value) => isControlsExpanded.value = value,
                      pauseAll: PlayingSounds().playingAudios.isNotEmpty,
                      playPauseEnabled: items.isNotEmpty ||
                          PlayingSounds().playingAudios.isNotEmpty,
                      setPauseAll: (value) => setState(() {}),
                    );
                  }
                ),
              );
            },
          )
        ],
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                icon: MyIcons.edit(),
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
        backgroundColor: Theme.of(context).colorScheme.surface,
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
    final List<Map<String, String>> pickItems = paths.map((path) => {
      'name': removeFileExtension(path),
      'path': path,
    }).toList();
    _addAudiosWithNames(pickItems);
  }

  Future<void> _addAudiosWithNames(List<Map<String, String>> items) async {
    String? targetFolder = widget.folderName;

    // Nếu đang ở màn hình chính và thêm > 1 file -> Hỏi xem có gộp nhóm không
    if (widget.folderName == null && items.length > 1) {
      bool? isGroup = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Thêm nhiều âm thanh'),
          content: const Text('Bạn muốn thêm từng âm thanh riêng lẻ hay gom chúng thành một Nhóm (Folder) mới?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Riêng lẻ'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tạo nhóm'),
            ),
          ],
        ),
      );

      // Nếu người dùng chọn Tạo Nhóm -> Hiện ô nhập tên
      if (isGroup == true) {
        final folderNameController = TextEditingController();
        targetFolder = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: const Text('Tên nhóm mới'),
            content: TextField(
              controller: folderNameController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Nhập tên nhóm...'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, folderNameController.text),
                child: const Text('Xong'),
              ),
            ],
          ),
        );
        
        // Nếu nhấn huỷ nhập tên thư mục -> huỷ thêm file luôn
        if (targetFolder == null || targetFolder.trim().isEmpty) {
          return; 
        }
      }
    }

    final allAudios = await AudioData.getAllAudios();
    bool added = false;
    
    for (var item in items) {
      final name = item['name']!;
      final path = item['path']!;
      
      final audio = Audio(
        name: name,
        path: path,
        audioSource: LocalAudioSource.file,
        folderName: targetFolder, // Gán folderName
      );
      
      if (!allAudios.any((e) => e.path == audio.path)) {
        allAudios.add(audio);
        added = true;
      }
    }
    
    if (added) {
      await AudioData.saveAllAudios(context, allAudios);
      resetTextFilter(context);
      
      // Notify components to update
      BlocProvider.of<AudioListBloc>(context).add(AudioListUpdate(allAudios));
    }
  }

  void resetTextFilter(BuildContext context) {
    focusNode.unfocus();
    filterController.clear();
    filterAudios(context);
  }

  // --- HÀM XỬ LÝ XÓA ÂM THANH / NHÓM ---
  Future<void> _deleteItem(dynamic item) async {
    final allAudios = await AudioData.getAllAudios();
    
    if (item is Audio) {
      // Dừng phát nếu đang phát
      AudioServiceCommands.stop(item);
      allAudios.removeWhere((a) => a.path == item.path);
    } else if (item is AudioFolder) {
      // Dừng tất cả âm thanh trong nhóm
      for (var audio in item.audios) {
        AudioServiceCommands.stop(audio);
      }
      allAudios.removeWhere((a) => a.folderName == item.name);
    }

    // Lưu lại danh sách mới
    await AudioData.saveAllAudios(context, allAudios);
    
    if (mounted) {
      // Cập nhật UI ngay lập tức
      setState(() {
        items.remove(item);
        filteredItems.remove(item);
      });
      BlocProvider.of<AudioListBloc>(context).add(AudioListUpdate(allAudios));
    }
  }

  // --- HÀM _renameFolder PHẢI NẰM Ở ĐÂY (BÊN TRONG AllSoundState) ---
  Future<String?> _renameFolder(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Đổi tên nhóm'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nhập tên mới...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (newName != null && newName.trim().isNotEmpty && newName != oldName) {
      final allAudios = await AudioData.getAllAudios();
      bool changed = false;
      
      for (int i = 0; i < allAudios.length; i++) {
        if (allAudios[i].folderName == oldName) {
          allAudios[i] = allAudios[i].copyFrom(folderName: newName.trim());
          changed = true;
        }
      }
      
      if (changed) {
        await AudioData.saveAllAudios(context, allAudios);
        if (mounted) {
          BlocProvider.of<AudioListBloc>(context).add(AudioListUpdate(allAudios));
        }
        return newName.trim();
      }
    }
    return null;
  }

} // <-- KẾT THÚC CLASS AllSoundState Ở ĐÂY

// --- PHẦN OPTION TILE BÊN DƯỚI ---
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
      leading: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
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