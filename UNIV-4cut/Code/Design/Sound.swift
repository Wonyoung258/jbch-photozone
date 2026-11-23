import AVFoundation
import AudioToolbox

/// Short sound effects used around the booth.
///
/// - `pop`, `tick`, `tickFinal` and `complete` are synthesized in code when the app starts, so
///   there are no audio files to add, and they sound the same on every iPad and in the Simulator.
/// - `shutter` is iOS's built-in camera shutter sound.
///
/// Sounds play through the "playback" audio category, so they are heard even when the silent
/// switch is on (they follow the volume buttons).
/// To use your own recording instead, add e.g. `pop.wav` to the project and load it in `makePlayer`.
enum SoundEffect: CaseIterable {
    /// Button taps.
    case pop
    /// Each second of the camera countdown.
    case tick
    /// The last three seconds before a photo (higher pitch).
    case tickFinal
    /// A photo is taken.
    case shutter
    /// Photos sent to the printer: a short sparkle chime.
    case complete

    func play() { SoundPlayer.shared.play(self) }
}

final class SoundPlayer {
    static let shared = SoundPlayer()

    private var players: [SoundEffect: AVAudioPlayer] = [:]

    private init() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, options: [.mixWithOthers])
        try? audioSession.setActive(true)

        for effect in SoundEffect.allCases {
            if let player = Self.makePlayer(for: effect) {
                player.prepareToPlay()
                players[effect] = player
            }
        }
    }

    /// Loads every sound ahead of time so the first tap isn't delayed. Call once at launch.
    func preload() {}

    func play(_ effect: SoundEffect) {
        if let player = players[effect] {
            player.currentTime = 0
            player.play()
        } else if effect == .shutter {
            AudioServicesPlaySystemSound(1108) // fallback, e.g. in the Simulator
        }
    }

    private static func makePlayer(for effect: SoundEffect) -> AVAudioPlayer? {
        switch effect {
        case .shutter:
            return try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: "/System/Library/Audio/UISounds/photoShutter.caf"))
        case .pop:
            return try? AVAudioPlayer(data: Synth.wav(Synth.pop()))
        case .tick:
            return try? AVAudioPlayer(data: Synth.wav(Synth.tick(frequency: 880)))
        case .tickFinal:
            return try? AVAudioPlayer(data: Synth.wav(Synth.tick(frequency: 1318.5)))
        case .complete:
            return try? AVAudioPlayer(data: Synth.wav(Synth.sparkle()))
        }
    }
}

// MARK: - Synthesized sounds

/// Builds the small sound effects from sine waves and packs them as WAV data.
private enum Synth {
    static let sampleRate: Double = 44_100

    /// Bubble-like pop: a quick upward pitch sweep that dies away in ~80 ms.
    static func pop() -> [Float] {
        let duration = 0.09
        var phase = 0.0
        return samples(duration) { t in
            let frequency = 380 * pow(3.2, t / duration) // 380 Hz → ~1.2 kHz
            phase += 2 * .pi * frequency / sampleRate
            let envelope = min(1, t / 0.003) * exp(-t / 0.022)
            return 0.8 * envelope * sin(phase)
        }
    }

    /// Soft countdown beep.
    static func tick(frequency: Double) -> [Float] {
        samples(0.16) { t in
            let envelope = min(1, t / 0.004) * exp(-t / 0.045)
            let tone = sin(2 * .pi * frequency * t) + 0.25 * sin(2 * .pi * frequency * 2 * t)
            return 0.55 * envelope * tone
        }
    }

    /// Rising bell arpeggio (G6 C7 E7 G7 C8) over a soft C-major chord, like a sparkle.
    static func sparkle() -> [Float] {
        let notes: [(start: Double, frequency: Double)] = [
            (0.00, 1568.0), (0.07, 2093.0), (0.14, 2637.0), (0.21, 3136.0), (0.30, 4186.0),
            (0.42, 3136.0), (0.50, 4186.0),
        ]
        let chord = [523.25, 659.25, 783.99] // C5 E5 G5
        let raw = samples(1.4) { t in
            var value = 0.0
            for note in notes where t >= note.start {
                let local = t - note.start
                let envelope = min(1, local / 0.002) * exp(-local / 0.22)
                // A bell has an inharmonic overtone; 2.76× gives the "ting".
                value += envelope * (sin(2 * .pi * note.frequency * local)
                                     + 0.3 * sin(2 * .pi * note.frequency * 2.76 * local))
            }
            let pad = min(1, t / 0.03) * exp(-t / 0.45)
            for frequency in chord {
                value += 0.35 * pad * sin(2 * .pi * frequency * t)
            }
            return value
        }
        return normalized(raw, peak: 0.75)
    }

    private static func samples(_ duration: Double, _ value: (Double) -> Double) -> [Float] {
        let count = Int(duration * sampleRate)
        return (0..<count).map { Float(value(Double($0) / sampleRate)) }
    }

    private static func normalized(_ samples: [Float], peak: Float) -> [Float] {
        let maxValue = samples.map(abs).max() ?? 1
        guard maxValue > 0 else { return samples }
        return samples.map { $0 / maxValue * peak }
    }

    /// 16-bit mono PCM WAV.
    static func wav(_ samples: [Float]) -> Data {
        var data = Data()
        func append<T: FixedWidthInteger>(_ value: T) {
            withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
        }
        let byteCount = UInt32(samples.count * 2)
        data.append(contentsOf: Array("RIFF".utf8)); append(UInt32(36) + byteCount)
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8)); append(UInt32(16))
        append(UInt16(1)); append(UInt16(1))                  // PCM, mono
        append(UInt32(sampleRate)); append(UInt32(sampleRate) * 2) // sample rate, byte rate
        append(UInt16(2)); append(UInt16(16))                 // block align, bits per sample
        data.append(contentsOf: Array("data".utf8)); append(byteCount)
        for sample in samples {
            append(Int16(max(-1, min(1, sample)) * Float(Int16.max)))
        }
        return data
    }
}
