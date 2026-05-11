import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

// --- WAV Header Constants ---
const int sampleRate = 44100;
const int bitDepth = 16;
const int numChannels = 1;

// --- Helper Functions ---

void writeWavHeader(RandomAccessFile file, int dataSize) {
  var byteRate = sampleRate * numChannels * bitDepth ~/ 8;
  var blockAlign = numChannels * bitDepth ~/ 8;

  file.writeStringSync('RIFF');
  file.writeFromSync(_int32(36 + dataSize));
  file.writeStringSync('WAVE');
  file.writeStringSync('fmt ');
  file.writeFromSync(_int32(16));
  file.writeFromSync(_int16(1)); // PCM
  file.writeFromSync(_int16(numChannels));
  file.writeFromSync(_int32(sampleRate));
  file.writeFromSync(_int32(byteRate));
  file.writeFromSync(_int16(blockAlign));
  file.writeFromSync(_int16(bitDepth));
  file.writeStringSync('data');
  file.writeFromSync(_int32(dataSize));
}

List<int> _int32(int val) {
  var b = ByteData(4)..setInt32(0, val, Endian.little);
  return b.buffer.asUint8List();
}

List<int> _int16(int val) {
  var b = ByteData(2)..setInt16(0, val, Endian.little);
  return b.buffer.asUint8List();
}

// --- Synthesis Functions ---

// Basic Waveforms
double sine(double t) => sin(2 * pi * t);
double square(double t) => (sin(2 * pi * t) >= 0) ? 1.0 : -1.0;
double saw(double t) => 2 * (t - t.floor()) - 1;
double triangle(double t) => 2 * (saw(t).abs()) - 1;
double noise() => Random().nextDouble() * 2 - 1;

// Envelope
double adsr(double t, double attack, double decay, double sustain, double release, double duration) {
  if (t < attack) return t / attack;
  if (t < attack + decay) return 1.0 - (1.0 - sustain) * ((t - attack) / decay);
  if (t < duration - release) return sustain;
  if (t < duration) return sustain * (1.0 - (t - (duration - release)) / release);
  return 0.0;
}

// Byte Generation
List<int> generateSound(double duration, double Function(double t) synth) {
  int numSamples = (duration * sampleRate).toInt();
  var bytes = BytesBuilder();

  for (int i = 0; i < numSamples; i++) {
    double t = i / sampleRate;
    double sample = synth(t);
    // Clip
    if (sample > 1.0) sample = 1.0;
    if (sample < -1.0) sample = -1.0;
    
    int intSample = (sample * 32767).toInt();
    bytes.add(_int16(intSample));
  }
  return bytes.toBytes();
}

void save(String name, List<int> bytes) {
  final f = File('assets/sounds/$name').openSync(mode: FileMode.write);
  writeWavHeader(f, bytes.length);
  f.writeFromSync(bytes);
  f.closeSync();
  print('Generated $name');
}

// --- Sounds ---

void main() {
  final dir = Directory('assets/sounds');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  // 1. CLICK: Soft high-tech blip (Sine with slight pitch drop)
  save('click.wav', generateSound(0.04, (t) {
    // Short, crisp, slightly high pitch
    double freq = 1200 - (t * 8000); 
    return sine(freq * t) * adsr(t, 0.002, 0.01, 0.0, 0.01, 0.04) * 0.4;
  }));

  // 2. MATCH FOUND: Ethereal Arpeggio (Sine waves with delay simulation)
  save('match_found.wav', generateSound(1.5, (t) {
    double vol = adsr(t, 0.1, 0.8, 0.0, 0.1, 1.5);
    // Ethereal chord: Cmaj7 + 9
    // C5(523) E5(659) G5(783) B5(987) D6(1174)
    double mix = 0.0;
    
    if (t > 0.0) mix += sine(523.25 * t);
    if (t > 0.05) mix += sine(659.25 * t);
    if (t > 0.1) mix += sine(783.99 * t);
    if (t > 0.15) mix += sine(987.77 * t);
    if (t > 0.2) mix += sine(1174.66 * t);
    
    return mix * 0.2 * vol; 
  }));

  // 3. CORRECT: "Level Up" / "Coin" (Dual tone rapid slide)
  save('correct.wav', generateSound(0.4, (t) {
    double vol = adsr(t, 0.01, 0.2, 0.0, 0.1, 0.4);
    // Two fast tones: B5 -> E6
    double freq = (t < 0.08) ? 987.77 : 1318.51; 
    // Add a bit of "shimmer" with FM
    double mod = sine(20 * t) * 50; 
    return (sine((freq + mod) * t) * 0.6 + square((freq * 2) * t) * 0.1) * vol * 0.5;
  }));

  // 4. WRONG: "Access Denied" (Low square wave with pitch bend down)
  save('wrong.wav', generateSound(0.3, (t) {
    double vol = adsr(t, 0.01, 0.1, 0.01, 0.05, 0.3);
    // Pitch drops fast
    double freq = 150 - (t * 200);
    // Rough square wave
    return square(freq * t) * vol * 0.5;
  }));

   // 5. WIN: Sci-Fi Victory Swell
  save('win.wav', generateSound(2.0, (t) {
    double vol = adsr(t, 0.2, 1.0, 0.0, 0.5, 2.0);
    // Rising intense chord
    double base = 220; // A3
    double mix = 0.0;
    
    mix += saw(base * t) * 0.5;
    mix += saw(base * 1.5 * t) * 0.4; // Fifth
    mix += saw(base * 2.0 * t) * 0.3; // Octave
    
    // Filter sweep simulation (volume based)
    // Add LFO
    mix *= (1.0 + 0.2 * sine(8 * t));

    return mix * vol * 0.3;
  }));

  // 6. LOSE: Power Down / System Fail
  save('lose.wav', generateSound(1.2, (t) {
    double vol = adsr(t, 0.05, 0.8, 0.0, 0.1, 1.2);
    // Frequency drops to 0
    double freq = 440 * (1.0 - t);
    // Intermittent noise (sputtering)
    double glitch = (Random().nextDouble() > 0.9) ? 0.0 : 1.0;
    
    return (saw(freq * t) * 0.8 * glitch) * vol * 0.5;
  }));

  // 7. START: Countdown Beeps
  save('start.wav', generateSound(1.5, (t) {
     double vol = 1.0;
     // Crisp high beeps
     if (t < 0.1) return sine(880 * t) * 0.4 * adsr(t, 0.01, 0.05, 0.0, 0.01, 0.1);
     if (t > 0.5 && t < 0.6) return sine(880 * t) * 0.4 * adsr(t - 0.5, 0.01, 0.05, 0.0, 0.01, 0.1);
     if (t > 1.0 && t < 1.4) return saw(1760 * t) * 0.3 * adsr(t - 1.0, 0.01, 0.3, 0.0, 0.1, 0.4); // GO!
     return 0.0;
  }));

  // 8. SWITCH: Toggle/Select (New!)
  save('switch.wav', generateSound(0.1, (t) {
    double freq = 800 + (t * 5000); // Slide up
    return sine(freq * t) * adsr(t, 0.01, 0.05, 0.0, 0.01, 0.1) * 0.3;
  }));
}
