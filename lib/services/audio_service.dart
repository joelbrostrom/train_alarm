import 'dart:js_interop';

import 'package:web/web.dart' as web;

class AudioService {
  web.HTMLAudioElement? _audioElement;
  bool _audioUnlocked = false;

  void _ensureAudioElement() {
    if (_audioElement != null) return;
    _audioElement = web.HTMLAudioElement();
    _audioElement!.loop = true;
    // Use a built-in oscillator-style alarm via data URI (sine wave beep pattern)
    _audioElement!.src = _generateAlarmDataUri();
  }

  void playAlarm() {
    _ensureAudioElement();
    _audioElement!.currentTime = 0;
    _audioElement!.play().toDart.then(
      (_) {
        _audioUnlocked = true;
      },
      onError: (e) {
        print('Audio play blocked by browser: $e');
      },
    );
  }

  void stopAlarm() {
    _audioElement?.pause();
    _audioElement?.currentTime = 0;
  }

  void playApproachingChime() {
    final chime = web.HTMLAudioElement();
    chime.src = _generateChimeDataUri();
    chime.play().toDart.catchError((_) => null);
  }

  String _generateChimeDataUri() {
    const sampleRate = 44100;
    const durationSeconds = 1;
    const totalSamples = sampleRate * durationSeconds;
    const freq = 660.0; // E5 — gentle

    final samples = List<int>.generate(totalSamples, (i) {
      final t = i / sampleRate;
      // Single gentle tone that fades out
      final envelope = (1.0 - t).clamp(0.0, 1.0);
      final sample = (16000 * envelope * _sin(2 * 3.14159265 * freq * t)).toInt();
      return sample.clamp(-32768, 32767);
    });

    final dataSize = totalSamples * 2;
    final fileSize = 36 + dataSize;
    final header = <int>[
      0x52, 0x49, 0x46, 0x46,
      fileSize & 0xFF, (fileSize >> 8) & 0xFF,
      (fileSize >> 16) & 0xFF, (fileSize >> 24) & 0xFF,
      0x57, 0x41, 0x56, 0x45,
      0x66, 0x6D, 0x74, 0x20,
      16, 0, 0, 0,
      1, 0, 1, 0,
      sampleRate & 0xFF, (sampleRate >> 8) & 0xFF,
      (sampleRate >> 16) & 0xFF, (sampleRate >> 24) & 0xFF,
      (sampleRate * 2) & 0xFF, ((sampleRate * 2) >> 8) & 0xFF,
      ((sampleRate * 2) >> 16) & 0xFF, ((sampleRate * 2) >> 24) & 0xFF,
      2, 0, 16, 0,
      0x64, 0x61, 0x74, 0x61,
      dataSize & 0xFF, (dataSize >> 8) & 0xFF,
      (dataSize >> 16) & 0xFF, (dataSize >> 24) & 0xFF,
    ];

    final bytes = <int>[...header];
    for (final sample in samples) {
      bytes.add(sample & 0xFF);
      bytes.add((sample >> 8) & 0xFF);
    }

    return 'data:audio/wav;base64,${_bytesToBase64(bytes)}';
  }

  bool get isUnlocked => _audioUnlocked;

  /// Unlock audio context with a user gesture (call from a button tap)
  void unlockAudio() {
    _ensureAudioElement();
    _audioElement!.volume = 0.01;
    _audioElement!.play().toDart.then(
      (_) {
        _audioElement!.pause();
        _audioElement!.volume = 1.0;
        _audioUnlocked = true;
      },
      onError: (e) {
        print('Audio unlock failed: $e');
      },
    );
  }

  String _generateAlarmDataUri() {
    // Generate a WAV file with an alarm-like beep pattern
    // 44100 Hz, 16-bit mono, ~3 seconds of beeping
    const sampleRate = 44100;
    const durationSeconds = 3;
    const totalSamples = sampleRate * durationSeconds;
    const freq1 = 880.0; // A5
    const freq2 = 1100.0; // ~C#6

    final samples = List<int>.generate(totalSamples, (i) {
      final t = i / sampleRate;
      final beepPhase = (t * 4).floor() % 2; // 4 beeps per second
      if (beepPhase == 0) {
        // Alternating frequencies for urgency
        final freq = (t * 2).floor() % 2 == 0 ? freq1 : freq2;
        final sample = (32000 * _sin(2 * 3.14159265 * freq * t)).toInt();
        return sample.clamp(-32768, 32767);
      }
      return 0;
    });

    // Build WAV header + data
    final dataSize = totalSamples * 2;
    final fileSize = 36 + dataSize;
    final header = <int>[
      // "RIFF"
      0x52, 0x49, 0x46, 0x46,
      // File size - 8
      fileSize & 0xFF, (fileSize >> 8) & 0xFF,
      (fileSize >> 16) & 0xFF, (fileSize >> 24) & 0xFF,
      // "WAVE"
      0x57, 0x41, 0x56, 0x45,
      // "fmt "
      0x66, 0x6D, 0x74, 0x20,
      // Subchunk1 size (16)
      16, 0, 0, 0,
      // Audio format (1 = PCM)
      1, 0,
      // Num channels (1)
      1, 0,
      // Sample rate
      sampleRate & 0xFF, (sampleRate >> 8) & 0xFF,
      (sampleRate >> 16) & 0xFF, (sampleRate >> 24) & 0xFF,
      // Byte rate
      (sampleRate * 2) & 0xFF, ((sampleRate * 2) >> 8) & 0xFF,
      ((sampleRate * 2) >> 16) & 0xFF, ((sampleRate * 2) >> 24) & 0xFF,
      // Block align (2)
      2, 0,
      // Bits per sample (16)
      16, 0,
      // "data"
      0x64, 0x61, 0x74, 0x61,
      // Data size
      dataSize & 0xFF, (dataSize >> 8) & 0xFF,
      (dataSize >> 16) & 0xFF, (dataSize >> 24) & 0xFF,
    ];

    final bytes = <int>[...header];
    for (final sample in samples) {
      bytes.add(sample & 0xFF);
      bytes.add((sample >> 8) & 0xFF);
    }

    final base64Data = _bytesToBase64(bytes);
    return 'data:audio/wav;base64,$base64Data';
  }

  double _sin(double x) {
    // Taylor series approximation for sin
    x = x % (2 * 3.14159265);
    if (x > 3.14159265) x -= 2 * 3.14159265;
    double result = x;
    double term = x;
    for (int i = 1; i <= 7; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  String _bytesToBase64(List<int> bytes) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final buffer = StringBuffer();
    for (int i = 0; i < bytes.length; i += 3) {
      final b0 = bytes[i];
      final b1 = i + 1 < bytes.length ? bytes[i + 1] : 0;
      final b2 = i + 2 < bytes.length ? bytes[i + 2] : 0;
      buffer.write(chars[(b0 >> 2) & 0x3F]);
      buffer.write(chars[((b0 << 4) | (b1 >> 4)) & 0x3F]);
      buffer.write(
        i + 1 < bytes.length ? chars[((b1 << 2) | (b2 >> 6)) & 0x3F] : '=',
      );
      buffer.write(i + 2 < bytes.length ? chars[b2 & 0x3F] : '=');
    }
    return buffer.toString();
  }

  void dispose() {
    stopAlarm();
    _audioElement = null;
  }
}
