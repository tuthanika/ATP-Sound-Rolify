import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:rolify/data/audios.dart';
import 'package:rolify/entities/audio.dart';
import 'package:rolify/data/playlist.dart';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';


class BackupService {
  static Future<void> backup(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? audiosJson = prefs.getString('audios');
      final String? playlistsJson = prefs.getString('playlists');

      Map<String, dynamic> settings = {};
      for (String key in prefs.getKeys()) {
        if (key != 'audios' && key != 'playlists' && !key.startsWith('widget_')) {
          settings[key] = prefs.get(key);
        }
      }

      final data = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'audios': audiosJson != null ? jsonDecode(audiosJson) : [],
        'playlists': playlistsJson != null ? jsonDecode(playlistsJson) : [],
        'settings': settings,
      };

      final tempDir = await getTemporaryDirectory();
      final fileName = 'rolify_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonEncode(data));

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Rolify Plus Backup',
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi sao lưu: $e')),
      );
    }
  }

  static Future<void> restore(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        await [Permission.storage, Permission.audio].request();
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final String content = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);

        if (data.containsKey('audios') && data.containsKey('playlists')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('audios', jsonEncode(data['audios']));
          await prefs.setString('playlists', jsonEncode(data['playlists']));

          if (data.containsKey('settings')) {
            final Map<String, dynamic> settings = data['settings'];
            for (String key in settings.keys) {
              final value = settings[key];
              if (value is int) {
                await prefs.setInt(key, value);
              } else if (value is double) {
                await prefs.setDouble(key, value);
              } else if (value is bool) {
                await prefs.setBool(key, value);
              } else if (value is String) {
                await prefs.setString(key, value);
              } else if (value is List) {
                await prefs.setStringList(key, List<String>.from(value));
              }
            }
          }

          final audios = await AudioData.getAllAudios();
          await AudioData.saveAllAudios(context, audios);
          
          final playlists = await PlaylistData.getAllPlaylist();
          await PlaylistData.saveAllPlaylist(context, playlists);

          await AudioData.addNewAssetsAudios(context);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Khôi phục thành công! Hãy khởi động lại app nếu chưa thấy cập nhật.')),
          );
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Định dạng file Backup không hợp lệ.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi khôi phục: $e')),
      );
    }
  }

  // Helper: Quét an toàn, CHỈ QUÉT ĐÚNG THƯ MỤC NGƯỜI DÙNG CHỌN
  static Future<List<File>> _safeGetAllFiles(String startPath) async {
    List<File> result = [];
    List<Directory> dirsToScan = [Directory(startPath)];

    while (dirsToScan.isNotEmpty) {
      Directory current = dirsToScan.removeLast();
      try {
        await for (var entity in current.list(followLinks: false)) {
          String name = entity.path.split(RegExp(r'[/\\]')).last;
          
          if (name.startsWith('.') || name == 'Android') continue;

          if (entity is File) {
            final ext = name.toLowerCase();
            if (ext.endsWith('.mp3') || ext.endsWith('.ogg') || ext.endsWith('.wav') || 
                ext.endsWith('.m4a') || ext.endsWith('.flac') || ext.endsWith('.aac')) {
              result.add(entity);
            }
          } else if (entity is Directory) {
            dirsToScan.add(entity);
          }
        }
      } catch (e) {
        // Bỏ qua các thư mục không có quyền truy cập
      }
    }
    return result;
  }

  static Future<void> relink(BuildContext context) async {
    try {
      String? directoryPath = await FilePicker.platform.getDirectoryPath();
      if (directoryPath == null) return;

      if (Platform.isAndroid) {
        final Map<Permission, PermissionStatus> statuses = await [
          Permission.storage,
          Permission.audio,
          Permission.manageExternalStorage,
        ].request();
        
        if (statuses[Permission.storage] != PermissionStatus.granted && 
            statuses[Permission.audio] != PermissionStatus.granted &&
            statuses[Permission.manageExternalStorage] != PermissionStatus.granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cần quyền truy cập bộ nhớ để liên kết lại.')),
          );
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang tìm kiếm âm thanh trong khu vực bạn chọn...')),
      );

      // Chỉ quét lấy các file có thật trong phạm vi thư mục người dùng vừa chọn
      final List<File> files = await _safeGetAllFiles(directoryPath);
      
      final allAudios = await AudioData.getAllAudios();
      final allPlaylists = await PlaylistData.getAllPlaylist();
      int relinkCount = 0;

      // ============================================
      // BƯỚC 1: RELINK GLOBAL AUDIOS
      // ============================================
      for (int i = 0; i < allAudios.length; i++) {
        final audio = allAudios[i];
        
        // BẢO VỆ 1: Bỏ qua Link Stream và file cài đặt sẵn (Assets)
        if (audio.path.startsWith('http') || audio.audioSource == LocalAudioSource.assets) {
          continue; 
        }

        // BẢO VỆ 2: BỎ QUA CÁC FILE ĐANG HOẠT ĐỘNG TỐT
        // (Giải quyết việc Relink nhiều lần trên nhiều Root khác nhau mà không bị ghi đè nhầm)
        if (File(audio.path).existsSync()) {
          continue;
        }

        // CHỈ TÌM VÀ NỐI LẠI CÁC FILE ĐÃ CHẾT/MẤT ĐƯỜNG DẪN
        final fileName = _getFileName(audio.path);
        try {
          final matchingFile = files.firstWhere((entity) => _getFileName(entity.path) == fileName);
          allAudios[i] = audio.copyFrom(path: matchingFile.path);
          relinkCount++;
        } catch (e) {
          // File không nằm trong thư mục này -> Chờ lần Relink ở thư mục khác
        }
      }

      // ============================================
      // BƯỚC 2: RELINK PLAYLIST AUDIOS
      // ============================================
      for (int i = 0; i < allPlaylists.length; i++) {
        final playlist = allPlaylists[i];
        bool playlistUpdated = false;
        
        for (int j = 0; j < playlist.audios.length; j++) {
          final audio = playlist.audios[j];
          
          if (audio.path.startsWith('http') || audio.audioSource == LocalAudioSource.assets) continue;
          
          if (File(audio.path).existsSync()) continue;

          final fileName = _getFileName(audio.path);
          try {
            final matchingFile = files.firstWhere((entity) => _getFileName(entity.path) == fileName);
            playlist.audios[j] = audio.copyFrom(path: matchingFile.path);
            playlistUpdated = true;
            relinkCount++;
          } catch (e) {
             // Bỏ qua
          }
        }
        
        if (playlistUpdated) {
          allPlaylists[i] = playlist;
        }
      }

      if (relinkCount > 0) {
        await AudioData.saveAllAudios(context, allAudios);
        await PlaylistData.saveAllPlaylist(context, allPlaylists);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tuyệt vời! Đã liên kết lại $relinkCount âm thanh thành công.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có âm thanh lỗi nào được tìm thấy trong thư mục này.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi liên kết lại: $e')),
      );
    }
  }

  static String _getFileName(String path) {
    try {
      String name = path;
      if (path.contains('content://')) {
        name = Uri.decodeComponent(Uri.parse(path).pathSegments.last);
      }
      String fileName = name.split(RegExp(r'[/\\]')).last;
      return fileName.split(':').last;
    } catch (e) {
      return path.split(RegExp(r'[/\\]')).last;
    }
  }
}