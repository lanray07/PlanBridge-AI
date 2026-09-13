import SwiftUI
import PlanBridgeCore

struct BookingEditor: View {
    @Environment(PlanStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var plan: PlanItem?
    @State private var title = ""
    @State private var kind = PlanKind.restaurant
    @State private var start = Date()
    @State private var end = Date().addingTimeInterval(3600)
    @State private var zone = TimeZone.current.identifier
    @State private var arrivalZone = TimeZone.current.identifier
    @State private var location = ""
    @State private var city = ""
    @State private var destination = ""
    @State private var destinationCity = ""
    @State private var reference = ""
    @State private var provider = ""
    @State private var status = PlanStatus.confirmed
    @State private var tripID: UUID?
    var body: some View {
        Form {
            if store.isDemo { Text("DEMO DATA · This booking stays in the demo.").font(.caption) }
            Section("Booking details") {
                TextField("Title",text:$title)
                Picker("Type",selection:$kind) { ForEach(PlanKind.allCases,id:\.self) { Text($0.rawValue.capitalized).tag($0) } }
                Picker("Status",selection:$status) { ForEach(PlanStatus.allCases,id:\.self) { Text($0.rawValue.capitalized).tag($0) } }
            }
            Section("Start · local time") {
                zonePicker("Time zone",selection:$zone)
                DatePicker("Starts",selection:$start).environment(\.timeZone,TimeZone(identifier:zone) ?? .current)
            }
            Section(kind.isTransport ? "Arrival · local time" : "End · local time") {
                zonePicker("Time zone",selection:$arrivalZone)
                DatePicker(kind.isTransport ? "Arrives" : "Ends",selection:$end).environment(\.timeZone,TimeZone(identifier:arrivalZone) ?? .current)
            }
            Section("Location") {
                TextField(kind.isTransport ? "Departure location" : "Place or address",text:$location)
                TextField("City",text:$city)
                if kind.isTransport { TextField("Arrival location",text:$destination); TextField("Arrival city",text:$destinationCity) }
            }
            Section("Source details") {
                TextField("Provider (optional)",text:$provider)
                TextField("Confirmation reference (optional)",text:$reference).textInputAutocapitalization(.characters)
                Picker("Trip",selection:$tripID) {
                    Text("No trip").tag(nil as UUID?)
                    ForEach(store.archive.trips) { trip in Text(trip.name).tag(Optional(trip.id)) }
                }
            }
            Section { Text("Check both local time zones before saving. Saving records the information you supplied; it does not connect to or change the provider.").font(.caption).foregroundStyle(.secondary) }
        }.navigationTitle(plan == nil ? "Add a booking" : "Edit booking").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement:.cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement:.confirmationAction) { Button("Save") { save() }.disabled(title.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || end < start) }
            }
            .onAppear {
                guard let plan else { return }
                title = plan.title; kind = plan.kind; start = plan.start; end = plan.end
                zone = plan.timeZoneID; arrivalZone = plan.arrivalTimeZoneID; location = plan.location?.name ?? ""; city = plan.location?.city ?? ""
                destination = plan.destination?.name ?? ""; destinationCity = plan.destination?.city ?? ""
                reference = plan.confirmationNumber ?? ""; provider = plan.provider ?? ""; status = plan.status; tripID = plan.tripID
            }
    }
    private func zonePicker(_ title: String,selection: Binding<String>) -> some View {
        Picker(title,selection:selection) { ForEach(TimeZone.knownTimeZoneIdentifiers,id:\.self) { Text($0.replacingOccurrences(of:"_",with:" ")).tag($0) } }
    }
    private func save() {
        var result = plan ?? PlanItem(title:title,kind:kind,start:start,end:end,source:store.isDemo ? .demo : .manual)
        result.title = title; result.kind = kind; result.start = start; result.end = end
        result.timeZoneID = zone; result.arrivalTimeZoneID = arrivalZone
        result.location = location.isEmpty && city.isEmpty ? nil : PlanLocation(name:location,city:city)
        result.destination = kind.isTransport && (!destination.isEmpty || !destinationCity.isEmpty) ? PlanLocation(name:destination,city:destinationCity) : nil
        result.confirmationNumber = reference.isEmpty ? nil : reference; result.provider = provider.isEmpty ? nil : provider
        result.status = status; result.tripID = tripID
        if store.save(result) { dismiss() }
    }
}

struct PlanDetailView: View {
    @Environment(PlanStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var planID: UUID
    @State private var edit: PlanItem?
    @State private var confirmDelete = false
    var body: some View {
        Group {
            if let plan = store.plans.first(where: { $0.id == planID }) {
                List {
                    Section {
                        Label(plan.title,systemImage:plan.kind.symbol).font(.title2)
                        LabeledContent("Starts",value:PlanFormatting.stamp(plan.start,zone:plan.timeZoneID))
                        LabeledContent(plan.kind.isTransport ? "Arrives" : "Ends",value:PlanFormatting.stamp(plan.end,zone:plan.arrivalTimeZoneID))
                        if let place = plan.location { LabeledContent("Location",value:"\(place.name) \(place.city)") }
                        if let place = plan.destination { LabeledContent("Destination",value:"\(place.name) \(place.city)") }
                    }
                    Section("Information source") {
                        LabeledContent("Source",value:plan.source.rawValue.capitalized)
                        LabeledContent("Status",value:plan.status.rawValue.capitalized)
                        if let provider = plan.provider { LabeledContent("Provider",value:provider) }
                        if let reference = plan.confirmationNumber { LabeledContent("Reference",value:reference) }
                        Text("No live provider status is available.").font(.caption).foregroundStyle(.secondary)
                    }
                    if plan.source == .calendar {
                        Section("Link to a booking") {
                            Picker("Same booking",selection:Binding(get:{ plan.linkedBookingID },set:{ id in var p = plan; p.linkedBookingID = id; store.save(p) })) {
                                Text("Not linked").tag(nil as UUID?)
                                ForEach(store.plans.filter { $0.source != .calendar }) { booking in Text(booking.title).tag(Optional(booking.id)) }
                            }
                            Text("Link only when both entries describe the same booking. Calendar times are read-only here.").font(.caption)
                        }
                    }
                    Section("Needs attention") {
                        ForEach(store.conflicts.filter { $0.planIDs.contains(plan.id) }) { conflict in
                            NavigationLink(conflict.title) { ConflictDetailView(conflict:conflict) }
                        }
                    }
                    if plan.source != .calendar {
                        Button("Edit booking") { edit = plan }
                        Button("Delete booking",role:.destructive) { confirmDelete = true }
                    }
                }
                .confirmationDialog("Delete this booking from PlanBridge?",isPresented:$confirmDelete,titleVisibility:.visible) {
                    Button("Delete booking",role:.destructive) { store.remove(plan); dismiss() }
                } message: { Text("This does not cancel the provider's booking.") }
            } else { ContentUnavailableView("Booking removed",systemImage:"calendar.badge.minus") }
        }.navigationTitle("Booking").navigationBarTitleDisplayMode(.inline)
            .sheet(item:$edit) { item in NavigationStack { BookingEditor(plan:item) } }
    }
}
