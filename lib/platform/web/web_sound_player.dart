import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'package:shuffle_alarm/platform/sound_player.dart';
import 'package:web/web.dart' as web;

/// Plays sounds with the browser's Web Audio API: one audio context for the
/// page, unlocked by a tap, and a gain node for each clip's volume.
///
/// Web Audio rather than an audio element per sound: once a tap resumed the
/// context, every later sound plays without a tap in Chrome, Firefox and
/// Safari, and a gain node sets the volume also where Safari on the iPhone
/// ignores the volume of an audio element (docs/DECISIONS.md, 1.4 and 2.4).
class WebSoundPlayer implements SoundPlayer {
  web.AudioContext? _context;
  final _buffers = <String, Future<web.AudioBuffer>>{};
  web.AudioBuffer? _tone;
  web.AudioBufferSourceNode? _source;

  @override
  bool get playsSounds => web.window.has('AudioContext');

  @override
  bool get needsUnlock => _context?.state != 'running';

  web.AudioContext get _audio => _context ??= web.AudioContext();

  @override
  Future<bool> unlock() async {
    if (!playsSounds) return false;
    final audio = _audio;
    // Still within the tap: a moment of silence, which Safari needs before
    // it lets the context play later, then resume.
    audio.createBufferSource()
      ..buffer = audio.createBuffer(1, 1, 22050)
      ..connect(audio.destination)
      ..start();
    return await _resume(audio, const Duration(seconds: 2));
  }

  /// Resumes [audio], and returns whether it runs. A browser that blocks
  /// the sound never settles the promise, so it waits [timeout] at most.
  Future<bool> _resume(web.AudioContext audio, Duration timeout) async {
    if (audio.state == 'running') return true;
    try {
      await audio.resume().toDart.timeout(timeout);
    } on Object {
      return false;
    }
    return audio.state == 'running';
  }

  @override
  Future<void> preload(Iterable<String> assets) async {
    if (!playsSounds) return;
    for (final asset in assets) {
      try {
        await _buffer(asset);
      } on Object {
        // Loaded again when it plays; a sound that cannot be read is skipped
        // then.
      }
    }
  }

  /// The decoded sound at [asset], decoded once. One that could not be read
  /// is read again the next time.
  Future<web.AudioBuffer> _buffer(String asset) async {
    var decoding = _buffers[asset];
    if (decoding == null) {
      decoding = _decode(asset);
      _buffers[asset] = decoding;
    }
    try {
      return await decoding;
    } on Object {
      if (identical(_buffers[asset], decoding)) {
        _buffers.remove(asset)?.ignore();
      }
      rethrow;
    }
  }

  Future<web.AudioBuffer> _decode(String asset) async {
    final data = await rootBundle.load(asset);
    // A copy, because decoding takes the bytes away from their buffer.
    final bytes = Uint8List.fromList(Uint8List.sublistView(data));
    return await _audio.decodeAudioData(bytes.buffer.toJS).toDart;
  }

  @override
  Future<void> play(
    String asset, {
    required Duration from,
    required Duration to,
    required double volume,
  }) async {
    if (!playsSounds) throw const SoundBlockedException('No Web Audio');
    final audio = _audio;
    // Without a tap now: Chrome and Firefox let a page play after any tap
    // it had before, so this can work without "Arm alarms" too.
    if (!await _resume(audio, const Duration(seconds: 1))) {
      throw const SoundBlockedException('The browser blocks the sound');
    }
    final buffer = await _buffer(asset);
    await stop();
    final source = audio.createBufferSource()..buffer = buffer;
    await _played(
      audio,
      source,
      volume,
      (source) => source.start(0, _seconds(from), _seconds(to - from)),
    );
  }

  @override
  Future<void> playTone({
    required Duration length,
    required double volume,
  }) async {
    if (!playsSounds) throw const SoundBlockedException('No Web Audio');
    final audio = _audio;
    if (!await _resume(audio, const Duration(seconds: 1))) {
      throw const SoundBlockedException('The browser blocks the sound');
    }
    await stop();
    final source = audio.createBufferSource()
      ..buffer = _toneBuffer(audio)
      ..loop = true;
    await _played(audio, source, volume, (source) {
      source
        ..start()
        ..stop(audio.currentTime + _seconds(length));
    });
  }

  /// Plays [source] at [volume], from its [start], until it ends or [stop]
  /// ends it.
  Future<void> _played(
    web.AudioContext audio,
    web.AudioBufferSourceNode source,
    double volume,
    void Function(web.AudioBufferSourceNode source) start,
  ) async {
    final gain = audio.createGain()
      ..gain.value = volume.clamp(0, 1)
      ..connect(audio.destination);
    source.connect(gain);
    final ended = Completer<void>();
    source.onended = ((web.Event _) {
      if (!ended.isCompleted) ended.complete();
    }).toJS;
    _source = source;
    start(source);
    await ended.future;
    if (identical(_source, source)) _source = null;
  }

  static double _seconds(Duration time) =>
      time.inMicroseconds / Duration.microsecondsPerSecond;

  /// One second of the tone, to loop: two short beeps and a pause. Made here
  /// once, so a ring needs no file or network for it.
  web.AudioBuffer _toneBuffer(web.AudioContext audio) {
    if (_tone case final tone?) return tone;
    final rate = audio.sampleRate.round();
    final samples = Float32List(rate);
    for (final start in const [0.0, 0.25]) {
      for (var i = 0; i < _beep * rate; i++) {
        final time = i / rate;
        // A short fade at both ends, so a beep does not click.
        final fade = min(1, min(time, _beep - time) / _beepFade);
        samples[(start * rate).round() + i] =
            _beepLevel * fade * sin(2 * pi * _beepPitch * time);
      }
    }
    final tone = audio.createBuffer(1, rate, rate.toDouble())
      ..copyToChannel(samples.toJS, 0);
    return _tone = tone;
  }

  /// How long one beep of the tone is, in seconds.
  static const _beep = 0.15;

  /// How long a beep of the tone takes to fade in and out, in seconds.
  static const _beepFade = 0.005;

  /// The pitch of the tone, in hertz.
  static const _beepPitch = 880.0;

  /// How loud a beep is, from 0 to 1: with its pauses, about as loud as the
  /// strong clips of the library, which reach -14 LUFS.
  static const _beepLevel = 0.5;

  @override
  Future<void> stop() async {
    final source = _source;
    _source = null;
    try {
      // Its "ended" event then ends the play() that started it.
      source?.stop();
    } on Object {
      // It had not started or had ended already.
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    final audio = _context;
    _context = null;
    if (audio != null) await audio.close().toDart;
  }
}
