import 'package:flutter/material.dart';

import '../models/audio_settings.dart';

/// Abre el panel de regulación de audio y efectos.
///
/// Spec "Sistema de regulación de audio y efectos": el panel se abre desde el
/// botón contiguo al de recargar y cada cambio se comunica al momento con
/// [onChanged] para que el usuario escuche el resultado sin cerrarlo.
Future<void> showAudioSettingsSheet({
  required BuildContext context,
  required AudioSettings settings,
  required bool supportsSoundEffects,
  required ValueChanged<AudioSettings> onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    // El panel puede superar media pantalla (valores + lista de efectos), así
    // que se permite crecer y desplazarse.
    isScrollControlled: true,
    builder: (sheetContext) => AudioSettingsSheet(
      settings: settings,
      supportsSoundEffects: supportsSoundEffects,
      onChanged: onChanged,
    ),
  );
}

/// Contenido del panel de audio: valores de reproducción y efectos de sonido.
class AudioSettingsSheet extends StatefulWidget {
  const AudioSettingsSheet({
    required this.settings,
    required this.supportsSoundEffects,
    required this.onChanged,
    super.key,
  });

  final AudioSettings settings;

  /// Si la plataforma puede aplicar efectos de sonido; si no, solo se ofrecen
  /// los valores de reproducción.
  final bool supportsSoundEffects;

  final ValueChanged<AudioSettings> onChanged;

  @override
  State<AudioSettingsSheet> createState() => _AudioSettingsSheetState();
}

class _AudioSettingsSheetState extends State<AudioSettingsSheet> {
  static const _effectsIcons = <AudioEffectPreset, IconData>{
    AudioEffectPreset.none: Icons.not_interested,
    AudioEffectPreset.bass: Icons.speaker,
    AudioEffectPreset.voice: Icons.record_voice_over,
    AudioEffectPreset.treble: Icons.graphic_eq,
    AudioEffectPreset.loudness: Icons.volume_up,
  };

  late AudioSettings _settings = widget.settings;

  void _update(AudioSettings settings) {
    setState(() => _settings = settings);
    widget.onChanged(settings);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Audio y efectos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _AudioValueSlider(
                label: 'Volumen',
                value: _settings.volume,
                min: AudioSettings.minVolume,
                max: AudioSettings.maxVolume,
                divisions: 20,
                display: '${(_settings.volume * 100).round()} %',
                onChanged: (volume) =>
                    _update(_settings.copyWith(volume: volume)),
              ),
              _AudioValueSlider(
                label: 'Velocidad',
                value: _settings.speed,
                min: AudioSettings.minSpeed,
                max: AudioSettings.maxSpeed,
                divisions: 30,
                display: '${_settings.speed.toStringAsFixed(2)}x',
                onChanged: (speed) => _update(_settings.copyWith(speed: speed)),
              ),
              _AudioValueSlider(
                label: 'Tono',
                value: _settings.pitch,
                min: AudioSettings.minPitch,
                max: AudioSettings.maxPitch,
                divisions: 30,
                display: '${_settings.pitch.toStringAsFixed(2)}x',
                onChanged: (pitch) => _update(_settings.copyWith(pitch: pitch)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Efectos de sonido',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (!widget.supportsSoundEffects)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Los efectos de sonido solo están disponibles en Android.',
                  ),
                )
              else
                for (final effect in AudioEffectPreset.values)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_effectsIcons[effect]),
                    title: Text(effect.label),
                    subtitle: Text(effect.description),
                    // La selección se marca con un icono, sin formas
                    // redondeadas, igual que el resto de la aplicación.
                    trailing: _settings.effect == effect
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => _update(_settings.copyWith(effect: effect)),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Valor de reproducción regulable con una barra.
class _AudioValueSlider extends StatelessWidget {
  const _AudioValueSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;

  /// Valor actual ya formateado (porcentaje o multiplicador).
  final String display;

  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(display)],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: display,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
