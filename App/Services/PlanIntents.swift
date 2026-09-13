import AppIntents

struct CheckPlansIntent: AppIntent {
    static let title: LocalizedStringResource = "Check my plans"
    static let description = IntentDescription("Open PlanBridge to review your available plans.")
    static let openAppWhenRun = true
    func perform() async throws -> some IntentResult { .result() }
}
struct PlanShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent:CheckPlansIntent(),phrases:["Check my plans with \(.applicationName)","Open \(.applicationName)"],shortTitle:"Check my plans",systemImageName:"checkmark.circle")
    }
}
