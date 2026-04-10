import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AudioFileManager {
  static final Map<String, Future<String?>> _processingFutures = {};
  
  // Lấy thư mục lưu trữ
  static Future<Directory> _getStorageDir(bool isOfflineMode) async {
    Directory? baseDir;
    if (isOfflineMode) {
      if (Platform.isAndroid) {
        baseDir = await getExternalStorageDirectory();
      } else if (Platform.isWindows) {
        baseDir = await getApplicationSupportDirectory();
      }
      baseDir ??= await getApplicationDocumentsDirectory(); 
    } else {
      if (Platform.isAndroid) {
        var cacheDirs = await getExternalCacheDirectories();
        if (cacheDirs != null && cacheDirs.isNotEmpty) {
          baseDir = cacheDirs.first;
        }
      }
      baseDir ??= await getTemporaryDirectory();
    }
    final targetDir = Directory('${baseDir.path}/cloud_audios');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    return targetDir;
  }

  // BẢN VÁ 1: Hàm bóc tách ĐÚNG đuôi file từ URL (Không ép thành mp3 nữa)
  static String _getExtension(String path) {
    try {
      if (path.startsWith('http')) {
         final urlPath = Uri.parse(path).path;
         if (urlPath.contains('.')) {
            final ext = urlPath.split('.').last.toLowerCase();
            if (['mp3', 'ogg', 'wav', 'm4a', 'aac', 'flac'].contains(ext)) {
              return '.$ext';
            }
         }
      } else if (path.contains('.')) {
         return '.${path.split('.').last.toLowerCase()}';
      }
    } catch (_) {}
    return '.mp3'; // Mặc định nếu URL bị ẩn đuôi
  }

  // Đã thêm tham số sourcePath để lấy đúng định dạng
  static Future<File> getLocalFile(String sourcePath, String audioName, bool isOfflineMode) async {
    final targetDir = await _getStorageDir(isOfflineMode);
    final safeFileName = audioName.replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '_');
    final extension = _getExtension(sourcePath);
    return File('${targetDir.path}/$safeFileName$extension');
  }

  static Future<String?> processPath(String sourcePath, String audioName, bool isOfflineMode) async {
    if (!sourcePath.startsWith('http')) return sourcePath; 

    if (_processingFutures.containsKey(sourcePath)) {
      return _processingFutures[sourcePath];
    }

    final future = _processPathInternal(sourcePath, audioName, isOfflineMode);
    _processingFutures[sourcePath] = future;

    try {
      return await future;
    } finally {
      _processingFutures.remove(sourcePath);
    }
  }

  static Future<String?> _processPathInternal(String sourcePath, String audioName, bool isOfflineMode) async {
    try {
      final localFile = await getLocalFile(sourcePath, audioName, isOfflineMode);

      // Nâng mức kiểm tra lên 1024 byte (1KB) để triệt tiêu các file rác sinh ra do lỗi mạng
      if (await localFile.exists()) {
        if (localFile.lengthSync() > 1024) {
          return localFile.path; 
        } else {
          await localFile.delete(); 
        }
      }

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(sourcePath));
      final response = await request.close();

      if (response.statusCode == 200) {
        // BẢN VÁ 2: Tải vào file ".temp" trước. 
        // Đảm bảo tải XONG HOÀN TOÀN 100% mới đổi tên thành file thật.
        // Tuyệt đối ngăn chặn ExoPlayer đọc nhầm file bị tải thiếu do rớt mạng!
        final tempFile = File('${localFile.path}.temp');
        await response.pipe(tempFile.openWrite());
        
        if (await tempFile.exists() && tempFile.lengthSync() > 1024) {
           await tempFile.rename(localFile.path);
           return localFile.path; 
        } else {
           if (await tempFile.exists()) await tempFile.delete();
        }
      }
    } catch (e) {
      debugPrint("Lỗi AudioFileManager tải file: $e");
    }
    return null;
  }

  static Future<String> getPlayablePath(String sourcePath, String audioName, bool isOfflineMode) async {
    if (!sourcePath.startsWith('http')) return sourcePath;
    
    final localFile = await getLocalFile(sourcePath, audioName, isOfflineMode);
    if (await localFile.exists() && localFile.lengthSync() > 1024) {
       return localFile.path; 
    }

    final downloadedPath = await processPath(sourcePath, audioName, isOfflineMode);
    return downloadedPath ?? sourcePath; 
  }

  // BẢN VÁ 3: Hàm xóa file nay phải linh động quét Tên thay vì quét Đuôi
  static Future<void> deleteLocalFile(String audioName) async {
     try {
        final safeFileName = audioName.replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '_');
        
        // Quét cả phân vùng vĩnh viễn và bộ nhớ Cache
        for (var isOffline in [true, false]) {
           final targetDir = await _getStorageDir(isOffline);
           if (await targetDir.exists()) {
              final files = targetDir.listSync();
              for (var file in files) {
                 if (file is File) {
                    final filename = file.path.split(Platform.pathSeparator).last;
                    if (filename.startsWith('$safeFileName.')) {
                       await file.delete();
                    }
                 }
              }
           }
        }
     } catch (e) {
        debugPrint("Lỗi dọn rác AudioFileManager: $e");
     }
  }
}