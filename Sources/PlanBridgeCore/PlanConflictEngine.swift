import Foundation

public struct PlanConflictEngine: Sendable {
    public init() {}
    public func evaluate(_ input: [PlanItem], buffers: TravelBuffer = TravelBuffer(),
                         routes: [RouteEstimate] = [], changes: [PlanChange] = [],
                         coverage: CalendarCoverage? = nil, now: Date = Date()) -> [PlanConflict] {
        let plans = input.filter { $0.status != .cancelled && $0.isValid }.sorted { $0.start < $1.start }
        var results: [PlanConflict] = []
        func add(_ kind: ConflictKind, _ items: [PlanItem], _ title: String, _ message: String,
                 _ evidence: [ConflictEvidence], severity: Severity = .check,
                 confidence: Confidence = .high, reason: String? = nil) {
            // Include evidence so dismissing a warning never suppresses a later changed warning.
            let fingerprint = items.map { "\($0.id):\($0.start.timeIntervalSince1970):\($0.end.timeIntervalSince1970)" }.sorted().joined(separator: "|")
            results.append(PlanConflict(id: "\(kind.rawValue)|\(fingerprint)|\(message)", kind: kind,
                planIDs: items.map(\.id), severity: severity, confidence: confidence,
                title: title, explanation: message,
                confidenceReason: reason ?? (confidence == .high ? "The supplied timestamps directly support this comparison." : "Some details or estimates need confirmation."),
                severityReason: severity == .important ? "The supplied times or dates disagree in a way that may affect this plan." : "This is a review prompt, not a confirmed disruption.",
                evidence: evidence, checkActions: items.map { "Review \($0.title)" }))
        }
        func evidence(_ p: PlanItem) -> ConflictEvidence {
            ConflictEvidence(p.title, "\(PlanFormatting.stamp(p.start, zone: p.timeZoneID)) – \(PlanFormatting.stamp(p.end, zone: p.arrivalTimeZoneID)) · \(p.source.rawValue)")
        }
        for (index, a) in plans.enumerated() {
            for b in plans.dropFirst(index + 1) {
                // Demo and personal plans cannot create conflicts against each other.
                guard (a.source == .demo) == (b.source == .demo) else { continue }
                let linked = a.linkedBookingID == b.id || b.linkedBookingID == a.id
                if linked {
                    if a.start != b.start || a.end != b.end {
                        let calendar = a.source == .calendar ? a : (b.source == .calendar ? b : nil)
                        let booking = calendar?.id == a.id ? b : a
                        let stale = calendar.map { c in changes.contains {
                            $0.planID == booking.id && $0.previousStart == c.start && $0.previousEnd == c.end &&
                            $0.currentStart == booking.start && $0.currentEnd == booking.end
                        }} ?? false
                        add(stale ? .staleCalendar : .timeMismatch, [a,b], stale ? "Your calendar hasn't caught up" : "These times don't match",
                            "The linked booking and calendar item show different times. Review both sources.", [evidence(a),evidence(b)], severity: .important)
                    }
                    continue
                }
                let referenceA = a.confirmationNumber?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let referenceB = b.confirmationNumber?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if let referenceA, !referenceA.isEmpty, referenceA == referenceB,
                   let provider = a.provider, !provider.isEmpty, provider.lowercased() == b.provider?.lowercased(),
                   a.kind == b.kind, a.start == b.start, a.end == b.end {
                    add(.duplicate, [a,b], "Possible duplicate booking", "These entries share a provider, reference and scheduled times. Confirm whether they represent the same booking.", [evidence(a),evidence(b)], confidence: .possible)
                    continue
                }
                // Hotels and all-day reminders don't occupy every minute of a person's day.
                guard a.kind != .hotel, b.kind != .hotel, !a.isAllDay, !b.isAllDay else { continue }
                if a.end > b.start && b.end > a.start {
                    let overlap = Int(ceil(min(a.end,b.end).timeIntervalSince(max(a.start,b.start)) / 60))
                    let arrival = a.kind.isTransport && !b.kind.isTransport && a.tripID != nil && a.tripID == b.tripID
                    add(arrival ? .arrival : .overlap, [a,b], arrival ? "Arrival after your booking begins" : "Two plans overlap",
                        arrival ? "\(a.title) is scheduled to arrive \(Int(ceil(a.end.timeIntervalSince(b.start)/60))) minutes after \(b.title) begins." : "\(a.title) and \(b.title) overlap by \(overlap) minutes.",
                        [evidence(a),evidence(b)], severity: .important,
                        confidence: a.status == .tentative || b.status == .tentative ? .possible : .high)
                    continue
                }
                let available = b.start.timeIntervalSince(a.end) / 60
                guard available >= 0 && available < 360 else { continue }
                let buffer = buffers.minutes(for: b.kind)
                if let route = routes.first(where: { $0.fromID == a.id && $0.toID == b.id && $0.minutes >= 0 && !$0.provider.isEmpty && now.timeIntervalSince($0.measuredAt) >= 0 && now.timeIntervalSince($0.measuredAt) < 3600 }) {
                    let needed = route.minutes + buffer
                    if available < Double(needed) {
                        add(b.kind.isTransport ? .departure : .travelTime, [a,b], "A little too close for comfort",
                            "Your schedule leaves about \(Int(ceil(Double(needed)-available))) minutes less than the route estimate plus your preferred buffer.",
                            [evidence(a),evidence(b),ConflictEvidence("Estimated travel", "\(route.minutes) min · \(route.provider)"),ConflictEvidence("Preferred buffer", "\(buffer) min"),ConflictEvidence("Available", "\(Int(available)) min")], confidence: .possible,
                            reason: "Travel time is an estimate and may change. No live service status is implied.")
                    }
                } else if available < Double(buffer) {
                    add(a.kind.isTransport && b.kind.isTransport ? .connectionRisk : (b.kind.isTransport ? .departure : .travelTime), [a,b], "Less time than your preferred buffer",
                        "You have \(Int(available)) minutes between these plans; your preferred buffer is \(buffer) minutes. Travel time has not been checked.", [evidence(a),evidence(b)], confidence: .possible,
                        reason: "This compares your buffer only. No route estimate is available.")
                } else if let from = (a.destination ?? a.location)?.city, let to = b.location?.city,
                          !from.isEmpty, !to.isEmpty, from.lowercased() != to.lowercased(), available < 120 {
                    add(.location, [a,b], "Check the locations", "These plans are in \(from) and \(to), with \(Int(available)) minutes between them. No route estimate is available.", [evidence(a),evidence(b)], confidence: .possible)
                }
            }
        }
        // Missing means absent from a successfully fetched, explicitly limited calendar window.
        if let coverage, coverage.fetchedSuccessfully {
            for booking in plans where booking.source != .calendar && booking.source != .demo && !booking.isAllDay {
                if booking.start >= coverage.interval.start && booking.start < coverage.interval.end &&
                    !plans.contains(where: { $0.source == .calendar && $0.linkedBookingID == booking.id }) {
                    add(.missingCalendar, [booking], "No linked calendar item", "No explicitly linked event was found in the selected calendars and checked date range. A matching unlinked event may already exist.", [evidence(booking)], severity: .info, confidence: .possible)
                }
            }
        }
        // Accommodation comparisons are scoped to a trip and destination, in the hotel's time zone.
        let hotels = plans.filter { $0.kind == .hotel && $0.tripID != nil }
        for hotel in hotels {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: hotel.timeZoneID)!
            let incoming = plans.filter { $0.kind.isTransport && $0.tripID == hotel.tripID &&
                $0.destination?.city.lowercased() == hotel.location?.city.lowercased() && $0.destination?.city.isEmpty == false }
            for transport in incoming.prefix(1) {
                let arrivalDay = calendar.startOfDay(for: transport.end)
                let firstNight = calendar.startOfDay(for: hotel.start)
                let checkout = calendar.startOfDay(for: hotel.end)
                if arrivalDay < firstNight || arrivalDay >= checkout {
                    add(.dateMismatch, [transport,hotel], "Check your hotel dates", "Your scheduled arrival date falls outside this hotel's booked nights in the hotel's time zone.", [evidence(transport),evidence(hotel)], severity: .important)
                }
            }
        }
        let grouped = Dictionary(grouping: hotels, by: { $0.tripID! })
        for stays in grouped.values {
            let sorted = stays.sorted { $0.start < $1.start }
            for (a,b) in zip(sorted,sorted.dropFirst()) {
                guard a.timeZoneID == b.timeZoneID else { continue }
                var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(identifier:a.timeZoneID)!
                let gap = calendar.dateComponents([.day], from: calendar.startOfDay(for:a.end), to:calendar.startOfDay(for:b.start)).day ?? 0
                if gap > 0 { add(.missingNight,[a,b],"Check accommodation between stays","There are \(gap) nights between the supplied hotel bookings. Other accommodation may not have been imported.",[evidence(a),evidence(b)],confidence:.possible) }
            }
        }
        return results.sorted { $0.severity.rank == $1.severity.rank ? $0.id < $1.id : $0.severity.rank > $1.severity.rank }
    }
}
