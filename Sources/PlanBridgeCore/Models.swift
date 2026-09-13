import Foundation

public enum PlanKind: String, Codable, CaseIterable, Sendable {
    case meeting, flight, train, hotel, restaurant, appointment, event
    public var isTransport: Bool { self == .flight || self == .train }
    public var symbol: String {
        switch self {
        case .meeting: "person.2"
        case .flight: "airplane"
        case .train: "tram"
        case .hotel: "bed.double"
        case .restaurant: "fork.knife"
        case .appointment: "calendar.badge.clock"
        case .event: "ticket"
        }
    }
}

public struct PlanLocation: Codable, Equatable, Sendable {
    public var name: String
    public var city: String
    public var latitude: Double?
    public var longitude: Double?
    public init(name: String, city: String = "", latitude: Double? = nil, longitude: Double? = nil) {
        self.name = name; self.city = city; self.latitude = latitude; self.longitude = longitude
    }
}

public enum SourceKind: String, Codable, Sendable { case manual, calendar, imported, demo }
public enum PlanStatus: String, Codable, CaseIterable, Sendable { case confirmed, tentative, cancelled }

/// Dates are absolute instants. Zone identifiers preserve how each endpoint was supplied.
public struct PlanItem: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var kind: PlanKind
    public var start: Date
    public var end: Date
    public var timeZoneID: String
    public var arrivalTimeZoneID: String
    public var location: PlanLocation?
    public var destination: PlanLocation?
    public var source: SourceKind
    public var sourceIdentifier: String?
    public var calendarIdentifier: String?
    public var confirmationNumber: String?
    public var provider: String?
    public var status: PlanStatus
    public var tripID: UUID?
    /// Explicitly confirmed link; titles alone never establish equivalence.
    public var linkedBookingID: UUID?
    public var createdAt: Date
    public var lastUpdated: Date
    public var isAllDay: Bool
    public init(id: UUID = UUID(), title: String, kind: PlanKind, start: Date, end: Date,
                timeZoneID: String = "Europe/London", arrivalTimeZoneID: String? = nil,
                location: PlanLocation? = nil, destination: PlanLocation? = nil,
                source: SourceKind = .manual, sourceIdentifier: String? = nil,
                calendarIdentifier: String? = nil, confirmationNumber: String? = nil,
                provider: String? = nil, status: PlanStatus = .confirmed, tripID: UUID? = nil,
                linkedBookingID: UUID? = nil, isAllDay: Bool = false) {
        self.id = id; self.title = title; self.kind = kind; self.start = start; self.end = end
        self.timeZoneID = timeZoneID; self.arrivalTimeZoneID = arrivalTimeZoneID ?? timeZoneID
        self.location = location; self.destination = destination; self.source = source
        self.sourceIdentifier = sourceIdentifier; self.calendarIdentifier = calendarIdentifier
        self.confirmationNumber = confirmationNumber; self.provider = provider; self.status = status
        self.tripID = tripID; self.linkedBookingID = linkedBookingID; self.isAllDay = isAllDay
        self.createdAt = Date(); self.lastUpdated = Date()
    }
    public var isValid: Bool {
        end >= start && TimeZone(identifier: timeZoneID) != nil && TimeZone(identifier: arrivalTimeZoneID) != nil
    }
}

public struct Trip: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var destination: String
    public var start: Date
    public var end: Date
    public init(id: UUID = UUID(), name: String, destination: String, start: Date, end: Date) {
        self.id = id; self.name = name; self.destination = destination; self.start = start; self.end = end
    }
}

public enum ConflictKind: String, Codable, Sendable {
    case overlap, travelTime, arrival, departure, location, dateMismatch, timeMismatch
    case duplicate, missingCalendar, staleCalendar, connectionRisk, missingNight
}
public enum Severity: String, Codable, CaseIterable, Sendable {
    case info = "Info", check = "Check", important = "Important", urgent = "Urgent"
    public var rank: Int { Self.allCases.firstIndex(of: self)! }
}
public enum Confidence: String, Codable, Sendable { case high = "High confidence", possible = "Possible conflict" }
public struct ConflictEvidence: Codable, Equatable, Sendable {
    public var label: String
    public var value: String
    public init(_ label: String, _ value: String) { self.label = label; self.value = value }
}
public struct PlanConflict: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var kind: ConflictKind
    public var planIDs: [UUID]
    public var severity: Severity
    public var confidence: Confidence
    public var title: String
    public var explanation: String
    public var confidenceReason: String
    public var severityReason: String
    public var evidence: [ConflictEvidence]
    public var checkActions: [String]
}
public struct PlanChange: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID = UUID()
    public var planID: UUID
    public var previousStart: Date
    public var currentStart: Date
    public var previousEnd: Date
    public var currentEnd: Date
    public var detectedAt: Date
    public init(previous: PlanItem, current: PlanItem, at: Date = Date()) {
        planID = current.id; previousStart = previous.start; currentStart = current.start
        previousEnd = previous.end; currentEnd = current.end; detectedAt = at
    }
}
public struct TravelBuffer: Codable, Equatable, Sendable {
    public var meeting: Int = 10
    public var airport: Int = 120
    public var train: Int = 20
    public var restaurant: Int = 15
    public var appointment: Int = 15
    public init() {}
    public func minutes(for kind: PlanKind) -> Int {
        let value = switch kind {
        case .flight: airport
        case .train: train
        case .meeting: meeting
        case .restaurant: restaurant
        case .appointment: appointment
        default: 0
        }
        return max(0, value)
    }
}
public struct RouteEstimate: Codable, Equatable, Sendable {
    public var fromID: UUID
    public var toID: UUID
    public var minutes: Int
    public var provider: String
    public var measuredAt: Date
    public init(fromID: UUID, toID: UUID, minutes: Int, provider: String, measuredAt: Date = Date()) {
        self.fromID = fromID; self.toID = toID; self.minutes = minutes
        self.provider = provider; self.measuredAt = measuredAt
    }
}
public struct CalendarCoverage: Sendable {
    public var interval: DateInterval
    public var fetchedSuccessfully: Bool
    public init(interval: DateInterval, fetchedSuccessfully: Bool) {
        self.interval = interval; self.fetchedSuccessfully = fetchedSuccessfully
    }
}
public enum ConflictDisposition: String, Codable, Sendable { case dismissed, intentional }
public enum NotificationPreference: String, Codable, CaseIterable, Sendable {
    case immediate = "When checked", importantOnly = "Important only", daily = "Daily reminder", off = "Off"
}
public struct ImportRecord: Identifiable, Codable, Sendable {
    public var id: UUID = UUID()
    public var importedAt: Date = Date()
    public var fileName: String
    public var planIDs: [UUID]
    public init(fileName: String, planIDs: [UUID]) { self.fileName = fileName; self.planIDs = planIDs }
}
public struct PlanArchive: Codable, Sendable {
    public var version = 1
    public var plans: [PlanItem] = []
    public var trips: [Trip] = []
    public var changes: [PlanChange] = []
    public var dispositions: [String: ConflictDisposition] = [:]
    public var buffers = TravelBuffer()
    public var imports: [ImportRecord] = []
    public init() {}
}

public enum PlanFormatting {
    public static func time(_ date: Date, zone: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.timeZone = TimeZone(identifier: zone) ?? TimeZone(secondsFromGMT: 0)!
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    public static func stamp(_ date: Date, zone: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.timeZone = TimeZone(identifier: zone) ?? TimeZone(secondsFromGMT: 0)!
        formatter.dateFormat = "d MMM yyyy, HH:mm zzz"
        return formatter.string(from: date)
    }
}
