import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rolify/data/playlist.dart';
import 'package:rolify/entities/playlist.dart';
import 'package:rolify/entities/audio.dart'; // BẢN VÁ: Import Audio để ép kiểu danh sách
import 'package:rolify/presentation_logic_holders/playlist_list_bloc/playlist_list_bloc.dart';
import 'package:rolify/presentation_logic_holders/playlist_list_bloc/playlist_list_state.dart';
import 'package:rolify/src/components/button.dart';
import 'package:rolify/src/components/my_icons.dart';
import 'package:rolify/src/components/playlist_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'edit_playlist.dart';

// BẢN VÁ: Bộ theo dõi sự kiện Thu gọn / Mở rộng toàn cục
class PlaylistGlobals {
  static final ValueNotifier<bool> expandNotifier = ValueNotifier<bool>(false);
}

class AllPlaylist extends StatefulWidget {
  const AllPlaylist({Key? key}) : super(key: key);

  @override
  AllPlaylistState createState() => AllPlaylistState();
}

class AllPlaylistState extends State<AllPlaylist> {
  List<Playlist> playlists = [];
  String _searchQuery = '';
  int _sortType = 0; // 0: Mới nhất, 1: A-Z, 2: Z-A, 3: Ít bài, 4: Nhiều bài

  @override
  void initState() {
    super.initState();
    _loadSortPreference();
    initPlaylists();
  }

  Future<void> _loadSortPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _sortType = prefs.getInt('playlist_sort_type') ?? 0;
      });
    }
  }

  Future<void> _updateSortType(int val) async {
    setState(() => _sortType = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('playlist_sort_type', val);
  }

  // BẢN VÁ: Chạm icon Sort để xoay vòng các kiểu sắp xếp
  void _cycleSort() {
    int next = (_sortType + 1) % 5;
    _updateSortType(next);
  }

  // BẢN VÁ: Hoán đổi Thu gọn/Mở rộng toàn bộ
  void _toggleExpandAll() async {
    PlaylistGlobals.expandNotifier.value = !PlaylistGlobals.expandNotifier.value;
    final prefs = await SharedPreferences.getInstance();
    for (var p in playlists) {
      await prefs.setBool('playlist_exp_${p.name}', PlaylistGlobals.expandNotifier.value);
    }
  }

  void initPlaylists() {
    PlaylistData.getAllPlaylist().then((value) {
      if (mounted) {
        setState(() {
          playlists = value;
        });
      }
    });
  }

  List<Playlist> get filteredPlaylists {
    var list = playlists.where((p) => 
        p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        
    if (_sortType == 0) {
      list = list.reversed.toList(); // Mới nhất
    } else if (_sortType == 1) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_sortType == 2) {
      list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    } else if (_sortType == 3) {
      list.sort((a, b) => a.audios.length.compareTo(b.audios.length));
    } else if (_sortType == 4) {
      list.sort((a, b) => b.audios.length.compareTo(a.audios.length));
    }
    return list;
  }

  IconData _getSortIcon() {
    switch (_sortType) {
      case 0: return Icons.access_time; // Mới nhất
      case 1: return Icons.sort_by_alpha; // A-Z
      case 2: return Icons.keyboard_arrow_up; // Z-A
      case 3: return Icons.filter_list; // Ít bài
      case 4: return Icons.filter_list_alt; // Nhiều bài
      default: return Icons.sort;
    }
  }

  String _getSortText() {
    switch (_sortType) {
      case 0: return "Mới nhất";
      case 1: return "A - Z";
      case 2: return "Z - A";
      case 3: return "Ít bài nhất";
      case 4: return "Nhiều bài nhất";
      default: return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PlaylistListBloc, PlaylistListState>(
      listener: (BuildContext context, PlaylistListState state) {
        if (state is PlaylistListEdited) initPlaylists();
      },
      child: Column(
        children: [
          _buildSearchBar(), 
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: getPlaylistList(),
            ),
          ),
        ],
      ),
    );
  }

  // BẢN VÁ: Thanh ngang đồng nhất UI (Search + Sort + Expand)
  Widget _buildSearchBar() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'Tìm playlist...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.black12,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Sắp xếp: ${_getSortText()}',
            child: IconButton(
              icon: Icon(_getSortIcon(), color: Theme.of(context).iconTheme.color),
              onPressed: _cycleSort,
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: PlaylistGlobals.expandNotifier,
            builder: (context, isExpandedAll, child) {
              return Tooltip(
                message: 'Thu gọn / Mở rộng',
                child: IconButton(
                  icon: Icon(
                    isExpandedAll ? Icons.unfold_less : Icons.unfold_more,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: _toggleExpandAll,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> getPlaylistList() {
    List<Widget> list = [];
    list.addAll(filteredPlaylists.map((playlist) => Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: PlaylistCard(
        key: ValueKey(playlist.name),
        playlist: playlist
      ),
    )).toList());

    list.add(Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Align(
        alignment: Alignment.center,
        child: MyButton(
            icon: MyIcons.add(),
            onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    // BẢN VÁ TUYỆT ĐỐI: Bỏ chữ "const" và định nghĩa "<Audio>[]" 
                    // Để mảng không bị khóa (immutable), sửa tận gốc lỗi nút + vô tác dụng
                    builder: (context) => EditPlaylist(
                        playlist: Playlist(name: 'New Playlist', audios: <Audio>[])),
                  ),
                )),
      ),
    ));

    return list;
  }
}