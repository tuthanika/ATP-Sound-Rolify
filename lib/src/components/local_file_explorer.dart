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
      bool granted = false;
      try {
        if (await Permission.storage.status.isGranted) granted = true;
      } catch (_) {}

      try {
        if (!granted && await Permission.storage.request().isGranted) granted = true;
      } catch (_) {}
      
      try {
        if (!granted && await Permission.audio.status.isGranted) granted = true;
        if (!granted && await Permission.audio.request().isGranted) granted = true;
      } catch (_) {}

      try {
        if (!granted && await Permission.manageExternalStorage.status.isGranted) granted = true;
        if (!granted && await Permission.manageExternalStorage.request().isGranted) granted = true;
      } catch (_) {}

      if (mounted) {
        setState(() => hasPermission = granted);
        if (granted) await _loadDir();
      }
    } else {
      if (mounted) {
        setState(() => hasPermission = true);
        await _loadDir();
      }
    }
  }

  Future<void> _loadDir() async {
    try {
      if (!await currentDir.exists()) return;

      final list = <FileSystemEntity>[];
      final stream = currentDir.list(recursive: false);
      
      await stream.forEach((e) {
        try {
          final isDir = FileSystemEntity.isDirectorySync(e.path);
          if (isDir) {
            // Hide hidden folders
            if (!e.path.split('/').last.startsWith('.')) {
              list.add(e);
            }
          } else {
            final name = e.path.toLowerCase();
            if (name.endsWith('.mp3') ||
                name.endsWith('.m4a') ||
                name.endsWith('.wav') ||
                name.endsWith('.ogg') ||
                name.endsWith('.flac') ||
                name.endsWith('.aac') ||
                name.endsWith('.opus') ||
                name.endsWith('.wma')) {
              list.add(e);
            }
          }
        } catch (_) {}
      });

      list.sort((a, b) {
        final aIsDir = FileSystemEntity.isDirectorySync(a.path);
        final bIsDir = FileSystemEntity.isDirectorySync(b.path);
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });

      if (mounted) {
        setState(() {
          files = list;
        });
      }
    } catch (e) {
      debugPrint('Error loading directory: $e');
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
                final isDir = FileSystemEntity.isDirectorySync(file.path);
                return InkWell(
                  onTap: () async {
                    if (isDir) {
                      setState(() {
                        currentDir = Directory(file.path);
                      });
                      await _loadDir();
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
                                : (NeumorphicTheme.of(context)?.current?.accentColor ?? Colors.blue)),
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
