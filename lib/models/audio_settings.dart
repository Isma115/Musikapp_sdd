/// Ajustes de reproducción (valores) y efectos de sonido.
///
/// Spec "Sistema de regulación de audio y efectos": junto al botón de recargar
/// hay un botón que permite subir varios valores de reproducción del audio y
/// añadir efectos de sonido especiales.
///
/// El spec no enumera ni los valores ni los efectos, así que se resuelve de
/// forma conservadora con lo que ya ofrece el reproductor incluido
/// (`just_audio`), sin añadir dependencias ni recursos nuevos:
/// * Valores: volumen, velocidad y tono, los tres regulables por encima de su
///   valor normal.
/// * Efectos: los efectos de audio reales del paquete, que son el ecualizador
///   por bandas (graves, voz y agudos) y el realzador de sonoridad
///   (amplificado).
library;

/// Valores de reproducción y efecto de sonido elegidos por el usuario.
///
/// No se guarda en el dispositivo: el spec no pide persistencia y el
/// almacenamiento local existente solo conserva playlists y descargas.
class AudioSettings {
  const AudioSettings({
    this.volume = defaultVolume,
    this.speed = defaultSpeed,
    this.pitch = defaultPitch,
    this.effect = AudioEffectPreset.none,
  });

  /// Volumen: `1` es el volumen normal y [maxVolume] lo sube al doble (por
  /// encima de `1` el audio se amplifica y puede saturar en grabaciones altas).
  static const double minVolume = 0;
  static const double maxVolume = 2;
  static const double defaultVolume = 1;

  /// Velocidad de reproducción: `1` es la velocidad normal.
  static const double minSpeed = 0.5;
  static const double maxSpeed = 2;
  static const double defaultSpeed = 1;

  /// Tono: `1` es el tono original de la canción.
  static const double minPitch = 0.5;
  static const double maxPitch = 2;
  static const double defaultPitch = 1;

  /// Ganancia en decibelios del efecto "Amplificado".
  static const double loudnessGainDecibels = 6;

  final double volume;
  final double speed;
  final double pitch;
  final AudioEffectPreset effect;

  /// Copia los ajustes cambiando solo los valores indicados.
  AudioSettings copyWith({
    double? volume,
    double? speed,
    double? pitch,
    AudioEffectPreset? effect,
  }) => AudioSettings(
    volume: volume ?? this.volume,
    speed: speed ?? this.speed,
    pitch: pitch ?? this.pitch,
    effect: effect ?? this.effect,
  );

  @override
  bool operator ==(Object other) =>
      other is AudioSettings &&
      other.volume == volume &&
      other.speed == speed &&
      other.pitch == pitch &&
      other.effect == effect;

  @override
  int get hashCode => Object.hash(volume, speed, pitch, effect);
}

/// Efectos de sonido disponibles en el panel de audio.
///
/// Todos menos [none] modifican la señal de audio; como el spec pide "efectos
/// de sonido especiales" sin concretarlos, se ofrecen los que el reproductor
/// puede aplicar de verdad en lugar de nombres decorativos.
enum AudioEffectPreset {
  none('Ninguno', 'Sin efecto de sonido'),
  bass('Graves', 'Refuerza las frecuencias bajas'),
  voice('Voz', 'Realza las frecuencias medias, donde se entiende la voz'),
  treble('Agudos', 'Refuerza las frecuencias altas'),
  loudness('Amplificado', 'Sube la ganancia general del audio');

  const AudioEffectPreset(this.label, this.description);

  /// Nombre del efecto tal y como se muestra en el panel.
  final String label;

  /// Explicación breve del efecto, como subtítulo en el panel.
  final String description;

  /// Efectos que se aplican ganando bandas del ecualizador.
  bool get usesEqualizer =>
      this == AudioEffectPreset.bass ||
      this == AudioEffectPreset.voice ||
      this == AudioEffectPreset.treble;

  /// Efecto que se aplica con el realzador de sonoridad.
  bool get usesLoudnessEnhancer => this == AudioEffectPreset.loudness;

  /// Refuerzo de una banda del ecualizador, normalizado entre `-1` y `1`, según
  /// su frecuencia central en hercios.
  ///
  /// Se reparte por frecuencia en lugar de usar una tabla de bandas fija porque
  /// el número de bandas y sus frecuencias los decide el ecualizador del
  /// dispositivo: así el efecto se adapta a cualquier ecualizador.
  double normalizedGainFor(double centerFrequency) {
    switch (this) {
      case AudioEffectPreset.bass:
        if (centerFrequency <= 300) {
          return 1;
        }
        if (centerFrequency <= 1000) {
          return 0.5;
        }
        return -0.3;
      case AudioEffectPreset.voice:
        if (centerFrequency <= 300) {
          return -0.3;
        }
        if (centerFrequency <= 1000) {
          return 0.6;
        }
        if (centerFrequency <= 4000) {
          return 1;
        }
        return -0.3;
      case AudioEffectPreset.treble:
        if (centerFrequency < 1000) {
          return -0.3;
        }
        if (centerFrequency < 4000) {
          return 0.4;
        }
        return 1;
      case AudioEffectPreset.none:
      case AudioEffectPreset.loudness:
        return 0;
    }
  }
}
