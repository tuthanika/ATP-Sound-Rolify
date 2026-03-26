import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AudioFileManager {
  
  // Lấy thư mục lưu trữ (Vĩnh viễn hoặc Cache tạm của SD Card)
  static Future<Directory> _getStorageDir(bool isOfflineMode) async {
    Directory? baseDir;
    if (isOfflineMode) {
      // Lưu offline vĩnh viễn vào Data App
      baseDir = await getExternalStorageDirectory();
      baseDir ??= await getApplicationDocumentsDirectory(); 
    } else {
      // Lưu Cache tạm thời vào SD Card (HĐH tự dọn dẹp khi đầy bộ nhớ)
      var cacheDirs = await getExternalCacheDirectories();
      if (cacheDirs != null && cacheDirs.isNotEmpty) {
        baseDir = cacheDirs.first;
      } else {
        baseDir = await getTemporaryDirectory();
      }
    }
    final targetDir = Directory('${baseDir.path}/cloud_audios');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    return targetDir;
  }

  // Khôi phục chính xác đường dẫn File Vật Lý dựa trên Tên Âm Thanh
  static Future<File> getLocalFile(String audioName, bool isOfflineMode) async {
    final targetDir = await _getStorageDir(isOfflineMode);
    final safeFileName = audioName.replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '_');
    return File('${targetDir.path}/$safeFileName.mp3');
  }

  // 1. DÙNG CHO UI: Tải file về (Có hiển thị Loading)
  static Future<String?> processPath(String sourcePath, String audioName, bool isOfflineMode) async {
    if (!sourcePath.startsWith('http')) return sourcePath; // File nội bộ bỏ qua luôn

    try {
      final localFile = await getLocalFile(audioName, isOfflineMode);

      if (await localFile.exists()) {
        if (localFile.lengthSync() > 1000) {
          return localFile.path; 
        } else {
          await localFile.delete(); // Dọn file 0 byte
        }
      }

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(sourcePath));
      final response = await request.close();

      if (response.statusCode == 200) {
        await response.pipe(localFile.openWrite());
        return localFile.path; 
      }
    } catch (e) {
      debugPrint("Lỗi AudioFileManager tải file: $e");
    }
    return null;
  }

  // 2. DÙNG CHO LÕI PHÁT NHẠC: Tìm file Local, nếu mất thì trả về URL để Stream
  static Future<String> getPlayablePath(String sourcePath, String audioName, bool isOfflineMode) async {
    if (!sourcePath.startsWith('http')) return sourcePath;
    
    final localFile = await getLocalFile(audioName, isOfflineMode);
    if (await localFile.exists() && localFile.lengthSync() > 1000) {
       return localFile.path; // Phát từ file Local (Nhanh, không tốn mạng)
    }
    return sourcePath; // Nếu file bị xóa thủ công, trả về URL để just_audio tự xử lý lại
  }

  // 3. HÀM XÓA FILE CHUẨN XÁC: Gọi khi user xóa Âm thanh
  // 3. HÀM XÓA FILE CHUẨN XÁC: Quét và xóa ở cả 2 phân vùng để không sót rác
  static Future<void> deleteLocalFile(String audioName) async {
     try {
        // Quét xóa ở thư mục Data vĩnh viễn
        final offlineFile = await getLocalFile(audioName, true);
        if (await offlineFile.exists()) await offlineFile.delete();

        // Quét xóa ở thư mục Cache tạm
        final tempFile = await getLocalFile(audioName, false);
        if (await tempFile.exists()) await tempFile.delete();
     } catch (e) {
        debugPrint("Lỗi dọn rác AudioFileManager: $e");
     }
  }
}