import 'package:flutter/material.dart';
import 'package:rolify/data/audios.dart';
import 'package:rolify/entities/audio.dart';

class PlayingSounds {
  static final PlayingSounds _singleton = PlayingSounds._internal();
  List<Audio> playingAudios = [];
  List<Audio> pausedAudios = [];
  List<String> activePlaylistIds = [];
  double masterVolume = 1.0;
  final ValueNotifier<bool> isPlayingPlaylist = ValueNotifier(false);
  final ValueNotifier<int> stateChangeNotifier = ValueNotifier(0);
  final ValueNotifier<double> masterVolumeNotifier = ValueNotifier(1.0);
  final ValueNotifier<List<String>> activePlaylistIdsNotifier = ValueNotifier([]);


  factory PlayingSounds() {
    return _singleton;
  }

  PlayingSounds._internal();

  _notify() {
    stateChangeNotifier.value++;
  }

  updateAudio(Audio audio) {
    final playingIndex = playingAudios.indexOf(audio);
    if (playingIndex >= 0) {
      playingAudios[playingIndex] = audio;
    }

    final pausedIndex = pausedAudios.indexOf(audio);
    if (pausedIndex >= 0) {
      pausedAudios[pausedIndex] = audio;
    }
    _notify();
  }

  removeAudio(Audio audio) {
    playingAudios.removeWhere((e) => e.path == audio.path);
    _notify();
  }

  playAudio(Audio audio) {
    pausedAudios = [];
    playingAudios.add(audio);
    _notify();
  }

  pauseAudio(Audio audio) {
    pausedAudios.add(audio);
    _notify();
  }

  syncFromBackground(List<String> playingPaths, List<String> pausedPaths) async {
    final allAudios = await AudioData.getAllAudios();
    
    final newPlaying = allAudios.where((a) => playingPaths.contains(a.path)).toList();
    final newPaused = allAudios.where((a) => pausedPaths.contains(a.path)).toList();
    
    bool changed = false;
    if (newPlaying.length != playingAudios.length || 
        !newPlaying.every((a) => playingAudios.contains(a))) {
      playingAudios = newPlaying;
      changed = true;
    }
    
    if (newPaused.length != pausedAudios.length || 
        !newPaused.every((a) => pausedAudios.contains(a))) {
      pausedAudios = newPaused;
      changed = true;
    }
    
    if (changed) _notify();
  }
}
