import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

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
    final gain = audio.createGain()
      ..gain.value = volume.clamp(0, 1)
      ..connect(audio.destination);
    final source = audio.createBufferSource()
      ..buffer = buffer
      ..connect(gain);
    final ended = Completer<void>();
    source.onended = ((web.Event _) {
      if (!ended.isCompleted) ended.complete();
    }).toJS;
    _source = source;
    source.start(
      0,
      from.inMicroseconds / Duration.microsecondsPerSecond,
      (to - from).inMicroseconds / Duration.microsecondsPerSecond,
    );
    await ended.future;
    if (identical(_source, source)) _source = null;
  }

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
