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
      final String? playlistsJson = prefs.getString('playlist');

      final data = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'audios': audiosJson != null ? jsonDecode(audiosJson) : [],
        'playlists': playlistsJson != null ? jsonDecode(playlistsJson) : [],
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
        SnackBar(content: Text('Error during backup: $e')),
      );
    }
  }

  static Future<void> restore(BuildContext context) async {
    try {
      // Request permissions before restore
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
          await prefs.setString('playlist', jsonEncode(data['playlists']));

          // Refresh the app state by reloading data into Blocs
          final audios = await AudioData.getAllAudios();
          await AudioData.saveAllAudios(context, audios);
          
          final playlists = await PlaylistData.getAllPlaylist();
          await PlaylistData.saveAllPlaylist(context, playlists);

           // Re-add any missing built-in assets
           await AudioData.addNewAssetsAudios(context);


          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data restored successfully! Please restart the app if changes don\'t appear.')),
          );
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid backup file format.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during restore: $e')),
      );
    }
  }

  static Future<void> relink(BuildContext context) async {
    try {
      String? directoryPath = await FilePicker.platform.getDirectoryPath();
      if (directoryPath == null) return;

      // Request storage permissions before relink
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

      final directory = Directory(directoryPath);
      final List<FileSystemEntity> files = directory.listSync(recursive: true);
      
      final allAudios = await AudioData.getAllAudios();
      final allPlaylists = await PlaylistData.getAllPlaylist();
      int relinkCount = 0;

      // 1. Relink global audios
      for (int i = 0; i < allAudios.length; i++) {
        final audio = allAudios[i];
        
        // SKIP ASSETS - only relink external files
        if (audio.audioSource == LocalAudioSource.assets) continue;

        final fileName = _getFileName(audio.path);
        
        try {
          final matchingFile = files.firstWhere((entity) => 
            entity is File && _getFileName(entity.path) == fileName
          );
          
          if (matchingFile.path != audio.path) {
            allAudios[i] = audio.copyFrom(path: matchingFile.path);
            relinkCount++;
          }
        } catch (e) {
          // No match found
        }
      }

      // 2. Relink audios inside playlists
      for (int i = 0; i < allPlaylists.length; i++) {
        final playlist = allPlaylists[i];
        bool playlistUpdated = false;
        
        for (int j = 0; j < playlist.audios.length; j++) {
          final audio = playlist.audios[j];
          
          // SKIP ASSETS
          if (audio.audioSource == LocalAudioSource.assets) continue;

          final fileName = _getFileName(audio.path);
          
          try {
            final matchingFile = files.firstWhere((entity) => 
              entity is File && _getFileName(entity.path) == fileName
            );
            
            if (matchingFile.path != audio.path) {
              playlist.audios[j] = audio.copyFrom(path: matchingFile.path);
              playlistUpdated = true;
              relinkCount++;
            }
          } catch (e) {
            // No match
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
          SnackBar(content: Text('Đã liên kết lại $relinkCount âm thanh thành công!')),
        );
      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy âm thanh nào cần liên kết lại.')),
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
        // Handle SAF content URIs which often encode the path in the last segment
        name = Uri.decodeComponent(Uri.parse(path).pathSegments.last);
      }
      // Split by path separators and take the last part
      String fileName = name.split(RegExp(r'[/\\]')).last;
      // In SAF, the name might still have a prefix like "ECCD-1BF6:music/"
      return fileName.split(':').last;
    } catch (e) {
      return path.split(RegExp(r'[/\\]')).last;
    }
  }
}

