import 'rolify_sound.dart';
import 'atp_arsm.dart';
import 'arsm_free.dart';
// import thêm các file chủ đề khác của bạn vào đây...

// Gộp tất cả các list con lại thành 1 list tổng bằng dấu ... (Spread Operator)
final List<Map<String, dynamic>> assetsAudios = [
  ...rolify_sound,
  ...atp_arsm,
  ...arsm_free,
  // ...thêm các list khác vào đây
];

// Giữ nguyên mảng version cập nhật
const List<int> versionNumberWithAudioUpdates = [
  1
];