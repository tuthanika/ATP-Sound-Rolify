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

      FilePickerResult? result = await FilePicker.pickFiles(
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

  // --- HÀM HELPER ĐỂ TÌM GỐC ---
  static String _getStorageRoot(String path) {
    if (path.startsWith('/storage/emulated/0')) {
      return '/storage/emulated/0';
    }
    final parts = path.split(RegExp(r'[/\\]'));
    if (parts.length >= 3 && parts[1] == 'storage') {
      return '/storage/${parts[2]}'; 
    }
    return path; 
  }

  // --- HÀM QUÉT THƯ MỤC AN TOÀN ---
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
      String? directoryPath = await FilePicker.getDirectoryPath();
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

      // SỬA: Tìm Gốc (Root) và quét toàn bộ hệ thống từ đó đi xuống
      final rootPath = _getStorageRoot(directoryPath);
      final List<File> files = await _safeGetAllFiles(rootPath);
      
      final allAudios = await AudioData.getAllAudios();
      final allPlaylists = await PlaylistData.getAllPlaylist();
      int relinkCount = 0;

      for (int i = 0; i < allAudios.length; i++) {
        final audio = allAudios[i];
        
        if (audio.path.startsWith('http') || audio.audioSource == LocalAudioSource.assets) {
          continue; 
        }

        if (File(audio.path).existsSync()) {
          continue;
        }

        final fileName = _getFileName(audio.path);
        try {
          final matchingFile = files.firstWhere((entity) => _getFileName(entity.path) == fileName);
          allAudios[i] = audio.copyFrom(path: matchingFile.path);
          relinkCount++;
        } catch (e) {
          // Bỏ qua
        }
      }

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
          const SnackBar(content: Text('Không có âm thanh lỗi nào được tìm thấy trong phân vùng này.')),
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