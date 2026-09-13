import Foundation

public enum ImportFailure: Error, LocalizedError {
    case unsupported(String)
    public var errorDescription: String? { if case .unsupported(let message) = self { return message }; return nil }
}
public struct ImportDraft: Sendable {
    public var plans: [PlanItem]
    public var warnings: [String]
}
public struct BookingImporter: Sendable {
    public init() {}
    public func parseJSON(_ data: Data) throws -> ImportDraft {
        guard data.count <= 2_000_000 else { throw ImportFailure.unsupported("Use a file smaller than 2 MB.") }
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let plans = try decoder.decode([PlanItem].self, from: data)
        guard plans.count <= 500, plans.allSatisfy(\.isValid) else { throw ImportFailure.unsupported("The itinerary contains invalid dates, time zones, or too many items.") }
        return ImportDraft(plans: plans.map { p in var p = p; p.id = UUID(); p.source = .imported; p.linkedBookingID = nil; p.tripID = nil; return p }, warnings: ["Review all fields before saving. This file does not connect a provider."])
    }
    /// Intentionally strict subset. Recurrence, floating dates, and custom VTIMEZONE are rejected.
    public func parseICS(_ text: String) throws -> ImportDraft {
        guard text.utf8.count <= 2_000_000 else { throw ImportFailure.unsupported("Use a file smaller than 2 MB.") }
        let unfolded = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\n ", with: "").replacingOccurrences(of: "\n\t", with: "")
        if unfolded.contains("RRULE:") || unfolded.contains("RECURRENCE-ID") || unfolded.contains("RDATE:") || unfolded.contains("EXDATE") || unfolded.contains("BEGIN:VTIMEZONE") {
            throw ImportFailure.unsupported("Recurring events and custom time zones need manual review. Import these through Apple Calendar instead.")
        }
        var fields: [String:String] = [:]; var plans: [PlanItem] = []; var inside = false
        for line in unfolded.components(separatedBy: "\n") {
            if line == "BEGIN:VEVENT" { fields = [:]; inside = true; continue }
            if line == "END:VEVENT" {
                guard inside, let startKey = fields.keys.first(where: { $0 == "DTSTART" || $0.hasPrefix("DTSTART;") }),
                      let endKey = fields.keys.first(where: { $0 == "DTEND" || $0.hasPrefix("DTEND;") }) else {
                    throw ImportFailure.unsupported("Every event must supply both start and end. Add incomplete bookings manually.")
                }
                let (start, zone, allDay) = try date(fields[startKey]!, key: startKey)
                let (end, endZone, _) = try date(fields[endKey]!, key: endKey)
                var plan = PlanItem(title: unescape(fields["SUMMARY"] ?? "Imported booking"), kind: .event,
                    start: start, end: end, timeZoneID: zone, arrivalTimeZoneID: endZone,
                    location: fields["LOCATION"].map { PlanLocation(name: unescape($0)) }, source: .imported,
                    sourceIdentifier: fields["UID"], status: fields["STATUS"] == "CANCELLED" ? .cancelled : .confirmed, isAllDay: allDay)
                plan.provider = "ICS file"
                guard plan.isValid else { throw ImportFailure.unsupported("An event ends before it starts.") }
                plans.append(plan); inside = false
            } else if inside, let colon = line.firstIndex(of: ":") {
                fields[String(line[..<colon])] = String(line[line.index(after: colon)...])
            }
        }
        guard !inside, !plans.isEmpty, plans.count <= 500 else { throw ImportFailure.unsupported("No complete supported events found, or more than 500 events supplied.") }
        return ImportDraft(plans: plans, warnings: ["Confirm times, time zones and booking types before saving.", "ICS imports are snapshots. They do not subscribe to future changes."])
    }
    private func unescape(_ text: String) -> String {
        text.replacingOccurrences(of: "\\n", with: "\n").replacingOccurrences(of: "\\,", with: ",").replacingOccurrences(of: "\\;", with: ";").replacingOccurrences(of: "\\\\", with: "\\")
    }
    private func date(_ value: String, key: String) throws -> (Date,String,Bool) {
        let allDay = key.contains("VALUE=DATE") && !key.contains("VALUE=DATE-TIME")
        let zone: String
        if value.hasSuffix("Z") { zone = "GMT" }
        else if let range = key.range(of: "TZID=") { zone = String(key[range.upperBound...]).components(separatedBy: ";")[0] }
        else { throw ImportFailure.unsupported("Floating or all-day dates need a time zone. Use Apple Calendar or add the plan manually.") }
        guard let tz = TimeZone(identifier: zone) else { throw ImportFailure.unsupported("Unknown time zone: \(zone).") }
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian); formatter.timeZone = tz; formatter.isLenient = false
        formatter.dateFormat = allDay ? "yyyyMMdd" : (value.hasSuffix("Z") ? "yyyyMMdd'T'HHmmss'Z'" : "yyyyMMdd'T'HHmmss")
        guard let result = formatter.date(from: value), formatter.string(from: result) == value else { throw ImportFailure.unsupported("Invalid or daylight-saving-adjusted timestamp: \(value).") }
        // A local fall-back hour can represent two instants. Require UTC for that ambiguity.
        if !value.hasSuffix("Z") && !allDay {
            for delta in [-7200.0,-3600.0,-1800.0,1800.0,3600.0,7200.0] {
                if formatter.string(from: result.addingTimeInterval(delta)) == value { throw ImportFailure.unsupported("Ambiguous daylight-saving time. Supply this timestamp in UTC.") }
            }
        }
        return (result,zone,allDay)
    }
}
