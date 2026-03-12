import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rolify/src/theme/texts.dart';

class LocalFileExplorer extends StatefulWidget {
  const LocalFileExplorer({Key? key}) : super(key: key);

  @override
  LocalFileExplorerState createState() => LocalFileExplorerState();
}

class LocalFileExplorerState extends State<LocalFileExplorer> {
  Directory currentDir = Directory('/storage/emulated/0');
  List<FileSystemEntity> files = [];
  bool hasPermission = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoad();
  }

  Future<void> _requestPermissionAndLoad() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.request().isGranted ||
          await Permission.storage.request().isGranted ||
          await Permission.audio.request().isGranted) {
        if (mounted) {
          setState(() {
            hasPermission = true;
          });
          _loadDir();
        }
      } else {
        if (mounted) {
          setState(() => hasPermission = false);
        }
      }
    } else {
      setState(() => hasPermission = true);
      _loadDir();
    }
  }

  void _loadDir() {
    try {
      final list = currentDir.listSync().where((e) {
        if (e is Directory) {
          // Hide hidden folders
          if (e.path.split('/').last.startsWith('.')) return false;
          return true;
        }
        final name = e.path.toLowerCase();
        return name.endsWith('.mp3') ||
            name.endsWith('.m4a') ||
            name.endsWith('.wav') ||
            name.endsWith('.ogg') ||
            name.endsWith('.flac') ||
            name.endsWith('.aac') ||
            name.endsWith('.opus') ||
            name.endsWith('.wma');
      }).toList();

      list.sort((a, b) {
        if (a is Directory && b is File) return -1;
        if (a is File && b is Directory) return 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });

      if (mounted) {
        setState(() {
          files = list;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          files = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeumorphicTheme.currentTheme(context).baseColor,
      appBar: NeumorphicAppBar(
        title: MyText.body(
            currentDir.path.split('/').last.isEmpty
                ? 'Internal Storage'
                : currentDir.path.split('/').last,
            fontWeight: FontWeight.bold),
        leading: NeumorphicButton(
          padding: const EdgeInsets.all(12),
          style: const NeumorphicStyle(
            boxShape: NeumorphicBoxShape.circle(),
          ),
          onPressed: () {
            if (currentDir.path != '/storage/emulated/0' &&
                currentDir.path != '/') {
              setState(() {
                currentDir = currentDir.parent;
                _loadDir();
              });
            } else {
              Navigator.pop(context);
            }
          },
          child: const Icon(Icons.arrow_back),
        ),
      ),
      body: !hasPermission
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MyText.body(
                        'Storage permission is required to browse files.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    NeumorphicButton(
                      onPressed: openAppSettings,
                      child: MyText.body('Open Settings'),
                    )
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                final isDir = file is Directory;
                return InkWell(
                  onTap: () {
                    if (isDir) {
                      setState(() {
                        currentDir = file as Directory;
                        _loadDir();
                      });
                    } else {
                      Navigator.pop(context, file.path);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(isDir ? Icons.folder : Icons.audiotrack,
                            size: 28,
                            color: isDir
                                ? Colors.amber
                                : NeumorphicTheme.currentTheme(context)
                                    .accentColor),
                        const SizedBox(width: 16),
                        Expanded(
                          child: MyText.body(file.path.split('/').last),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
