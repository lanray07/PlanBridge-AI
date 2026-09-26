@preconcurrency import AVFoundation
@preconcurrency import Speech
import SwiftUI

@MainActor @Observable final class VoiceService {
    var transcript = ""
    var isListening = false
    var isStarting = false
    var message: String?

    private var engine: AVAudioEngine?
    private var recognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var hasTap = false
    private var startGeneration: UInt = 0
    private let speaker = AVSpeechSynthesizer()

    func start() async {
        guard !isStarting, !isListening else { return }
        stop()
        let generation = startGeneration
        isStarting = true
        transcript = ""
        message = nil

        // Voice input is optional and typing is always available. Some iPad audio
        // routes can terminate AVAudioEngine during microphone startup instead of
        // returning a recoverable error. Keep the Ask screen usable on iPad while
        // avoiding that process-level failure.
        guard UIDevice.current.userInterfaceIdiom != .pad else {
            message = "Voice input is currently unavailable on iPad. Type your question instead."
            return
        }
        defer {
            if generation == startGeneration {
                isStarting = false
            }
        }

        let recognizer = SFSpeechRecognizer(locale: Locale.current)
        guard let recognizer, recognizer.supportsOnDeviceRecognition, recognizer.isAvailable else {
            message = "On-device voice recognition is unavailable for this language or device. Type your question instead."
            return
        }

        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        guard generation == startGeneration else { return }

        let microphone = await AVAudioApplication.requestRecordPermission()
        guard generation == startGeneration else { return }
        guard speech && microphone else {
            message = "Voice needs microphone and speech permission. You can still type your question."
            return
        }

        do {
            let audio = AVAudioSession.sharedInstance()
            try audio.setCategory(.record, mode: .measurement)
            try audio.setActive(true)
            guard !audio.currentRoute.inputs.isEmpty else {
                try? audio.setActive(false, options: .notifyOthersOnDeactivation)
                message = "No microphone input is available. Type your question instead."
                return
            }

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.requiresOnDeviceRecognition = true
            request.shouldReportPartialResults = true

            // Create a fresh engine after the recording route is active. Passing a
            // previously captured hardware format to installTap can terminate the
            // process when iPadOS changes the input route or sample rate.
            let engine = AVAudioEngine()
            let node = engine.inputNode
            let inputFormat = node.inputFormat(forBus: 0)
            guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
                try? audio.setActive(false, options: .notifyOthersOnDeactivation)
                message = "No microphone input is available. Type your question instead."
                return
            }

            self.recognizer = recognizer
            self.request = request
            self.engine = engine
            node.installTap(onBus: 0, bufferSize: 1024, format: nil) { buffer, _ in
                request.append(buffer)
            }
            hasTap = true

            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                let text = result?.bestTranscription.formattedString
                let finished = result?.isFinal == true
                let failed = error != nil
                Task { @MainActor in
                    guard let self else { return }
                    if let text { self.transcript = text }
                    if finished || failed { self.stop() }
                }
            }

            engine.prepare()
            try engine.start()
            guard generation == startGeneration else {
                stop()
                return
            }
            isListening = true
        } catch {
            stop()
            message = "The microphone could not start. \(error.localizedDescription)"
        }
    }

    func stop() {
        startGeneration &+= 1
        isStarting = false
        engine?.stop()
        if hasTap {
            engine?.inputNode.removeTap(onBus: 0)
            hasTap = false
        }
        request?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        request = nil
        recognizer = nil
        engine = nil
        isListening = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func speak(_ text: String) {
        stop()
        speaker.stopSpeaking(at: .immediate)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            speaker.speak(AVSpeechUtterance(string: text))
        } catch {
            message = "Spoken playback is unavailable."
        }
    }

    func clear() {
        stop()
        speaker.stopSpeaking(at: .immediate)
        transcript = ""
    }
}
