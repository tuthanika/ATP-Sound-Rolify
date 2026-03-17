import 'package:audio_session/audio_session.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:rolify/presentation_logic_holders/audio_edit_bloc/audio_edit_bloc.dart';
import 'package:rolify/presentation_logic_holders/audio_handler.dart';
import 'package:rolify/presentation_logic_holders/audio_list_bloc/audio_list_bloc.dart';
import 'package:rolify/presentation_logic_holders/playlist_list_bloc/playlist_list_bloc.dart';
import 'package:rolify/presentation_logic_holders/singletons/app_state.dart';
import 'package:rolify/root/base.dart';

Future<void> main() async {
  // store this in a singleton
  AppState().audioHandler = await initAudioService();

  await _configureAudioSession();

  const seedColor = Color(0xFF6750A4);
  final lightScheme = ColorScheme.fromSeed(seedColor: seedColor);
  final darkScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.dark,
  );

  runApp(NeumorphicTheme(
    themeMode: ThemeMode.system,
    darkTheme: NeumorphicThemeData(
      baseColor: darkScheme.surface,
      disabledColor: darkScheme.onSurfaceVariant,
      accentColor: darkScheme.primary,
      variantColor: darkScheme.tertiary,
      lightSource: LightSource.topLeft,
      depth: 2,
      intensity: 0.5,
    ),
    theme: NeumorphicThemeData(
      baseColor: lightScheme.surface,
      disabledColor: lightScheme.onSurfaceVariant,
      accentColor: lightScheme.primary,
      variantColor: lightScheme.tertiary,
      intensity: 0.8,
      lightSource: LightSource.topLeft,
      depth: 1,
    ),
    child: const MyApp(),
  ));
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
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF6750A4);
    final lightScheme = ColorScheme.fromSeed(seedColor: seedColor);
    final darkScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<PlaylistListBloc>(create: (context) => PlaylistListBloc()),
        BlocProvider<AudioListBloc>(create: (context) => AudioListBloc()),
        BlocProvider<AudioEditBloc>(create: (context) => AudioEditBloc())
      ],
      child: MaterialApp(
        title: 'Rolify',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: lightScheme,
          scaffoldBackgroundColor: lightScheme.surface,
          appBarTheme: AppBarTheme(
            centerTitle: false,
            scrolledUnderElevation: 0,
            backgroundColor: lightScheme.surface,
            foregroundColor: lightScheme.onSurface,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: darkScheme,
          scaffoldBackgroundColor: darkScheme.surface,
          appBarTheme: AppBarTheme(
            centerTitle: false,
            scrolledUnderElevation: 0,
            backgroundColor: darkScheme.surface,
            foregroundColor: darkScheme.onSurface,
          ),
        ),
        home: ScrollConfiguration(
          behavior: NoScrollGlowBehavior(),
          child: const Base(),
        ),
      ),
    );
  }
}

class NoScrollGlowBehavior extends ScrollBehavior {
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
