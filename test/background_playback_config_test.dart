import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guarda de regresión de la spec "Fix: Audio interrumpido al ejecutar en
/// segundo plano".
///
/// El fallo (la app se cerraba sola pasados unos minutos de reproducción en
/// segundo plano) depende del servicio multimedia nativo y no se puede
/// reproducir en un test de widget, así que aquí se fija la configuración que
/// lo evita: el servicio permanece en primer plano (con su wake lock) mientras
/// exista una sesión de reproducción. Con el valor por defecto de
/// `androidStopForegroundOnPause`, el servicio sale del primer plano al pausar
/// o al terminar la canción, suelta el wake lock y Android puede matar el
/// proceso para recuperar recursos.
void main() {
  test('el servicio no abandona el primer plano al pausar', () {
    final sources = _libSources();
    const option = 'androidStopForegroundOnPause';

    expect(
      _matching(sources, '$option: false'),
      isNotEmpty,
      reason: 'la reproducción en segundo plano quedaría desprotegida',
    );
    expect(
      _matching(sources, '$option: true'),
      isEmpty,
      reason: 'ninguna configuración debe reactivar la salida del primer plano',
    );
  });

  test('Android declara el servicio en primer plano de reproducción', () {
    final manifest = _read('android/app/src/main/AndroidManifest.xml');

    expect(manifest, contains('android.permission.WAKE_LOCK'));
    expect(manifest, contains('android.permission.FOREGROUND_SERVICE'));
    expect(manifest, contains('FOREGROUND_SERVICE_MEDIA_PLAYBACK'));
    expect(manifest, contains('foregroundServiceType="mediaPlayback"'));
    expect(manifest, contains('android:stopWithTask="false"'));
  });

  test('iOS conserva el modo de audio en segundo plano', () {
    final infoPlist = _read('ios/Runner/Info.plist');

    expect(infoPlist, contains('<key>UIBackgroundModes</key>'));
    expect(infoPlist, contains('<string>audio</string>'));
  });
}

/// Ficheros de `lib/` que contienen [snippet].
List<String> _matching(List<String> sources, String snippet) =>
    sources.where((source) => source.contains(snippet)).toList(growable: false);

/// Contenido de todos los ficheros Dart de `lib/`.
List<String> _libSources() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'))
    .map((file) => file.readAsStringSync())
    .toList(growable: false);

String _read(String path) => File(path).readAsStringSync();
