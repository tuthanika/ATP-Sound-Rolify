import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:rolify/entities/audio.dart';
import 'package:rolify/entities/playlist.dart';
import 'package:rolify/root/edit_playlist.dart';

void main() {
  testWidgets('EditPlaylist mount test', (WidgetTester tester) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      print('FLUTTER ERROR CAUGHT IN TEST: \${details.exceptionAsString()}');
      print(details.stack);
    };

    final playlist = Playlist(
      name: '',
      audios: <Audio>[],
      color: null,
    );

    await tester.pumpWidget(
      NeumorphicApp(
        home: EditPlaylist(playlist: playlist),
      ),
    );

    await tester.pumpAndSettle();
    
    expect(find.byType(EditPlaylist), findsOneWidget);
  });
}
