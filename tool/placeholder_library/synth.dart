/// Sound synthesis for the placeholder clips (task 2.3): oscillators,
/// filters, instruments, drums and effects, in plain Dart.
///
/// Everything is arithmetic, `dart:math` and the noise of [Noise], so the
/// same settings give the same samples on every run.
library;

import 'dart:math' as math;
import 'dart:typed_data';

/// Samples per second of every clip, the most the placeholders may have
/// (docs/DECISIONS.md, task 2.3).
const sampleRate = 22050;

/// The sample at [seconds] from the start.
int sampleAt(double seconds) => (seconds * sampleRate).round();

/// The frequency in Hz of the MIDI note [note]: 69 is A4, at 440 Hz.
double hz(num note) => 440 * math.pow(2, (note - 69) / 12).toDouble();

/// The MIDI note of a name such as `C4` (60), `F#3` or `Bb2`.
int note(String name) {
  final match = _noteName.firstMatch(name);
  if (match == null) throw ArgumentError.value(name, 'name', 'Not a note');
  final accidental = switch (match[2]) {
    '#' => 1,
    'b' => -1,
    _ => 0,
  };
  return (int.parse(match[3]!) + 1) * 12 + _steps[match[1]]! + accidental;
}

/// The MIDI notes of names separated by spaces, such as `'C4 E4 G4'`.
List<int> notes(String names) => [
  for (final name in names.split(' ')) note(name),
];

final _noteName = RegExp(r'^([A-G])([#b]?)(\d)$');
const _steps = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};

/// White noise from a seed (xorshift32). Unlike `Random`, whose numbers may
/// change in a new Dart release, it gives the same numbers forever.
class Noise {
  Noise(int seed) : _state = seed & _mask == 0 ? 1 : seed & _mask;

  int _state;

  /// The next value, from -1 to 1.
  double next() {
    var x = _state;
    x ^= (x << 13) & _mask;
    x ^= x >> 17;
    x ^= (x << 5) & _mask;
    _state = x;
    return x / 0x80000000 - 1;
  }

  /// The next value, from 0 to 1.
  double nextUnit() => (next() + 1) / 2;
}

const _mask = 0xFFFFFFFF;

/// The time constant of a fade that loses 60 dB in [seconds].
double _tau(double seconds) => seconds / math.ln10 / 3;

/// A second-order filter with the formulas of the Audio EQ Cookbook (Robert
/// Bristow-Johnson).
class Biquad {
  factory Biquad.lowPass(double cutoff, {double q = math.sqrt1_2}) {
    final (cos, alpha) = _shape(cutoff, q);
    return Biquad._(
      (1 - cos) / 2,
      1 - cos,
      (1 - cos) / 2,
      1 + alpha,
      -2 * cos,
      1 - alpha,
    );
  }

  factory Biquad.highPass(double cutoff, {double q = math.sqrt1_2}) {
    final (cos, alpha) = _shape(cutoff, q);
    return Biquad._(
      (1 + cos) / 2,
      -(1 + cos),
      (1 + cos) / 2,
      1 + alpha,
      -2 * cos,
      1 - alpha,
    );
  }

  /// A band-pass filter with a peak gain of 1 at [center].
  factory Biquad.bandPass(double center, {double q = 1}) {
    final (cos, alpha) = _shape(center, q);
    return Biquad._(alpha, 0, -alpha, 1 + alpha, -2 * cos, 1 - alpha);
  }

  /// Raises the sound above [cutoff] by [gainDb].
  factory Biquad.highShelf(
    double cutoff,
    double gainDb, {
    double q = math.sqrt1_2,
  }) {
    final (cos, alpha) = _shape(cutoff, q);
    final a = math.pow(10, gainDb / 40).toDouble();
    final root = 2 * math.sqrt(a) * alpha;
    return Biquad._(
      a * ((a + 1) + (a - 1) * cos + root),
      -2 * a * ((a - 1) + (a + 1) * cos),
      a * ((a + 1) + (a - 1) * cos - root),
      (a + 1) - (a - 1) * cos + root,
      2 * ((a - 1) - (a + 1) * cos),
      (a + 1) - (a - 1) * cos - root,
    );
  }

  Biquad._(double b0, double b1, double b2, double a0, double a1, double a2)
    : _b0 = b0 / a0,
      _b1 = b1 / a0,
      _b2 = b2 / a0,
      _a1 = a1 / a0,
      _a2 = a2 / a0;

  final double _b0;
  final double _b1;
  final double _b2;
  final double _a1;
  final double _a2;
  double _x1 = 0;
  double _x2 = 0;
  double _y1 = 0;
  double _y2 = 0;

  /// The next output for the input [x].
  double process(double x) {
    final y = _b0 * x + _b1 * _x1 + _b2 * _x2 - _a1 * _y1 - _a2 * _y2;
    _x2 = _x1;
    _x1 = x;
    _y2 = _y1;
    _y1 = y;
    return y;
  }

  /// Filters [samples] in place.
  void filter(Float64List samples) {
    for (var i = 0; i < samples.length; i++) {
      samples[i] = process(samples[i]);
    }
  }

  static (double, double) _shape(double frequency, double q) {
    final w = 2 * math.pi * frequency / sampleRate;
    return (math.cos(w), math.sin(w) / (2 * q));
  }
}

/// A low-pass filter whose cutoff can change at every sample: the
/// state-variable filter in Andrew Simper's trapezoidal form, which stays
/// stable while its cutoff moves.
class SweepFilter {
  double _s1 = 0;
  double _s2 = 0;

  /// The next output for the input [x], with the cutoff at [cutoff] Hz.
  double lowPass(double x, double cutoff, {double q = math.sqrt1_2}) {
    final g = math.tan(
      math.pi * math.min(cutoff, 0.45 * sampleRate) / sampleRate,
    );
    final k = 1 / q;
    final a1 = 1 / (1 + g * (g + k));
    final a2 = g * a1;
    final a3 = g * a2;
    final v3 = x - _s2;
    final v1 = a1 * _s1 + a2 * v3;
    final v2 = _s2 + a2 * _s1 + a3 * v3;
    _s1 = 2 * v1 - _s1;
    _s2 = 2 * v2 - _s2;
    return v2;
  }
}

/// The shape of an oscillator.
enum Wave { sine, triangle, saw, square }

/// One sample of [wave] at [phase] (0 to 1), for a tone that moves [step] of
/// a cycle per sample. Saw and square are band-limited (polyBLEP), so high
/// notes do not alias.
double _wave(Wave wave, double phase, double step) => switch (wave) {
  Wave.sine => math.sin(2 * math.pi * phase),
  Wave.triangle => 1 - 4 * ((phase + 0.25) % 1 - 0.5).abs(),
  Wave.saw => 2 * phase - 1 - _blep(phase, step),
  Wave.square =>
    (phase < 0.5 ? 1 : -1) +
        _blep(phase, step) -
        _blep((phase + 0.5) % 1, step),
};

double _blep(double phase, double step) {
  if (phase < step) {
    final t = phase / step;
    return t + t - t * t - 1;
  }
  if (phase > 1 - step) {
    final t = (phase - 1) / step;
    return t * t + t + t + 1;
  }
  return 0;
}

/// Adds a plucked string at [start] seconds: Karplus–Strong synthesis with
/// an all-pass filter that tunes it between whole samples.
///
/// [brightness] goes from 0 (soft, like a thumb) to 1 (a pick). The string
/// fades by 60 dB in [ring] seconds, or is damped after [length] seconds.
void pluck(
  Float64List out,
  Noise noise, {
  required double start,
  required double freq,
  required double gain,
  double brightness = 0.5,
  double ring = 3,
  double? length,
}) {
  final first = sampleAt(start);
  final seconds = length == null
      ? ring * 1.6
      : math.min(ring * 1.6, length + 0.3);
  final count = math.min(out.length - first, sampleAt(seconds));
  if (count <= 0) return;

  // Per period, the loop keeps `perPeriod` of the fundamental, so it fades by
  // 60 dB in `ring` seconds. A two-tap low-pass filter takes the part that
  // the loss factor cannot: the loss stays below 1, so the loop is stable.
  final omega = 2 * math.pi * freq / sampleRate;
  final perPeriod = math.pow(10, -3 / (freq * ring)).toDouble();
  const maxLoss = 0.9995;
  var tap = 0.5;
  var loss = maxLoss;
  final needed = perPeriod / maxLoss;
  if (needed < 1) {
    final q = (1 - needed * needed) / (1 - math.cos(omega));
    if (q < 0.5) {
      tap = (1 - math.sqrt(1 - 2 * q)) / 2;
    } else {
      loss = perPeriod / math.cos(omega / 2);
    }
  } else {
    tap = 0;
    loss = perPeriod;
  }

  // The loop delays by its delay line, by the low-pass filter, and by the
  // all-pass filter, which tunes the string between whole samples.
  final tapDelay =
      math.atan2(tap * math.sin(omega), 1 - tap + tap * math.cos(omega)) /
      omega;
  final period = sampleRate / freq;
  final line = (period - tapDelay - 0.1).floor();
  final fraction = period - tapDelay - line;
  final allPass = (1 - fraction) / (1 + fraction);

  // The string starts as one period of noise, low-passed for a soft pluck.
  final buffer = Float64List(line);
  final smoothing = 0.08 + 0.9 * brightness * brightness;
  var level = 0.0;
  var sum = 0.0;
  for (var i = 0; i < line; i++) {
    level += smoothing * (noise.next() - level);
    buffer[i] = level;
    sum += level;
  }
  var peak = 1e-9;
  for (var i = 0; i < line; i++) {
    buffer[i] -= sum / line;
    peak = math.max(peak, buffer[i].abs());
  }
  for (var i = 0; i < line; i++) {
    buffer[i] /= peak;
  }

  final damp = length == null ? count : sampleAt(length);
  final dampFall = math.exp(-1 / (_tau(0.25) * sampleRate));
  var envelope = 1.0;
  var index = 0;
  var previous = 0.0;
  var allPassIn = 0.0;
  var allPassOut = 0.0;
  for (var n = 0; n < count; n++) {
    final x = buffer[index];
    final low = (1 - tap) * x + tap * previous;
    previous = x;
    final tuned = allPass * low + allPassIn - allPass * allPassOut;
    allPassIn = low;
    allPassOut = tuned;
    buffer[index] = loss * tuned;
    index = index + 1 == line ? 0 : index + 1;
    if (n >= damp) envelope *= dampFall;
    out[first + n] += gain * envelope * x;
  }
}

/// Adds a strummed chord: [notes] plucked one after the other, [spread]
/// seconds apart, from the lowest up, or from the highest down for an
/// [upstroke].
void strum(
  Float64List out,
  Noise noise, {
  required double start,
  required List<int> notes,
  required double gain,
  double spread = 0.012,
  bool upstroke = false,
  double brightness = 0.6,
  double ring = 2,
  double? length,
}) {
  final order = upstroke ? notes.reversed.toList() : notes;
  for (final (i, midi) in order.indexed) {
    pluck(
      out,
      noise,
      start: start + i * spread,
      freq: hz(midi),
      gain: gain * (1 - 0.06 * i),
      brightness: brightness,
      ring: ring,
      length: length == null ? null : length - i * spread,
    );
  }
}

/// Adds a struck bar at [start] seconds, like a vibraphone or a music box: a
/// sine with two higher partials that fade sooner, by 60 dB in [ring]
/// seconds for the lowest. [bright] goes from 0 to 1.
void mallet(
  Float64List out, {
  required double start,
  required double freq,
  required double gain,
  double ring = 2,
  double bright = 0.5,
}) {
  final first = sampleAt(start);
  final count = math.min(out.length - first, sampleAt(ring * 1.6));
  final partials = [
    (1.0, 1.0, ring),
    (3.93, 0.35 * bright, ring * 0.25),
    (9.54, 0.12 * bright, ring * 0.08),
  ];
  for (final (ratio, level, seconds) in partials) {
    final partialFreq = freq * ratio;
    if (partialFreq > 0.45 * sampleRate) continue;
    final step = 2 * math.pi * partialFreq / sampleRate;
    final fall = math.exp(-1 / (_tau(seconds) * sampleRate));
    var envelope = gain * level;
    for (var n = 0; n < count; n++) {
      final attack = n < 60 ? n / 60 : 1;
      out[first + n] += envelope * attack * math.sin(step * n);
      envelope *= fall;
    }
  }
}

/// Adds an electric piano note at [start] seconds, held for [length]
/// seconds: two-operator FM, a warm tone whose brightness fades, with a
/// short bell-like tine at the start. [bright] goes from 0 to 1; [tremolo]
/// sways the level 4.8 times a second.
void electricPiano(
  Float64List out, {
  required double start,
  required double freq,
  required double length,
  required double gain,
  double bright = 0.5,
  double tremolo = 0,
}) {
  final first = sampleAt(start);
  const release = 0.15;
  final count = math.min(out.length - first, sampleAt(length + 5 * release));
  if (count <= 0) return;
  final decay = 2.4 * math.pow(220 / freq, 0.4).toDouble();
  final step = 2 * math.pi * freq / sampleRate;
  final tineRatio = math.min(14, (0.4 * sampleRate / freq).floor());
  final held = sampleAt(length);
  for (var n = 0; n < count; n++) {
    final t = n / sampleRate;
    var level = math.exp(-t / decay);
    if (n < 40) level *= n / 40;
    if (n > held) level *= math.exp(-(n - held) / (release * sampleRate));
    final phase = step * n;
    final index = bright * (0.5 + 1.8 * math.exp(-t / 0.35));
    final body = math.sin(phase + index * math.sin(phase));
    final tine =
        0.3 *
        bright *
        math.exp(-t / 0.04) *
        math.sin(phase + 1.5 * math.sin(phase * tineRatio));
    final sway = 1 + tremolo * math.sin(2 * math.pi * 4.8 * t);
    out[first + n] += gain * level * sway * (body + tine);
  }
}

/// Adds a synthesizer note at [start] seconds, held for [length] seconds:
/// [wave] through a low-pass filter whose cutoff starts [sweep] Hz above
/// [cutoff] and falls back in about [sweepTime] seconds, with an ADSR
/// envelope. [detune] (in cents) adds a second oscillator, [sub] a sine an
/// octave lower.
void synth(
  Float64List out, {
  required double start,
  required double freq,
  required double length,
  required double gain,
  Wave wave = Wave.saw,
  double cutoff = 2000,
  double sweep = 0,
  double sweepTime = 0.2,
  double q = math.sqrt1_2,
  double detune = 0,
  double sub = 0,
  double attack = 0.005,
  double decay = 0.3,
  double sustain = 0.7,
  double release = 0.1,
}) {
  final first = sampleAt(start);
  final count = math.min(out.length - first, sampleAt(length + 6 * release));
  if (count <= 0) return;
  final step = freq / sampleRate;
  final step2 = step * math.pow(2, detune / 1200);
  final filter = SweepFilter();
  final attackEnd = sampleAt(attack);
  final held = sampleAt(length);
  var phase = 0.0;
  var phase2 = 0.37;
  var subPhase = 0.0;
  var level = 0.0;
  var releaseFrom = 0.0;
  for (var n = 0; n < count; n++) {
    final t = n / sampleRate;
    if (n < held) {
      level = n < attackEnd
          ? n / attackEnd
          : sustain + (1 - sustain) * math.exp(-(t - attack) / decay);
      releaseFrom = level;
    } else {
      level = releaseFrom * math.exp(-(t - length) / release);
    }
    var x = _wave(wave, phase, step);
    if (detune != 0) x = 0.5 * (x + _wave(wave, phase2, step2));
    if (sub > 0) x += sub * math.sin(2 * math.pi * subPhase);
    final y = filter.lowPass(
      x,
      cutoff + sweep * math.exp(-t / sweepTime),
      q: q,
    );
    out[first + n] += gain * level * y;
    phase += step;
    if (phase >= 1) phase -= 1;
    phase2 += step2;
    if (phase2 >= 1) phase2 -= 1;
    subPhase += step / 2;
    if (subPhase >= 1) subPhase -= 1;
  }
}

/// Adds a kick drum at [start] seconds: a falling tone with a click.
/// [punch] goes from 0 (soft and round) to 1 (hard).
void kick(
  Float64List out,
  Noise noise, {
  required double start,
  required double gain,
  double punch = 0.5,
}) {
  final first = sampleAt(start);
  final count = math.min(out.length - first, sampleAt(0.45));
  final top = 80 + 100 * punch;
  const bottom = 46;
  final fall = 0.14 + 0.1 * (1 - punch);
  var phase = 0.0;
  for (var n = 0; n < count; n++) {
    final t = n / sampleRate;
    final freq = bottom + (top - bottom) * math.exp(-t / 0.035);
    phase += 2 * math.pi * freq / sampleRate;
    final body = math.exp(-t / fall) * math.sin(phase);
    final click = 0.5 * punch * math.exp(-t / 0.0015) * noise.next();
    out[first + n] += gain * (body + click);
  }
}

/// Adds a snare drum at [start] seconds: a short tone and a burst of
/// band-passed noise, the snares.
void snare(
  Float64List out,
  Noise noise, {
  required double start,
  required double gain,
  double tone = 0.5,
}) {
  final first = sampleAt(start);
  final count = math.min(out.length - first, sampleAt(0.3));
  final band = Biquad.bandPass(1900, q: 0.6);
  for (var n = 0; n < count; n++) {
    final t = n / sampleRate;
    final body = tone * math.exp(-t / 0.045) * math.sin(2 * math.pi * 185 * t);
    final snares = 1.6 * math.exp(-t / 0.09) * band.process(noise.next());
    out[first + n] += gain * (body + snares);
  }
}

/// Adds a hand clap at [start] seconds: three quick bursts of noise and a
/// short tail.
void clap(
  Float64List out,
  Noise noise, {
  required double start,
  required double gain,
}) {
  final first = sampleAt(start);
  final count = math.min(out.length - first, sampleAt(0.35));
  final band = Biquad.bandPass(1250, q: 1.1);
  for (var n = 0; n < count; n++) {
    final t = n / sampleRate;
    var envelope = 0.0;
    for (final burst in const [0.0, 0.011, 0.022]) {
      if (t >= burst) {
        envelope = math.max(envelope, math.exp(-(t - burst) / 0.004));
      }
    }
    if (t >= 0.022) {
      envelope = math.max(envelope, 0.7 * math.exp(-(t - 0.022) / 0.08));
    }
    out[first + n] += gain * 3 * envelope * band.process(noise.next());
  }
}

/// Adds a hi-hat at [start] seconds: high-passed noise, short when closed,
/// longer when [open].
void hat(
  Float64List out,
  Noise noise, {
  required double start,
  required double gain,
  bool open = false,
}) {
  final first = sampleAt(start);
  final fall = open ? 0.22 : 0.035;
  final count = math.min(out.length - first, sampleAt(fall * 6));
  final high = Biquad.highPass(6500);
  for (var n = 0; n < count; n++) {
    final t = n / sampleRate;
    out[first + n] += gain * math.exp(-t / fall) * high.process(noise.next());
  }
}

/// Adds a shaker at [start] seconds: band-passed noise that swells and fades
/// quickly.
void shaker(
  Float64List out,
  Noise noise, {
  required double start,
  required double gain,
}) {
  final first = sampleAt(start);
  final count = math.min(out.length - first, sampleAt(0.18));
  final band = Biquad.bandPass(5200, q: 0.8);
  for (var n = 0; n < count; n++) {
    final t = n / sampleRate;
    final swell = t < 0.012 ? t / 0.012 : math.exp(-(t - 0.012) / 0.035);
    out[first + n] += gain * 2 * swell * band.process(noise.next());
  }
}

/// Adds vinyl crackle to [out]: about [rate] clicks a second over a faint
/// hiss.
void crackle(
  Float64List out,
  Noise noise, {
  required double gain,
  double rate = 8,
}) {
  final high = Biquad.highPass(1500);
  final hiss = Biquad.lowPass(5000);
  final chance = rate / sampleRate;
  var click = 0.0;
  for (var n = 0; n < out.length; n++) {
    if (noise.nextUnit() < chance) click += noise.next();
    click *= 0.55;
    out[n] += gain * high.process(click + 0.04 * hiss.process(noise.next()));
  }
}

/// Adds [source] times [gain] to [target].
void addInto(Float64List target, Float64List source, [double gain = 1]) {
  for (var i = 0; i < target.length; i++) {
    target[i] += gain * source[i];
  }
}

/// The reverb of [input] alone, without the dry sound: a small hall in mono
/// (Freeverb by Jezar at Dreampoint). [room] from 0 to 1 sets how long it
/// rings, [damp] from 0 to 1 how dark it gets. Mix it in at about 0.1–0.5.
Float64List reverb(
  Float64List input, {
  double room = 0.6,
  double damp = 0.4,
  double preDelay = 0.02,
}) {
  // Freeverb's delay lengths in samples at 44.1 kHz, halved for 22.05 kHz.
  const combs = [558, 594, 638, 678, 711, 745, 778, 808];
  const allPasses = [278, 220, 170, 112];
  final feedback = 0.7 + 0.28 * room;
  final damping = 0.4 * damp;
  final delay = sampleAt(preDelay);
  final out = Float64List(input.length);
  for (final length in combs) {
    final buffer = Float64List(length);
    var index = 0;
    var store = 0.0;
    for (var n = 0; n < out.length; n++) {
      final x = n >= delay ? input[n - delay] : 0.0;
      final y = buffer[index];
      store = y * (1 - damping) + store * damping;
      buffer[index] = 0.045 * x + store * feedback;
      index = index + 1 == length ? 0 : index + 1;
      out[n] += y;
    }
  }
  for (final length in allPasses) {
    final buffer = Float64List(length);
    var index = 0;
    for (var n = 0; n < out.length; n++) {
      final x = out[n];
      final y = buffer[index];
      out[n] = y - x;
      buffer[index] = x + 0.5 * y;
      index = index + 1 == length ? 0 : index + 1;
    }
  }
  return out;
}

/// Adds echoes of [samples] to them, in place: [delay] seconds apart, each
/// [feedback] times the one before and a little darker.
void echo(
  Float64List samples, {
  required double delay,
  double feedback = 0.35,
  double mix = 0.35,
}) {
  final length = sampleAt(delay);
  final line = Float64List(length);
  final tone = Biquad.lowPass(3500);
  var index = 0;
  for (var n = 0; n < samples.length; n++) {
    final delayed = line[index];
    line[index] = samples[n] + feedback * tone.process(delayed);
    index = index + 1 == length ? 0 : index + 1;
    samples[n] += mix * delayed;
  }
}

/// [samples] as if played from a worn tape: the speed sways [rate] times a
/// second by up to [depth] seconds of delay, with a quicker flutter on top.
Float64List wow(
  Float64List samples, {
  double depth = 0.0015,
  double rate = 0.55,
  double flutter = 0.00015,
}) {
  final out = Float64List(samples.length);
  final base = depth + flutter + 0.001;
  for (var n = 0; n < out.length; n++) {
    final t = n / sampleRate;
    final delay =
        base +
        depth * math.sin(2 * math.pi * rate * t) +
        flutter * math.sin(2 * math.pi * 6.3 * t);
    final position = n - delay * sampleRate;
    final i = position.floor();
    if (i < 0 || i + 1 >= samples.length) continue;
    final fraction = position - i;
    out[n] = samples[i] + fraction * (samples[i + 1] - samples[i]);
  }
  return out;
}

/// A gentle saturation: about [x] for small values, never beyond ±1.
double soften(double x) {
  if (x > 3) return 1;
  if (x < -3) return -1;
  return x * (27 + x * x) / (27 + 9 * x * x);
}

/// The highest sample of a clip after [master]: -1 dBFS.
final double _peakLimit = math.pow(10, -1 / 20).toDouble();

/// [mix] made ready for a clip: rumble and the deep bass that phone speakers
/// cannot play filtered out, faded in over [fadeIn] and out over [fadeOut]
/// seconds, and brought to [loudness] (LUFS, see [loudnessOf]) by a gain and
/// a limiter, so no sample peaks above -1 dBFS.
Float64List master(
  Float64List mix, {
  required double fadeIn,
  required double fadeOut,
  required double loudness,
}) {
  final out = Float64List.fromList(mix);
  Biquad.highPass(50).filter(out);
  final inEnd = sampleAt(fadeIn);
  final outStart = out.length - sampleAt(fadeOut);
  for (var n = 0; n < out.length; n++) {
    if (n < inEnd) out[n] *= _rise(n / inEnd);
    if (n >= outStart) {
      out[n] *= _rise((out.length - n) / (out.length - outStart));
    }
  }
  // The limiter takes some loudness away, so a second round makes it up.
  for (var round = 0; round < 2; round++) {
    final gain = math.pow(10, (loudness - loudnessOf(out)) / 20).toDouble();
    for (var n = 0; n < out.length; n++) {
      out[n] *= gain;
    }
    _limit(out, _peakLimit);
  }
  return out;
}

/// Turns down every peak of [samples] above [ceiling], in place: a limiter
/// that looks 2 ms ahead, so it is down by the time a peak comes, and lets
/// go over about 60 ms.
void _limit(Float64List samples, double ceiling) {
  final ahead = sampleAt(0.002);
  final gains = Float64List(samples.length)..fillRange(0, samples.length, 1);
  for (var n = 0; n < samples.length; n++) {
    final level = samples[n].abs();
    if (level <= ceiling) continue;
    final needed = ceiling / level;
    for (var k = 0; k <= ahead && k <= n; k++) {
      final ramp = needed + (1 - needed) * k / ahead;
      if (ramp < gains[n - k]) gains[n - k] = ramp;
    }
  }
  final letGo = 1 - math.exp(-1 / (0.06 * sampleRate));
  var gain = 1.0;
  for (var n = 0; n < samples.length; n++) {
    gain = math.min(gains[n], gain + (1 - gain) * letGo);
    samples[n] *= gain;
  }
}

/// A smooth rise from 0 to 1 as [x] goes from 0 to 1 (a raised cosine).
double _rise(double x) => 0.5 - 0.5 * math.cos(math.pi * x);

/// The loudness of [samples] in LUFS: their K-weighted level, as in
/// ITU-R BS.1770, without its gates. The filters are the standard's,
/// worked out for [sampleRate].
double loudnessOf(List<double> samples) {
  final shelf = Biquad.highShelf(1681.97, 4, q: 0.7072);
  final high = Biquad.highPass(38.135, q: 0.5003);
  var sum = 0.0;
  for (final x in samples) {
    final y = high.process(shelf.process(x));
    sum += y * y;
  }
  return -0.691 + 10 * math.log(sum / samples.length) / math.ln10;
}

/// The highest sample of [samples], in dBFS.
double peakOf(List<double> samples) {
  var peak = 1e-9;
  for (final x in samples) {
    peak = math.max(peak, x.abs());
  }
  return 20 * math.log(peak) / math.ln10;
}

/// [samples] as 16-bit PCM: each one rounded to the nearest step, and
/// clipped at full scale.
Int16List pcm16(Float64List samples) => Int16List.fromList([
  for (final x in samples) (x * 32767).round().clamp(-32768, 32767),
]);

/// [pcm] as a WAV file: PCM, 16-bit, mono, at [sampleRate].
Uint8List wav(Int16List pcm) {
  final dataSize = pcm.length * 2;
  final bytes = ByteData(44 + dataSize);
  void tag(int offset, String text) {
    for (var i = 0; i < 4; i++) {
      bytes.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  bytes.setUint32(4, 36 + dataSize, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  bytes
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little) // PCM
    ..setUint16(22, 1, Endian.little) // mono
    ..setUint32(24, sampleRate, Endian.little)
    ..setUint32(28, sampleRate * 2, Endian.little) // bytes per second
    ..setUint16(32, 2, Endian.little) // bytes per sample
    ..setUint16(34, 16, Endian.little); // bits per sample
  tag(36, 'data');
  bytes.setUint32(40, dataSize, Endian.little);
  for (var i = 0; i < pcm.length; i++) {
    bytes.setInt16(44 + 2 * i, pcm[i], Endian.little);
  }
  return bytes.buffer.asUint8List();
}
