import 'package:rolify/entities/audio.dart';
import 'package:rolify/presentation_logic_holders/audio_handler.dart';
import 'package:rolify/presentation_logic_holders/event_bus/stop_all_event_bus.dart';
import 'package:rolify/presentation_logic_holders/playing_sounds_singleton.dart';
import 'package:rolify/presentation_logic_holders/singletons/app_state.dart';

class AudioServiceCommands {
  static int globalStopGeneration = 0;
  static int globalPlayGeneration = 0;
  static Future<bool> startAudioService() async {
    await initAudioService();
    return true;
  }

  static play(Audio audio) async {
    AppState().audioHandler.customAction('play', {"audio": audio.toJson()});
  }

  static stop(Audio audio) async {
    AppState().audioHandler.customAction('stop', {"audio": audio.toJson()});
  }
  
  static playFolderSpecial(String folderName, List<Audio> audios, String mode) async {
    AppState().audioHandler.customAction('play_special_folder', {
      'folderName': folderName,
      'mode': mode,
      'audios': audios.map((a) => a.toJson()).toList(),
    });
  }

  static stopFolderSpecial(String folderName, List<Audio> audios) async {
    AppState().audioHandler.customAction('stop_special_folder', {
      'folderName': folderName,
      'audios': audios.map((a) => a.toJson()).toList(),
    });
  }

  static setLoop(bool value, Audio audio) async {
    AppState()
        .audioHandler
        .customAction('loop', {"audio": audio.toJson(), "param": value});
  }

  static Future getLoop(Audio audio) async {
    return AppState()
        .audioHandler
        .customAction('get_loop', {"audio": audio.toJson()});
  }

  static Future<void> setVolume(Audio audio, double value,
      {bool global = false}) async {
    AppState()
        .audioHandler
        .customAction('set_volume', {"audio": audio.toJson(), "param": value});
  }

  static Future getVolume(Audio audio) async {
    return AppState()
        .audioHandler
        .customAction('get_volume', {"audio": audio.toJson()});
  }

  static Future getPlaying(Audio audio) async {
    return AppState()
        .audioHandler
        .customAction('is_playing', {"audio": audio.toJson()});
  }
}
