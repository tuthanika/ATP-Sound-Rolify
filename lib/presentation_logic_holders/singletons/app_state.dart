import 'package:audio_service/audio_service.dart';

import 'compatibility_flags.dart';

class AppState {
  static final AppState _singleton = AppState._internal();
  double deviceHeight = 2000;
  double deviceWidth = 2000;
  late AudioHandler audioHandler;
  CompatibilityFlags compatibilityFlags = const CompatibilityFlags(
    isLegacyGpuDevice: false,
    isLowRamDevice: false,
  );

  factory AppState() {
    return _singleton;
  }

  AppState._internal();
}

double get heightFactor => AppState().deviceHeight > 1280 ? 1 : 0.75;
