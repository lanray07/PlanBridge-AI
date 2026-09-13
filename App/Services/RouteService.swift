@preconcurrency import MapKit
@preconcurrency import CoreLocation
import PlanBridgeCore

@MainActor struct RouteService {
    func estimate(from: PlanItem, to: PlanItem) async throws -> RouteEstimate {
        guard let origin = from.destination ?? from.location, let destination = to.location else {
            throw RouteError.missingLocation
        }
        let source = try await mapItem(origin)
        let target = try await mapItem(destination)
        let request = MKDirections.Request()
        request.source = source; request.destination = target
        request.transportType = .automobile
        request.departureDate = max(Date(),from.end)
        let response = try await MKDirections(request:request).calculate()
        guard let route = response.routes.first else { throw RouteError.noRoute }
        return RouteEstimate(fromID:from.id,toID:to.id,minutes:Int(ceil(route.expectedTravelTime/60)),provider:"Apple Maps · driving")
    }
    private func mapItem(_ location: PlanLocation) async throws -> MKMapItem {
        if let latitude = location.latitude, let longitude = location.longitude,
           (-90...90).contains(latitude), (-180...180).contains(longitude) {
            return MKMapItem(placemark:MKPlacemark(coordinate:CLLocationCoordinate2D(latitude:latitude,longitude:longitude)))
        }
        guard !location.name.isEmpty else { throw RouteError.missingLocation }
        let matches = try await CLGeocoder().geocodeAddressString("\(location.name), \(location.city)")
        // An ambiguous place must not silently become a reliable estimate.
        guard matches.count == 1, let match = matches.first else { throw RouteError.ambiguousLocation }
        return MKMapItem(placemark:MKPlacemark(placemark:match))
    }
    enum RouteError: LocalizedError {
        case missingLocation, noRoute, ambiguousLocation
        var errorDescription: String? {
            switch self {
            case .missingLocation: "Add a complete address to both bookings before checking a route."
            case .noRoute: "Apple Maps did not return a driving route. No estimate has been assumed."
            case .ambiguousLocation: "The address did not resolve to one location. Make the booking address more specific."
            }
        }
    }
}
