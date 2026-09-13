import Foundation

/// Evidence-grounded local language layer. No LLM, audio, or itinerary leaves the device.
/// A future cloud implementation must be opt-in and conform to this boundary.
public struct PlanBridgeAIService: Sendable {
    public init() {}
    public func explainConflict(_ conflict: PlanConflict) -> String { conflict.explanation }
    public func explainChange(_ change: PlanChange, plan: PlanItem) -> String {
        "\(plan.title) changed from \(PlanFormatting.stamp(change.previousStart, zone: plan.timeZoneID)) to \(PlanFormatting.stamp(change.currentStart, zone: plan.timeZoneID)). This is a comparison of saved observations, not live provider status."
    }
    public func summariseDay(plans: [PlanItem], conflicts: [PlanConflict]) -> String {
        let ids = Set(plans.map(\.id))
        let relevant = conflicts.filter { !$0.planIDs.allSatisfy { !ids.contains($0) } }
        guard !plans.isEmpty else { return "No plans are available for this day. Only added or selected calendar data can be checked." }
        return "\(plans.count) \(plans.count == 1 ? "plan" : "plans") checked. \(relevant.count) \(relevant.count == 1 ? "item needs" : "items need") attention. " + (relevant.first?.explanation ?? "No conflicts were found in the available information. Travel and missing sources may still need checking.")
    }
    public func summariseTrip(trip: Trip, plans: [PlanItem], conflicts: [PlanConflict]) -> String {
        "\(trip.name): " + summariseDay(plans: plans.filter { $0.tripID == trip.id }, conflicts: conflicts)
    }
    public func summariseMismatch(_ conflict: PlanConflict) -> String {
        conflict.explanation + " " + conflict.evidence.map { "\($0.label): \($0.value)." }.joined(separator: " ")
    }
    public func generateCheckActions(_ conflict: PlanConflict) -> [String] { conflict.checkActions }
    public func answerPlanQuestion(_ question: String, plans: [PlanItem], conflicts: [PlanConflict],
                                   changes: [PlanChange] = [], trips: [Trip] = [],
                                   now: Date = Date(), timeZone: TimeZone = .current) -> String {
        let q = question.lowercased()
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = timeZone
        let day = calendar.startOfDay(for: now)
        let target = q.contains("tomorrow") ? calendar.date(byAdding: .day, value: 1, to: day)! : day
        let end = calendar.date(byAdding: .day, value: 1, to: target)!
        let active = plans.filter { $0.status != .cancelled }
        let dayPlans = active.filter { $0.start < end && $0.end >= target }
        if q.contains("changed") {
            let recent = changes.sorted { $0.detectedAt > $1.detectedAt }
            guard let change = recent.first, let plan = active.first(where: { $0.id == change.planID }) else { return "No saved timing changes are available. This does not indicate live airline or booking status." }
            return explainChange(change, plan: plan)
        }
        if q.contains("leave") { return "I need a reliable route estimate and your preferred arrival buffer to suggest a departure time. Review the plan's location and transport details." }
        if q.contains("trip") || q.contains("hotel") {
            let matches = trips.filter { q.contains($0.name.lowercased()) || q.contains($0.destination.lowercased()) }
            if let trip = matches.first ?? (trips.count == 1 ? trips.first : nil) { return summariseTrip(trip: trip, plans: active, conflicts: conflicts) }
            return "Open a trip to check its supplied bookings together, or include its destination in your question."
        }
        if q.contains("next") || q.contains("when") || q.contains("flight") {
            let candidates = active.filter { $0.start >= now && (!q.contains("flight") || $0.kind == .flight) }.sorted { $0.start < $1.start }
            guard let next = candidates.first else { return "No matching upcoming booking is available." }
            return "\(next.title) is scheduled for \(PlanFormatting.stamp(next.start, zone: next.timeZoneID)). Source: \(next.source.rawValue)."
        }
        if q.contains("why") || q.contains("dinner") || q.contains("check?") {
            let dinnerIDs = Set(active.filter { $0.kind == .restaurant }.map(\.id))
            let match = conflicts.first { !q.contains("dinner") || !$0.planIDs.allSatisfy { !dinnerIDs.contains($0) } }
            if let match { return explainConflict(match) + " " + generateCheckActions(match).joined(separator: ". ") + "." }
        }
        if q.contains("today") || q.contains("tomorrow") || q.contains("conflict") || q.contains("plans") || q.contains("match") {
            return summariseDay(plans: dayPlans, conflicts: conflicts)
        }
        return "I can check today's or tomorrow's plans, explain a conflict, find your next booking, or describe saved changes. Try ‘Do I have any conflicts tomorrow?’"
    }
}
