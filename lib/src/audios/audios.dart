// Thay "https://domain-cua-ban.com/audios/" bằng link host thực tế của bạn
const String _baseUrl = "https://raw.githubusercontent.com/tuthanika/ATP-Sound-Audio-File/refs/heads/main/audios";

List assetsAudios = const [
  {
    'name': "Bard's Lute",
    'path': "$_baseUrl/Bard's_Lute.mp3",
    'image': 'assets/images/tavern.jpg', 
    'audio_source': 'file', // QUAN TRỌNG: Ép thành 'file' để kích hoạt logic Tải/Stream
    'folder_name': 'Thư viện Cloud', // Gom chung vào 1 Folder
    'is_offline_mode': true, // True: Tải về khi phát lần đầu. False: Stream trực tiếp
    'version_number': 17 // Đổi version để ép app cập nhật
  },
  {
    'name': "Bard chill",
    'path': "$_baseUrl/Bard_chill_by_Oliver_Getzp.mp3",
    'image': 'assets/images/tavern.jpg', 
    'audio_source': 'file', 
    'folder_name': 'Thư viện Cloud',
    'is_offline_mode': true,
    'version_number': 17
  },
  {
    'name': "Battlefield",
    'path': "$_baseUrl/1/Battlefield.mp3",
    'image': 'assets/images/battlefield.jpg', 
    'audio_source': 'file', 
    'folder_name': 'Thư viện Cloud',
    'is_offline_mode': true,
    'version_number': 17
  },
  {
    'name': "Cavern",
    'path': "$_baseUrl/Cavern.mp3",
    'image': 'assets/images/cavern.jpg', 
    'audio_source': 'file', 
    'folder_name': 'Thư viện Cloud',
    'is_offline_mode': true,
    'version_number': 17
  },
  {
    'name': "Distant Thunder",
    'path': "$_baseUrl/1/Distant_Thunder.mp3",
    'image': 'assets/images/rain.jpg', 
    'audio_source': 'file', 
    'folder_name': 'Thư viện Cloud',
    'is_offline_mode': true,
    'version_number': 17
  },
  {
    'name': "Drafty Castle",
    'path': "$_baseUrl/Drafty_Castle.mp3",
    'image': 'assets/images/demon.jpg', 
    'audio_source': 'file', 
    'folder_name': 'Thư viện Cloud',
    'is_offline_mode': true,
    'version_number': 17
  },
  {
    'name': "Fireplace",
    'path': "$_baseUrl/1/Fireplace.mp3",
    'image': 'assets/images/tavern.jpg', 
    'audio_source': 'file', 
    'folder_name': 'Thư viện Cloud',
    'is_offline_mode': true,
    'version_number': 17
  },
  {
    'name': "Generic Dungeon",
    'path': "$_baseUrl/Generic_Dungeon.mp3",
    'image': 'assets/images/cavern.jpg', 
    'audio_source': 'file', 
    'folder_name': 'Thư viện Cloud',
    'is_offline_mode': true,
    'version_number': 17
  },
  {
    'name': "Gregorian Voices",
    'path': "$_baseUrl/1/Gregorian_Voices.mp3",
    'image': 'assets/images/heaven.jpg', 
    'audio_source': 'file', 
    'folder_name': 'Thư viện Cloud',
    'is_offline_mode': true,
    'version_number': 17
  },
  {
    'name': "Hearing Voices",
    'path': "$_baseUrl/Hearing_Voices.mp3",
    'image': 'assets/images/market.jpg', 
    'audio_source': 'file', 
    'folder_name': 'Thư viện Cloud',
    'is_offline_mode': true,
    'version_number': 17
  },
  {
    'name': "Heavy Rain",
    'path': "$_baseUrl/Heavy_Rain.mp3",
    'image': 'assets/images/rain.jpg', 
    'audio_source': 'file', 
    'folder_name': 'Thư viện Cloud',
    'is_offline_mode': true,
    'version_number': 17
  },
  {
    'name': "Into Battle",
    'path': "$_baseUrl/Into_Battle.mp3",
    'image': 'assets/images/battlefield.jpg', 
    'audio_source': 'file', 
    'folder_name': 'Thư viện Cloud',
    'is_offline_mode': true,
    'version_number': 17
  },
  {
    'name': "Morning Birds",
    'path': "$_baseUrl/Morning_Birds.mp3",
    'image': 'assets/images/sea.jpg', 
    'audio_source': 'file', 
    'folder_name': 'Thư viện Cloud',
    'is_offline_mode': true,
    'version_number': 17
  },
  {
    'name': "Night Forest",
    'path': "$_baseUrl/Night_Forest.mp3",
    'image': 'assets/images/forest.jpg', 
    'audio_source': 'file', 
    'folder_name': 'Thư viện Cloud',
    'is_offline_mode': true,
    'version_number': 17
  },
  {
    'name': "Our Mountain",
    'path': "$_baseUrl/Our_Mountain.mp3",
    'image': 'assets/images/deer.jpg', 
    'audio_source': 'file', 
    'folder_name': 'Thư viện Cloud',
    'is_offline_mode': true,
    'version_number': 17
  },
  {
    'name': "Pirates",
    'path': "$_baseUrl/Pirates.mp3",
    'image': 'assets/images/sea.jpg', 
    'audio_source': 'file', 
    'folder_name': 'Thư viện Cloud',
    'is_offline_mode': true,
    'version_number': 17
  },
  {
    'name': "Rain",
    'path': "$_baseUrl/Rain.mp3",
    'image': 'assets/images/rain.jpg', 
    'audio_source': 'file', 
    'folder_name': 'Thư viện Cloud',
    'is_offline_mode': true,
    'version_number': 17
  },
  {
    'name': "Sacred Valley",
    'path': "$_baseUrl/Sacred_Valley.mp3",
    'image': 'assets/images/heaven.jpg', 
    'audio_source': 'file', 
    'folder_name': 'Thư viện Cloud',
    'is_offline_mode': true,
    'version_number': 17
  },
  {
    'name': "Sea Coast",
    'path': "$_baseUrl/Sea_Coast.mp3",
    'image': 'assets/images/sea.jpg', 
    'audio_source': 'file', 
    'folder_name': 'Thư viện Cloud',
    'is_offline_mode': true,
    'version_number': 17
  },
  {
    'name': "Tavern",
    'path': "$_baseUrl/1/Tavern.mp3",
    'image': 'assets/images/tavern.jpg', 
    'audio_source': 'file', 
    'folder_name': 'Thư viện Cloud',
    'is_offline_mode': true,
    'version_number': 17
  },
  {
    'name': "Village",
    'path': "$_baseUrl/1/Village.mp3",
    'image': 'assets/images/market.jpg', 
    'audio_source': 'file', 
    'folder_name': 'Thư viện Cloud',
    'is_offline_mode': true,
    'version_number': 17
  },
];

// Cập nhật mảng version để báo cho App biết có danh sách âm thanh mới cần nạp vào Database
List versionNumberWithAudioUpdates = const [
  16, 
  17 // <-- Thêm số 17 vào đây
];