import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rolify/presentation_logic_holders/audio_edit_bloc/audio_edit_bloc.dart';
import 'package:rolify/presentation_logic_holders/audio_handler.dart';
import 'package:rolify/presentation_logic_holders/audio_list_bloc/audio_list_bloc.dart';
import 'package:rolify/presentation_logic_holders/playlist_list_bloc/playlist_list_bloc.dart';
import 'package:rolify/presentation_logic_holders/singletons/app_state.dart';
import 'package:rolify/presentation_logic_holders/singletons/theme_mode_controller.dart';
import 'package:rolify/root/base.dart';

Future<void> main() async {
  AppState().audioHandler = await initAudioService();
  await _configureAudioSession();
  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeModeController().themeMode,
      builder: (context, themeMode, child) {
        return MyApp(themeMode: themeMode);
      },
    );
  }
}

Future<void> _configureAudioSession() async {
  final session = await AudioSession.instance;
  await session.configure(
    const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.mixWithOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions:
          AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
      androidWillPauseWhenDucked: true,
    ),
  );
}

class MyApp extends StatelessWidget {
  final ThemeMode themeMode;

  const MyApp({super.key, required this.themeMode});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PlaylistListBloc>(create: (context) => PlaylistListBloc()),
        BlocProvider<AudioListBloc>(create: (context) => AudioListBloc()),
        BlocProvider<AudioEditBloc>(create: (context) => AudioEditBloc())
      ],
      child: MaterialApp(
        title: 'Rolify',
        debugShowCheckedModeBanner: false,
        themeMode: themeMode,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007AFF)),
          fontFamily: 'Inter-Regular',
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF007AFF),
            brightness: Brightness.dark,
          ),
          fontFamily: 'Inter-Regular',
        ),
        home: ScrollConfiguration(
          behavior: const NoScrollGlowBehavior(),
          child: const Base(),
        ),
      ),
    );
  }
}

class NoScrollGlowBehavior extends ScrollBehavior {
  const NoScrollGlowBehavior();

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
