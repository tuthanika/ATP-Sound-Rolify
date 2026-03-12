import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;

class LocalFileExplorer extends StatefulWidget {
  final Function(List<String>) onFilesSelected;

  const LocalFileExplorer({Key? key, required this.onFilesSelected}) : super(key: key);

  @override
  _LocalFileExplorerState createState() => _LocalFileExplorerState();
}

class _LocalFileExplorerState extends State<LocalFileExplorer> {
  String currentPath = '/storage/emulated/0';
  List<FileSystemEntity> _files = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndLoad();
  }

  Future<void> _requestPermissionsAndLoad() async {
    bool granted = false;
    try {
      if (Platform.isAndroid) {
        final status = await Permission.manageExternalStorage.request();
        if (status.isGranted) granted = true;
        
        if (!granted) {
          final storageStatus = await Permission.storage.request();
          if (storageStatus.isGranted) granted = true;
        }
      } else {
        granted = true; // For other platforms
      }
    } catch (e) {
      debugPrint('Permission exception: \$e');
    }

    if (granted) {
      _loadFiles();
    } else {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Storage permission denied. Cannot explore files.';
        });
      }
    }
  }

  void _loadFiles() {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final root = Directory(currentPath);
      final entries = root.listSync(recursive: false, followLinks: false);
      
      // Sort: Directories first, then files
      entries.sort((a, b) {
        final aIsDir = a is Directory;
        final bIsDir = b is Directory;
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });

      if (mounted) {
        setState(() {
          _files = entries;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _files = [];
          _loading = false;
          _error = 'Error accessing folder: \${e.toString()}';
        });
      }
    }
  }

  void _navigateUp() {
    if (currentPath == '/storage/emulated/0' || currentPath == '/') return;
    final parent = Directory(currentPath).parent.path;
    setState(() {
      currentPath = parent;
    });
    _loadFiles();
  }

  void _onItemTap(FileSystemEntity entity) {
    if (entity is Directory) {
      try {
        // Test access before navigating
        entity.listSync().isEmpty;
        setState(() {
          currentPath = entity.path;
        });
        _loadFiles();
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access denied to this folder')),
        );
      }
    } else if (entity is File) {
      final ext = p.extension(entity.path).toLowerCase();
      if (['.mp3', '.ogg', '.wav', '.flac', '.m4a', '.aac'].contains(ext)) {
        widget.onFilesSelected([entity.path]);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an audio file')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                if (currentPath != '/storage/emulated/0' && currentPath != '/')
                  IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: _navigateUp,
                  ),
                Expanded(
                  child: Text(
                    currentPath.split('/').last.isEmpty ? '/' : currentPath.split('/').last,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))))
                    : _files.isEmpty
                        ? const Center(child: Text('Folder is empty'))
                        : ListView.builder(
                            itemCount: _files.length,
                            itemBuilder: (context, index) {
                              final entity = _files[index];
                              final isDir = entity is Directory;
                              final name = p.basename(entity.path);

                              IconData icon = Icons.insert_drive_file;
                              Color iconColor = Colors.grey;

                              if (isDir) {
                                icon = Icons.folder;
                                iconColor = Colors.amber;
                              } else {
                                final ext = p.extension(entity.path).toLowerCase();
                                if (['.mp3', '.ogg', '.wav', '.flac', '.m4a', '.aac'].contains(ext)) {
                                  icon = Icons.audiotrack;
                                  iconColor = Colors.blue;
                                }
                              }

                              return ListTile(
                                leading: Icon(icon, color: iconColor),
                                title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                onTap: () => _onItemTap(entity),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
