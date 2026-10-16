import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  const sampleRate = 44100;

  // 1. Generate Activity Alarm (Energetic, cheerful, ascending fanfare chime)
  final activitySamples = generateActivityAlarm(sampleRate);
  writeWavFile('assets/audio/activity_alarm.wav', activitySamples, sampleRate);
  print('Generated assets/audio/activity_alarm.wav (${activitySamples.length} samples)');

  // 2. Generate Rest Alarm (Calm, soothing meditation chime / bell)
  final restSamples = generateRestAlarm(sampleRate);
  writeWavFile('assets/audio/rest_alarm.wav', restSamples, sampleRate);
  print('Generated assets/audio/rest_alarm.wav (${restSamples.length} samples)');
}

List<double> generateActivityAlarm(int sampleRate) {
  final totalDurationSeconds = 4.2;
  final totalSamples = (totalDurationSeconds * sampleRate).round();
  final buffer = List<double>.filled(totalSamples, 0.0);

  // Play two repeats of an uplifting melody: C5 (523Hz), E5 (659Hz), G5 (784Hz), C6 (1046Hz)
  void addTone(double startSec, double durationSec, double freq, double volume) {
    final startIdx = (startSec * sampleRate).round();
    final count = (durationSec * sampleRate).round();
    for (int i = 0; i < count; i++) {
      final t = i / sampleRate;
      final idx = startIdx + i;
      if (idx >= totalSamples) break;

      // Envelope: quick attack (0.02s), exponential decay
      double env = 1.0;
      if (t < 0.02) {
        env = t / 0.02;
      } else {
        env = exp(-4.0 * (t - 0.02) / durationSec);
      }

      // Harmonic synthesis (fundamental + 2nd harmonic for rich bell/marimba sound)
      final sample = (sin(2 * pi * freq * t) * 0.75 +
                      sin(2 * pi * (freq * 2) * t) * 0.25) * env * volume;
      buffer[idx] += sample;
    }
  }

  // Round 1
  addTone(0.0, 0.35, 523.25, 0.7); // C5
  addTone(0.35, 0.35, 659.25, 0.7); // E5
  addTone(0.70, 0.35, 783.99, 0.7); // G5
  addTone(1.05, 0.85, 1046.50, 0.9); // C6 long sustain

  // Round 2 (slightly higher energy)
  addTone(2.1, 0.35, 523.25, 0.7); // C5
  addTone(2.45, 0.35, 659.25, 0.7); // E5
  addTone(2.80, 0.35, 783.99, 0.7); // G5
  addTone(3.15, 0.95, 1046.50, 0.95); // C6
  addTone(3.15, 0.95, 1318.51, 0.4); // E6 harmony

  return buffer;
}

List<double> generateRestAlarm(int sampleRate) {
  final totalDurationSeconds = 4.5;
  final totalSamples = (totalDurationSeconds * sampleRate).round();
  final buffer = List<double>.filled(totalSamples, 0.0);

  // Soothing singing bell / Tibetan bowl harmonic chord:
  // A4 (440Hz), C#5 (554.37Hz), E5 (659.25Hz), A5 (880Hz)
  void addBellChord(double startSec, double durationSec, double volume) {
    final startIdx = (startSec * sampleRate).round();
    final count = (durationSec * sampleRate).round();
    for (int i = 0; i < count; i++) {
      final t = i / sampleRate;
      final idx = startIdx + i;
      if (idx >= totalSamples) break;

      // Soft gentle attack (0.08s) and long peaceful exponential decay
      double env = 1.0;
      if (t < 0.08) {
        env = t / 0.08;
      } else {
        env = exp(-2.2 * (t - 0.08) / durationSec);
      }

      // Calm harmonic overtones
      final s1 = sin(2 * pi * 440.0 * t) * 0.45;
      final s2 = sin(2 * pi * 554.37 * t) * 0.30;
      final s3 = sin(2 * pi * 659.25 * t) * 0.20;
      final s4 = sin(2 * pi * 880.0 * t) * 0.15;
      final sample = (s1 + s2 + s3 + s4) * env * volume;
      buffer[idx] += sample;
    }
  }

  // Two peaceful chimes
  addBellChord(0.0, 2.2, 0.85);
  addBellChord(2.0, 2.4, 0.85);

  return buffer;
}

void writeWavFile(String path, List<double> samples, int sampleRate) {
  final numSamples = samples.length;
  final subChunk2Size = numSamples * 2; // 16-bit mono = 2 bytes per sample
  final chunkSize = 36 + subChunk2Size;

  final byteData = ByteData(44 + subChunk2Size);

  // "RIFF"
  byteData.setUint8(0, 0x52);
  byteData.setUint8(1, 0x49);
  byteData.setUint8(2, 0x46);
  byteData.setUint8(3, 0x46);

  // ChunkSize
  byteData.setUint32(4, chunkSize, Endian.little);

  // "WAVE"
  byteData.setUint8(8, 0x57);
  byteData.setUint8(9, 0x41);
  byteData.setUint8(10, 0x56);
  byteData.setUint8(11, 0x45);

  // "fmt "
  byteData.setUint8(12, 0x66);
  byteData.setUint8(13, 0x6D);
  byteData.setUint8(14, 0x74);
  byteData.setUint8(15, 0x20);

  // Subchunk1Size (16 for PCM)
  byteData.setUint32(16, 16, Endian.little);
  // AudioFormat (1 for PCM)
  byteData.setUint16(20, 1, Endian.little);
  // NumChannels (1 for mono)
  byteData.setUint16(22, 1, Endian.little);
  // SampleRate
  byteData.setUint32(24, sampleRate, Endian.little);
  // ByteRate (SampleRate * NumChannels * BitsPerSample / 8)
  byteData.setUint32(28, sampleRate * 1 * 2, Endian.little);
  // BlockAlign (NumChannels * BitsPerSample / 8)
  byteData.setUint16(32, 2, Endian.little);
  // BitsPerSample (16)
  byteData.setUint16(34, 16, Endian.little);

  // "data"
  byteData.setUint8(36, 0x64);
  byteData.setUint8(37, 0x61);
  byteData.setUint8(38, 0x74);
  byteData.setUint8(39, 0x61);

  // Subchunk2Size
  byteData.setUint32(40, subChunk2Size, Endian.little);

  // Write samples clamped to 16-bit signed integer [-32768, 32767]
  int offset = 44;
  for (int i = 0; i < numSamples; i++) {
    final val = (samples[i].clamp(-1.0, 1.0) * 32767.0).round();
    byteData.setInt16(offset, val, Endian.little);
    offset += 2;
  }

  File(path).writeAsBytesSync(byteData.buffer.asUint8List());
}
