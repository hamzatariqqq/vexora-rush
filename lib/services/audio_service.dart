import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'storage_service.dart';

class AudioService {
  AudioService(this.storage)
      : _dashSound = _tone(
    seconds: 0.14,
    startFrequency: 360,
    endFrequency: 830,
  ),
        _coinSound = _tone(
          seconds: 0.20,
          startFrequency: 720,
          endFrequency: 1150,
        ),
        _hitSound = _tone(
          seconds: 0.34,
          startFrequency: 240,
          endFrequency: 55,
        ),
        _musicSound = _music();

  final StorageService storage;

  final AudioPlayer _dashPlayer = AudioPlayer();
  final AudioPlayer _coinPlayer = AudioPlayer();
  final AudioPlayer _hitPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  final Uint8List _dashSound;
  final Uint8List _coinSound;
  final Uint8List _hitSound;
  final Uint8List _musicSound;

  bool _musicStarted = false;
  bool _disposed = false;

  void dash() {
    if (storage.soundOn) {
      _play(_dashPlayer, _dashSound, 0.35);
    }
    if (storage.vibrationOn) {
      unawaited(HapticFeedback.lightImpact());
    }
  }

  void coin() {
    if (storage.soundOn) {
      _play(_coinPlayer, _coinSound, 0.45);
    }
    if (storage.vibrationOn) {
      unawaited(HapticFeedback.selectionClick());
    }
  }

  void hit() {
    if (storage.soundOn) {
      _play(_hitPlayer, _hitSound, 0.55);
    }
    if (storage.vibrationOn) {
      unawaited(HapticFeedback.heavyImpact());
    }
  }

  void _play(AudioPlayer player, Uint8List sound, double volume) {
    if (_disposed) return;

    unawaited(
      player
          .play(
        BytesSource(sound, mimeType: 'audio/wav'),
        volume: volume,
      )
          .catchError((Object error) {
        debugPrint('Sound playback failed: $error');
      }),
    );
  }

  Future<void> startMusic() async {
    if (_disposed || !storage.musicOn || _musicStarted) return;

    _musicStarted = true;

    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);

      if (_disposed || !storage.musicOn) return;

      await _musicPlayer.play(
        BytesSource(_musicSound, mimeType: 'audio/wav'),
        volume: 0.12,
      );
    } catch (error) {
      _musicStarted = false;
      debugPrint('Music playback failed: $error');
    }
  }

  void pauseMusic() {
    if (!_musicStarted || _disposed) return;

    unawaited(_musicPlayer.pause());
  }

  void resumeMusic() {
    if (_disposed || !storage.musicOn) return;

    if (_musicStarted) {
      unawaited(_musicPlayer.resume());
    } else {
      unawaited(startMusic());
    }
  }

  void stopMusic() {
    if (_disposed) return;

    _musicStarted = false;
    unawaited(_musicPlayer.stop());
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    await Future.wait([
      _dashPlayer.dispose(),
      _coinPlayer.dispose(),
      _hitPlayer.dispose(),
      _musicPlayer.dispose(),
    ]);
  }

  static Uint8List _tone({
    required double seconds,
    required double startFrequency,
    required double endFrequency,
  }) {
    return _makeWav(seconds, (time) {
      final progress = time / seconds;
      final frequencyChange = endFrequency - startFrequency;
      final phase = 2 *
          pi *
          (startFrequency * time +
              frequencyChange * time * time / (2 * seconds));
      final fade = pow(1 - progress, 2).toDouble();

      return sin(phase) * fade * 0.65;
    });
  }

  static Uint8List _music() {
    const notes = <double>[
      110,
      164.81,
      130.81,
      196,
      110,
      174.61,
      146.83,
      196,
    ];

    return _makeWav(4, (time) {
      final beat = (time / 0.5).floor();
      final withinBeat = (time % 0.5) / 0.5;
      final frequency = notes[beat.clamp(0, notes.length - 1).toInt()];
      final beatFade = sin(pi * withinBeat);
      final loopFade = sin(pi * time / 4);

      return (sin(2 * pi * frequency * time) +
          sin(2 * pi * frequency * 2 * time) * 0.22) *
          beatFade *
          loopFade *
          0.26;
    });
  }

  static Uint8List _makeWav(
      double seconds,
      double Function(double time) sample,
      ) {
    const sampleRate = 22050;
    final count = (seconds * sampleRate).round();
    final dataLength = count * 2;
    final bytes = Uint8List(44 + dataLength);
    final data = ByteData.sublistView(bytes);

    void writeText(int offset, String text) {
      for (var i = 0; i < text.length; i++) {
        bytes[offset + i] = text.codeUnitAt(i);
      }
    }

    writeText(0, 'RIFF');
    data.setUint32(4, 36 + dataLength, Endian.little);
    writeText(8, 'WAVE');
    writeText(12, 'fmt ');

    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);

    writeText(36, 'data');
    data.setUint32(40, dataLength, Endian.little);

    for (var i = 0; i < count; i++) {
      final value = sample(i / sampleRate).clamp(-1.0, 1.0);
      data.setInt16(
        44 + i * 2,
        (value * 32767).round(),
        Endian.little,
      );
    }

    return bytes;
  }
}