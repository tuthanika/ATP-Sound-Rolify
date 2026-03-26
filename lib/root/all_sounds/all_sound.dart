import 'dart:io'; // Để xử lý xóa File vật lý

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
import 'package:rolify/presentation_logic_holders/audio_service_commands.dart'; // import để gọi hàm play cơ bản
import 'package:rolify/presentation_logic_holders/audio_download_manager.dart'; // Để gọi hàm tải File

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

                // === DÃY NÚT ĐIỀU KHIỂN FOLDER ===
                if (widget.folderName != null && items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _FolderActionButton(
                          icon: Icons.all_inclusive_rounded,
                          label: 'Tất cả',
                          onTap: () {
                            final audios = filteredItems.whereType<Audio>().toList();
                            for (var a in audios) {
                              AudioServiceCommands.play(a); // Mix phát song song
                            }
                          },
                        ),
                        _FolderActionButton(
                          icon: Icons.low_priority_rounded,
                          label: 'Tuần tự',
                          onTap: () {
                            final audios = filteredItems.whereType<Audio>().toList();
                            AppState().audioHandler.customAction('play_special_folder', {
                              'folderName': widget.folderName,
                              'mode': 'sequential',
                              'audios': audios.map((a) => a.toJson()).toList(),
                            });
                          },
                        ),
                        _FolderActionButton(
                          icon: Icons.shuffle_rounded,
                          label: 'Ngẫu nhiên',
                          onTap: () {
                            final audios = filteredItems.whereType<Audio>().toList();
                            AppState().audioHandler.customAction('play_special_folder', {
                              'folderName': widget.folderName,
                              'mode': 'random',
                              'audios': audios.map((a) => a.toJson()).toList(),
                            });
                          },
                        ),
                        _FolderActionButton(
                          icon: Icons.stop_rounded,
                          label: 'Dừng',
                          onTap: () {
                            final audios = filteredItems.whereType<Audio>().toList();
                            AppState().audioHandler.customAction('stop_special_folder', {
                              'folderName': widget.folderName,
                              'audios': audios.map((a) => a.toJson()).toList(),
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                // ==================================

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
                  _pickFilesNative(); // Gọi hàm thêm từ máy
                },
              ),
              _OptionTile(
                icon: MyIcons.edit(),
                title: 'Enter file path / URL',
                subtitle: 'Manually input path or web link',
                onTap: () {
                  Navigator.pop(context);
                  _showManualPathInput(); // Gọi hàm nhập Link/URL
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // HÀM 1: LẤY FILE TỪ BỘ NHỚ MÁY (LOGIC GỐC ĐƯỢC GIỮ NGUYÊN)
  Future<void> _pickFilesNative() async {
    try {
      final List<dynamic>? result = await platform.invokeMethod('pickAudioFiles');
      if (result != null) {
        // Dùng Map<String, dynamic> để đồng bộ với hàm _addAudiosWithNames mới
        List<Map<String, dynamic>> audioItems = [];
        for (var item in result) {
          if (item is Map) {
            audioItems.add({
              'name': item['name']?.toString() ?? '',
              'path': item['path']?.toString() ?? '',
              'isOfflineMode': true, // File từ máy thì mặc định là Offline
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

  // HÀM 2: NHẬP URL BẰNG TAY (CÓ CHECKBOX LƯU OFFLINE)
  void _showManualPathInput() {
    final controller = TextEditingController();
    bool saveOffline = true; // Cờ mặc định là tích chọn

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: MyText.body('Enter file path / URL', fontWeight: FontWeight.bold),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'https://.../audio.mp3',
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Lưu Offline vào máy (Cache)', style: TextStyle(fontSize: 14)),
                  value: saveOffline,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (val) {
                    setStateDialog(() => saveOffline = val ?? true);
                  },
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: MyText.body('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    Navigator.pop(context); // Đóng hộp thoại trước
                    await _addAudiosByPathsWithFlag([text], saveOffline); // Thêm lệnh await vào đây
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: MyText.body('Add'),
              ),
            ],
          );
        }
      ),
    );
  }

  // Helper method added to fix build error
  Future<void> _addAudiosByPathsWithFlag(List<String> paths, bool saveOffline) async {
    final List<Map<String, dynamic>> pickItems = paths.map((path) {
      String rawName = "Âm thanh mới";
      path = path.trim(); // Cắt khoảng trắng thừa chống lỗi
      
      try {
        final uri = Uri.parse(path);
        if (uri.pathSegments.isNotEmpty && uri.pathSegments.last.isNotEmpty) {
          rawName = uri.pathSegments.last;
        } else {
          rawName = path.split('/').last;
        }
      } catch (e) {
        rawName = path.split('/').last;
      }

      rawName = rawName.split('?').first; 
      if (rawName.trim().isEmpty) rawName = "Âm thanh mới";

      return {
        'name': rawName,
        'path': path,
        'isOfflineMode': saveOffline,
      };
    }).toList();
    
    await _addAudiosWithNames(pickItems); // QUAN TRỌNG: Thêm await ở đây
  }

Future<void> _addAudiosByPaths(List<String> paths) async {
    await _addAudiosByPathsWithFlag(paths, true); // Mặc định là lưu offline
  }

  // HÀM MỚI: ĐỔI PATH CỦA AUDIO ĐÃ CÓ
  void _changeAudioPath(Audio oldAudio) {
    final controller = TextEditingController();
    bool saveOffline = oldAudio.isOfflineMode;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: MyText.body('Đổi nguồn âm thanh', fontWeight: FontWeight.bold),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: 'Nhập URL / Path mới...'),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Lưu Offline', style: TextStyle(fontSize: 14)),
                  value: saveOffline,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (val) {
                    setStateDialog(() => saveOffline = val ?? true);
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Chọn file từ máy để lấy Path
                    final List<dynamic>? result = await platform.invokeMethod('pickAudioFiles');
                    if (result != null && result.isNotEmpty) {
                      final item = result.first as Map;
                      controller.text = item['path']?.toString() ?? '';
                    }
                  },
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Chọn từ bộ nhớ máy'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: MyText.body('Hủy'),
              ),
              TextButton(
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    Navigator.pop(context); // Tắt hộp thoại trước
                    
                    // 1. Dừng nhạc đang phát
                    AudioServiceCommands.stop(oldAudio);
                    
                    // 2. Xóa file Cache cũ nếu có
                    if (oldAudio.path.contains('/cloud_audios/')) {
                      try {
                        final file = File(oldAudio.path);
                        if (await file.exists()) await file.delete();
                      } catch (_) {}
                    }

                    // 3. Lấy path mới (Kiểm tra xem path mới là URL thì cần tải không)
                    String newPath = controller.text;
                    if (newPath.startsWith('http')) {
                       // Gọi Manager để tải hoặc cache file mới
                       final downloadedPath = await AudioFileManager.processPath(
                           newPath, oldAudio.name, saveOffline
                       );
                       if (downloadedPath != null) {
                         newPath = downloadedPath;
                       } else {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi tải file mới!')));
                         return; // Thất bại thì không đổi
                       }
                    }

                    // 4. Cập nhật Model và lưu Database
                    final allAudios = await AudioData.getAllAudios();
                    final index = allAudios.indexWhere((a) => a.path == oldAudio.path);
                    if (index != -1) {
                      final updatedAudio = allAudios[index].copyFrom(
                        path: newPath, 
                        isOfflineMode: saveOffline
                      );
                      allAudios[index] = updatedAudio;
                      
                      await AudioData.saveAllAudios(context, allAudios);
                      BlocProvider.of<AudioListBloc>(context).add(AudioListUpdate(allAudios));
                      
                      // 5. Nếu đang phát dở thì phát lại bằng link mới
                      AudioServiceCommands.play(updatedAudio);
                    }
                  }
                },
                child: MyText.body('Lưu'),
              ),
            ],
          );
        }
      ),
    );
  }
  
  // --- HÀM TỰ ĐỘNG LÀM ĐẸP TÊN AUDIO ---
  String _formatAudioName(String rawName) {
    // 1. Xóa các đuôi mở rộng phổ biến (không phân biệt hoa thường)
    String cleanName = rawName.replaceAll(RegExp(r'\.(mp3|wav|ogg|m4a|flac|aac|wma)$', caseSensitive: false), '');
    
    // 2. Thay thế dấu gạch dưới (_) và gạch ngang (-) thành dấu cách
    //cleanName = cleanName.replaceAll('_', ' ').replaceAll('-', ' ');
    
    // 3. Xóa khoảng trắng thừa ở 2 đầu
    return cleanName.trim();
  }

  // HÀM XỬ LÝ LƯU DATA CHUNG
Future<void> _addAudiosWithNames(List<Map<String, dynamic>> items) async {
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
        
        if (targetFolder == null || targetFolder.trim().isEmpty) return; 
      }
    }

    final allAudios = await AudioData.getAllAudios();
    bool added = false;
    
    for (var item in items) {
      final rawName = item['name'] as String;
      final sourcePath = item['path'] as String;
      final isOffline = item['isOfflineMode'] as bool? ?? true;

      // --- SỬ DỤNG HÀM LÀM ĐẸP TÊN TẠI ĐÂY ---
      final formattedName = _formatAudioName(rawName);

      // CHỈ LƯU URL VÀO DATABASE, KHÔNG TẢI GÌ CẢ (Add siêu tốc)
      final audio = Audio(
        name: formattedName, 
        path: sourcePath, // Bảo toàn URL
        audioSource: LocalAudioSource.file,
        folderName: targetFolder, 
        isOfflineMode: isOffline, 
      );
      
      if (!allAudios.any((e) => e.path == audio.path)) {
        allAudios.add(audio);
        added = true;
      }
    }
    
    if (added) {
      await AudioData.saveAllAudios(context, allAudios);
      resetTextFilter(context);
      if (mounted) {
        // Ép Bloc và UI nhận diện thay đổi tức thì
        BlocProvider.of<AudioListBloc>(context).add(AudioListUpdate(List.from(allAudios)));
        initAudios(); 
      }
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
      AudioServiceCommands.stop(item);
      
      // BẢO VỆ DỮ LIỆU: Chỉ xóa file vật lý NẾU path gốc là URL
      if (item.path.startsWith('http')) {
        await AudioFileManager.deleteLocalFile(item.name); // <-- Bỏ item.isOfflineMode
      }
      
      allAudios.removeWhere((a) => a.path == item.path);
    } else if (item is AudioFolder) {
      for (var audio in item.audios) {
        AudioServiceCommands.stop(audio);
        
        // BẢO VỆ DỮ LIỆU: Chỉ xóa file vật lý (Cache/Offline) NẾU path gốc là URL
        if (audio.path.startsWith('http')) {
          await AudioFileManager.deleteLocalFile(audio.name); // <-- Cũng chỉ truyền mỗi name
        }
      }
      allAudios.removeWhere((a) => a.folderName == item.name);
    }

    await AudioData.saveAllAudios(context, allAudios);
    
    if (mounted) {
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

// --- WIDGET NÚT HÀNH ĐỘNG CHO FOLDER ---
class _FolderActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FolderActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colorScheme.primary, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
