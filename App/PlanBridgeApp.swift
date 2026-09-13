import SwiftUI

@main struct PlanBridgeApp: App {
    @State private var store = PlanStore()
    @State private var privacy = PrivacyService()
    @State private var subscription = SubscriptionService()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environment(store).environment(privacy).environment(subscription)
                    .opacity(privacy.isLocked || scenePhase != .active ? 0 : 1)
                    .allowsHitTesting(!privacy.isLocked && scenePhase == .active)
                if privacy.isLocked || scenePhase != .active {
                    VStack(spacing:24) {
                        Image(systemName:"lock.shield").font(.system(size:52)).foregroundStyle(BridgeTheme.green)
                        Text("Your plans stay personal.").font(.title2.weight(.semibold))
                        if privacy.isLocked {
                            Button("Unlock PlanBridge") { Task { await privacy.unlock() } }.buttonStyle(PrimaryButton())
                            if let message = privacy.message { Text(message).font(.footnote).foregroundStyle(.secondary) }
                        }
                    }.padding(32).frame(maxWidth:.infinity,maxHeight:.infinity).background(BridgeTheme.canvas)
                }
            }
            .background(PrivacyCurtain(privacy:privacy,inactive:scenePhase != .active).frame(width:0,height:0))
            .tint(BridgeTheme.green)
            .task { await subscription.start() }
            .onChange(of:scenePhase) { _, phase in
                if phase == .background && privacy.enabled { privacy.isLocked = true }
                if phase == .active && !privacy.isLocked { store.refreshCalendars() }
            }
            .onChange(of:privacy.isLocked) { _, locked in if !locked { store.refreshCalendars() } }
        }
    }
}
