import SwiftUI
import PlanBridgeCore

struct SettingsView: View {
    @Environment(PlanStore.self) private var store
    @Environment(PrivacyService.self) private var privacy
    @Environment(SubscriptionService.self) private var subscription
    @Environment(\.dismiss) private var dismiss
    @AppStorage("notificationPreference") private var notification = NotificationPreference.off.rawValue
    @State private var confirmDelete = false
    @State private var export: ExportFile?
    var body: some View {
        Form {
            Section("Your PlanBridge") {
                NavigationLink("Calendars & imports") { ConnectionsView() }
                NavigationLink("Smart buffers") { BufferSettingsView() }
                NavigationLink(subscription.isPro ? "PlanBridge Pro · active" : "Explore PlanBridge Pro") { PaywallView() }
                Toggle("Explore demo plans",isOn:Binding(get:{ store.isDemo },set:{ store.isDemo = $0; if !$0 { store.refreshCalendars() } }))
            }
            Section("Private by design") {
                Toggle("Require Face ID or device passcode",isOn:Binding(get:{ privacy.enabled },set:{ enabled in
                    if enabled { Task { await privacy.enable() } } else { privacy.enabled = false }
                }))
                if let message = privacy.message { Text(message).font(.caption) }
                Text("Your plans are stored on this device and excluded from app backups. Optional driving checks send the two locations to Apple Maps. No account, analytics, email access or cloud AI is connected.").font(.caption).foregroundStyle(.secondary)
                Button("Export my data") {
                    do { export = ExportFile(url:try store.exportURL()) } catch { store.error = error.localizedDescription }
                }
                Button("Restore dismissed warnings") { store.update { $0.dispositions = [:] } }
                Button(store.isDemo ? "Clear demo plans" : "Delete all PlanBridge data",role:.destructive) { confirmDelete = true }
            }
            Section("Notifications") {
                Picker("Alert preference",selection:$notification) {
                    ForEach(NotificationPreference.allCases,id:\.rawValue) { Text($0.rawValue).tag($0.rawValue) }
                }.onChange(of:notification) { _, value in
                    Task {
                        do { try await NotificationService.configure(NotificationPreference(rawValue:value) ?? .off) }
                        catch { store.error = error.localizedDescription; notification = NotificationPreference.off.rawValue }
                    }
                }
                Text("Alerts hide itinerary details. Calendar checks run when you open the app; daily notifications remind you to run a check. Background delivery and live provider monitoring are not included.").font(.caption).foregroundStyle(.secondary)
                Button("Run a plan check now") {
                    store.refreshCalendars()
                    Task { do { try await NotificationService.notify(conflicts:store.conflicts,preference:NotificationPreference(rawValue:notification) ?? .off) } catch { store.error = error.localizedDescription } }
                }
            }
            Section("About") {
                NavigationLink("Privacy & data handling") { PolicyView(isPrivacy:true) }
                NavigationLink("Terms & limitations") { PolicyView(isPrivacy:false) }
                LabeledContent("Version",value:"1.0 · Development build")
            }
        }.navigationTitle("Your settings").toolbar { ToolbarItem(placement:.confirmationAction) { Button("Done") { dismiss() } } }
            .confirmationDialog(store.isDemo ? "Clear the demo?" : "Delete all local PlanBridge data?",isPresented:$confirmDelete,titleVisibility:.visible) {
                Button("Delete data",role:.destructive) {
                    if store.update({ $0 = PlanArchive() }) {
                        if !store.isDemo { store.calendarService.disconnect(); store.coverage = nil; store.routes = [] }
                        notification = NotificationPreference.off.rawValue
                        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                    }
                }
            } message: { Text("This clears plans, trips, saved changes and warning decisions. It does not cancel provider bookings.") }
            .sheet(item:$export,onDismiss:{ try? FileManager.default.removeItem(at:FileManager.default.temporaryDirectory.appendingPathComponent("PlanBridge-export.json")) }) { file in
                ActivityShare(url:file.url)
            }
    }
}
import UserNotifications
struct ExportFile: Identifiable { let id = UUID(); let url: URL }
struct ActivityShare: UIViewControllerRepresentable {
    var url: URL
    func makeUIViewController(context:Context) -> UIActivityViewController { UIActivityViewController(activityItems:[url],applicationActivities:nil) }
    func updateUIViewController(_ uiViewController:UIActivityViewController,context:Context) {}
}

struct BufferSettingsView: View {
    @Environment(PlanStore.self) private var store
    var body: some View {
        Form {
            Section("Your preferred breathing room") {
                buffer("Meetings",key:\.meeting,range:0...120)
                buffer("Airport departures",key:\.airport,range:0...360)
                buffer("Train departures",key:\.train,range:0...120)
                buffer("Restaurants",key:\.restaurant,range:0...120)
                buffer("Appointments",key:\.appointment,range:0...120)
            }
            Text("Buffers are your preferences. They do not include travel time unless a reliable route estimate is available. Changes recalculate warnings immediately.").font(.caption)
        }.navigationTitle("Smart buffers")
    }
    private func buffer(_ name:String,key:WritableKeyPath<TravelBuffer,Int>,range:ClosedRange<Int>) -> some View {
        Stepper("\(name): \(store.archive.buffers[keyPath:key]) min",value:Binding(get:{ store.archive.buffers[keyPath:key] },set:{ value in store.update { $0.buffers[keyPath:key] = value } }),in:range,step:5)
    }
}
struct ConnectionsView: View {
    @Environment(PlanStore.self) private var store
    @State private var importing = false
    @State private var loading = false
    var body: some View {
        Form {
            Section("Apple Calendar") {
                Text("iOS asks for calendar access. PlanBridge then reads only the calendars you select, for today through the next 90 days. Your calendars are never edited.").font(.subheadline)
                if store.isDemo { Text("Switch off demo mode in Settings to connect your calendars.").font(.caption) }
                else if !store.calendarService.hasAccess {
                    Button("Allow calendar access") {
                        loading = true
                        Task { defer { loading = false }; do { try await store.calendarService.request() } catch { store.error = error.localizedDescription } }
                    }.disabled(loading)
                } else {
                    ForEach(store.calendarService.calendars,id:\.calendarIdentifier) { calendar in
                        Toggle(calendar.title,isOn:Binding(get:{ store.calendarService.selected.contains(calendar.calendarIdentifier) },set:{ selected in
                            if selected { store.calendarService.selected.insert(calendar.calendarIdentifier) }
                            else { store.calendarService.selected.remove(calendar.calendarIdentifier) }
                            store.calendarService.saveSelection(); store.refreshCalendars()
                        }))
                    }
                    Button("Refresh selected calendars") { store.refreshCalendars() }
                    Button("Disconnect & remove calendar data",role:.destructive) { store.disconnectCalendars() }
                    Text("To revoke system permission as well, use iOS Settings → Apps → PlanBridge AI → Calendars.").font(.caption)
                }
            }
            Section("Bookings you provide") {
                Label("Manual bookings",systemImage:"pencil")
                Button("Import an ICS or structured JSON file") { importing = true }
                Text("Every imported booking is shown for review before it is saved.").font(.caption)
            }
            Section("Not connected") {
                Text("Airlines, rail operators, hotels, restaurants and email services are not connected. No live delays, cancellations or provider changes are monitored.").font(.subheadline).foregroundStyle(.secondary)
                Text("PDF, image and Wallet extraction are not yet supported. Enter those bookings manually.").font(.caption)
            }
        }.navigationTitle("Connections").onAppear { store.calendarService.discover() }
            .sheet(isPresented:$importing) { NavigationStack { ImportView() } }
    }
}
struct PolicyView: View {
    var isPrivacy: Bool
    var body: some View {
        ScrollView {
            Text(isPrivacy ? "PlanBridge stores the plans you add and the selected calendar events on your device. The local database uses iOS file protection and is excluded from app backups.\n\nNo account is created. No advertising or analytics SDK is included. No itinerary data is sold or transmitted to a PlanBridge server. Apple processes App Store purchases under its own policies. Optional route checks send the supplied addresses to Apple Maps when you request them.\n\nVoice requires microphone and speech permission. Recognition must support on-device processing; otherwise use typing. Raw audio and transcripts are not persisted. Answers are produced locally from supplied evidence.\n\nExport shares a copy with the destination you choose. Delete all data clears local plans, trips, changes, imports and decisions. Disconnect removes cached calendar events. Revoking system calendar permission is available in iOS Settings.\n\nThis is a development privacy summary. A publisher identity, support contact and publicly hosted policy must be supplied before App Store release." : "PlanBridge highlights potential inconsistencies in the information you supply. It does not guarantee that your itinerary is complete, feasible or current. Confirm important details with your provider.\n\nNo booking is made, cancelled or amended through this app. Travel times and buffers, where supplied, are estimates or preferences.\n\nPro subscriptions renew automatically unless cancelled in App Store subscription settings. Prices and billing periods are shown by StoreKit when configured. Privacy and data deletion do not require Pro.\n\nThis development build requires final publisher terms and public policy URLs before subscriptions are offered for sale.")
                .lineSpacing(6).padding(24).frame(maxWidth:720)
        }.navigationTitle(isPrivacy ? "Privacy" : "Terms")
    }
}
