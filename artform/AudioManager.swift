import AVFoundation
import Combine
import UIKit

@MainActor
final class AudioManager: ObservableObject {

    @Published private(set) var isSpeaking = false
    @Published var isMuted = false

    private let engine      = AVAudioEngine()
    private let playerNode  = AVAudioPlayerNode()
    private let synthesizer = AVSpeechSynthesizer()
    private var synthDelegate: SynthDelegate?
    private let haptic = UIImpactFeedbackGenerator(style: .medium)
    private let softHaptic = UIImpactFeedbackGenerator(style: .light)
    private let notifHaptic = UINotificationFeedbackGenerator()

    static let shared = AudioManager()

    private init() {
        engine.attach(playerNode)
        let mixer = engine.mainMixerNode
        engine.connect(playerNode, to: mixer, format: nil)
        try? engine.start()
        let d = SynthDelegate { [weak self] in self?.isSpeaking = false }
        self.synthDelegate = d
        synthesizer.delegate = d
        haptic.prepare()
        softHaptic.prepare()
        notifHaptic.prepare()
    }

    func playBrushStart()  { guard !isMuted else { return }; playTone(freq: 600, dur: 0.04, amp: 0.08) }
    func playBrushEnd()    { guard !isMuted else { return }; playTone(freq: 500, dur: 0.05, amp: 0.06) }
    func playFill()        { guard !isMuted else { return }; playTone(freq: 440, dur: 0.18, amp: 0.14); hapticFill() }
    func playUndo()        { guard !isMuted else { return }; playTone(freq: 380, dur: 0.10, amp: 0.10) }
    func playRedo()        { guard !isMuted else { return }; playTone(freq: 520, dur: 0.10, amp: 0.10) }
    func playLevelComplete() {
        guard !isMuted else { return }
        playArpeggio([523.25, 659.25, 783.99, 1046.5])
        hapticSuccess()
    }

    func speak(_ text: String) {
        guard !isMuted, !text.isEmpty else { return }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-IN") ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate  = AVSpeechUtteranceDefaultSpeechRate * 0.88
        utterance.volume = 0.85
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .word)
        isSpeaking = false
    }

    func hapticFill()    { haptic.impactOccurred() }
    func hapticSuccess() { notifHaptic.notificationOccurred(.success) }
    func hapticLight()   { softHaptic.impactOccurred() }

    private func playTone(freq: Double, dur: Double, amp: Float) {
        let sr = 44_100.0
        let sampleCount = Int(sr * dur)
        let format = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 1)!
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleCount)) else { return }
        buf.frameLength = AVAudioFrameCount(sampleCount)
        let ptr = buf.floatChannelData![0]
        for i in 0..<sampleCount {
            let t = Double(i) / sr
            let envelope = min(t / 0.005, 1.0) * max(1.0 - (t - (dur - 0.02)) / 0.02, 0.0)
            ptr[i] = Float(sin(2 * .pi * freq * t) * Double(amp) * envelope)
        }
        playerNode.scheduleBuffer(buf, completionHandler: nil)
        if !playerNode.isPlaying { playerNode.play() }
    }

    private func playArpeggio(_ freqs: [Double]) {
        let sr = 44_100.0
        let noteDur = 0.14
        let sampleCount = Int(sr * noteDur * Double(freqs.count))
        let format = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 1)!
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleCount)) else { return }
        buf.frameLength = AVAudioFrameCount(sampleCount)
        let ptr = buf.floatChannelData![0]
        for (ni, freq) in freqs.enumerated() {
            let start = Int(sr * noteDur * Double(ni))
            for i in 0..<Int(sr * noteDur) {
                guard start + i < sampleCount else { break }
                let t = Double(i) / sr
                let env = min(t / 0.005, 1.0) * max(1.0 - (t - (noteDur - 0.03)) / 0.03, 0.0)
                ptr[start + i] += Float(sin(2 * .pi * freq * t) * 0.15 * env)
            }
        }
        playerNode.scheduleBuffer(buf, completionHandler: nil)
        if !playerNode.isPlaying { playerNode.play() }
    }
}

private final class SynthDelegate: NSObject, AVSpeechSynthesizerDelegate {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.onFinish() }
    }
}
