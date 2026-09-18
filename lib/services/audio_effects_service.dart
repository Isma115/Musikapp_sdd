import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/audio_settings.dart';

/// Aplica al reproductor los valores de reproducción y los efectos de sonido
/// del panel de audio.
///
/// Spec "Sistema de regulación de audio y efectos".
///
/// Los valores (volumen, velocidad y tono) los soporta `just_audio` en todas
/// las plataformas. Los efectos especiales se apoyan en los dos efectos de
/// audio que ese mismo paquete implementa (`AndroidEqualizer` y
/// `AndroidLoudnessEnhancer`), que solo existen en Android: en el resto de
/// plataformas [supportsSoundEffects] es `false` y el panel ofrece únicamente
/// los valores, en lugar de mostrar efectos que no se podrían aplicar. No se
/// añade ninguna dependencia nueva para cubrirlas porque el spec no pide
/// efectos concretos y el proyecto no incluye recursos de audio.
class AudioEffectsService {
  AudioEffectsService._({
    AndroidEqualizer? equalizer,
    AndroidLoudnessEnhancer? loudnessEnhancer,
  }) : _equalizer = equalizer,
       _loudnessEnhancer = loudnessEnhancer;

  /// Crea los efectos que la plataforma actual puede aplicar.
  ///
  /// Los efectos se crean antes que el reproductor porque `just_audio` recibe
  /// el pipeline de efectos en su constructor (ver [pipeline]).
  factory AudioEffectsService.forCurrentPlatform() {
    if (!supportsSoundEffects) {
      return AudioEffectsService._();
    }
    return AudioEffectsService._(
      equalizer: AndroidEqualizer(),
      loudnessEnhancer: AndroidLoudnessEnhancer(),
    );
  }

  /// Indica si la plataforma actual puede aplicar efectos de sonido.
  static bool get supportsSoundEffects => !kIsWeb && Platform.isAndroid;

  /// Refuerzo máximo, en decibelios, que aplica una banda del ecualizador.
  static const double _maxBoostDecibels = 6;

  /// Recorte máximo, en decibelios, que aplica una banda del ecualizador.
  static const double _maxCutDecibels = 4.5;

  final AndroidEqualizer? _equalizer;
  final AndroidLoudnessEnhancer? _loudnessEnhancer;

  /// Número de la última aplicación de ajustes.
  ///
  /// Cambiar de ajustes mientras las bandas del ecualizador todavía se están
  /// leyendo no debe dejar aplicado el efecto anterior.
  int _equalizerRequest = 0;

  /// Pipeline que debe recibir el reproductor para poder aplicar los efectos.
  /// En las plataformas sin efectos de audio queda vacío.
  AudioPipeline get pipeline => AudioPipeline(
    androidAudioEffects: <AndroidAudioEffect>[
      if (_equalizer != null) _equalizer,
      if (_loudnessEnhancer != null) _loudnessEnhancer,
    ],
  );

  /// Aplica [settings] al reproductor dado.
  ///
  /// Lanza si el reproductor no puede aplicar los valores; el error lo comunica
  /// la vista.
  Future<void> apply(AudioPlayer player, AudioSettings settings) async {
    await player.setVolume(settings.volume);
    await player.setSpeed(settings.speed);
    await player.setPitch(settings.pitch);

    final equalizer = _equalizer;
    final loudnessEnhancer = _loudnessEnhancer;
    final request = ++_equalizerRequest;
    if (equalizer == null || loudnessEnhancer == null) {
      return;
    }

    final preset = settings.effect;
    // El realzador de sonoridad es independiente del ecualizador: se activa o
    // se desactiva según el efecto elegido.
    await loudnessEnhancer.setEnabled(preset.usesLoudnessEnhancer);
    if (preset.usesLoudnessEnhancer) {
      await loudnessEnhancer.setTargetGain(AudioSettings.loudnessGainDecibels);
    }

    await equalizer.setEnabled(preset.usesEqualizer);
    if (preset.usesEqualizer) {
      // Las bandas solo se conocen cuando el reproductor ya se ha conectado a la
      // plataforma, así que el reparto de ganancias se completa solo cuando el
      // ecualizador publica sus parámetros. No se espera aquí para que el resto
      // de valores del panel se sigan aplicando al momento.
      unawaited(_applyEqualizerBands(equalizer, preset, request));
    }
  }

  /// Reparte la ganancia del efecto [preset] por las bandas del ecualizador.
  Future<void> _applyEqualizerBands(
    AndroidEqualizer equalizer,
    AudioEffectPreset preset,
    int request,
  ) async {
    try {
      final parameters = await equalizer.parameters;
      if (request != _equalizerRequest) {
        return;
      }
      for (final band in parameters.bands) {
        final normalized = preset.normalizedGainFor(band.centerFrequency);
        await band.setGain(_gainDecibels(parameters, normalized));
      }
    } on Object {
      // Un dispositivo sin ecualizador utilizable no debe romper el panel: los
      // valores de reproducción ya se han aplicado.
    }
  }

  /// Convierte un refuerzo normalizado en decibelios dentro del rango que
  /// admite el ecualizador del dispositivo.
  ///
  /// El refuerzo se limita a [_maxBoostDecibels] y el recorte a
  /// [_maxCutDecibels] para que el efecto se note sin llegar a saturar, aunque
  /// el ecualizador del dispositivo permita rangos mucho mayores.
  double _gainDecibels(
    AndroidEqualizerParameters parameters,
    double normalized,
  ) {
    final target = normalized >= 0
        ? normalized * _maxBoostDecibels
        : normalized * _maxCutDecibels;
    return target.clamp(parameters.minDecibels, parameters.maxDecibels);
  }
}
