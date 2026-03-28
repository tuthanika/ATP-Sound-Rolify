import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:rolify/data/playlist.dart';
import 'package:rolify/entities/playlist.dart';
import 'package:rolify/entities/audio.dart'; 
import 'package:rolify/presentation_logic_holders/playlist_list_bloc/playlist_list_bloc.dart';
import 'package:rolify/presentation_logic_holders/playlist_list_bloc/playlist_list_state.dart';
import 'package:rolify/src/components/button.dart';
import 'package:rolify/src/components/my_icons.dart';
import 'package:rolify/src/components/playlist_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'edit_playlist.dart';

class PlaylistGlobals {
  static final ValueNotifier<bool> expandNotifier = ValueNotifier<bool>(false);
  static final Set<String> expandedPlaylists = {}; 
}

class AllPlaylist extends StatefulWidget {
  const AllPlaylist({Key? key}) : super(key: key);

  @override
  AllPlaylistState createState() => AllPlaylistState();
}

class AllPlaylistState extends State<AllPlaylist> {
  List<Playlist> playlists = [];
  
  // BẢN VÁ TỐI THƯỢNG: Danh sách đã được lọc và sắp xếp. 
  // Biến này triệt tiêu hoàn toàn sự cố tính toán lại khi cuộn màn hình!
  List<Playlist> _filteredPlaylists = []; 
  
  String _searchQuery = '';
  int _sortType = 0; 
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadSortPreference();
    initPlaylists();
    PlaylistGlobals.expandNotifier.value = false; 
    PlaylistGlobals.expandedPlaylists.clear(); 
  }

  Future<void> _loadSortPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _sortType = prefs.getInt('playlist_sort_type') ?? 0;
      });
    }
  }

  void _cycleSort() async {
    int next = (_sortType + 1) % 5;
    setState(() {
       _sortType = next;
       _applyFilters(); // Cập nhật lại list tĩnh khi bấm Sort
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('playlist_sort_type', next);
  }

  void _toggleExpandAll() {
    PlaylistGlobals.expandNotifier.value = !PlaylistGlobals.expandNotifier.value;
    PlaylistGlobals.expandedPlaylists.clear(); 
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    PlaylistGlobals.expandNotifier.value = false;
    PlaylistGlobals.expandedPlaylists.clear();
    super.dispose();
  }

  void initPlaylists() {
    PlaylistData.getAllPlaylist().then((value) {
      if (mounted) {
        setState(() {
          playlists = value;
          _applyFilters();
        });
      }
    });
  }

  // Hàm xử lý data chạy độc lập, tách rời khỏi build()
  void _applyFilters() {
    var list = playlists.where((p) => 
        p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        
    if (_sortType == 0) {
      list = list.reversed.toList(); 
    } else if (_sortType == 1) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_sortType == 2) {
      list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    } else if (_sortType == 3) {
      list.sort((a, b) => a.audios.length.compareTo(b.audios.length));
    } else if (_sortType == 4) {
      list.sort((a, b) => b.audios.length.compareTo(a.audios.length));
    }
    
    _filteredPlaylists = list;
  }

  IconData _getSortIcon() {
    switch (_sortType) {
      case 0: return Icons.access_time; 
      case 1: return Icons.sort_by_alpha; 
      case 2: return Icons.keyboard_arrow_up; 
      case 3: return Icons.filter_list; 
      case 4: return Icons.filter_list_alt; 
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
            // Tốc độ cuộn mượt 60fps vì _filteredPlaylists chỉ là tham chiếu thẳng tới mảng tĩnh
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredPlaylists.length + 1,
              itemBuilder: (context, index) {
                if (index < _filteredPlaylists.length) {
                  final playlist = _filteredPlaylists[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0), 
                    child: PlaylistCard(
                      key: ValueKey(playlist.name),
                      playlist: playlist
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Align(
                      alignment: Alignment.center,
                      child: MyButton(
                          icon: MyIcons.add(),
                          onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditPlaylist(
                                      playlist: Playlist(name: 'New Playlist', audios: <Audio>[])),
                                ),
                              )),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

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
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 150), () {
                  if (!mounted) return;
                  setState(() {
                    _searchQuery = val;
                    _applyFilters();
                  });
                });
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
}
