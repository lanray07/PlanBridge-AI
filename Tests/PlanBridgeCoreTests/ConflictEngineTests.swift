import XCTest
@testable import PlanBridgeCore

final class ConflictEngineTests: XCTestCase {
    let engine = PlanConflictEngine()
    func date(_ value: String) -> Date { ISO8601DateFormatter().date(from:value)! }
    func plan(_ start: String, _ end: String, kind: PlanKind = .meeting, zone: String = "Europe/London") -> PlanItem {
        PlanItem(title:kind.rawValue,kind:kind,start:date(start),end:date(end),timeZoneID:zone)
    }
    func testOverlapAndBoundary() {
        let a = plan("2026-09-18T14:00:00Z","2026-09-18T15:00:00Z")
        let b = plan("2026-09-18T14:35:00Z","2026-09-18T15:30:00Z")
        XCTAssertTrue(engine.evaluate([a,b]).contains { $0.kind == .overlap && $0.explanation.contains("25 minutes") })
        var c = b; c.start = a.end
        XCTAssertFalse(engine.evaluate([a,c]).contains { $0.kind == .overlap })
    }
    func testDSTFallbackAbsoluteInstants() {
        let a = plan("2026-10-25T00:15:00Z","2026-10-25T00:45:00Z")
        let b = plan("2026-10-25T01:15:00Z","2026-10-25T01:45:00Z")
        XCTAssertEqual(PlanFormatting.time(a.start,zone:a.timeZoneID),PlanFormatting.time(b.start,zone:b.timeZoneID))
        XCTAssertFalse(engine.evaluate([a,b]).contains { $0.kind == .overlap })
    }
    func testDateLineAndCrossZoneOverlap() {
        let a = plan("2026-09-18T23:00:00Z","2026-09-19T01:00:00Z",zone:"Pacific/Auckland")
        let b = plan("2026-09-19T00:00:00Z","2026-09-19T02:00:00Z",zone:"America/Los_Angeles")
        XCTAssertTrue(engine.evaluate([a,b]).contains { $0.kind == .overlap })
    }
    func testHotelAndCancelledDoNotBlockTime() {
        let a = plan("2026-09-18T14:00:00Z","2026-09-19T11:00:00Z",kind:.hotel)
        var b = plan("2026-09-18T18:00:00Z","2026-09-18T19:00:00Z")
        XCTAssertTrue(engine.evaluate([a,b]).isEmpty)
        b.status = .cancelled
        XCTAssertTrue(engine.evaluate([a,b]).isEmpty)
    }
    func testRouteAndBufferArithmetic() {
        let a = plan("2026-09-18T16:00:00Z","2026-09-18T17:00:00Z")
        let b = plan("2026-09-18T18:00:00Z","2026-09-18T19:00:00Z",kind:.restaurant)
        let now = date("2026-09-18T15:00:00Z")
        let route = RouteEstimate(fromID:a.id,toID:b.id,minutes:47,provider:"Verified test fixture",measuredAt:now)
        let conflicts = engine.evaluate([a,b],routes:[route],now:now)
        XCTAssertEqual(conflicts.first?.kind,.travelTime)
        XCTAssertTrue(conflicts.first!.explanation.contains("2 minutes"))
        XCTAssertEqual(conflicts.first?.confidence,.possible)
        XCTAssertTrue(engine.evaluate([a,b],routes:[route],now:now.addingTimeInterval(7200)).isEmpty)
    }
    func testMissingCalendarRequiresCoverage() {
        let a = plan("2026-09-18T16:00:00Z","2026-09-18T17:00:00Z")
        XCTAssertTrue(engine.evaluate([a]).isEmpty)
        let coverage = CalendarCoverage(interval:DateInterval(start:a.start,end:a.end),fetchedSuccessfully:true)
        XCTAssertEqual(engine.evaluate([a],coverage:coverage).first?.kind,.missingCalendar)
    }
    func testLinkedChangedBookingIsNotAnOverlap() {
        let old = plan("2026-09-18T16:20:00Z","2026-09-18T20:00:00Z",kind:.flight)
        var new = old; new.start = date("2026-09-18T18:05:00Z")
        var event = old; event.id = UUID(); event.source = .calendar; event.linkedBookingID = old.id
        let conflicts = engine.evaluate([new,event],changes:[PlanChange(previous:old,current:new)])
        XCTAssertEqual(conflicts.count,1)
        XCTAssertEqual(conflicts.first?.kind,.staleCalendar)
    }
    func testDemoSeparationAndChangedDismissalIdentity() {
        var a = plan("2026-09-18T14:00:00Z","2026-09-18T15:00:00Z")
        var b = plan("2026-09-18T14:30:00Z","2026-09-18T16:00:00Z")
        let first = engine.evaluate([a,b]).first!.id
        b.start = date("2026-09-18T14:40:00Z")
        XCTAssertNotEqual(first,engine.evaluate([a,b]).first!.id)
        a.source = .demo
        XCTAssertTrue(engine.evaluate([a,b]).isEmpty)
    }
    func testArrivalConflict() {
        let trip = UUID()
        var train = plan("2026-09-18T17:00:00Z","2026-09-18T19:42:00Z",kind:.train); train.tripID = trip
        var dinner = plan("2026-09-18T19:30:00Z","2026-09-18T21:00:00Z",kind:.restaurant); dinner.tripID = trip
        XCTAssertEqual(engine.evaluate([train,dinner]).first?.kind,.arrival)
        XCTAssertTrue(engine.evaluate([train,dinner]).first!.explanation.contains("12 minutes"))
    }
    func testHotelDateUsesDestinationZone() {
        let trip = UUID()
        var flight = plan("2026-09-18T10:00:00Z","2026-09-18T23:30:00Z",kind:.flight)
        flight.tripID = trip; flight.destination = PlanLocation(name:"Tokyo airport",city:"Tokyo")
        var hotel = plan("2026-09-18T06:00:00Z","2026-09-18T22:00:00Z",kind:.hotel,zone:"Asia/Tokyo")
        hotel.tripID = trip; hotel.location = PlanLocation(name:"Hotel",city:"Tokyo")
        XCTAssertTrue(engine.evaluate([flight,hotel]).contains { $0.kind == .dateMismatch })
    }
    func testDuplicateReferenceRequiresSameProviderAndTimes() {
        var a = plan("2026-09-18T14:00:00Z","2026-09-18T15:00:00Z"); a.confirmationNumber = "ABC"; a.provider = "Test"
        var b = a; b.id = UUID()
        XCTAssertEqual(engine.evaluate([a,b]).first?.kind,.duplicate)
        b.provider = "Other"
        XCTAssertEqual(engine.evaluate([a,b]).first?.kind,.overlap)
    }
    func testInvalidPlanExcluded() {
        var a = plan("2026-09-18T14:00:00Z","2026-09-18T15:00:00Z"); a.timeZoneID = "No/Such_Zone"
        XCTAssertFalse(a.isValid)
        XCTAssertTrue(engine.evaluate([a]).isEmpty)
    }
    func testICSReviewAndDSTRejection() throws {
        let source = "BEGIN:VCALENDAR\nBEGIN:VEVENT\nUID:1\nSUMMARY:Dinner\nDTSTART:20260918T193000Z\nDTEND:20260918T210000Z\nEND:VEVENT\nEND:VCALENDAR"
        let draft = try BookingImporter().parseICS(source)
        XCTAssertEqual(draft.plans.count,1)
        XCTAssertEqual(draft.plans[0].source,.imported)
        XCTAssertThrowsError(try BookingImporter().parseICS(source.replacingOccurrences(of:"DTSTART:20260918T193000Z",with:"DTSTART;TZID=Europe/London:20261025T013000")))
        XCTAssertThrowsError(try BookingImporter().parseICS(source.replacingOccurrences(of:"DTSTART:20260918T193000Z",with:"DTSTART;TZID=Europe/London:20260329T013000")))
        XCTAssertThrowsError(try BookingImporter().parseICS(source.replacingOccurrences(of:"UID:1",with:"UID:1\nRRULE:FREQ=DAILY")))
    }
    func testEmptyDataNeverClaimsLiveAccess() {
        let answer = PlanBridgeAIService().answerPlanQuestion("What changed?",plans:[],conflicts:[])
        XCTAssertTrue(answer.contains("No saved timing changes"))
        XCTAssertTrue(PlanBridgeAIService().summariseDay(plans:[],conflicts:[]).contains("No plans"))
    }
    func testArchiveRoundTrip() throws {
        let archive = DemoData.archive()
        let data = try JSONEncoder().encode(archive)
        let restored = try JSONDecoder().decode(PlanArchive.self,from:data)
        XCTAssertEqual(archive.plans,restored.plans)
    }
    func testMissingNightBetweenStays() {
        let trip = UUID()
        var a = plan("2026-09-18T14:00:00Z","2026-09-19T10:00:00Z",kind:.hotel); a.tripID = trip
        var b = plan("2026-09-20T14:00:00Z","2026-09-21T10:00:00Z",kind:.hotel); b.tripID = trip
        XCTAssertTrue(engine.evaluate([a,b]).contains { $0.kind == .missingNight && $0.explanation.contains("1 nights") })
    }
    func testNoCoverageWarningOutsideFetchedWindow() {
        let a = plan("2026-09-18T16:00:00Z","2026-09-18T17:00:00Z")
        let interval = DateInterval(start:date("2026-09-19T00:00:00Z"),duration:86400)
        XCTAssertTrue(engine.evaluate([a],coverage:CalendarCoverage(interval:interval,fetchedSuccessfully:true)).isEmpty)
        XCTAssertTrue(engine.evaluate([a],coverage:CalendarCoverage(interval:DateInterval(start:a.start,end:a.end),fetchedSuccessfully:false)).isEmpty)
    }
    func testBufferOnlyWarningAdmitsUnknownTravel() {
        let a = plan("2026-09-18T16:00:00Z","2026-09-18T17:00:00Z")
        let b = plan("2026-09-18T17:05:00Z","2026-09-18T18:00:00Z",kind:.restaurant)
        let conflicts = engine.evaluate([a,b])
        XCTAssertEqual(conflicts.first?.confidence,.possible)
        XCTAssertTrue(conflicts.first!.explanation.contains("Travel time has not been checked"))
    }
    func testCancelledAndAllDayEventsDoNotFlag() {
        var a = plan("2026-09-18T14:00:00Z","2026-09-18T15:00:00Z")
        let b = plan("2026-09-18T14:30:00Z","2026-09-18T15:30:00Z")
        a.isAllDay = true; XCTAssertTrue(engine.evaluate([a,b]).isEmpty)
        a.isAllDay = false; a.status = .cancelled; XCTAssertTrue(engine.evaluate([a,b]).isEmpty)
    }
    func testICSDoesNotPartiallyAcceptMalformedOrFloatingFile() {
        XCTAssertThrowsError(try BookingImporter().parseICS("BEGIN:VEVENT\nDTSTART:20260918T193000Z\nEND:VEVENT"))
        XCTAssertThrowsError(try BookingImporter().parseICS("BEGIN:VEVENT\nDTSTART:20260918T193000\nDTEND:20260918T203000\nEND:VEVENT"))
    }
    func testJSONImportReidentifiesAndClearsExternalLinks() throws {
        var item = plan("2026-09-18T14:00:00Z","2026-09-18T15:00:00Z")
        item.tripID = UUID(); item.linkedBookingID = UUID(); item.source = .demo
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let draft = try BookingImporter().parseJSON(encoder.encode([item]))
        XCTAssertNotEqual(draft.plans[0].id,item.id)
        XCTAssertNil(draft.plans[0].tripID)
        XCTAssertNil(draft.plans[0].linkedBookingID)
        XCTAssertEqual(draft.plans[0].source,.imported)
    }
    func testTomorrowQueryUsesLocalDayAcrossDST() {
        let now = date("2026-10-24T22:30:00Z")
        let a = plan("2026-10-25T23:30:00Z","2026-10-25T23:45:00Z")
        let answer = PlanBridgeAIService().answerPlanQuestion("Check tomorrow",plans:[a],conflicts:[],now:now,timeZone:TimeZone(identifier:"Europe/London")!)
        XCTAssertTrue(answer.contains("1 plan checked"))
    }
}
