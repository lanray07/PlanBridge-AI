@preconcurrency import AVFoundation
@preconcurrency import Speech
import SwiftUI

@MainActor @Observable final class VoiceService {
    var transcript = ""
    var isListening = false
    var message: String?
    private let engine = AVAudioEngine()
    private var recognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var hasTap = false
    private let speaker = AVSpeechSynthesizer()
    func start() async {
        stop(); transcript = ""; message = nil
        let recognizer = SFSpeechRecognizer(locale:Locale.current)
        guard let recognizer, recognizer.supportsOnDeviceRecognition, recognizer.isAvailable else {
            message = "On-device voice recognition is unavailable for this language or device. Type your question instead."; return
        }
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in continuation.resume(returning:status == .authorized) }
        }
        let microphone = await AVAudioApplication.requestRecordPermission()
        guard speech && microphone else { message = "Voice needs microphone and speech permission. You can still type your question."; return }
        do {
            self.recognizer = recognizer
            let audio = AVAudioSession.sharedInstance()
            try audio.setCategory(.record,mode:.measurement,options:.duckOthers)
            try audio.setActive(true)
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.requiresOnDeviceRecognition = true; request.shouldReportPartialResults = true
            self.request = request
            let node = engine.inputNode; let format = node.outputFormat(forBus:0)
            guard format.sampleRate > 0, format.channelCount > 0 else { stop(); message = "No microphone input is available."; return }
            node.installTap(onBus:0,bufferSize:1024,format:format) { buffer,_ in request.append(buffer) }
            hasTap = true
            recognitionTask = recognizer.recognitionTask(with:request) { [weak self] result,error in
                let text = result?.bestTranscription.formattedString
                let finished = result?.isFinal == true
                let failed = error != nil
                Task { @MainActor in
                    guard let self else { return }
                    if let text { self.transcript = text }
                    if finished || failed { self.stop() }
                }
            }
            engine.prepare(); try engine.start(); isListening = true
        } catch { stop(); message = "The microphone could not start. \(error.localizedDescription)" }
    }
    func stop() {
        engine.stop()
        if hasTap { engine.inputNode.removeTap(onBus:0); hasTap = false }
        request?.endAudio(); recognitionTask?.cancel(); recognitionTask = nil; request = nil
        isListening = false
        try? AVAudioSession.sharedInstance().setActive(false,options:.notifyOthersOnDeactivation)
    }
    func speak(_ text: String) {
        stop(); speaker.stopSpeaking(at:.immediate)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback,mode:.spokenAudio,options:.duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            speaker.speak(AVSpeechUtterance(string:text))
        } catch { message = "Spoken playback is unavailable." }
    }
    func clear() { stop(); speaker.stopSpeaking(at:.immediate); transcript = "" }
}
