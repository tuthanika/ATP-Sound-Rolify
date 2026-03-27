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
  List<Audio> filteredAudios = []; // Sổ tay lọc list tốc độ cao
  Color? color;
  
  late Set<String> _playlistAudioPaths; // Sổ tay đánh dấu bài hát O(1)
  
  String _searchQuery = '';
  int _sortType = 0; // 0: Mới nhất, 1: A-Z, 2: Z-A

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

  // Thuật toán Lọc siêu mượt, không chạy lại khi cuộn
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

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // THU NHỎ LỀ TỔNG: 24 -> 16
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.all(Radius.circular(16.0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), // Ép sát khoảng cách
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Edit playlist', 
                              // BÓP NHỎ CHỮ ĐỂ TIẾT KIỆM KHÔNG GIAN
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
                              height: 48, // Ép lùn TextField
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
                
                // THANH SEARCH & SORT GỌN GÀNG (Cao chỉ 40px)
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
                              hintText: 'Tìm sound...',
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
                              _applyFilters(); 
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.black12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _sortType,
                            dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                            icon: Icon(Icons.sort, color: Theme.of(context).iconTheme.color, size: 20),
                            style: TextStyle(color: textColor, fontSize: 14),
                            items: const [
                              DropdownMenuItem(value: 0, child: Text("Mới nhất")),
                              DropdownMenuItem(value: 1, child: Text("A - Z")),
                              DropdownMenuItem(value: 2, child: Text("Z - A")),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                _sortType = val;
                                _applyFilters();
                              }
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: filteredAudios.length,
                    itemBuilder: (context, index) {
                      final audio = filteredAudios[index];
                      final isAdded = _playlistAudioPaths.contains(audio.path);
                      return _AudioRow(
                        audio: audio,
                        isAdded: isAdded, // Truyền trực tiếp kết quả O(1) siêu nhanh
                        onAdd: () => addSoundToPlaylist(audio),
                        onRemove: () => removeSoundFromPlaylist(audio),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(height: 12.0), // Giảm khoảng cách giữa các hàng
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