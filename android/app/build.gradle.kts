plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---------------------------------------------------------------------------
// Tamaño del APK (spec "Tamaño de apk")
//
// El APK de release ocupaba ~136 MB porque metía, sin comprimir, las librerías
// nativas de tres ABIs: las de FFmpeg que aporta ffmpeg_kit_flutter_new_audio
// (libavcodec, libavformat, libavfilter, libswscale, libavutil, libc++_shared)
// más libflutter.so / libapp.so de cada ABI.
//
// 1) ABIs empaquetadas en la variante release (afecta al APK y al AAB). Por
//    defecto solo las dos de ARM, que son las de todos los móviles/tabletas
//    Android reales; se descartan x86 y x86_64 (solo emuladores y algún
//    Chromebook, donde no se usa el APK de release). Se puede cambiar sin tocar
//    este fichero:
//      flutter build apk --release --android-project-arg=releaseAbis=arm64-v8a
//      flutter build apk --release --android-project-arg=releaseAbis=armeabi-v7a,arm64-v8a,x86_64
//    La primera deja el APK más pequeño posible (solo móviles de 64 bits, que
//    son prácticamente todos desde 2017); la segunda recupera el APK original
//    con las tres ABIs. El build de debug NO se filtra: sigue con todas las
//    ABIs para que los emuladores x86_64 sigan funcionando con `flutter run`.
//
//    No se usa `splits.abi` de Gradle a propósito: `flutter build apk` (sin
//    --split-per-abi) busca el fichero app-release.apk y fallaría si Gradle
//    generase un APK por ABI. Para APKs separados por ABI existe el flag
//    oficial `flutter build apk --split-per-abi`.
val releaseAbis: List<String> =
    (project.findProperty("releaseAbis") as String?)
        ?.split(",")
        ?.map { it.trim() }
        ?.filter { it.isNotEmpty() }
        ?: listOf("armeabi-v7a", "arm64-v8a")

// 2) Las .so se guardan comprimidas (deflate) dentro del APK en vez de "stored",
//    que es lo que hace AGP por defecto desde que existe
//    android:extractNativeLibs="false". El fichero APK baja a menos de la mitad.
//    A cambio, Android descomprime las librerías al instalar la app: ocupa más
//    espacio en el dispositivo y el arranque en frío es algo más lento. Para
//    volver al comportamiento por defecto de AGP:
//      flutter build apk --release --android-project-arg=compressNativeLibs=false
val compressNativeLibs: Boolean =
    project.findProperty("compressNativeLibs")?.toString()?.toBoolean() ?: true

// El plugin de Flutter activa los splits por ABI cuando se pasa
// `--split-per-abi` (-Psplit-per-abi=true). En ese caso NO se toca abiFilters:
// el plugin genera un APK por ABI y `flutter build apk` espera exactamente
// app-<abi>-release.apk de cada plataforma pedida, así que recortar ABIs aquí
// haría que faltase el APK de x86_64 y el comando fallase.
val splitPerAbi: Boolean =
    project.findProperty("split-per-abi")?.toString()?.toBoolean() ?: false

android {
    namespace = "com.example.sdd_music_simple"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.sdd_music_simple"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")

            // 3) Recorta las ABIs que realmente se empaquetan (ver arriba). Se
            //    reescribe la lista que el plugin de Flutter pone por defecto
            //    (armeabi-v7a + arm64-v8a + x86_64). Con --split-per-abi no se
            //    toca (ver splitPerAbi arriba).
            if (!splitPerAbi) {
                ndk {
                    abiFilters.clear()
                    abiFilters.addAll(releaseAbis)
                }
            }

            // 4) R8 (minificado + optimización) y eliminación de recursos no
            //    usados. Las reglas que necesitan los plugins con reflexión /
            //    componentes declarados en el manifiesto están en
            //    proguard-rules.pro. Ojo: el paquete de FFmpeg ya aporta las
            //    suyas en su consumer-rules.pro.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    packaging {
        jniLibs {
            // true = comprimir las .so dentro del APK (ver punto 2 arriba).
            useLegacyPackaging = compressNativeLibs
        }
    }
}

flutter {
    source = "../.."
}
