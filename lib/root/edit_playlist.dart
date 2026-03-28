import 'package:flutter/material.dart';
import 'dart:async';
import 'package:rolify/data/audios.dart';
import 'package:rolify/data/playlist.dart';
import 'package:rolify/entities/audio.dart';
import 'package:rolify/entities/playlist.dart';
import 'package:rolify/src/components/button.dart';
import 'package:rolify/src/components/color_selection.dart';
import 'package:rolify/src/components/my_icons.dart';
import 'package:rolify/src/components/text_field.dart';

class EditPlaylist extends StatefulWidget {
  final Playlist playlist;

  const EditPlaylist({Key? key, required this.playlist}) : super(key: key);

  @override
  EditPlaylistState createState() => EditPlaylistState();
}

class EditPlaylistState extends State<EditPlaylist> {
  final playlistNameController = TextEditingController();
  List<Audio> audios = [];
  List<Audio> filteredAudios = []; 
  Color? color;
  
  late Set<String> _playlistAudioPaths; 
  Set<String> _expandedFolders = {}; 
  
  String _searchQuery = '';
  int _sortType = 0; // 0: Mới nhất, 1: A-Z, 2: Z-A
  bool _showAllFlat = false; 
  Timer? _searchDebounce;

  // BẢN VÁ TỐI THƯỢNG CHỐNG ĐƠ: Danh sách phẳng trải dài để ListView.builder render siêu tốc
  List<dynamic> _flattenedList = [];

  @override
  void initState() {
    super.initState();
    _playlistAudioPaths = widget.playlist.audios.map((a) => a.path).toSet();
    initAudios();
    playlistNameController.text = widget.playlist.name;
    color = widget.playlist.color;
  }

  initAudios() {
    AudioData.getAllAudios().then((value) {
      if (mounted) {
        setState(() {
          audios = value;
          _applyFilters(notify: false);
        });
      }
    });
  }

  void _applyFilters({bool notify = true}) {
    var list = audios.where((a) => 
        a.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        
    if (_sortType == 0) {
      list = list.reversed.toList(); 
    } else if (_sortType == 1) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_sortType == 2) {
      list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    }
    
    filteredAudios = list;
    _buildFlattenedList();
    if (notify && mounted) setState(() {});
  }

  // Thuật toán chuẩn bị dữ liệu (Chạy 1 lần, render vạn lần không đơ)
  void _buildFlattenedList() {
    _flattenedList.clear();

    if (_showAllFlat) {
      _flattenedList.addAll(filteredAudios);
    } else {
      Map<String, List<Audio>> folders = {};
      List<Audio> standalones = [];
      
      for (var a in filteredAudios) {
        if (a.folderName != null && a.folderName!.isNotEmpty) {
          folders.putIfAbsent(a.folderName!, () => []).add(a);
        } else {
          standalones.add(a);
        }
      }

      List<String> sortedFolderNames = folders.keys.toList()..sort();

      for (var fName in sortedFolderNames) {
        _flattenedList.add({'type': 'folder', 'name': fName, 'audios': folders[fName]});
        if (_expandedFolders.contains(fName)) {
          for (var a in folders[fName]!) {
            _flattenedList.add({'type': 'child_audio', 'audio': a});
          }
        }
      }
      for (var a in standalones) {
        _flattenedList.add({'type': 'audio', 'audio': a});
      }
    }
  }

  void _cycleSort() {
    _sortType = (_sortType + 1) % 3;
    _applyFilters();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    playlistNameController.dispose();
    super.dispose();
  }

  IconData _getSortIcon() {
    switch (_sortType) {
      case 0: return Icons.access_time; 
      case 1: return Icons.sort_by_alpha; 
      case 2: return Icons.keyboard_arrow_up; 
      default: return Icons.sort;
    }
  }

  String _getSortText() {
    switch (_sortType) {
      case 0: return "Mới nhất";
      case 1: return "A - Z";
      case 2: return "Z - A";
      default: return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0), 
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.all(Radius.circular(16.0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), 
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Edit playlist', 
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)
                            )
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: MyIcons.close(),
                          )
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: SizedBox(
                              height: 48, 
                              child: MyTextField(
                                controller: playlistNameController,
                                hintText: 'Create a new playlist...',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          MyButton(icon: MyIcons.done(), onTap: savePlaylist),
                          const SizedBox(width: 8.0),
                          MyButton(icon: MyIcons.delete(), onTap: removePlaylist),
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
                
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm sound...',
                              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                              prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                              filled: true,
                              fillColor: isDark ? Colors.black26 : Colors.black12,
                              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (val) {
                              _searchDebounce?.cancel();
                              _searchDebounce = Timer(const Duration(milliseconds: 150), () {
                                if (!mounted) return;
                                _searchQuery = val;
                                if (val.isNotEmpty && !_showAllFlat) _showAllFlat = true;
                                _applyFilters();
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // BẢN VÁ: NÚT SORT ĐÃ THÀNH ICON XOAY VÒNG
                      Tooltip(
                        message: 'Sắp xếp: ${_getSortText()}',
                        child: Container(
                          height: 40, width: 40,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : Colors.black12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(_getSortIcon(), color: Theme.of(context).iconTheme.color, size: 20),
                            onPressed: _cycleSort,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: _showAllFlat ? 'Đang hiển thị All Sound' : 'Đang phân nhóm Folder',
                        child: Container(
                          height: 40, width: 40,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : Colors.black12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(_showAllFlat ? Icons.list : Icons.folder_copy, color: Theme.of(context).iconTheme.color, size: 20),
                            onPressed: () {
                              _showAllFlat = !_showAllFlat;
                              _applyFilters();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // BẢN VÁ: Dùng ListView.builder render siêu tốc
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _flattenedList.length,
                    itemBuilder: (context, index) {
                      final item = _flattenedList[index];

                      if (item is Audio) {
                        // Chế độ Trải phẳng (showAllFlat)
                        final isAdded = _playlistAudioPaths.contains(item.path);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: _AudioRow(
                            audio: item,
                            isAdded: isAdded,
                            onAdd: () => addSoundToPlaylist(item),
                            onRemove: () => removeSoundFromPlaylist(item),
                          ),
                        );
                      } else if (item['type'] == 'folder') {
                        // Thẻ Header Của Folder
                        String fName = item['name'];
                        List<Audio> fAudios = item['audios'];
                        bool isExpanded = _expandedFolders.contains(fName);
                        bool allAdded = fAudios.every((a) => _playlistAudioPaths.contains(a.path));

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: _FolderRow(
                            folderName: fName,
                            audioCount: fAudios.length,
                            isExpanded: isExpanded,
                            allAdded: allAdded,
                            onTap: () {
                              setState(() {
                                if (isExpanded) _expandedFolders.remove(fName);
                                else _expandedFolders.add(fName);
                                _buildFlattenedList();
                              });
                            },
                            onAddRemoveAll: () {
                              setState(() {
                                if (allAdded) {
                                  for (var a in fAudios) {
                                    widget.playlist.audios.removeWhere((p) => p.path == a.path);
                                    _playlistAudioPaths.remove(a.path);
                                  }
                                } else {
                                  for (var a in fAudios) {
                                    if (!_playlistAudioPaths.contains(a.path)) {
                                      widget.playlist.audios.add(a);
                                      _playlistAudioPaths.add(a.path);
                                    }
                                  }
                                }
                              });
                              PlaylistData.savePlaylist(context, widget.playlist);
                            }
                          ),
                        );
                      } else if (item['type'] == 'child_audio') {
                        // Bài hát con bên trong Folder
                        Audio a = item['audio'];
                        bool isAdded = _playlistAudioPaths.contains(a.path);
                        return Padding(
                          padding: const EdgeInsets.only(left: 32.0, top: 4, bottom: 4),
                          child: _AudioRow(
                            audio: a,
                            isAdded: isAdded,
                            onAdd: () => addSoundToPlaylist(a),
                            onRemove: () => removeSoundFromPlaylist(a),
                          ),
                        );
                      } else if (item['type'] == 'audio') {
                        // Bài hát lẻ (Standalone)
                        Audio a = item['audio'];
                        bool isAdded = _playlistAudioPaths.contains(a.path);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: _AudioRow(
                            audio: a,
                            isAdded: isAdded,
                            onAdd: () => addSoundToPlaylist(a),
                            onRemove: () => removeSoundFromPlaylist(a),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                )
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
    if (mounted) Navigator.pop(context);
  }

  removePlaylist() {
    PlaylistData.removePlaylist(context, widget.playlist);
    Navigator.pop(context);
  }

  addSoundToPlaylist(Audio audio) {
    widget.playlist.audios.add(audio);
    setState(() { _playlistAudioPaths.add(audio.path); }); 
    PlaylistData.savePlaylist(context, widget.playlist);
  }

  removeSoundFromPlaylist(Audio audio) {
    widget.playlist.audios.removeWhere((a) => a.path == audio.path);
    setState(() { _playlistAudioPaths.remove(audio.path); }); 

    if (widget.playlist.audios.isEmpty) {
      removePlaylist();
    } else {
      PlaylistData.savePlaylist(context, widget.playlist);
    }
  }
}

class _FolderRow extends StatelessWidget {
  final String folderName;
  final int audioCount;
  final bool isExpanded;
  final bool allAdded;
  final VoidCallback onTap;
  final VoidCallback onAddRemoveAll;

  const _FolderRow({
    required this.folderName,
    required this.audioCount,
    required this.isExpanded,
    required this.allAdded,
    required this.onTap,
    required this.onAddRemoveAll,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12)
        ),
        child: Row(
          children: <Widget>[
            Icon(
              isExpanded ? Icons.folder_open : Icons.folder,
              color: Theme.of(context).colorScheme.primary,
              size: 26,
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folderName,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  Text(
                    '$audioCount sounds',
                    style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16.0),
            MyButton(
              icon: allAdded ? MyIcons.playlistDelete() : MyIcons.playlistAdd(),
              onTap: onAddRemoveAll,
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioRow extends StatelessWidget {
  const _AudioRow({
    Key? key,
    required this.audio,
    required this.isAdded,
    required this.onAdd,
    required this.onRemove,
  }) : super(key: key);

  final Audio audio;
  final bool isAdded; 
  final Function() onAdd, onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            audio.name,
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w500, 
              color: Theme.of(context).textTheme.bodyLarge?.color
            ),
          ),
        ),
        const SizedBox(width: 16.0),
        MyButton(
          icon: isAdded ? MyIcons.playlistDelete() : MyIcons.playlistAdd(),
          onTap: isAdded ? onRemove : onAdd,
        ),
      ],
    );
  }
}
