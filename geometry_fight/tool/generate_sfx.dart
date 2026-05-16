// Genera file WAV procedurali per SFX del gioco.
// Eseguire con: dart run tool/generate_sfx.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main(List<String> args) {
  if (!File('pubspec.yaml').existsSync()) {
    stderr.writeln(
      'Error: pubspec.yaml not found in current directory. '
      'Run this script from the geometry_fight project root.',
    );
    exit(1);
  }
  final outDir = Directory('assets/audio');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  // Sparo: bip acuto brevissimo (40ms)
  _writeWav('${outDir.path}/shoot.wav', _synth(
    duration: 0.04, sampleRate: 22050,
    generator: (t) => sin(2 * pi * (1200 - t * 15000) * t) * (1 - t / 0.04) * 0.3,
  ));

  // Nemico ucciso: esplosione bassa (120ms)
  _writeWav('${outDir.path}/enemy_death.wav', _synth(
    duration: 0.12, sampleRate: 22050,
    generator: (t) {
      final env = (1 - t / 0.12);
      final noise = Random(((t * 22050).toInt())).nextDouble() * 2 - 1;
      return (sin(2 * pi * (200 - t * 800) * t) * 0.5 + noise * 0.3) * env * 0.4;
    },
  ));

  // Bomba: esplosione grande (400ms)
  _writeWav('${outDir.path}/bomb.wav', _synth(
    duration: 0.4, sampleRate: 22050,
    generator: (t) {
      final env = (1 - t / 0.4);
      final noise = Random(((t * 22050).toInt())).nextDouble() * 2 - 1;
      return (sin(2 * pi * (80 - t * 100) * t) * 0.6 + noise * 0.4) * env * env * 0.5;
    },
  ));

  // Power-up: sweep ascendente (150ms)
  _writeWav('${outDir.path}/powerup.wav', _synth(
    duration: 0.15, sampleRate: 22050,
    generator: (t) {
      final env = sin(pi * t / 0.15);
      return sin(2 * pi * (400 + t * 4000) * t) * env * 0.35;
    },
  ));

  // Player hit: rumore distorto (200ms)
  _writeWav('${outDir.path}/player_hit.wav', _synth(
    duration: 0.2, sampleRate: 22050,
    generator: (t) {
      final env = (1 - t / 0.2);
      final noise = Random(((t * 22050).toInt())).nextDouble() * 2 - 1;
      return (sin(2 * pi * 150 * t) * 0.4 + noise * 0.5) * env * 0.45;
    },
  ));

  // Boss spawn: basso rimbombo (500ms)
  _writeWav('${outDir.path}/boss_spawn.wav', _synth(
    duration: 0.5, sampleRate: 22050,
    generator: (t) {
      final env = (1 - t / 0.5);
      return sin(2 * pi * (60 + sin(2 * pi * 3 * t) * 20) * t) * env * env * 0.5;
    },
  ));

  // Wave complete: accordo ascendente (250ms)
  _writeWav('${outDir.path}/wave_complete.wav', _synth(
    duration: 0.25, sampleRate: 22050,
    generator: (t) {
      final env = sin(pi * t / 0.25);
      final f1 = sin(2 * pi * 523 * t); // C5
      final f2 = sin(2 * pi * 659 * t); // E5
      final f3 = sin(2 * pi * 784 * t); // G5
      return (f1 + f2 + f3) / 3 * env * 0.3;
    },
  ));

  // Game over: tono discendente triste (600ms)
  _writeWav('${outDir.path}/game_over.wav', _synth(
    duration: 0.6, sampleRate: 22050,
    generator: (t) {
      final env = (1 - t / 0.6);
      return sin(2 * pi * (400 - t * 500) * t) * env * 0.35;
    },
  ));

  // Geom collect: click dolce (25ms)
  _writeWav('${outDir.path}/geom.wav', _synth(
    duration: 0.025, sampleRate: 22050,
    generator: (t) {
      final env = (1 - t / 0.025);
      return sin(2 * pi * 2000 * t) * env * 0.2;
    },
  ));

  // Extra life: fanfara breve (300ms)
  _writeWav('${outDir.path}/extra_life.wav', _synth(
    duration: 0.3, sampleRate: 22050,
    generator: (t) {
      final env = sin(pi * t / 0.3);
      final f1 = sin(2 * pi * 523 * t);
      final f2 = sin(2 * pi * 659 * t);
      final f3 = sin(2 * pi * 784 * t);
      final f4 = sin(2 * pi * 1047 * t);
      final mix = t < 0.15 ? (f1 + f2) / 2 : (f3 + f4) / 2;
      return mix * env * 0.35;
    },
  ));

  stdout.writeln(
    'Generated ${outDir.listSync().length} SFX files in ${outDir.path}',
  );
}

Float64List _synth({
  required double duration,
  required int sampleRate,
  required double Function(double t) generator,
}) {
  final samples = (duration * sampleRate).toInt();
  final data = Float64List(samples);
  for (int i = 0; i < samples; i++) {
    data[i] = generator(i / sampleRate);
  }
  return data;
}

void _writeWav(String path, Float64List samples, {int sampleRate = 22050}) {
  final numSamples = samples.length;
  final bitsPerSample = 16;
  final numChannels = 1;
  final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
  final blockAlign = numChannels * bitsPerSample ~/ 8;
  final dataSize = numSamples * blockAlign;
  final fileSize = 36 + dataSize;

  final buffer = ByteData(44 + dataSize);
  // RIFF header
  buffer.setUint8(0, 0x52); buffer.setUint8(1, 0x49); buffer.setUint8(2, 0x46); buffer.setUint8(3, 0x46);
  buffer.setUint32(4, fileSize, Endian.little);
  buffer.setUint8(8, 0x57); buffer.setUint8(9, 0x41); buffer.setUint8(10, 0x56); buffer.setUint8(11, 0x45);
  // fmt chunk
  buffer.setUint8(12, 0x66); buffer.setUint8(13, 0x6D); buffer.setUint8(14, 0x74); buffer.setUint8(15, 0x20);
  buffer.setUint32(16, 16, Endian.little); // chunk size
  buffer.setUint16(20, 1, Endian.little); // PCM
  buffer.setUint16(22, numChannels, Endian.little);
  buffer.setUint32(24, sampleRate, Endian.little);
  buffer.setUint32(28, byteRate, Endian.little);
  buffer.setUint16(32, blockAlign, Endian.little);
  buffer.setUint16(34, bitsPerSample, Endian.little);
  // data chunk
  buffer.setUint8(36, 0x64); buffer.setUint8(37, 0x61); buffer.setUint8(38, 0x74); buffer.setUint8(39, 0x61);
  buffer.setUint32(40, dataSize, Endian.little);

  for (int i = 0; i < numSamples; i++) {
    final s = (samples[i].clamp(-1.0, 1.0) * 32767).toInt();
    buffer.setInt16(44 + i * 2, s, Endian.little);
  }

  File(path).writeAsBytesSync(buffer.buffer.asUint8List());
}
