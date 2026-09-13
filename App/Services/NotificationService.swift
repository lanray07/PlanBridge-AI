import UserNotifications
import PlanBridgeCore

@MainActor enum NotificationService {
    static func configure(_ preference: NotificationPreference) async throws {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard preference != .off else { return }
        guard try await center.requestAuthorization(options:[.alert,.sound,.badge]) else {
            throw NSError(domain:"PlanBridge",code:1,userInfo:[NSLocalizedDescriptionKey:"Notifications are disabled in iOS Settings."])
        }
        if preference == .daily {
            let content = UNMutableNotificationContent()
            content.title = "A moment for your plans"
            // A scheduled reminder must not claim that a background check actually ran.
            content.body = "Open PlanBridge for today's plan check."
            try await center.add(UNNotificationRequest(identifier:"daily",content:content,
                trigger:UNCalendarNotificationTrigger(dateMatching:DateComponents(hour:8,minute:0),repeats:true)))
        }
    }
    static func notify(conflicts: [PlanConflict], preference: NotificationPreference) async throws {
        guard preference == .immediate || preference == .importantOnly else { return }
        guard conflicts.contains(where: { preference == .immediate || $0.severity.rank >= Severity.important.rank }) else { return }
        let content = UNMutableNotificationContent(); content.title = "PlanBridge"
        content.body = "Your plans have an item worth checking."
        try await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier:"plan-check",content:content,trigger:nil))
    }
}
