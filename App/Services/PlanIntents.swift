import AppIntents

struct CheckPlansIntent: AppIntent {
    static var title: LocalizedStringResource = "Check my plans"
    static var description = IntentDescription("Open PlanBridge to review your available plans.")
    static var openAppWhenRun = true
    func perform() async throws -> some IntentResult { .result() }
}
struct PlanShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent:CheckPlansIntent(),phrases:["Check my plans with \(.applicationName)","Open \(.applicationName)"],shortTitle:"Check my plans",systemImageName:"checkmark.circle")
    }
}
