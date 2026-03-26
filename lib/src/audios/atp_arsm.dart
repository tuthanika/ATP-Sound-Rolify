// Khai báo Base URL dành RIÊNG cho file này
const String _baseUrl = "https://raw.githubusercontent.com/tuthanika/ATP-Sound-Audio-File/refs/heads/main/atp_arsm";

const List<Map<String, dynamic>> atp_arsm = [
  {
    'name': "2.5-Ngủ Sâu",
    'path': "$_baseUrl/2.5 - Ngu Sau.ogg",
    'image': 'assets/images/tavern.jpg', 
    'audio_source': 'file', // QUAN TRỌNG: Ép thành 'file' để kích hoạt logic Tải/Stream
    'folder_name': 'ATP ARSM', // Gom chung vào 1 Folder
    'is_offline_mode': true, // True: Tải về khi phát lần đầu. False: Stream trực tiếp
    'version_number': 1 // Đổi version để ép app cập nhật
  },
  {
    'name': "4-Ngủ Mơ Màng",
    'path': "$_baseUrl/4 - Ngu Mo Mang.ogg",
    'image': 'assets/images/tavern.jpg', 
    'audio_source': 'file', 
    'folder_name': 'ATP ARSM',
    'is_offline_mode': true,
    'version_number': 1
  },
  {
    'name': "5-Thiền Sâu",
    'path': "$_baseUrl/5 - Thien Sau.ogg",
    'image': 'assets/images/battlefield.jpg', 
    'audio_source': 'file', 
    'folder_name': 'ATP ARSM',
    'is_offline_mode': true,
    'version_number': 1
  },
  {
    'name': "8-Trước Khi Ngủ",
    'path': "$_baseUrl/8 - Trc Khi Ngu.ogg",
    'image': 'assets/images/cavern.jpg', 
    'audio_source': 'file', 
    'folder_name': 'ATP ARSM',
    'is_offline_mode': true,
    'version_number': 1
  },
  {
    'name': "10-Thư Giãn",
    'path': "$_baseUrl/10 - Thu Gian.ogg",
    'image': 'assets/images/rain.jpg', 
    'audio_source': 'file', 
    'folder_name': 'ATP ARSM',
    'is_offline_mode': true,
    'version_number': 1
  },
  {
    'name': "20-Tỉnh Táo",
    'path': "$_baseUrl/20 - Tinh Tao.ogg",
    'image': 'assets/images/demon.jpg', 
    'audio_source': 'file', 
    'folder_name': 'ATP ARSM',
    'is_offline_mode': true,
    'version_number': 1
  },
  {
    'name': "174-Giảm Đau",
    'path': "$_baseUrl/174 - Giam Dau.ogg",
    'image': 'assets/images/tavern.jpg', 
    'audio_source': 'file', 
    'folder_name': 'ATP ARSM',
    'is_offline_mode': true,
    'version_number': 1
  },
  {
    'name': "285-Trẻ Hóa",
    'path': "$_baseUrl/285 - Tre Hoa.ogg",
    'image': 'assets/images/cavern.jpg', 
    'audio_source': 'file', 
    'folder_name': 'ATP ARSM',
    'is_offline_mode': true,
    'version_number': 1
  },
  {
    'name': "396-Chữa Lo Âu",
    'path': "$_baseUrl/396 - Chua Lo Au.ogg",
    'image': 'assets/images/heaven.jpg', 
    'audio_source': 'file', 
    'folder_name': 'ATP ARSM',
    'is_offline_mode': true,
    'version_number': 1
  },
  {
    'name': "417-Làm Sạch Năng Lượng",
    'path': "$_baseUrl/417 - Lam Sach Nang Luong.ogg",
    'image': 'assets/images/market.jpg', 
    'audio_source': 'file', 
    'folder_name': 'ATP ARSM',
    'is_offline_mode': true,
    'version_number': 1
  },
  {
    'name': "432-Rung Động Tích Cực",
    'path': "$_baseUrl/432 - Rung Dong Tich Cuc.ogg",
    'image': 'assets/images/rain.jpg', 
    'audio_source': 'file', 
    'folder_name': 'ATP ARSM',
    'is_offline_mode': true,
    'version_number': 1
  },
  {
    'name': "528-Giải Phóng Cảm Xúc",
    'path': "$_baseUrl/528 - Giai Phong Cam Xuc.ogg",
    'image': 'assets/images/battlefield.jpg', 
    'audio_source': 'file', 
    'folder_name': 'ATP ARSM',
    'is_offline_mode': true,
    'version_number': 1
  },
  {
    'name': "639-Kết Nối",
    'path': "$_baseUrl/639 - Ket Noi.ogg",
    'image': 'assets/images/sea.jpg', 
    'audio_source': 'file', 
    'folder_name': 'ATP ARSM',
    'is_offline_mode': true,
    'version_number': 1
  },
  {
    'name': "741-Thanh Loc",
    'path': "$_baseUrl/741 - Thanh Loc.ogg",
    'image': 'assets/images/forest.jpg', 
    'audio_source': 'file', 
    'folder_name': 'ATP ARSM',
    'is_offline_mode': true,
    'version_number': 1
  },
  {
    'name': "852- Bình Yên Nội Tâm",
    'path': "$_baseUrl/852 - Binh Yen Noi Tam.ogg",
    'image': 'assets/images/deer.jpg', 
    'audio_source': 'file', 
    'folder_name': 'ATP ARSM',
    'is_offline_mode': true,
    'version_number': 1
  },
  {
    'name': "963-Trực Giác",
    'path': "$_baseUrl/963 - Truc Giac.ogg",
    'image': 'assets/images/sea.jpg', 
    'audio_source': 'file', 
    'folder_name': 'ATP ARSM',
    'is_offline_mode': true,
    'version_number': 1
  },
  {
    'name': "TN 2.5-Ngủ Sâu",
    'path': "$_baseUrl/TN/TN 2.5 - Ngu Sau.ogg",
    'image': 'assets/images/rain.jpg', 
    'audio_source': 'file', 
    'folder_name': 'ATP ARSM TN',
    'is_offline_mode': true,
    'version_number': 1
  },
  {
    'name': "TN 4-Ngủ Mơ Màng",
    'path': "$_baseUrl/TN/TN 4 - Ngu Mo Mang.ogg",
    'image': 'assets/images/rain.jpg', 
    'audio_source': 'file', 
    'folder_name': 'ATP ARSM TN',
    'is_offline_mode': true,
    'version_number': 1
  },
  {
    'name': "TN 5-Thiền Sâu",
    'path': "$_baseUrl/TN/TN 5 - Thien Sau.ogg",
    'image': 'assets/images/rain.jpg', 
    'audio_source': 'file', 
    'folder_name': 'ATP ARSM TN',
    'is_offline_mode': true,
    'version_number': 1
  },
  {
    'name': "TN 8-Trước Khi Ngủ",
    'path': "$_baseUrl/TN/TN 8 - Trc Khi Ngu.ogg",
    'image': 'assets/images/rain.jpg', 
    'audio_source': 'file', 
    'folder_name': 'ATP ARSM TN',
    'is_offline_mode': true,
    'version_number': 1
  },
  {
    'name': "TN 10-Thư Giãn",
    'path': "$_baseUrl/TN/TN 10 - Thu Gian.ogg",
    'image': 'assets/images/rain.jpg', 
    'audio_source': 'file', 
    'folder_name': 'ATP ARSM TN',
    'is_offline_mode': true,
    'version_number': 1
  },
  {
    'name': "TN 20-Tỉnh Táo",
    'path': "$_baseUrl/TN/TN 20 - Tinh Tao.ogg",
    'image': 'assets/images/rain.jpg', 
    'audio_source': 'file', 
    'folder_name': 'ATP ARSM TN',
    'is_offline_mode': true,
    'version_number': 1
  },
  {
    'name': "Hát ru brahms lullaby-sound110",
    'path': "$_baseUrl/Hat Ru brahms lullaby - sound110.ogg",
    'image': 'assets/images/rain.jpg', 
    'audio_source': 'file', 
    'folder_name': 'ATP ARSM',
    'is_offline_mode': true,
    'version_number': 1
  },
];