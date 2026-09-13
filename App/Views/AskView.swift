import SwiftUI
import PlanBridgeCore

struct AskView: View {
    @Environment(PlanStore.self) private var store
    @Environment(SubscriptionService.self) private var subscription
    @Environment(\.scenePhase) private var scenePhase
    @State private var voice = VoiceService()
    @State private var question = ""
    @State private var answer: String?
    @State private var speakAnswers = false
    @State private var paywall = false
    private let suggestions = ["Do I have any conflicts today?","What's my next booking?","What changed?","Check my trip."]
    var body: some View {
        ScrollView {
            VStack(spacing:26) {
                Eyebrow(text:"Ask PlanBridge")
                Text("Less searching.\nMore knowing.").font(.system(.largeTitle,design:.serif)).multilineTextAlignment(.center)
                Text("A clear answer, from the plans you have.").font(.subheadline).foregroundStyle(.secondary)
                if store.isDemo { StatusPill(text:"DEMO DATA") }
                Button {
                    if voice.isListening { voice.stop(); question = voice.transcript }
                    else if subscription.isPro || store.isDemo { Task { await voice.start() } }
                    else { paywall = true }
                } label: {
                    Image(systemName:voice.isListening ? "stop.fill" : "mic.fill").font(.system(size:36)).foregroundStyle(.white)
                        .frame(width:112,height:112).background(BridgeTheme.green,in:Circle())
                        .padding(14).background(BridgeTheme.sage.opacity(0.5),in:Circle())
                }.accessibilityLabel(voice.isListening ? "Stop listening" : "Ask using on-device voice")
                Text(voice.isListening ? "Listening… tap to stop" : "Tap to ask, or type below").font(.caption).foregroundStyle(.secondary)
                if let message = voice.message { Text(message).font(.caption).foregroundStyle(.secondary) }
                VStack(spacing:12) {
                    TextField("Ask about your plans…",text:$question,axis:.vertical).lineLimit(1...4).padding(18).background(BridgeTheme.card,in:RoundedRectangle(cornerRadius:18))
                    Button("Check my plans") { ask(question) }.buttonStyle(PrimaryButton()).disabled(question.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
                }
                if let answer {
                    VStack(alignment:.leading,spacing:14) {
                        Label("PlanBridge",systemImage:"sparkle").font(.caption.weight(.semibold)).foregroundStyle(BridgeTheme.green)
                        Text(answer).lineSpacing(5).textSelection(.enabled)
                        Button { voice.speak(answer) } label: { Label("Read aloud",systemImage:"speaker.wave.2") }.font(.caption)
                    }.frame(maxWidth:.infinity,alignment:.leading).bridgeCard()
                }
                VStack(spacing:10) {
                    ForEach(suggestions,id:\.self) { suggestion in Button { question = suggestion; ask(suggestion) } label: { HStack { Text(suggestion); Spacer(); Image(systemName:"arrow.up.left") }.font(.subheadline).padding(16).background(BridgeTheme.card,in:RoundedRectangle(cornerRadius:16)) } }
                }
                Toggle("Read answers aloud",isOn:$speakAnswers).font(.subheadline)
                Text("Voice is push-to-talk and on-device only. No raw audio or transcript is saved. Answers use local rules and supplied evidence; no cloud AI is connected.").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }.padding(24).frame(maxWidth:680).frame(maxWidth:.infinity)
        }.background(BridgeTheme.canvas).navigationBarTitleDisplayMode(.inline)
            .onChange(of:voice.transcript) { _, value in question = value }
            .onChange(of:scenePhase) { _, phase in if phase != .active { voice.clear(); question = ""; answer = nil } }
            .onDisappear { voice.clear(); question = ""; answer = nil }
            .sheet(isPresented:$paywall) { NavigationStack { PaywallView() } }
    }
    private func ask(_ text: String) {
        voice.stop()
        let response = store.ai.answerPlanQuestion(text,plans:store.plans,conflicts:store.conflicts,changes:store.archive.changes,trips:store.archive.trips)
        answer = store.isDemo ? "Demo plans: " + response : response
        if speakAnswers { voice.speak(answer!) }
    }
}
