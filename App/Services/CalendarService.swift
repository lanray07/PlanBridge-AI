@preconcurrency import EventKit
import Observation
import Foundation
import PlanBridgeCore

@MainActor @Observable final class CalendarService {
    private let store = EKEventStore()
    var calendars: [EKCalendar] = []
    var selected: Set<String> = Set(UserDefaults.standard.stringArray(forKey:"selectedCalendars") ?? [])
    var lastChecked: Date?
    var hasAccess: Bool { EKEventStore.authorizationStatus(for:.event) == .fullAccess }
    func request() async throws {
        guard try await store.requestFullAccessToEvents() else { throw CalendarError.denied }
        calendars = store.calendars(for:.event)
    }
    func discover() {
        if hasAccess { calendars = store.calendars(for:.event) }
        else { calendars = [] }
    }
    func fetch(in interval: DateInterval) throws -> [PlanItem] {
        guard hasAccess else { throw CalendarError.denied }
        let chosen = store.calendars(for:.event).filter { selected.contains($0.calendarIdentifier) }
        guard !chosen.isEmpty else { return [] } // Never pass nil/empty to an all-calendars predicate.
        let predicate = store.predicateForEvents(withStart:interval.start,end:interval.end,calendars:chosen)
        let events = store.events(matching:predicate)
        lastChecked = Date()
        return events.map { event in
            PlanItem(title:event.title ?? "Calendar event",kind:.event,start:event.startDate,end:event.endDate,
                timeZoneID:event.timeZone?.identifier ?? TimeZone.current.identifier,
                location:event.location.map { PlanLocation(name:$0) },source:.calendar,
                sourceIdentifier:"\(event.calendarItemIdentifier)|\(event.occurrenceDate?.timeIntervalSince1970.description ?? "single")",
                calendarIdentifier:event.calendar.calendarIdentifier,
                status:event.status == .canceled ? .cancelled : (event.status == .tentative ? .tentative : .confirmed),isAllDay:event.isAllDay)
        }
    }
    func saveSelection() { UserDefaults.standard.set(Array(selected),forKey:"selectedCalendars") }
    func disconnect() { selected = []; saveSelection(); lastChecked = nil }
    enum CalendarError: LocalizedError {
        case denied
        var errorDescription: String? { "Calendar access is unavailable. You can enable it in iOS Settings or keep using manual bookings." }
    }
}
