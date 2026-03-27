import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rolify/data/playlist.dart';
import 'package:rolify/entities/playlist.dart';
import 'package:rolify/presentation_logic_holders/playlist_list_bloc/playlist_list_bloc.dart';
import 'package:rolify/presentation_logic_holders/playlist_list_bloc/playlist_list_state.dart';
import 'package:rolify/src/components/button.dart';
import 'package:rolify/src/components/my_icons.dart';
import 'package:rolify/src/components/playlist_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'edit_playlist.dart';

class AllPlaylist extends StatefulWidget {
  const AllPlaylist({Key? key}) : super(key: key);

  @override
  AllPlaylistState createState() => AllPlaylistState();
}

class AllPlaylistState extends State<AllPlaylist> {
  List<Playlist> playlists = [];
  String _searchQuery = '';
  int _sortType = 4; // Mặc định là 4: Mới nhất

  @override
  void initState() {
    super.initState();
    _loadSortPreference();
    initPlaylists();
  }

  // Khôi phục trạng thái Sort đã lưu
  Future<void> _loadSortPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _sortType = prefs.getInt('playlist_sort_type') ?? 4;
      });
    }
  }

  // Lưu trạng thái Sort khi thay đổi
  Future<void> _updateSortType(int val) async {
    setState(() => _sortType = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('playlist_sort_type', val);
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

  // Logic Sắp xếp bao gồm "Mới nhất"
  List<Playlist> get filteredPlaylists {
    var list = playlists.where((p) => 
        p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        
    if (_sortType == 0) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_sortType == 1) {
      list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    } else if (_sortType == 2) {
      list.sort((a, b) => a.audios.length.compareTo(b.audios.length));
    } else if (_sortType == 3) {
      list.sort((a, b) => b.audios.length.compareTo(a.audios.length));
    } else if (_sortType == 4) {
      // Mới nhất: Dữ liệu get từ Local thường theo thứ tự thêm vào, ta chỉ cần đảo ngược (reversed)
      list = list.reversed.toList();
    }
    return list;
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tìm playlist...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
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
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _sortType,
                dropdownColor: Colors.grey[900],
                icon: const Icon(Icons.sort, color: Colors.white),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 4, child: Text("Mới nhất")),
                  DropdownMenuItem(value: 0, child: Text("A - Z")),
                  DropdownMenuItem(value: 1, child: Text("Z - A")),
                  DropdownMenuItem(value: 2, child: Text("Ít bài nhất")),
                  DropdownMenuItem(value: 3, child: Text("Nhiều bài nhất")),
                ],
                onChanged: (val) {
                  if (val != null) _updateSortType(val);
                },
              ),
            ),
          )
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
                    builder: (context) => const EditPlaylist(
                        playlist: Playlist(name: 'New Playlist', audios: [])),
                  ),
                )),
      ),
    ));

    return list;
  }
}