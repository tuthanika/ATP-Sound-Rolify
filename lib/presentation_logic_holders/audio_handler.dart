import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math'; 

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
import 'package:rolify/presentation_logic_holders/audio_download_manager.dart';

enum AudioCustomEvents { audioEnded, resumeAll, pauseAll }

class FileAudioSource extends StreamAudioSource {
  final File file;
  final String? contentType;

  FileAudioSource(this.file, {this.contentType});

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final int size = await file.length();
    final int startOffset = start ?? 0;
    final int endOffset = end ?? size;
    return StreamAudioResponse(
      sourceLength: size,
      contentLength: endOffset - startOffset,
      offset: startOffset,
      stream: file.openRead(start, end),
      contentType: contentType ?? 'audio/mpeg',
    );
  }
}


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

  final allAudios = await AudioData.getAllAudios();
  final audiosJsonList = allAudios.map((a) => a.toJson()).toList();
  await prefs.setString('audios', jsonEncode(audiosJsonList));

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

  // BẢN VÁ: Cờ lưu trữ những bài hát ĐƯỢC GỌI TỪ NÚT TUẦN TỰ/NGẪU NHIÊN
  final Set<String> _sequentialActivePaths = {};

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
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            // Ducking: lower volume is handled by just_audio if configured, 
            // but we can manually handle if needed.
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            if (playingAudio.isNotEmpty) {
              pause();
            }
            break;
        }
      }
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

  bool _handleSpecialFolderNext(Audio currentAudio) {
    if (currentAudio.folderName == null) return false;
    
    final specialFolders = PlayingSounds().activeSpecialFolders;
    if (!specialFolders.containsKey(currentAudio.folderName)) return false;

    final folderData = specialFolders[currentAudio.folderName]!;
    final mode = folderData['mode'] as String;
    List<Audio> audios = folderData['audios'] as List<Audio>;
    
    if (audios.isEmpty) return false;

    int currentIndex = audios.indexWhere((a) => a.path == currentAudio.path);

    if (currentAudio.loopMode == LoopMode.off) {
        if (currentIndex != -1) audios.removeAt(currentIndex);
        specialFolders[currentAudio.folderName]!['audios'] = audios;
        if (audios.isEmpty) {
            specialFolders.remove(currentAudio.folderName);
            return false; 
        }
        currentIndex--; 
    }

    int nextIndex = 0;
    if (mode == 'sequential') {
        nextIndex = currentIndex + 1;
        if (nextIndex >= audios.length) nextIndex = 0; 
    } else if (mode == 'random') {
        if (audios.length == 1) {
            nextIndex = 0;
        } else {
            if (currentAudio.loopMode == LoopMode.off) {
                 nextIndex = Random().nextInt(audios.length);
            } else {
                 do { nextIndex = Random().nextInt(audios.length); } while (nextIndex == currentIndex); 
            }
        }
    }

    final nextAudio = audios[nextIndex];
    
    _sequentialActivePaths.remove(currentAudio.path); // Xóa cờ bài vừa phát xong
    stopAudio(currentAudio, dispose: true); 
    
    Future.delayed(const Duration(milliseconds: 100), () {
      // Tiếp tục phát bài mới kèm cờ isSequential
      playAudio(nextAudio, isSequential: true);
    });
    
    return true; 
  }
  
   // BẢN VÁ: Hàm xử lý triệt để khi gặp File âm thanh bị hỏng/lỗi định dạng
  void _handleBrokenAudioNext(Audio brokenAudio) {
    if (brokenAudio.folderName == null) return;
    
    final specialFolders = PlayingSounds().activeSpecialFolders;
    if (!specialFolders.containsKey(brokenAudio.folderName)) return;

    final folderData = specialFolders[brokenAudio.folderName]!;
    final mode = folderData['mode'] as String;
    List<Audio> audios = folderData['audios'] as List<Audio>;
    
    if (audios.isEmpty) return;

    // 1. Gỡ bỏ vĩnh viễn file lỗi khỏi danh sách phát của phiên Tuần tự này
    int currentIndex = audios.indexWhere((a) => a.path == brokenAudio.path);
    if (currentIndex != -1) {
       audios.removeAt(currentIndex);
    }
    
    specialFolders[brokenAudio.folderName]!['audios'] = audios;
    _sequentialActivePaths.remove(brokenAudio.path);

    // Nếu xóa xong mà thư mục trống trơn (tất cả file đều lỗi) -> Dừng luôn để chống crash
    if (audios.isEmpty) {
        specialFolders.remove(brokenAudio.folderName);
        return; 
    }

    // 2. Tính toán khéo léo bài tiếp theo
    int nextIndex = 0;
    if (mode == 'sequential') {
        // Vì bài lỗi đã bị xóa, các bài sau sẽ dồn vị trí lên. 
        // Do đó currentIndex hiện tại chính là bài tiếp theo!
        nextIndex = currentIndex;
        if (nextIndex >= audios.length || nextIndex < 0) nextIndex = 0; 
    } else if (mode == 'random') {
        nextIndex = Random().nextInt(audios.length);
    }

    final nextAudio = audios[nextIndex];
    
    // 3. Tự động ra lệnh phát bài mới
    Future.delayed(const Duration(milliseconds: 100), () {
      playAudio(nextAudio, isSequential: true);
    });
  }

  // BẢN VÁ: Truyền cờ isFromSpecialFolder xuyên suốt xuống lõi để định hình ExoPlayer ngay từ đầu
  Future<AudioPlayer> getAudioPlayer(Audio audio, {bool isFromSpecialFolder = false}) async {
    if (audioPlayers.containsKey(audio.path)) {
      return audioPlayers[audio.path]!;
    }
    
    if (_audioPlayerFutures.containsKey(audio.path)) {
      return _audioPlayerFutures[audio.path]!;
    }

    final future = _initAudioPlayer(audio, isFromSpecialFolder: isFromSpecialFolder);
    _audioPlayerFutures[audio.path] = future;
    
    final player = await future;
    audioPlayers[audio.path] = player;
    _audioPlayerFutures.remove(audio.path);
    return player;
  }

  Future<AudioPlayer> _initAudioPlayer(Audio audio, {bool isFromSpecialFolder = false}) async {
    final audioPlayer = AudioPlayer(handleInterruptions: false);

    final playablePath = await AudioFileManager.getPlayablePath(
        audio.path, audio.name, audio.isOfflineMode
    );

    if (audio.audioSource == LocalAudioSource.assets) {
      await audioPlayer.setAsset(playablePath);
    } else if (playablePath.startsWith('http')) {
      await audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(playablePath)));
    } else if (playablePath.startsWith('content://') || playablePath.startsWith('file://')) {
      await audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(playablePath)));
    } else {
      // BẢN VÁ: Sử dụng StreamAudioSource trên Windows để hỗ trợ Tiếng Việt Unicode 100%
      if (Platform.isWindows) {
        await audioPlayer.setAudioSource(FileAudioSource(File(playablePath)));
      } else {
        await audioPlayer.setFilePath(playablePath);
      }
    }
    
    // ĐÃ XÓA BỎ HOÀN TOÀN CỜ CHECK FOLDER NAME TẠI ĐÂY!
    // Chạm thủ công -> isFromSpecialFolder = false -> Nạp LoopMode.one y hệt Main UI.
    await audioPlayer.setVolume(audio.volume * PlayingSounds().masterVolume);
    // Lưu ý: setLoopMode đã được chuyển lên playAudio để định đoạt bằng hành động

    audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (playingAudio.contains(audioPlayer)) {
          playingAudio.remove(audioPlayer);
          
          bool isHandledByFolder = false;
          
          // ĐIỀU KIỆN RÀNG BUỘC CỦA BẠN: Chỉ check logic tuần tự NẾU có cờ isSequential
          if (_sequentialActivePaths.contains(audio.path)) {
             isHandledByFolder = _handleSpecialFolderNext(audio);
          }

          // Nếu không có cờ, báo kết thúc bình thường (logic Main UI)
          if (!isHandledByFolder) {
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
      'activePlaylistIds': PlayingSounds().activePlaylistIds,
    });
    writeWidgetState();
  }

  // BẢN VÁ: Thêm tham số isFromSpecialFolder để phân biệt rạch ròi
  // Thêm biến isSequential
  Future<void> playAudio(Audio audio, {bool broadcast = true, bool isSequential = false}) async {
    
    if (isSequential) {
      // Đánh dấu bài này đang chạy bằng logic Tuần tự
      _sequentialActivePaths.add(audio.path);
    } else {
      // RESET VỀ LOGIC GỐC: Xóa cờ tuần tự và dọn dẹp Player cũ
      _sequentialActivePaths.remove(audio.path);
      if (audio.folderName != null) {
        PlayingSounds().activeSpecialFolders.remove(audio.folderName);
      }
      
      final existingPlayer = audioPlayers[audio.path];
      if (existingPlayer != null && existingPlayer.loopMode == LoopMode.off && audio.loopMode == LoopMode.one) {
        audioPlayers.remove(audio.path);
        _audioPlayerFutures.remove(audio.path);
        try {
          await existingPlayer.stop();
          await existingPlayer.dispose();
        } catch (_) {}
      }
    }

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
      final player = await getAudioPlayer(audio);
      if (!audioPlayers.containsKey(audio.path)) return; 

      await player.pause();
      
      // LOGIC CHỐT HẠ: Ép tắt loop nếu chạy tuần tự, còn lại dùng loopMode chuẩn của sound
      await player.setLoopMode(isSequential ? LoopMode.off : audio.loopMode);
      await player.setVolume(audio.volume * PlayingSounds().masterVolume);
      
      await player.seek(Duration.zero);
      
      if (!player.playing) {
        PlayingSounds().playAudio(audio);
        // Đã update: truyền thêm đối tượng audio vào để hệ thống biết bài nào đang chạy
        playAudioPlayer(player, audio); 
      }
    } catch (e) {
      debugPrint("Lỗi Play Audio: $e");
      playingAudio.removeWhere((p) => _getAudioPath(p) == audio.path);
      final brokenPlayer = audioPlayers.remove(audio.path);
      try { brokenPlayer?.dispose(); } catch(_) {}
      PlayingSounds().removeAudio(audio);
      _broadcastState();

      // BẢN VÁ: Nếu đang chạy Tuần tự/Ngẫu nhiên mà gặp file nạp bị lỗi -> Tự bỏ qua
      if (isSequential || _sequentialActivePaths.contains(audio.path)) {
        debugPrint("Tự động bỏ qua file hỏng: ${audio.name}");
        _handleBrokenAudioNext(audio);
      }
    } finally {
      _loadingPaths.remove(audio.path);
    }

    if (broadcast) _broadcastState();
  }

  // --- HÀM TÁI SỬ DỤNG: Đã thêm tham số dispose để trị lỗi giật/ngắt quãng ---
  Future<void> stopAudio(Audio audio, {bool dispose = true}) async {
    _sequentialActivePaths.remove(audio.path); // Xóa cờ nếu bị stop
    playingAudio.removeWhere((p) => _getAudioPath(p) == audio.path);
    pausedAudio.removeWhere((p) => _getAudioPath(p) == audio.path);
    PlayingSounds().removeAudio(audio);
    _broadcastState();

    if (dispose) {
      final player = audioPlayers.remove(audio.path);
      if (player != null) {
        try {
          await player.stop();
          await player.dispose(); 
        } catch (e) {
          debugPrint("Lỗi stopAudio dispose: $e");
        }
      }
    } else {
      final player = audioPlayers[audio.path];
      if (player != null) {
        try {
          // BẢN VÁ TUYỆT ĐỐI: Không dùng stop() cho máy phát tái sử dụng.
          // Lệnh stop() sẽ đóng vĩnh viễn File Local. Ta chỉ Pause và tua về 0!
          await player.pause();
          await player.seek(Duration.zero);
        } catch (e) {}
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
    await prefs.setString('widget_playing_paths_csv', playingPaths.join(',,'));

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      try {
        const MethodChannel('com.tuthanika.rolify/widget').invokeMethod('updateWidgets');
      } catch (e) {
        debugPrint("Lỗi update Widget: $e");
      }
    });
  }

  // Thêm tham số audioContext để biết chính xác bài nào đang bị lỗi
  void playAudioPlayer(AudioPlayer audioPlayer, [Audio? audioContext]) {
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
      
      if (audioContext != null) {
         PlayingSounds().removeAudio(audioContext);
      }
      _broadcastState();

      // BẢN VÁ: Nếu ấn nút Play mà loa bị lỗi, tự động Next sang bài mới
      if (audioContext != null && _sequentialActivePaths.contains(audioContext.path)) {
         _handleBrokenAudioNext(audioContext);
      }
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
    
    // MỚI: Dọn dẹp triệt để rác, giải phóng RAM và bộ giải mã của just_audio khi dừng toàn bộ
    for (final player in audioPlayers.values) {
      try {
        await player.dispose();
      } catch (_) {}
    }
    audioPlayers.clear();

    playingAudio = [];
    pausedAudio = [];
    _loadingPaths.clear();
    PlayingSounds().activePlaylistIds = []; // BẢN VÁ: Clear sạch playlist khi dừng hẳn
    PlayingSounds().activeSpecialFolders.clear(); 

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

  @override
  Future customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'set_master_volume') {
      final double volume = (extras?['volume'] as int? ?? 100) / 100.0;
      PlayingSounds().masterVolume = volume;
      PlayingSounds().masterVolumeNotifier.value = volume;
      
      final allAudios = await AudioData.getAllAudios();
      final audioMap = { for (var a in allAudios) a.path: a };
      
      for (var entry in audioPlayers.entries) {
        final String path = entry.key;
        final player = entry.value;
        
        final Audio? audio = audioMap[path];
        if (audio != null) {
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
          
          // KHÔNG CẦN CHECK FOLDER NAME, cứ chạm ngoài là dọn dẹp Tuần Tự
          PlayingSounds().activeSpecialFolders.clear();

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
      PlayingSounds().activePlaylistIds = []; // BẢN VÁ: Cầu chì bảo hiểm cuối cùng
      PlayingSounds().activeSpecialFolders.clear();
      PlayingSounds().playingAudios = [];
      PlayingSounds().pausedAudios = [];
      writeWidgetState();
      _broadcastState();
      return null;
    }

    if (name == 'play_special_folder') {
      final folderName = extras?['folderName'];
      final mode = extras?['mode']; 
      final audiosJson = extras?['audios'] as List<dynamic>;
      
      if (folderName != null && audiosJson.isNotEmpty) {
        final audios = audiosJson.map((e) => Audio.fromJson(e)).toList();
        
        for (var a in audios) {
          // Khi bắt đầu phát Tuần tự, dọn dẹp sạch sẽ các trình phát rác đang vướng
          await stopAudio(a, dispose: true); 
        }
        
        PlayingSounds().activeSpecialFolders[folderName] = {
          'mode': mode,
          'audios': audios,
        };
        
        Audio firstAudio = audios.first;
        if (mode == 'random') {
          firstAudio = audios[Random().nextInt(audios.length)];
        }
        // BẢN VÁ: Gắn cờ true để xác nhận quyền kích hoạt Tuần tự từ nút bấm
        await playAudio(firstAudio, isSequential: true);
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
              await stopAudio(a); // Tự động dispose = true để giải phóng RAM
            }
        }
      }
      writeWidgetState();
      return null;
    }

    if (name == 'broadcast_state') {
      writeWidgetState();
      _broadcastState();
      return null;
    }

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
      'name': name.toString().split('.').last, 
      'audioPath': audioPath,
    };
  }
}