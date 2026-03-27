import 'package:flutter/material.dart';
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
  Set<String> _expandedFolders = {}; // Sổ tay nhớ thư mục đang mở
  
  String _searchQuery = '';
  int _sortType = 0; 
  bool _showAllFlat = false; // Cờ chuyển đổi hiển thị: Gom thư mục vs Trải phẳng

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
        audios = value;
        _applyFilters();
      }
    });
  }

  void _applyFilters() {
    var list = audios.where((a) => 
        a.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        
    if (_sortType == 0) {
      list = list.reversed.toList(); 
    } else if (_sortType == 1) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_sortType == 2) {
      list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    }
    
    setState(() {
      filteredAudios = list;
    });
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
                
                // THANH CÔNG CỤ TỐI ƯU KHÔNG GIAN
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
                              _searchQuery = val;
                              // Khi search, tự động bung phẳng danh sách để dễ tìm
                              if (val.isNotEmpty && !_showAllFlat) _showAllFlat = true;
                              _applyFilters(); 
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Nút Sort tối giản chỉ còn Icon
                      Tooltip(
                        message: 'Sắp xếp: ${_getSortText()}',
                        child: Container(
                          height: 40, width: 40,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : Colors.black12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.sort, color: Theme.of(context).iconTheme.color, size: 20),
                            onPressed: () {
                              _sortType = (_sortType + 1) % 3;
                              _applyFilters();
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Nút chuyển chế độ Gom Folder / Trải phẳng All
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
                            onPressed: () => setState(() => _showAllFlat = !_showAllFlat),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // DANH SÁCH LINH HOẠT TỐC ĐỘ CAO
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: _buildListItems(),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // BẢN VÁ: THUẬT TOÁN TẠO GIAO DIỆN FOLDER / SOUND MIXED
  List<Widget> _buildListItems() {
    List<Widget> items = [];

    // Chế độ 1: Trải phẳng toàn bộ
    if (_showAllFlat) {
      for (var audio in filteredAudios) {
        final isAdded = _playlistAudioPaths.contains(audio.path);
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: _AudioRow(
              audio: audio,
              isAdded: isAdded,
              onAdd: () => addSoundToPlaylist(audio),
              onRemove: () => removeSoundFromPlaylist(audio),
            ),
          )
        );
      }
      return items;
    }

    // Chế độ 2: Gom cụm theo Thư mục
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

    // 1. Vẽ các Thư mục trước
    for (var fName in sortedFolderNames) {
      List<Audio> folderAudios = folders[fName]!;
      bool isExpanded = _expandedFolders.contains(fName);
      
      // Nếu MỌI bài trong folder đều có trong playlist -> Mới hiện nút Remove All
      bool allAdded = folderAudios.every((a) => _playlistAudioPaths.contains(a.path));

      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: _FolderRow(
            folderName: fName,
            audioCount: folderAudios.length,
            isExpanded: isExpanded,
            allAdded: allAdded,
            onTap: () {
              setState(() {
                if (isExpanded) _expandedFolders.remove(fName);
                else _expandedFolders.add(fName);
              });
            },
            onAddRemoveAll: () {
              setState(() {
                if (allAdded) {
                  // Xóa sạch
                  for (var a in folderAudios) {
                    widget.playlist.audios.removeWhere((p) => p.path == a.path);
                    _playlistAudioPaths.remove(a.path);
                  }
                } else {
                  // Thêm tất cả những bài chưa có
                  for (var a in folderAudios) {
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
        )
      );

      // Nếu thư mục được mở rộng, xổ ra các bài bên trong (có lùi lề trái)
      if (isExpanded) {
        for (var a in folderAudios) {
          bool isAdded = _playlistAudioPaths.contains(a.path);
          items.add(
             Padding(
               padding: const EdgeInsets.only(left: 32.0, top: 4, bottom: 4),
               child: _AudioRow(
                 audio: a,
                 isAdded: isAdded,
                 onAdd: () => addSoundToPlaylist(a),
                 onRemove: () => removeSoundFromPlaylist(a),
               )
             )
          );
        }
      }
    }

    // 2. Vẽ các bài Standalone lẻ tẻ ở dưới cùng
    for (var a in standalones) {
       bool isAdded = _playlistAudioPaths.contains(a.path);
       items.add(
          Padding(
             padding: const EdgeInsets.symmetric(vertical: 6.0),
             child: _AudioRow(
               audio: a,
               isAdded: isAdded,
               onAdd: () => addSoundToPlaylist(a),
               onRemove: () => removeSoundFromPlaylist(a),
             )
          )
       );
    }

    return items;
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

// UI HIỂN THỊ CỤM THƯ MỤC
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