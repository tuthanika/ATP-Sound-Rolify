// Khai báo Base URL dành RIÊNG cho file này
const String _baseUrl = "https://raw.githubusercontent.com/tuthanika/ATP-Sound-Audio-File/refs/heads/main/arsm_free";

const List<Map<String, dynamic>> arsm_free = [
  {
    'name': "Nhịp đập hai tai 1Hz_Binaural-beats_trái-110,50Hz-phải-111,50Hz",
    'path': "$_baseUrl/Nhịp đập hai tai 1Hz_Binaural-beats_trái-110,50Hz-phải-111,50Hz.mp3",
    'image': 'assets/images/tavern.jpg', 
    'audio_source': 'file', // QUAN TRỌNG: Ép thành 'file' để kích hoạt logic Tải/Stream
    'folder_name': 'ARSM Free', // Gom chung vào 1 Folder
    'is_offline_mode': true, // True: Tải về khi phát lần đầu. False: Stream trực tiếp
    'version_number': 1 // Đổi version để ép app cập nhật
  },
];