import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'theme/app_theme.dart';
import 'views/music_shell.dart';

export 'views/music_shell.dart';
export 'views/playlist_detail_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.sdd_music_simple.audio',
    androidNotificationChannelName: 'Reproducción de audio',
    androidNotificationOngoing: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDD Music',
      theme: buildAppTheme(),
      home: const MyHomePage(title: 'SDD Music'),
    );
  }
}

class MyHomePage extends MusicShell {
  const MyHomePage({super.key, this.title});

  final String? title;
}
