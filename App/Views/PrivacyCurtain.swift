import SwiftUI
import UIKit

/// A separate scene window also covers presented sheets in app-switcher snapshots.
struct PrivacyCurtain: UIViewRepresentable {
    var privacy: PrivacyService
    var inactive: Bool
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context:Context) -> WindowProbe {
        let probe = WindowProbe()
        let coordinator = context.coordinator
        probe.changed = { [weak coordinator] scene in coordinator?.scene = scene }
        return probe
    }
    func updateUIView(_ view:WindowProbe,context:Context) {
        context.coordinator.privacy = privacy
        context.coordinator.inactive = inactive
        context.coordinator.scene = view.window?.windowScene
        context.coordinator.update()
    }
    static func dismantleUIView(_ uiView:WindowProbe,coordinator:Coordinator) {
        coordinator.curtain?.isHidden = true; coordinator.curtain = nil; uiView.changed = nil
    }
    @MainActor final class WindowProbe: UIView {
        var changed: ((UIWindowScene?) -> Void)?
        override func didMoveToWindow() { super.didMoveToWindow(); changed?(window?.windowScene) }
    }
    @MainActor final class Coordinator {
        weak var scene: UIWindowScene? { didSet { update() } }
        var curtain: UIWindow?
        var privacy: PrivacyService?
        var inactive = false
        func update() {
            guard let scene, let privacy else { return }
            if curtain == nil {
                let window = UIWindow(windowScene:scene)
                window.windowLevel = .alert + 1
                window.backgroundColor = .systemBackground
                curtain = window
            }
            let visible = inactive || privacy.isLocked
            if visible {
                curtain?.rootViewController = UIHostingController(rootView:LockCurtain(privacy:privacy,allowUnlock:!inactive))
            }
            curtain?.isHidden = !visible
        }
    }
}
private struct LockCurtain: View {
    var privacy: PrivacyService
    var allowUnlock: Bool
    var body: some View {
        VStack(spacing:24) {
            Image(systemName:"lock.shield").font(.system(size:52)).foregroundStyle(BridgeTheme.green)
            Text("Your plans stay personal.").font(.title2.weight(.semibold))
            if allowUnlock && privacy.isLocked {
                Button("Unlock PlanBridge") { Task { await privacy.unlock() } }.buttonStyle(PrimaryButton())
                if let message = privacy.message { Text(message).font(.footnote).foregroundStyle(.secondary) }
            }
        }.padding(32).frame(maxWidth:.infinity,maxHeight:.infinity).background(BridgeTheme.canvas)
    }
}
