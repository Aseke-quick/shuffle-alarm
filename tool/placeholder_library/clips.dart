/// The nine placeholder clips of task 2.3: three genres, each with a gentle
/// (intensity 1), a medium (2) and a strong (3) clip. Original music, written
/// and synthesized here: gentle clips are softer and slower, strong ones
/// brighter and faster.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'synth.dart';

/// One placeholder clip: what the manifest says about it, and how it is
/// made.
class PlaceholderClip {
  const PlaceholderClip({
    required this.id,
    required this.title,
    required this.genre,
    required this.intensity,
    required this.make,
  });

  final String id;
  final String title;
  final String genre;
  final int intensity;

  /// Makes the clip's samples, mastered, from -1 to 1.
  final Float64List Function() make;
}

/// Every placeholder clip, by genre and intensity.
const placeholderClips = [
  PlaceholderClip(
    id: 'quiet-strings',
    title: 'Quiet Strings',
    genre: 'acoustic',
    intensity: 1,
    make: _quietStrings,
  ),
  PlaceholderClip(
    id: 'back-porch',
    title: 'Back Porch',
    genre: 'acoustic',
    intensity: 2,
    make: _backPorch,
  ),
  PlaceholderClip(
    id: 'wake-up-strum',
    title: 'Wake-Up Strum',
    genre: 'acoustic',
    intensity: 3,
    make: _wakeUpStrum,
  ),
  PlaceholderClip(
    id: 'soft-circuit',
    title: 'Soft Circuit',
    genre: 'electronic',
    intensity: 1,
    make: _softCircuit,
  ),
  PlaceholderClip(
    id: 'morning-signal',
    title: 'Morning Signal',
    genre: 'electronic',
    intensity: 2,
    make: _morningSignal,
  ),
  PlaceholderClip(
    id: 'fast-lane',
    title: 'Fast Lane',
    genre: 'electronic',
    intensity: 3,
    make: _fastLane,
  ),
  PlaceholderClip(
    id: 'warm-tape',
    title: 'Warm Tape',
    genre: 'lo-fi',
    intensity: 1,
    make: _warmTape,
  ),
  PlaceholderClip(
    id: 'coffee-steam',
    title: 'Coffee Steam',
    genre: 'lo-fi',
    intensity: 2,
    make: _coffeeSteam,
  ),
  PlaceholderClip(
    id: 'brisk-walk',
    title: 'Brisk Walk',
    genre: 'lo-fi',
    intensity: 3,
    make: _briskWalk,
  ),
];

/// The loudness of a clip of each intensity, in LUFS (`master`). Gentle
/// clips are a little softer, and the players turn them down further at the
/// start of a ring (task 1.4).
const _loudness = {1: -18.0, 2: -16.0, 3: -14.0};

/// A clip being made: its length, its tempo and its noise.
class _Song {
  _Song({required double seconds, required this.bpm, required int seed})
    : length = sampleAt(seconds),
      noise = Noise(seed);

  final int length;
  final double bpm;
  final Noise noise;

  /// Seconds from the start of the clip to [beat], after a short lead-in.
  double at(num beat) => 0.05 + beats(beat);

  /// How long [count] beats last, in seconds.
  double beats(num count) => count * 60 / bpm;

  /// A new, silent track as long as the clip.
  Float64List track() => Float64List(length);
}

/// The notes of a tune written as `beat:pitch`, or `beat:pitch:beats` for a
/// note that is not [length] beats long, separated by spaces: such as
/// `'0:E5:1.5 1.5:D5'`.
List<(double, int, double)> _tune(String text, {double length = 0.5}) => [
  for (final item in text.split(' '))
    if (item.split(':') case [final beat, final pitch, ...final rest])
      (
        double.parse(beat),
        note(pitch),
        rest.isEmpty ? length : double.parse(rest.single),
      ),
];

/// [beat] with each off-beat eighth note played late, at [swing] of its
/// beat (0.5: straight).
double _swing(double beat, double swing) =>
    beat % 1 == 0.5 ? beat - 0.5 + swing : beat;

/// Plays [names] on the electric piano, rolled [roll] seconds apart, from
/// [beat] for [beats] beats.
void _keys(
  Float64List out,
  _Song song, {
  required num beat,
  required num beats,
  required String names,
  required double gain,
  double roll = 0.03,
  double bright = 0.45,
}) {
  for (final (i, midi) in notes(names).indexed) {
    electricPiano(
      out,
      start: song.at(beat) + i * roll,
      freq: hz(midi),
      length: song.beats(beats),
      gain: gain,
      bright: bright,
      tremolo: 0.1,
    );
  }
}

/// Plays [names] as a synthesizer pad from [beat] for [beats] beats.
void _pad(
  Float64List out,
  _Song song, {
  required num beat,
  required num beats,
  required String names,
  required double gain,
  double cutoff = 900,
  double attack = 0.4,
  double release = 0.8,
}) {
  for (final midi in notes(names)) {
    synth(
      out,
      start: song.at(beat),
      freq: hz(midi),
      length: song.beats(beats),
      gain: gain,
      cutoff: cutoff,
      detune: 9,
      attack: attack,
      sustain: 1,
      release: release,
    );
  }
}

/// Plays a bass note on a soft triangle wave.
void _bass(
  Float64List out,
  _Song song, {
  required num beat,
  required num beats,
  required int midi,
  double gain = 0.2,
  double cutoff = 700,
}) {
  synth(
    out,
    start: song.at(beat),
    freq: hz(midi),
    length: song.beats(beats),
    gain: gain,
    wave: Wave.triangle,
    cutoff: cutoff,
    attack: 0.01,
    decay: 0.5,
    sustain: 0.6,
    release: 0.12,
  );
}

/// [samples] through a low-pass filter at [cutoff] Hz.
Float64List _lowPassed(Float64List samples, double cutoff) {
  final out = Float64List.fromList(samples);
  Biquad.lowPass(cutoff).filter(out);
  return out;
}

/// [samples] pushed through a gentle saturation, [drive] times harder than
/// they are.
Float64List _saturated(Float64List samples, double drive) =>
    Float64List.fromList([for (final x in samples) soften(drive * x) / drive]);

// Acoustic: plucked strings.

/// Gentle: a slow harp-like arpeggio in G major, 3/4 at 72 BPM.
Float64List _quietStrings() {
  final song = _Song(seconds: 21.5, bpm: 72, seed: 101);
  final strings = song.track();
  // Each bar: its bass note, the arpeggio above it in eighths, and a note of
  // the tune.
  const bars = [
    ('G2', 'D3 G3 B3 D4 B3', 'B4'),
    ('F#2', 'A2 D3 F#3 A3 F#3', 'A4'),
    ('E2', 'B2 E3 G3 B3 G3', 'G4'),
    ('C2', 'G2 C3 E3 G3 E3', 'G4'),
    ('B1', 'D3 G3 B3 D4 B3', 'B4'),
    ('A1', 'E3 A3 C4 E4 C4', 'C5'),
    ('D2', 'A2 D3 G3 A3 F#3', 'A4'),
  ];
  for (final (bar, (bass, arpeggio, tune)) in bars.indexed) {
    final downbeat = bar * 3;
    pluck(
      strings,
      song.noise,
      start: song.at(downbeat),
      freq: hz(note(bass)),
      gain: 0.45,
      brightness: 0.15,
      ring: 4,
    );
    pluck(
      strings,
      song.noise,
      start: song.at(downbeat),
      freq: hz(note(tune)),
      gain: 0.32,
      brightness: 0.4,
      ring: 3.5,
    );
    for (final (i, midi) in notes(arpeggio).indexed) {
      pluck(
        strings,
        song.noise,
        start: song.at(downbeat + (i + 1) * 0.5),
        freq: hz(midi),
        gain: 0.3,
        brightness: 0.25,
      );
    }
  }
  strum(
    strings,
    song.noise,
    start: song.at(21),
    notes: notes('G2 D3 G3 B3 D4 G4'),
    gain: 0.42,
    spread: 0.09,
    brightness: 0.3,
    ring: 6,
  );

  final mix = Float64List.fromList(strings);
  addInto(mix, reverb(strings, room: 0.75, damp: 0.5), 0.35);
  return master(mix, fadeIn: 0.3, fadeOut: 1.5, loudness: _loudness[1]!);
}

/// Medium: fingerpicking with an alternating bass in C major, 4/4 at
/// 100 BPM, with a shaker.
Float64List _backPorch() {
  final song = _Song(seconds: 20.4, bpm: 100, seed: 102);
  final strings = song.track();
  final shakers = song.track();
  // A chord for each half bar, as root, alternate bass and two treble notes.
  const shapes = {
    'C': 'C3 G2 G3 E4',
    'Am': 'A2 E3 A3 C4',
    'F': 'F2 C3 A3 C4',
    'G': 'G2 D3 B3 D4',
  };
  const halves = 'C C Am Am F F G G C C Am Am F G';
  final chords = halves.split(' ');
  for (var eighth = 0; eighth < 4 * chords.length; eighth++) {
    final [root, alternate, high, higher] = notes(shapes[chords[eighth ~/ 4]]!);
    final (midi, gain, brightness) = switch (eighth % 4) {
      0 => (root, 0.4, 0.25),
      1 => (high, 0.26, 0.4),
      2 => (alternate, 0.34, 0.25),
      _ => (higher, 0.26, 0.4),
    };
    pluck(
      strings,
      song.noise,
      start: song.at(eighth / 2),
      freq: hz(midi),
      gain: gain,
      brightness: brightness,
      ring: 2.2,
    );
    shaker(
      shakers,
      song.noise,
      start: song.at(eighth / 2),
      gain: eighth.isOdd ? 0.06 : 0.035,
    );
  }
  final tune = _tune(
    '0:E5 1.5:G5 3:E5 4:C5 5.5:E5 7:A4 8:A4 9.5:C5 11:F5 12:D5 13.5:B4 15:G4 '
    '16:E5 17.5:G5 19:A5 20:G5 21.5:E5 23:C5 24:A4 25.5:C5 26:B4 27:D5',
  );
  for (final (beat, midi, _) in tune) {
    pluck(
      strings,
      song.noise,
      start: song.at(beat),
      freq: hz(midi),
      gain: 0.36,
      brightness: 0.6,
      ring: 2.2,
    );
  }
  strum(
    strings,
    song.noise,
    start: song.at(28),
    notes: notes('C3 G3 C4 E4 G4 E5'),
    gain: 0.4,
    spread: 0.05,
    brightness: 0.45,
    ring: 4,
  );

  final mix = Float64List.fromList(strings);
  addInto(mix, shakers);
  addInto(mix, reverb(strings, damp: 0.5), 0.25);
  return master(mix, fadeIn: 0.1, fadeOut: 1.2, loudness: _loudness[2]!);
}

/// Strong: fast strumming in D major, 4/4 at 132 BPM, with stomps, claps
/// and a bright lead.
Float64List _wakeUpStrum() {
  final song = _Song(seconds: 16, bpm: 132, seed: 103);
  final guitar = song.track();
  final lead = song.track();
  final drums = song.track();
  const chords = {
    'D': 'A2 D3 A3 D4 F#4',
    'A': 'A2 E3 A3 C#4 E4',
    'Bm': 'B2 F#3 B3 D4 F#4',
    'G': 'G2 B2 D3 G3 B3 G4',
  };
  // Down, down, up, up, down, up, as eighth notes.
  const strokes = [0, 2, 3, 5, 6, 7];
  const ups = {3, 5, 7};
  for (final (bar, name) in 'D A Bm G D A G A'.split(' ').indexed) {
    final chord = notes(chords[name]!);
    for (final (i, eighth) in strokes.indexed) {
      final up = ups.contains(eighth);
      final next = i + 1 < strokes.length ? strokes[i + 1] : 8;
      strum(
        guitar,
        song.noise,
        start: song.at(bar * 4 + eighth / 2),
        notes: up ? chord.sublist(chord.length - 4) : chord,
        gain: up ? 0.14 : 0.2,
        spread: up ? 0.008 : 0.012,
        upstroke: up,
        brightness: up ? 0.8 : 0.72,
        ring: 1.6,
        length: song.beats((next - eighth) / 2),
      );
    }
  }
  strum(
    guitar,
    song.noise,
    start: song.at(32),
    notes: notes(chords['D']!),
    gain: 0.22,
    brightness: 0.7,
  );

  final tune = _tune(
    '0:F#5 1:A5 2:F#5 3:E5 4:E5 5:C#5 6:E5 7:A5 '
    '8:D5 9:F#5 10:B5 11:A5 12:B4 13:D5 14:G5 15:F#5 '
    '16:A5 16.5:F#5 17:D5 17.5:E5 18:F#5 19:A5 '
    '20:E5 20.5:C#5 21:A4 21.5:B4 22:C#5 23:E5 '
    '24:D5 24.5:B4 25:G4 25.5:A4 26:B4 27:D5 '
    '28:C#5 29:E5 30:A5 30.5:G5 31:F#5 31.5:E5 32:D5:0',
  );
  for (final (beat, midi, beats) in tune) {
    pluck(
      lead,
      song.noise,
      start: song.at(beat),
      freq: hz(midi),
      gain: 0.32,
      brightness: 0.92,
      ring: 1.2,
      length: beats == 0 ? null : song.beats(beats),
    );
  }

  for (var beat = 0; beat <= 32; beat++) {
    if (beat.isEven) {
      kick(drums, song.noise, start: song.at(beat), gain: 0.5, punch: 0.4);
    } else {
      clap(drums, song.noise, start: song.at(beat), gain: 0.38);
    }
  }
  for (var eighth = 0; eighth < 64; eighth++) {
    shaker(
      drums,
      song.noise,
      start: song.at(eighth / 2),
      gain: eighth.isOdd ? 0.1 : 0.06,
    );
  }

  final mix = Float64List.fromList(guitar);
  addInto(mix, lead);
  addInto(mix, drums);
  final send = Float64List.fromList(guitar);
  addInto(send, lead);
  addInto(mix, reverb(send, room: 0.45), 0.18);
  return master(mix, fadeIn: 0.02, fadeOut: 1, loudness: _loudness[3]!);
}

// Electronic: synthesizers.

/// Gentle: soft pads under a music-box arpeggio with echoes, 70 BPM, no
/// drums.
Float64List _softCircuit() {
  final song = _Song(seconds: 19.2, bpm: 70, seed: 201);
  final pads = song.track();
  final bells = song.track();
  // Each bar: the pad chord, its bass note and the arpeggio in eighths.
  const bars = [
    ('F3 A3 C4 E4', 'F2', 'F5 A5 C6 E6 C6 A5 F5 C5'),
    ('E3 G3 A3 C4', 'A2', 'E5 G5 A5 C6 A5 G5 E5 C5'),
    ('D3 F3 A3 E4', 'D2', 'D5 F5 A5 E6 A5 F5 D5 A4'),
    ('F3 Bb3 C4 D4', 'Bb1', 'D5 F5 Bb5 C6 Bb5 F5 D5 C5'),
  ];
  for (final (bar, (chord, bass, arpeggio)) in bars.indexed) {
    final downbeat = bar * 4;
    _pad(
      pads,
      song,
      beat: downbeat,
      beats: 4.4,
      names: chord,
      gain: 0.08,
      cutoff: 700,
      attack: 1.2,
      release: 1.4,
    );
    synth(
      pads,
      start: song.at(downbeat),
      freq: hz(note(bass)),
      length: song.beats(4),
      gain: 0.1,
      wave: Wave.sine,
      attack: 0.6,
      sustain: 1,
      release: 1,
    );
    for (final (i, midi) in notes(arpeggio).indexed) {
      mallet(
        bells,
        start: song.at(downbeat + i / 2),
        freq: hz(midi),
        gain: 0.17,
        ring: 1.6,
        bright: 0.4,
      );
    }
  }
  _pad(
    pads,
    song,
    beat: 16,
    beats: 3,
    names: 'F3 A3 C4 E4 G4',
    gain: 0.07,
    cutoff: 700,
    attack: 0.8,
    release: 1.6,
  );
  for (final (beat, midi, _) in _tune('16:F5 17:A5 18:C6 19:E6 20:G6')) {
    mallet(
      bells,
      start: song.at(beat),
      freq: hz(midi),
      gain: 0.16,
      bright: 0.4,
    );
  }
  echo(bells, delay: song.beats(0.75), feedback: 0.4);

  final mix = Float64List.fromList(pads);
  addInto(mix, bells);
  addInto(mix, reverb(mix, room: 0.85, damp: 0.5, preDelay: 0.03), 0.4);
  return master(mix, fadeIn: 0.8, fadeOut: 2, loudness: _loudness[1]!);
}

/// Medium: synth-pop at 104 BPM, with an arpeggio in sixteenths, a bouncing
/// bass, claps and hi-hats, and a lead in the second half.
Float64List _morningSignal() {
  final song = _Song(seconds: 19.46, bpm: 104, seed: 202);
  final synths = song.track();
  final drums = song.track();
  // Each bar: the pad chord, the bass root and the arpeggio.
  const bars = [
    ('A3 C4 E4', 'A2', 'A4 C5 E5 A5 E5 C5 A4 E4'),
    ('A3 C4 F4', 'F2', 'F4 A4 C5 F5 C5 A4 F4 C4'),
    ('G3 C4 E4', 'C3', 'C5 E5 G5 C6 G5 E5 C5 G4'),
    ('G3 B3 D4', 'G2', 'G4 B4 D5 G5 D5 B4 G4 D4'),
  ];
  for (var bar = 0; bar < 8; bar++) {
    final (chord, bass, arpeggio) = bars[bar % 4];
    final downbeat = bar * 4;
    _pad(synths, song, beat: downbeat, beats: 4, names: chord, gain: 0.05);
    final root = note(bass);
    for (final (eighth, offset) in [0, 0, 12, 0, 0, 12, 0, 7].indexed) {
      synth(
        synths,
        start: song.at(downbeat + eighth / 2),
        freq: hz(root + offset),
        length: song.beats(0.42),
        gain: 0.15,
        cutoff: 380,
        sweep: 900,
        sweepTime: 0.09,
        q: 0.9,
        sub: 0.5,
        decay: 0.15,
        sustain: 0.6,
        release: 0.05,
      );
    }
    final arp = notes(arpeggio);
    for (var sixteenth = 0; sixteenth < 16; sixteenth++) {
      synth(
        synths,
        start: song.at(downbeat + sixteenth / 4),
        freq: hz(arp[sixteenth % 8]),
        length: song.beats(0.2),
        gain: 0.075,
        wave: Wave.square,
        cutoff: 1400,
        sweep: 2600,
        sweepTime: 0.06,
        q: 1.2,
        decay: 0.1,
        sustain: 0.4,
        release: 0.06,
      );
    }
    for (final beat in [0, 2, if (bar % 4 == 3) 2.5]) {
      kick(drums, song.noise, start: song.at(downbeat + beat), gain: 0.65);
    }
    for (final beat in [1, 3]) {
      clap(drums, song.noise, start: song.at(downbeat + beat), gain: 0.4);
    }
    for (var eighth = 0; eighth < 8; eighth++) {
      hat(
        drums,
        song.noise,
        start: song.at(downbeat + eighth / 2),
        gain: eighth.isOdd ? 0.18 : 0.1,
      );
    }
  }
  kick(drums, song.noise, start: song.at(32), gain: 0.65);
  final tune = _tune(
    '16:E5:1.5 17.5:D5 18:C5:1 19:D5:1 20:C5:1.5 21.5:A4 22:C5:1 23:F5:1 '
    '24:E5:1.5 25.5:G5 26:E5:1 27:C5:1 28:D5:2 30:B4:1 31:D5:1',
  );
  for (final (beat, midi, beats) in tune) {
    synth(
      synths,
      start: song.at(beat),
      freq: hz(midi),
      length: song.beats(beats) - 0.03,
      gain: 0.12,
      wave: Wave.square,
      detune: 8,
      cutoff: 2200,
      sweep: 1500,
      sweepTime: 0.15,
      sustain: 0.75,
      release: 0.12,
    );
  }

  final mix = Float64List.fromList(synths);
  addInto(mix, drums);
  addInto(mix, reverb(synths, room: 0.55, damp: 0.45), 0.25);
  return master(mix, fadeIn: 0.05, fadeOut: 1, loudness: _loudness[2]!);
}

/// Strong: a driving dance beat at 128 BPM, with a kick on every beat, a
/// rolling bass, a pad that ducks under the kick, and a bright lead.
Float64List _fastLane() {
  final song = _Song(seconds: 16, bpm: 128, seed: 203);
  final pads = song.track();
  final synths = song.track();
  final drums = song.track();
  // Each bar: the pad chord and the bass note.
  const bars = [
    ('G3 B3 E4', 'E2'),
    ('G3 C4 E4', 'C2'),
    ('G3 B3 D4', 'G2'),
    ('F#3 A3 D4', 'D2'),
  ];
  for (var bar = 0; bar < 8; bar++) {
    final (chord, bass) = bars[bar % 4];
    final downbeat = bar * 4;
    for (final midi in notes(chord)) {
      synth(
        pads,
        start: song.at(downbeat),
        freq: hz(midi),
        length: song.beats(4),
        gain: 0.06,
        detune: 12,
        cutoff: 1600,
        attack: 0.05,
        sustain: 1,
        release: 0.3,
      );
    }
    for (var sixteenth = 0; sixteenth < 16; sixteenth++) {
      if (sixteenth % 4 == 0) continue;
      synth(
        synths,
        start: song.at(downbeat + sixteenth / 4),
        freq: hz(note(bass)),
        length: song.beats(0.2),
        gain: sixteenth % 4 == 2 ? 0.18 : 0.12,
        cutoff: 500,
        sweep: 1800,
        sweepTime: 0.07,
        q: 1.4,
        sub: 0.6,
        decay: 0.1,
        sustain: 0.5,
        release: 0.04,
      );
    }
  }
  // The pad ducks under each kick, as with a sidechain compressor.
  final beatLength = song.beats(1);
  for (var n = sampleAt(song.at(0)); n < pads.length; n++) {
    final sinceKick = (n / sampleRate - song.at(0)) % beatLength;
    pads[n] *= 1 - 0.7 * math.exp(-sinceKick / 0.1);
  }

  // The lead: a hook over four bars, played twice with a new ending.
  const hook =
      '0:B4 0.5:E5 1:G5 1.5:E5 2:B5:0.75 3:A5 3.5:G5 '
      '4:G5 4.5:E5 5:C5 5.5:E5 6:G5:1 7:E5:1 '
      '8:D5 8.5:G5 9:B5 9.5:G5 10:D6:0.75 11:C6 11.5:B5';
  const endings = [
    '12:A5 12.5:F#5 13:D5 13.5:F#5 14:A5:1 15:F#5:1',
    '12:A5 12.5:B5 13:D6:1 14:F#5:2',
  ];
  for (final (round, ending) in endings.indexed) {
    for (final (beat, midi, beats) in _tune('$hook $ending')) {
      synth(
        synths,
        start: song.at(round * 16 + beat),
        freq: hz(midi),
        length: song.beats(beats) - 0.02,
        gain: 0.12,
        detune: 14,
        cutoff: 3000,
        sweep: 3000,
        sweepTime: 0.15,
        q: 1,
        decay: 0.25,
        release: 0.08,
      );
    }
  }

  for (var beat = 0; beat < 32; beat++) {
    kick(drums, song.noise, start: song.at(beat), gain: 0.7, punch: 0.9);
    if (beat.isOdd) clap(drums, song.noise, start: song.at(beat), gain: 0.45);
    hat(drums, song.noise, start: song.at(beat + 0.5), gain: 0.16, open: true);
    for (final sixteenth in [0.25, 0.75]) {
      hat(drums, song.noise, start: song.at(beat + sixteenth), gain: 0.07);
    }
  }
  kick(drums, song.noise, start: song.at(32), gain: 0.7, punch: 0.9);

  final mix = Float64List.fromList(pads);
  addInto(mix, synths);
  addInto(mix, drums);
  final send = Float64List.fromList(pads);
  addInto(send, synths);
  addInto(mix, reverb(send, room: 0.5), 0.18);
  return master(mix, fadeIn: 0.02, fadeOut: 0.9, loudness: _loudness[3]!);
}

// Lo-fi: electric piano, worn tape and vinyl.

/// Gentle: slow jazzy electric piano chords on worn tape, 66 BPM, no drums.
Float64List _warmTape() {
  final song = _Song(seconds: 20.2, bpm: 66, seed: 301);
  final keys = song.track();
  // Each bar: the chord, its bass note, and two notes on the vibraphone.
  const bars = [
    ('E3 G3 B3 D4', 'C2', '1:B4 2.5:D5'),
    ('G3 B3 C4 E4', 'A2', '1:C5 2.5:E5'),
    ('F3 A3 C4 E4', 'D2', '1:F5 2.5:E5'),
    ('F3 B3 E4', 'G2', '1:D5 2.5:B4'),
  ];
  for (final (bar, (chord, bass, vibes)) in bars.indexed) {
    final downbeat = bar * 4;
    _keys(keys, song, beat: downbeat, beats: 2.5, names: chord, gain: 0.16);
    _keys(
      keys,
      song,
      beat: downbeat + 2.5,
      beats: 1.4,
      names: chord,
      gain: 0.1,
      roll: 0.015,
    );
    _bass(
      keys,
      song,
      beat: downbeat,
      beats: 3.2,
      midi: note(bass),
      cutoff: 500,
    );
    for (final (beat, midi, _) in _tune(vibes)) {
      mallet(
        keys,
        start: song.at(downbeat + beat),
        freq: hz(midi),
        gain: 0.13,
        ring: 2.5,
        bright: 0.2,
      );
    }
  }
  _keys(
    keys,
    song,
    beat: 16,
    beats: 4.5,
    names: 'C3 E3 G3 B3 D4',
    gain: 0.15,
    roll: 0.06,
  );
  mallet(keys, start: song.at(16.5), freq: hz(note('E5')), gain: 0.12, ring: 3);

  return _tape(song, keys, cutoff: 3600, dust: 0.03, loudness: _loudness[1]!);
}

/// Medium: a lazy swung beat with electric piano and bass, 80 BPM.
Float64List _coffeeSteam() {
  final song = _Song(seconds: 19, bpm: 80, seed: 302);
  final keys = song.track();
  final drums = song.track();
  const swing = 0.6;
  // Each half bar: the chord and its bass note.
  const halves = [
    ('A3 C4 E4 G4', 'F2'), ('A3 C4 E4 G4', 'F2'), // Fmaj9
    ('G3 B3 D4', 'E2'), ('G3 B3 D4', 'E2'), // Em7
    ('F3 A3 C4 E4', 'D2'), ('F3 A3 C4 E4', 'D2'), // Dm9
    ('F3 B3 E4', 'G2'), ('F3 B3 E4', 'G2'), // G13
    ('G3 B3 D4', 'E2'), ('G3 B3 C4 E4', 'A2'), // Em7, Am9
    ('F3 A3 C4 E4', 'D2'), ('F3 B3 E4', 'G2'), // Dm9, G13
  ];
  for (var bar = 0; bar < 6; bar++) {
    final downbeat = bar * 4;
    final (first, firstBass) = halves[bar * 2];
    final (second, secondBass) = halves[bar * 2 + 1];
    _keys(keys, song, beat: downbeat, beats: 1.5, names: first, gain: 0.15);
    _keys(
      keys,
      song,
      beat: downbeat + _swing(2.5, swing),
      beats: 1.2,
      names: second,
      gain: 0.12,
      roll: 0.02,
    );
    final low = note(firstBass);
    final high = note(secondBass);
    _bass(keys, song, beat: downbeat, beats: 1.4, midi: low);
    _bass(
      keys,
      song,
      beat: downbeat + _swing(1.5, swing),
      beats: 0.4,
      midi: low + 12,
    );
    _bass(keys, song, beat: downbeat + 2, beats: 1.4, midi: high);
    _bass(
      keys,
      song,
      beat: downbeat + _swing(3.5, swing),
      beats: 0.3,
      midi: high + 12,
    );
    for (final beat in [0.0, 1.5, 2.5]) {
      kick(
        drums,
        song.noise,
        start: song.at(downbeat + _swing(beat, swing)),
        gain: beat == 0 ? 0.65 : 0.5,
        punch: 0.15,
      );
    }
    for (final beat in [1, 3]) {
      snare(drums, song.noise, start: song.at(downbeat + beat), gain: 0.45);
    }
    if (bar.isOdd) {
      snare(
        drums,
        song.noise,
        start: song.at(downbeat + _swing(3.5, swing)),
        gain: 0.12,
      );
    }
    for (var eighth = 0; eighth < 8; eighth++) {
      hat(
        drums,
        song.noise,
        start: song.at(downbeat + _swing(eighth / 2, swing)),
        gain: eighth.isOdd ? 0.07 : 0.12,
      );
    }
  }
  _keys(keys, song, beat: 24, beats: 2, names: 'E3 G3 B3 D4', gain: 0.14);

  addInto(keys, _saturated(_lowPassed(drums, 5000), 1.5));
  return _tape(song, keys, cutoff: 4800, dust: 0.02, loudness: _loudness[2]!);
}

/// Strong: a bouncing swung beat with a vibraphone tune over electric piano,
/// 92 BPM.
Float64List _briskWalk() {
  final song = _Song(seconds: 16.66, bpm: 92, seed: 303);
  final keys = song.track();
  final drums = song.track();
  const swing = 0.58;
  // Each bar: the chord, its bass note and the tune.
  const bars = [
    ('G3 B3 C4 E4', 'A2', '0:E5 0.5:G5 1:A5 2:G5 2.5:E5 3:D5'), // Am9
    ('F3 A3 C4 E4', 'D2', '0:C5 0.5:D5 1:E5 2:A5 3:G5'), // Dm9
    ('F3 B3 E4', 'G2', '0:D5 0.5:E5 1:G5 2:E5 2.5:D5 3:B4'), // G13
    ('E3 G3 B3 D4', 'C2', '0:C5 1:E5 1.5:G5 2:B5 3:A5'), // Cmaj9
    ('A3 C4 E4 G4', 'F2', '0:A5 0.5:G5 1:E5 2:C5 2.5:D5 3:E5'), // Fmaj9
    ('G#3 B3 D4', 'E2', '0:G#4 1:B4 2:D5 3:E5'), // E7
  ];
  for (final (bar, (chord, bass, tune)) in bars.indexed) {
    final downbeat = bar * 4;
    _keys(keys, song, beat: downbeat, beats: 1.6, names: chord, gain: 0.13);
    _keys(
      keys,
      song,
      beat: downbeat + _swing(1.5, swing),
      beats: 0.8,
      names: chord,
      gain: 0.09,
      roll: 0.012,
    );
    _keys(
      keys,
      song,
      beat: downbeat + 2.5,
      beats: 1.2,
      names: chord,
      gain: 0.11,
      roll: 0.015,
    );
    for (final (beat, beats) in [
      (0.0, 1.3),
      (1.5, 0.4),
      (2.0, 1.3),
      (3.0, 0.8),
    ]) {
      _bass(
        keys,
        song,
        beat: downbeat + _swing(beat, swing),
        beats: beats,
        midi: note(bass),
        cutoff: 800,
      );
    }
    for (final (beat, midi, _) in _tune(tune)) {
      mallet(
        keys,
        start: song.at(downbeat + _swing(beat, swing)),
        freq: hz(midi),
        gain: 0.26,
        ring: 1.2,
        bright: 0.85,
      );
    }
    for (final beat in [0.0, 1.5, 2.0]) {
      kick(
        drums,
        song.noise,
        start: song.at(downbeat + _swing(beat, swing)),
        gain: beat == 0 ? 0.7 : 0.55,
        punch: 0.25,
      );
    }
    for (final beat in [1, 3]) {
      snare(drums, song.noise, start: song.at(downbeat + beat), gain: 0.5);
    }
    for (var sixteenth = 0; sixteenth < 16; sixteenth++) {
      hat(
        drums,
        song.noise,
        start: song.at(downbeat + sixteenth / 4 + (sixteenth.isOdd ? 0.03 : 0)),
        gain: sixteenth.isEven ? 0.09 : 0.05,
      );
    }
    for (final beat in [0.5, 1.5, 2.5, 3.5]) {
      shaker(
        drums,
        song.noise,
        start: song.at(downbeat + _swing(beat, swing)),
        gain: 0.05,
      );
    }
  }
  _keys(keys, song, beat: 24, beats: 1.5, names: 'G3 B3 C4 E4', gain: 0.12);
  mallet(keys, start: song.at(24), freq: hz(note('A5')), gain: 0.2, ring: 1.5);
  kick(drums, song.noise, start: song.at(24), gain: 0.7, punch: 0.25);

  addInto(keys, _saturated(_lowPassed(drums, 9000), 1.5));
  return _tape(song, keys, cutoff: 9000, dust: 0.015, loudness: _loudness[3]!);
}

/// [music] as if played from a worn tape: wobbling, dulled above [cutoff]
/// Hz, with vinyl crackle at [dust] and a little room; mastered to
/// [loudness].
Float64List _tape(
  _Song song,
  Float64List music, {
  required double cutoff,
  required double dust,
  required double loudness,
}) {
  final worn = _lowPassed(wow(music), cutoff);
  final mix = Float64List.fromList(worn);
  addInto(mix, reverb(worn, room: 0.55, damp: 0.6), 0.25);
  crackle(mix, song.noise, gain: dust);
  return master(mix, fadeIn: 0.15, fadeOut: 1.2, loudness: loudness);
}
