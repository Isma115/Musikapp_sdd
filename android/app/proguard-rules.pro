# Reglas de R8 para el APK de release (`isMinifyEnabled = true` en build.gradle.kts).
#
# Qué se protege aquí y por qué:
#
# * GeneratedPluginRegistrant: el motor de Flutter la carga POR REFLEXIÓN
#   (io.flutter.embedding.engine.plugins.util.GeneratedPluginRegister busca la
#   clase "io.flutter.plugins.GeneratedPluginRegistrant" y su método
#   registerWith). Si R8 la borra, la app arranca pero ningún plugin se registra
#   y todo falla con MissingPluginException. La clase generada lleva @Keep, pero
#   lo dejamos explícito.
# * Componentes declarados en AndroidManifest.xml: Android los instancia por
#   nombre (MainActivity, el servicio de audio_service y su receiver de botones
#   multimedia).
# * Plugins registrados desde GeneratedPluginRegistrant: se conservan sus
#   paquetes para no depender de que la referencia directa baste.
# * ffmpeg_kit_flutter_new_audio NO necesita reglas aquí: el paquete ya trae
#   consumer-rules.pro, que hace -keep de com.antonkarpenko.ffmpegkit.** y de
#   sus métodos nativos.
# * androidx.media3 (ExoPlayer, usado por just_audio) tampoco: sus AAR traen
#   proguard.txt (media3-common, media3-extractor).

# Registro de plugins de Flutter (carga por reflexión).
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keep class io.flutter.plugins.** { *; }

# Componentes de la app declarados en el manifiesto.
-keep class com.example.sdd_music_simple.MainActivity { *; }
-keep class com.ryanheise.audioservice.** { *; }

# Plugins Android usados por la app (just_audio, audio_session, file_picker,
# url_launcher, flutter_plugin_android_lifecycle; sqflite y jni/jni_flutter
# también se registran aquí). No hay regla para path_provider porque
# path_provider_android 2.3.1 ya no trae plugin Java (va por JNI/Dart), y
# androidx.media (MediaBrowserServiceCompat) tampoco la necesita: su AAR
# (media-1.7.0) trae proguard.txt con las suyas.
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.audio_session.** { *; }
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keep class io.flutter.plugins.urllauncher.** { *; }
-keep class io.flutter.plugins.flutter_plugin_android_lifecycle.** { *; }
-keep class com.tekartik.sqflite.** { *; }

# Los canales de audio_service/just_audio mandan objetos Parcelable y MediaItem
# entre el hilo principal y el de reproducción; conservamos los métodos que R8
# podría considerar muertos en clases Parcelable.
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}
