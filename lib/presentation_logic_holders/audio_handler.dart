import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rolify/entities/audio.dart';
import 'package:rolify/presentation_logic_holders/playing_sounds_singleton.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AudioCustomEvents { audioEnded, resumeAll, pauseAll }

Future<AudioHandler> initAudioService() async {
  final audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.rolify.app.audio',
      androidNotificationChannelName: 'Rolify',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidShowNotificationBadge: true,
      androidNotificationIcon: 'mipmap/ic_launcher_foreground',
      notificationColor: Color(0xFFF0F0F3),
    ),
  );
  audioHandler.setMockMediaItem('launcher_icon/512px_512px.png');

  return audioHandler;
}

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  Map<String, AudioPlayer> audioPlayers = {};
  Map<String, Future<AudioPlayer>> _audioPlayerFutures = {};
  List<AudioPlayer> playingAudio = [];
  List<AudioPlayer> pausedAudio = [];
  bool stoppingAll = false;

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
    audioPlayer.setVolume(audio.volume * PlayingSounds().masterVolume);
    audioPlayer.setLoopMode(audio.loopMode);
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
    });
    writeWidgetState();
  }

  Future<void> writeWidgetState() async {
    final prefs = await SharedPreferences.getInstance();
    final playingPaths = playingAudio.map((p) => _getAudioPath(p)).where((path) => path.isNotEmpty).toList();
    final state = {
      'playingPaths': playingPaths,
      'activePlaylistIds': PlayingSounds().activePlaylistIds,
      'masterVolume': PlayingSounds().masterVolume,
    };
    await prefs.setString('widget_state', jsonEncode(state));
  }

  void playAudioPlayer(AudioPlayer audioPlayer) {
    audioPlayer.play().then((_) async {
      if (audioPlayer.playing) {
        await audioPlayer.stop();
        await audioPlayer.seek(Duration.zero);
        playingAudio.remove(audioPlayer);
        customEvent.add(createAudioCustomEvent(
            AudioCustomEvents.audioEnded, _getAudioPath(audioPlayer)));
        _broadcastState();
      }
    });

    playingAudio.add(audioPlayer);
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
    for (final audioPlayer in pausedAudio) {
      playAudioPlayer(audioPlayer);
      playingAudio.add(audioPlayer);
    }
    pausedAudio = [];
    customEvent.add(createAudioCustomEvent(AudioCustomEvents.resumeAll));
    _broadcastState();
  }

  @override
  Future<void> pause() async {
    for (final audioPlayer in playingAudio) {
      await audioPlayer.stop();
      pausedAudio.add(audioPlayer);
    }
    playingAudio = [];
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
    playingAudio = [];
    pausedAudio = [];
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
    stop();
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
    if (extras != null) {
      final audio = Audio.fromJson(extras["audio"]);
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
        if (name == 'play') {
          playAudioPlayer(audioPlayer);
        }
        if (name == 'stop') {
          audioPlayer.stop();
          playingAudio.remove(audioPlayer);
          pausedAudio.remove(audioPlayer);
          _broadcastState();
        }
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
    if (name == 'set_master_volume' && extras != null) {
      final double volume = extras['volume'];
      for (final path in audioPlayers.keys) {
        final player = audioPlayers[path]!;
        Audio? audio;
        try {
          audio = PlayingSounds().playingAudios.firstWhere((a) => a.path == path);
        } catch (_) {
          try {
             audio = PlayingSounds().pausedAudios.firstWhere((a) => a.path == path);
          } catch (_) {}
        }
        
        if (audio != null) {
          player.setVolume(audio.volume * volume);
        } else {
          player.setVolume(volume);
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
    if (name == 'stop_all') {
      await stop();
      writeWidgetState();
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
