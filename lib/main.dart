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
    // Spec "Fix: Audio interrumpido al ejecutar en segundo plano".
    //
    // audio_service daba por terminada la sesión de reproducción en cada pausa
    // o al acabar la canción (processingState `completed`), salía del estado de
    // servicio en primer plano y soltaba el wake lock: a partir de ahí el
    // proceso queda como un proceso en segundo plano normal y Android puede
    // matarlo para recuperar recursos, que es lo que el usuario percibe como
    // "la app se cierra sola pasados unos minutos de reproducción".
    //
    // Con androidStopForegroundOnPause en false el servicio multimedia se
    // mantiene en primer plano (y con el wake lock) mientras exista una sesión
    // de reproducción, aunque esté en pausa o haya terminado la canción, así
    // que el sistema no reclama el proceso ni con la pantalla apagada.
    //
    // androidNotificationOngoing no se activa: el propio plugin lo declara
    // incompatible con androidStopForegroundOnPause=false (assert de
    // AudioServiceConfig) y, mientras el servicio está en primer plano, Android
    // ya fuerza que la notificación sea fija. La notificación conserva su botón
    // de detener para cerrar la sesión y liberar el servicio.
    androidStopForegroundOnPause: false,
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
