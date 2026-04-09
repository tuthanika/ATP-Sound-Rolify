import 'package:flutter/material.dart';
import 'package:rolify/data/audios.dart';
import 'package:rolify/entities/audio.dart';

class PlayingSounds {
  static final PlayingSounds _singleton = PlayingSounds._internal();
   // --- THÊM DÒNG NÀY VÀO ĐÂY ---
  // Key: folderName, Value: {'mode': 'sequential' | 'random', 'audios': List<Audio>}
  Map<String, Map<String, dynamic>> activeSpecialFolders = {}; 
  // -----------------------------
  List<String> activePlaylistIds = [];
  double masterVolume = 1.0;
  final ValueNotifier<bool> isPlayingPlaylist = ValueNotifier(false);
  final ValueNotifier<int> stateChangeNotifier = ValueNotifier(0);
  final ValueNotifier<double> masterVolumeNotifier = ValueNotifier(1.0);
  final ValueNotifier<List<String>> activePlaylistIdsNotifier = ValueNotifier([]);
  
  // NEW: Optimized and central ValueNotifiers for UI components
  final ValueNotifier<Set<String>> playingPathsNotifier = ValueNotifier({});
  final ValueNotifier<Set<String>> pausedPathsNotifier = ValueNotifier({});

  List<Audio> allAudiosCache = [];
  List<Audio> playingAudios = [];
  List<Audio> pausedAudios = [];
  Set<String> playingPathsSet = {};
  Set<String> pausedPathsSet = {};


  factory PlayingSounds() {
    return _singleton;
  }

  PlayingSounds._internal();

  _notify() {
    playingPathsSet = playingAudios.map((e) => e.path).toSet();
    pausedPathsSet = pausedAudios.map((e) => e.path).toSet();
    
    // Update the high-performance notifiers
    playingPathsNotifier.value = Set.from(playingPathsSet);
    pausedPathsNotifier.value = Set.from(pausedPathsSet);
    
    stateChangeNotifier.value++;
  }

  /// Refreshes the internal audio cache from the database.
  /// Should be called after any Audio add/delete/edit operation.
  Future<void> refreshCache() async {
    allAudiosCache = await AudioData.getAllAudios();
  }

  updateAudio(Audio audio) {
    final playingIndex = playingAudios.indexWhere((a) => a.path == audio.path);
    if (playingIndex >= 0) {
      playingAudios[playingIndex] = audio;
    }

    final pausedIndex = pausedAudios.indexWhere((a) => a.path == audio.path);
    if (pausedIndex >= 0) {
      pausedAudios[pausedIndex] = audio;
    }
    
    final cacheIndex = allAudiosCache.indexWhere((a) => a.path == audio.path);
    if (cacheIndex >= 0) {
      allAudiosCache[cacheIndex] = audio;
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

  syncFromBackground(List<String> playingPaths, List<String> pausedPaths, [double? newMasterVolume, List<String>? newActivePlaylistIds]) async {
    // 1. Ensure cache is loaded (only await once if empty)
    if (allAudiosCache.isEmpty) {
      await refreshCache();
    }
    
    // 2. Map paths to cached Audio objects (O(N) operation in memory, no DB hit)
    final newPlaying = allAudiosCache.where((a) => playingPaths.contains(a.path)).toList();
    final newPaused = allAudiosCache.where((a) => pausedPaths.contains(a.path)).toList();
    
    bool changed = false;
    
    // Check if lengths or content actually changed
    // Use set comparison for efficiency
    final newPlayingSet = playingPaths.toSet();
    final newPausedSet = pausedPaths.toSet();

    if (newPlayingSet.length != playingPathsSet.length || 
        !newPlayingSet.every((path) => playingPathsSet.contains(path))) {
      playingAudios = newPlaying;
      playingPathsSet = newPlayingSet;
      playingPathsNotifier.value = Set.from(newPlayingSet);
      changed = true;
    }
    
    if (newPausedSet.length != pausedPathsSet.length || 
        !newPausedSet.every((path) => pausedPathsSet.contains(path))) {
      pausedAudios = newPaused;
      pausedPathsSet = newPausedSet;
      pausedPathsNotifier.value = Set.from(newPausedSet);
      changed = true;
    }

    if (newMasterVolume != null && (newMasterVolume - masterVolume).abs() > 0.01) {
      masterVolume = newMasterVolume;
      masterVolumeNotifier.value = newMasterVolume;
      changed = true;
    }

    if (newActivePlaylistIds != null) {
      activePlaylistIds = List.from(newActivePlaylistIds);
      activePlaylistIdsNotifier.value = List.from(newActivePlaylistIds);
      changed = true;
    }
    
    if (changed) {
      stateChangeNotifier.value++;
    }
  }
}

