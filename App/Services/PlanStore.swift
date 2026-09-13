import SwiftUI
import PlanBridgeCore

@MainActor @Observable final class PlanStore {
    private let repository: ArchiveRepository?
    private var personal = PlanArchive()
    private var demo = DemoData.archive()
    var isDemo = false
    var error: String?
    var storageReady = false
    var coverage: CalendarCoverage?
    var routes: [RouteEstimate] = []
    let calendarService = CalendarService()
    let ai = PlanBridgeAIService()
    init() {
        do {
            let repository = try ArchiveRepository()
            personal = try repository.load(); self.repository = repository; storageReady = true
        } catch { self.repository = nil; self.error = "Your saved plans could not be opened. No data was replaced. \(error.localizedDescription)" }
    }
    var archive: PlanArchive { isDemo ? demo : personal }
    var plans: [PlanItem] { archive.plans.sorted { $0.start < $1.start } }
    var conflicts: [PlanConflict] {
        PlanConflictEngine().evaluate(plans,buffers:archive.buffers,routes:isDemo ? [] : routes,changes:archive.changes,coverage:isDemo ? nil : coverage)
            .filter { archive.dispositions[$0.id] == nil }
    }
    var todayPlans: [PlanItem] {
        let interval = Calendar.current.dateInterval(of:.day,for:Date())!
        return plans.filter { $0.status != .cancelled && $0.start < interval.end && $0.end >= interval.start }
    }
    @discardableResult func update(_ edit: (inout PlanArchive) -> Void) -> Bool {
        var copy = archive; edit(&copy)
        if isDemo { demo = copy; return true }
        guard let repository, storageReady else { error = "Storage is unavailable. Restart after unlocking your device."; return false }
        do { try repository.save(copy); personal = copy; return true }
        catch { self.error = "Your change could not be saved. \(error.localizedDescription)"; return false }
    }
    @discardableResult func save(_ plan: PlanItem) -> Bool {
        guard plan.isValid, !plan.title.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { error = "Check the title, dates and time zones."; return false }
        routes.removeAll { $0.fromID == plan.id || $0.toID == plan.id }
        return update { archive in
            if let index = archive.plans.firstIndex(where: { $0.id == plan.id }) {
                let old = archive.plans[index]
                if old.start != plan.start || old.end != plan.end { archive.changes.append(PlanChange(previous:old,current:plan)) }
                var updated = plan; updated.lastUpdated = Date(); archive.plans[index] = updated
            } else { archive.plans.append(plan) }
        }
    }
    func remove(_ plan: PlanItem) {
        routes.removeAll { $0.fromID == plan.id || $0.toID == plan.id }
        update { archive in
            archive.plans.removeAll { $0.id == plan.id }
            archive.changes.removeAll { $0.planID == plan.id }
            archive.imports = archive.imports.compactMap { record in
                var record = record; record.planIDs.removeAll { $0 == plan.id }; return record.planIDs.isEmpty ? nil : record
            }
            for i in archive.plans.indices where archive.plans[i].linkedBookingID == plan.id { archive.plans[i].linkedBookingID = nil }
            archive.dispositions = [:]
        }
    }
    func removeTrip(_ trip: Trip) {
        update { archive in
            let ids = Set(archive.plans.filter { $0.tripID == trip.id }.map(\.id))
            archive.trips.removeAll { $0.id == trip.id }
            archive.plans.removeAll { ids.contains($0.id) && $0.source != .calendar }
            for i in archive.plans.indices {
                if archive.plans[i].tripID == trip.id { archive.plans[i].tripID = nil }
                if let linked = archive.plans[i].linkedBookingID, ids.contains(linked) { archive.plans[i].linkedBookingID = nil }
            }
            archive.changes.removeAll { ids.contains($0.planID) }; archive.dispositions = [:]
            archive.imports = archive.imports.compactMap { record in
                var record = record; record.planIDs.removeAll { ids.contains($0) }; return record.planIDs.isEmpty ? nil : record
            }
        }
    }
    func resolve(_ conflict: PlanConflict, as disposition: ConflictDisposition) { update { $0.dispositions[conflict.id] = disposition } }
    func refreshCalendars() {
        guard !isDemo else { return }
        calendarService.discover()
        guard calendarService.hasAccess else { disconnectCalendars(); return }
        let start = Calendar.current.startOfDay(for:Date())
        let interval = DateInterval(start:start,end:Calendar.current.date(byAdding:.day,value:90,to:start)!)
        do {
            var fetched = try calendarService.fetch(in:interval)
            let previous = personal.plans.filter { $0.source == .calendar }
            for i in fetched.indices {
                if let old = previous.first(where: { $0.sourceIdentifier == fetched[i].sourceIdentifier }) {
                    fetched[i].id = old.id; fetched[i].linkedBookingID = old.linkedBookingID; fetched[i].tripID = old.tripID
                    fetched[i].createdAt = old.createdAt
                }
            }
            let saved = update { archive in
                let retainedIDs = Set(fetched.map(\.id))
                let removedIDs = Set(previous.map(\.id)).subtracting(retainedIDs)
                archive.changes.removeAll { removedIDs.contains($0.planID) }
                for new in fetched {
                    if let old = previous.first(where: { $0.id == new.id }), old.start != new.start || old.end != new.end {
                        archive.changes.append(PlanChange(previous:old,current:new))
                    }
                }
                archive.plans.removeAll { $0.source == .calendar }; archive.plans.append(contentsOf:fetched)
            }
            coverage = saved && !calendarService.selected.isEmpty ? CalendarCoverage(interval:interval,fetchedSuccessfully:true) : nil
            if saved { routes = [] }
        } catch { coverage = nil; self.error = error.localizedDescription }
    }
    func disconnectCalendars() {
        calendarService.disconnect(); coverage = nil
        guard archive.plans.contains(where: { $0.source == .calendar }) else { return }
        update { archive in
            let ids = Set(archive.plans.filter { $0.source == .calendar }.map(\.id))
            archive.plans.removeAll { ids.contains($0.id) }; archive.changes.removeAll { ids.contains($0.planID) }
            archive.dispositions = [:]
        }
    }
    func exportURL() throws -> URL {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted,.sortedKeys]; encoder.dateEncodingStrategy = .iso8601
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("PlanBridge-export.json")
        try encoder.encode(archive).write(to:url,options:[.atomic,.completeFileProtection])
        return url
    }
}
