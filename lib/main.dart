import 'package:audio_session/audio_session.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:rolify/presentation_logic_holders/audio_edit_bloc/audio_edit_bloc.dart';
import 'package:rolify/presentation_logic_holders/audio_handler.dart';
import 'package:rolify/presentation_logic_holders/audio_list_bloc/audio_list_bloc.dart';
import 'package:rolify/presentation_logic_holders/playlist_list_bloc/playlist_list_bloc.dart';
import 'package:rolify/presentation_logic_holders/singletons/app_state.dart';
import 'package:rolify/presentation_logic_holders/singletons/theme_mode_controller.dart';
import 'package:rolify/root/base.dart';

Future<void> main() async {
  // store this in a singleton
  AppState().audioHandler = await initAudioService();

  await _configureAudioSession();
  await ThemeModeController().init();

  runApp(const AppRoot());
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

class AppRoot extends StatelessWidget {
  const AppRoot({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeModeController().themeMode,
      builder: (context, themeMode, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<PlaylistListBloc>(create: (context) => PlaylistListBloc()),
            BlocProvider<AudioListBloc>(create: (context) => AudioListBloc()),
            BlocProvider<AudioEditBloc>(create: (context) => AudioEditBloc())
          ],
          child: DynamicColorBuilder(
            builder: (lightDynamic, darkDynamic) {
              ColorScheme lightScheme;
              ColorScheme darkScheme;
              if (lightDynamic != null && darkDynamic != null) {
                lightScheme = lightDynamic.harmonized();
                darkScheme = darkDynamic.harmonized();
              } else {
                lightScheme = ColorScheme.fromSeed(
                  seedColor: const Color(0xFF007aff),
                  brightness: Brightness.light,
                );
                darkScheme = ColorScheme.fromSeed(
                  seedColor: const Color(0xFF007aff),
                  brightness: Brightness.dark,
                );
              }

              return MaterialApp(
                title: 'Rolify',
                debugShowCheckedModeBanner: false,
                themeMode: themeMode,
                theme: ThemeData(
                  useMaterial3: true,
                  colorScheme: lightScheme,
                  scaffoldBackgroundColor: const Color(0xFFF0F0F3),
                ),
                darkTheme: ThemeData(
                  useMaterial3: true,
                  colorScheme: darkScheme,
                  scaffoldBackgroundColor: const Color(0xff333333),
                ),
                home: ScrollConfiguration(
                  behavior: NoScrollGlowBehavior(),
                  child: const Base(),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class NoScrollGlowBehavior extends ScrollBehavior {
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
