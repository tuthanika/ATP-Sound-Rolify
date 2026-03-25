import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math'; // <-- Bổ sung thư viện Math

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phone_state/phone_state.dart';
import 'package:rolify/data/audios.dart';
import 'package:rolify/data/playlist.dart';
import 'package:rolify/entities/audio.dart';
import 'package:rolify/presentation_logic_holders/playing_sounds_singleton.dart';
import 'package:rolify/presentation_logic_holders/singletons/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';


enum AudioCustomEvents { audioEnded, resumeAll, pauseAll }

Future<AudioHandler> initAudioService() async {
  final audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.tuthanika.rolify.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,

      androidShowNotificationBadge: true,

      androidNotificationIcon: 'mipmap/ic_launcher_foreground',
      notificationColor: Color(0xFFF0F0F3),
    ),
  );
  audioHandler.setMockMediaItem('launcher_icon/512px_512px.png');

  final prefs = await SharedPreferences.getInstance();
  int maxLimit = int.tryParse(prefs.get('max_concurrent_audios').toString()) ?? 30;
  (audioHandler as MyAudioHandler).setMaxLimit(maxLimit);

  // Force sync All Audios to SharedPreferences for AppWidget on fresh install
  final allAudios = await AudioData.getAllAudios();
  final audiosJsonList = allAudios.map((a) => a.toJson()).toList();
  await prefs.setString('audios', jsonEncode(audiosJsonList));

  // Cập nhật giao diện Widget ngay lập tức cho lần cài đặt đầu tiên
  try {
    const MethodChannel('com.tuthanika.rolify/widget').invokeMethod('updateWidgets');
  } catch (e) {
    debugPrint("Init update widget error: $e");
  }

  return audioHandler;
}

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  Map<String, AudioPlayer> audioPlayers = {};
  Map<String, Future<AudioPlayer>> _audioPlayerFutures = {};
  List<AudioPlayer> playingAudio = [];
  List<AudioPlayer> pausedAudio = [];
  bool stoppingAll = false;
  bool _wasAutoPausedByCall = false;
  int _maxConcurrentAudios = 30;
  final Set<String> _loadingPaths = {};
  Timer? _debounceTimer;

  void setMaxLimit(int limit) {
    _maxConcurrentAudios = limit;
  }


  MyAudioHandler() {
    _initFocusListener();
    _initPhoneStateListener();
  }

  void _initPhoneStateListener() {
    if (Platform.isAndroid) {
      PhoneState.stream.listen((status) {
        if (AppState().autoPauseDuringCalls) {
          if (status == PhoneStateStatus.CALL_INCOMING || 
              status == PhoneStateStatus.CALL_STARTED) {
            if (playingAudio.isNotEmpty) {
              _wasAutoPausedByCall = true;
              pause();
            }
          } else if (status == PhoneStateStatus.CALL_ENDED) {
            if (_wasAutoPausedByCall) {
              _wasAutoPausedByCall = false;
              play();
            }
          }
        }
      });
    }
  }

  void _initFocusListener() async {
    final session = await AudioSession.instance;
    session.interruptionEventStream.listen((event) {
      // DUCKING ONLY logic - we let just_audio handle ducking if it wants
      // but we REMOVE the auto-pause on generic focus loss
      // to satisfy the "only pause for calls" requirement.
    });
  }

  Future<void> setMockMediaItem(String path) async {
    final byteData = await rootBundle.load('assets/$path');

    final file = File('${(await getTemporaryDirectory()).path}/mock.png');
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    final mockMediaItem = MediaItem(
      id: "id",
      album: "For awesome roleplayers",
      title: "Rolify",
      artUri: Uri.parse('file://${file.path}'),
    );

    mediaItem.add(mockMediaItem);
  }

  // --- HÀM XỬ LÝ CHUYỂN BÀI TỰ ĐỘNG CHO FOLDER ---
  bool _handleSpecialFolderNext(Audio currentAudio) {
    if (currentAudio.folderName == null) return false;
    
    final specialFolders = PlayingSounds().activeSpecialFolders;
    if (!specialFolders.containsKey(currentAudio.folderName)) return false;

    final folderData = specialFolders[currentAudio.folderName]!;
    final mode = folderData['mode'] as String;
    List<Audio> audios = folderData['audios'] as List<Audio>;
    
    if (audios.isEmpty) return false;

    int currentIndex = audios.indexWhere((a) => a.path == currentAudio.path);

    // --- LOGIC MỚI TẠI ĐÂY ---
    // Kiểm tra cấu hình Loop của chính Audio đó (dựa theo UI bạn đã set). 
    // Nếu nó đang là tắt Loop -> nó chỉ được phát 1 lần -> xóa nó khỏi hàng đợi vĩnh viễn.
    if (currentAudio.loopMode == LoopMode.off) {
        if (currentIndex != -1) {
            audios.removeAt(currentIndex);
        }
        
        // Cập nhật lại danh sách thực tế của nhóm
        specialFolders[currentAudio.folderName]!['audios'] = audios;

        // Nếu tất cả các bài đều tắt Loop và đã phát hết sạch -> Dừng hoàn toàn nhóm
        if (audios.isEmpty) {
            specialFolders.remove(currentAudio.folderName);
            return false; // Trả về false để kích hoạt event dừng bình thường
        }

        // Quan trọng: Lùi currentIndex lại 1 đơn vị vì bài hiện tại vừa bị xóa, 
        // để khi +1 ở logic tuần tự dưới nó sẽ trượt vào đúng bài tiếp theo
        currentIndex--; 
    }
    // -------------------------

    int nextIndex = 0;

    if (mode == 'sequential') {
        nextIndex = currentIndex + 1;
        if (nextIndex >= audios.length) nextIndex = 0; // Vòng lại các bài còn lại trong hàng đợi
    } else if (mode == 'random') {
        if (audios.length == 1) {
            nextIndex = 0;
        } else {
            // Nếu bài cũ vừa bị xóa (Loop.off) -> random tự do. 
            // Nếu bài cũ còn giữ lại (Loop.on) -> random sao cho tránh trùng bài vừa phát
            if (currentAudio.loopMode == LoopMode.off) {
                 nextIndex = Random().nextInt(audios.length);
            } else {
                 do {
                     nextIndex = Random().nextInt(audios.length);
                 } while (nextIndex == currentIndex); 
            }
        }
    }

    final nextAudio = audios[nextIndex];
    
    // Ép stopAudio cũ để UI tắt đèn
    stopAudio(currentAudio);
    
    // Phát bài tiếp theo sau delay nhỏ để không kẹt Frame
    Future.delayed(const Duration(milliseconds: 100), () {
      playAudio(nextAudio);
    });
    
    return true; 
  }
  // -------------------------------------

  Future<AudioPlayer> getAudioPlayer(Audio audio) async {
    if (audioPlayers.containsKey(audio.path)) {
      return audioPlayers[audio.path]!;
    }
    
    if (_audioPlayerFutures.containsKey(audio.path)) {
      return _audioPlayerFutures[audio.path]!;
    }

    final future = _initAudioPlayer(audio);
    _audioPlayerFutures[audio.path] = future;
    
    final player = await future;
    audioPlayers[audio.path] = player;
    _audioPlayerFutures.remove(audio.path);
    return player;
  }

  Future<AudioPlayer> _initAudioPlayer(Audio audio) async {
    final audioPlayer = AudioPlayer(handleInterruptions: false);

    if (audio.audioSource == LocalAudioSource.assets) {
      await audioPlayer.setAsset(audio.path);
    } else if (audio.path.startsWith('content://') ||
        audio.path.startsWith('file://')) {
      await audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(audio.path)));
    } else {
      await audioPlayer.setFilePath(audio.path);
    }
    
    // Cập nhật Loop Mode tắt lặp nếu đang ở chế độ Playlist Folder
    bool isSpecial = audio.folderName != null && PlayingSounds().activeSpecialFolders.containsKey(audio.folderName);
    audioPlayer.setVolume(audio.volume * PlayingSounds().masterVolume);
    audioPlayer.setLoopMode(isSpecial ? LoopMode.off : audio.loopMode);

    audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (playingAudio.contains(audioPlayer)) {
          playingAudio.remove(audioPlayer);
          
          // Kiểm tra xem có chuyển bài tự động không, nếu không thì end bình thường
          if (!_handleSpecialFolderNext(audio)) {
            customEvent.add(createAudioCustomEvent(AudioCustomEvents.audioEnded, audio.path));
            _broadcastState();
          }
        }
      }
    });

    return audioPlayer;
  }

  String _getAudioPath(AudioPlayer audioPlayer) {
    return audioPlayers.keys.firstWhere(
        (path) => audioPlayers[path] == audioPlayer,
        orElse: () => '');
  }

  void _broadcastState() {
    final playingPaths = playingAudio.map((p) => _getAudioPath(p)).where((path) => path.isNotEmpty).toList();
    final pausedPaths = pausedAudio.map((p) => _getAudioPath(p)).where((path) => path.isNotEmpty).toList();
    
    customEvent.add({
      'name': 'state_update',
      'playingPaths': playingPaths,
      'pausedPaths': pausedPaths,
      'masterVolume': PlayingSounds().masterVolume,
    });
    writeWidgetState();
  }

  Future<void> playAudio(Audio audio, {bool broadcast = true}) async {
    playingAudio.removeWhere((p) => _getAudioPath(p) == audio.path);
    pausedAudio.removeWhere((p) => _getAudioPath(p) == audio.path);

    if ((playingAudio.length + _loadingPaths.length) >= _maxConcurrentAudios) {
      debugPrint("Đạt giới hạn phát âm thanh đồng thời!");
      customEvent.add({'name': 'limit_reached', 'limit': _maxConcurrentAudios});
      return; 
    }

    if (_loadingPaths.contains(audio.path)) return; 
    _loadingPaths.add(audio.path);

    try {
      if (!audioPlayers.containsKey(audio.path)) {
        final player = AudioPlayer(handleInterruptions: false);
        audioPlayers[audio.path] = player; 

        if (audio.audioSource == LocalAudioSource.assets) {
          await player.setAsset(audio.path);
        } else if (audio.path.startsWith('content://') || audio.path.startsWith('file://')) {
          await player.setAudioSource(AudioSource.uri(Uri.parse(audio.path)));
        } else {
          await player.setFilePath(audio.path);
        }
        
        if (!audioPlayers.containsKey(audio.path)) {
             await player.stop();
             await player.dispose();
             return;
        }

        // Cập nhật Loop Mode tắt lặp nếu đang ở chế độ Playlist Folder
        bool isSpecial = audio.folderName != null && PlayingSounds().activeSpecialFolders.containsKey(audio.folderName);
        player.setVolume(audio.volume * PlayingSounds().masterVolume);
        player.setLoopMode(isSpecial ? LoopMode.off : audio.loopMode);
        
        player.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            if (playingAudio.contains(player)) {
              playingAudio.remove(player);
              if (!_handleSpecialFolderNext(audio)) {
                customEvent.add(createAudioCustomEvent(AudioCustomEvents.audioEnded, audio.path));
                _broadcastState();
              }
            }
          }
        });

        PlayingSounds().playAudio(audio);
        playAudioPlayer(player);
      } else {
        final player = audioPlayers[audio.path]!;
        await player.seek(Duration.zero);
        if (!player.playing) {
          PlayingSounds().playAudio(audio);
          playAudioPlayer(player);
        }
      }
    } catch (e) {
      debugPrint("Lỗi Play Audio: $e");
      playingAudio.removeWhere((p) => _getAudioPath(p) == audio.path);
      final brokenPlayer = audioPlayers.remove(audio.path);
      try { brokenPlayer?.dispose(); } catch(_) {}
      PlayingSounds().removeAudio(audio);
      _broadcastState();
    } finally {
      _loadingPaths.remove(audio.path);
    }

    if (broadcast) _broadcastState();
  }

  Future<void> stopAudio(Audio audio) async {
    // 1. XÓA ĐỒNG BỘ: Cập nhật UI Widget ngay lập tức để chặn lệnh rác
    playingAudio.removeWhere((p) => _getAudioPath(p) == audio.path);
    pausedAudio.removeWhere((p) => _getAudioPath(p) == audio.path);
    PlayingSounds().removeAudio(audio);
    _broadcastState();

    // 2. XÓA BẤT ĐỒNG BỘ: Dọn dẹp engine an toàn
    final player = audioPlayers.remove(audio.path);
    if (player != null) {
      try {
        await player.stop();
        await player.dispose(); 
      } catch (e) {
        debugPrint("Lỗi stopAudio: $e");
      }
    }
  }

  Future<void> writeWidgetState() async {
    final prefs = await SharedPreferences.getInstance();
    final playingPaths = playingAudio.map((p) => _getAudioPath(p)).where((path) => path.isNotEmpty).toList();
    final state = {
      'playingPaths': playingPaths,
      'activePlaylistIds': PlayingSounds().activePlaylistIds,
      'masterVolume': PlayingSounds().masterVolume,
      'isPlaying': playingAudio.isNotEmpty,
    };
    await prefs.setString('widget_state', jsonEncode(state));
    
    // Lưu thành String bình thường để chống crash ClassCastException trên Android
    await prefs.setString('widget_playing_paths_csv', playingPaths.join(',,'));

    // Debounce chặn Spam MethodChannel làm đứng UI
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      try {
        const MethodChannel('com.tuthanika.rolify/widget').invokeMethod('updateWidgets');
      } catch (e) {
        debugPrint("Lỗi update Widget: $e");
      }
    });
  }

  void playAudioPlayer(AudioPlayer audioPlayer) {
    audioPlayer.play().catchError((e) {
      debugPrint("Lỗi playAudioPlayer: $e");
      playingAudio.remove(audioPlayer);
      
      final path = _getAudioPath(audioPlayer);
      if (path.isNotEmpty) {
        audioPlayers.remove(path);
      }
      try {
        audioPlayer.dispose();
      } catch (_) {}
      
      _broadcastState();
    });

    if (!playingAudio.contains(audioPlayer)) {
      playingAudio.add(audioPlayer);
    }
    _broadcastState();

    playbackState.add(PlaybackState(
      controls: [
        MediaControl.pause,
        MediaControl.stop,
      ],
      processingState: AudioProcessingState.ready,
      playing: true,
    ));
  }

  @override
  Future<void> play() async {
    final toPlay = List<AudioPlayer>.from(pausedAudio);
    pausedAudio.clear();

    for (final audioPlayer in toPlay) {
      playAudioPlayer(audioPlayer);
    }
    customEvent.add(createAudioCustomEvent(AudioCustomEvents.resumeAll));
    _broadcastState();
  }

  @override
  Future<void> pause() async {
    if (AppState().stopInsteadOfPause) {
      await stop();
      PlayingSounds().activePlaylistIds = [];
      PlayingSounds().playingAudios = [];
      PlayingSounds().pausedAudios = [];
      _broadcastState();
      return;
    }
    final toPause = List<AudioPlayer>.from(playingAudio);
    playingAudio.clear();

    for (final audioPlayer in toPause) {
      await audioPlayer.pause();
      if (!pausedAudio.contains(audioPlayer)) {
        pausedAudio.add(audioPlayer);
      }
    }
    _broadcastState();

    playbackState.add(PlaybackState(
      controls: [
        MediaControl.play,
        MediaControl.stop,
      ],
      processingState: AudioProcessingState.ready,
      playing: false,
    ));

    customEvent.add(createAudioCustomEvent(AudioCustomEvents.pauseAll));
  }

  @override
  Future<void> stop() async {
    for (final audioPlayer in playingAudio) {
      await audioPlayer.stop();
    }
    for (final audioPlayer in pausedAudio) {
      await audioPlayer.stop();
    }
    
    // MỚI: Dọn dẹp triệt để rác, giải phóng RAM và bộ giải mã của just_audio
    for (final player in audioPlayers.values) {
      try {
        await player.dispose();
      } catch (_) {}
    }
    audioPlayers.clear();

    playingAudio = [];
    pausedAudio = [];
    _loadingPaths.clear();
    
    PlayingSounds().activeSpecialFolders.clear(); // <-- Dọn dẹp hàng đợi Playlist

    _broadcastState();

    playbackState.add(PlaybackState(
      controls: [],
      processingState: AudioProcessingState.idle,
      playing: false,
    ));

    super.stop();
  }

  @override
  Future<void> onTaskRemoved() {
    if (!AppState().playInBackground) {
      stop();
    }
    return super.onTaskRemoved();
  }


  ///
  /// Expect extras as:
  /// {
  ///   "audio": value,
  ///   "param": value
  /// }
  @override
  Future customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'set_master_volume') {
      final double volume = (extras?['volume'] as int? ?? 100) / 100.0;
      PlayingSounds().masterVolume = volume;
      PlayingSounds().masterVolumeNotifier.value = volume;
      
      final allAudios = await AudioData.getAllAudios();
      
      for (var entry in audioPlayers.entries) {
        final String path = entry.key;
        final player = entry.value;
        
        final int audioIndex = allAudios.indexWhere((a) => a.path == path);
        if (audioIndex >= 0) {
          final Audio audio = allAudios[audioIndex];
          player.setVolume(audio.volume * volume);
        } else {
          player.setVolume(volume);
        }
      }
      writeWidgetState();

      return null;
    }

    if (name == 'play_audio') {
      final String? path = extras?['path'];
      if (path != null) {
        final allAudios = await AudioData.getAllAudios();
        try {
          final audio = allAudios.firstWhere((a) => a.path == path);
          if (PlayingSounds().playingAudios.contains(audio)) {
             await stopAudio(audio);
          } else {
             await playAudio(audio);
          }
        } catch (e) {
           debugPrint("Lỗi tại customAction: $e");
        }
      }
      writeWidgetState();
      return null;
    }

    if (name == 'play_playlist') {
      final String? id = extras?['id'];
      if (id != null) {
        final allPlaylists = await PlaylistData.getAllPlaylist();
        final pIndex = int.tryParse(id);
        if (pIndex != null && pIndex >= 0 && pIndex < allPlaylists.length) {
          final playlist = allPlaylists[pIndex];
          final isAlreadyActive = PlayingSounds().activePlaylistIds.contains(id);

          if (isAlreadyActive) {
            PlayingSounds().activePlaylistIds.remove(id);
            for (final audio in playlist.audios) {
              await stopAudio(audio);
            }
          } else {
            PlayingSounds().activePlaylistIds.add(id);
            PlayingSounds().isPlayingPlaylist.value = true;
            for (final audio in playlist.audios) {
              await playAudio(audio);
              await Future.delayed(const Duration(milliseconds: 50));
            }
          }
          PlayingSounds().activePlaylistIdsNotifier.value = 
              List.from(PlayingSounds().activePlaylistIds);
        }
      }
      writeWidgetState();
      return null;
    }

    if (name == 'play_pause') {
      if (playingAudio.isNotEmpty) {
        await pause();
      } else if (pausedAudio.isNotEmpty) {
        await play();
      }
      writeWidgetState();
      return null;
    }

    if (name == 'stop_all') {
      await stop();
      PlayingSounds().activePlaylistIds = [];
      PlayingSounds().playingAudios = [];
      PlayingSounds().pausedAudios = [];
      writeWidgetState();
      _broadcastState();
      return null;
    }

    // --- CÁC HÀM XỬ LÝ LỆNH TỪ UI NHÓM (FOLDER) ---
    if (name == 'play_special_folder') {
      final folderName = extras?['folderName'];
      final mode = extras?['mode']; 
      final audiosJson = extras?['audios'] as List<dynamic>;
      
      if (folderName != null && audiosJson.isNotEmpty) {
        final audios = audiosJson.map((e) => Audio.fromJson(e)).toList();
        
        // Dừng tất cả các audio thuộc folder này đang phát để reset lại
        for (var a in audios) {
          await stopAudio(a);
        }
        
        // Lưu vào hàng đợi ảo
        PlayingSounds().activeSpecialFolders[folderName] = {
          'mode': mode,
          'audios': audios,
        };
        
        // Bốc bài đầu tiên (hoặc random) để mồi phát
        Audio firstAudio = audios.first;
        if (mode == 'random') {
          firstAudio = audios[Random().nextInt(audios.length)];
        }
        await playAudio(firstAudio);
      }
      writeWidgetState();
      return null;
    }

    if (name == 'stop_special_folder') {
      final folderName = extras?['folderName'];
      final audiosJson = extras?['audios'] as List<dynamic>?;
      if (folderName != null) {
        PlayingSounds().activeSpecialFolders.remove(folderName);
        if (audiosJson != null) {
            final audios = audiosJson.map((e) => Audio.fromJson(e)).toList();
            for (var a in audios) {
              await stopAudio(a);
            }
        }
      }
      writeWidgetState();
      return null;
    }
    // ----------------------------------------------

    if (name == 'broadcast_state') {
      writeWidgetState();
      _broadcastState();
      return null;
    }

    // Audio-specific actions
    if (extras != null && extras.containsKey("audio")) {
      final audio = Audio.fromJson(extras["audio"]);
      
      if (extras["param"] == null) {
        if (name == 'play') {
          await playAudio(audio);
          return null;
        }
        if (name == 'stop') {
          await stopAudio(audio);
          return null;
        }
      }

      final audioPlayer = await getAudioPlayer(audio);
      if (extras["param"] != null) {
        final dynamic param = extras["param"];

        if (name == 'set_volume') {
          audioPlayer.setVolume(param);
        }
        if (name == 'loop') {
          audioPlayer.setLoopMode(param ? LoopMode.one : LoopMode.off);
        }
      } else {
        if (name == 'is_playing') {
          return audioPlayer.playing;
        }
        if (name == 'get_volume') {
          return audioPlayer.volume;
        }
        if (name == 'get_loop') {
          return audioPlayers[audio.path]!.loopMode == LoopMode.one;
        }
      }
    }

    if (name == 'update_max_limit') {
      _maxConcurrentAudios = int.tryParse(extras?['limit'].toString() ?? '30') ?? 30;
      return null;
    }

    return super.customAction(name, extras);
  }

  Map<String, dynamic> createAudioCustomEvent(AudioCustomEvents name,
      [String? audioPath]) {
    return {
      'name': name.toString().split('.').last, // Secure string serialization
      'audioPath': audioPath,
    };
  }
}