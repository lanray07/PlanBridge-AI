import SwiftUI
import PlanBridgeCore

struct TripsView: View {
    @Environment(PlanStore.self) private var store
    @State private var create = false
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:22) {
                Text("Make room for\nthe good part.").font(.system(.largeTitle,design:.serif))
                Text("Your bookings together. The details checked.").foregroundStyle(.secondary)
                if store.isDemo { StatusPill(text:"DEMO DATA") }
                if store.archive.trips.isEmpty { EmptyPlans(title:"Where are you heading?",detail:"Create a trip, then assign your bookings to check them together.") }
                ForEach(store.archive.trips) { trip in
                    NavigationLink { TripDetailView(trip:trip) } label: {
                        VStack(alignment:.leading,spacing:20) {
                            HStack { Image(systemName:"suitcase.rolling").font(.largeTitle); Spacer(); Image(systemName:"arrow.up.right") }.foregroundStyle(BridgeTheme.green)
                            Text(trip.destination).font(.system(.largeTitle,design:.serif)).foregroundStyle(.primary)
                            Text(trip.name).font(.subheadline).foregroundStyle(.secondary)
                            Text("\(trip.start.formatted(date:.abbreviated,time:.omitted)) – \(trip.end.formatted(date:.abbreviated,time:.omitted))").font(.caption).foregroundStyle(.secondary)
                            let ids = Set(store.plans.filter { $0.tripID == trip.id }.map(\.id))
                            let count = store.conflicts.filter { !$0.planIDs.allSatisfy { !ids.contains($0) } }.count
                            StatusPill(text:count == 0 ? "No flags in supplied plans" : "\(count) worth checking",warning:count > 0)
                        }.frame(maxWidth:.infinity,alignment:.leading).bridgeCard()
                    }
                }
            }.padding(24).frame(maxWidth:760).frame(maxWidth:.infinity)
        }.background(BridgeTheme.canvas).navigationTitle("My trips").navigationBarTitleDisplayMode(.inline)
            .toolbar { Button { create = true } label: { Image(systemName:"plus").accessibilityLabel("Create trip") } }
            .sheet(isPresented:$create) { NavigationStack { TripEditor() } }
    }
}
struct TripEditor: View {
    @Environment(PlanStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var destination = ""
    @State private var start = Date()
    @State private var end = Date().addingTimeInterval(86400)
    var body: some View {
        Form {
            TextField("Trip name",text:$name); TextField("Destination city",text:$destination)
            DatePicker("From",selection:$start,displayedComponents:.date)
            DatePicker("Until",selection:$end,in:start...,displayedComponents:.date)
        }.navigationTitle("Create a trip").toolbar {
            ToolbarItem(placement:.cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement:.confirmationAction) { Button("Create") {
                if store.update({ $0.trips.append(Trip(name:name,destination:destination,start:start,end:end)) }) { dismiss() }
            }.disabled(name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || destination.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || end < start) }
        }
    }
}
struct TripDetailView: View {
    @Environment(PlanStore.self) private var store
    @Environment(SubscriptionService.self) private var subscription
    @Environment(\.dismiss) private var dismiss
    @AppStorage("freeTripChecks") private var freeChecks = 0
    @State private var summary: String?
    @State private var paywall = false
    @State private var confirmDelete = false
    var trip: Trip
    var body: some View {
        List {
            Section {
                Text(trip.destination).font(.system(.largeTitle,design:.serif))
                Text("Only the bookings assigned to this trip are checked. Missing sources and travel estimates may limit the result.").font(.caption).foregroundStyle(.secondary)
                Button("Check My Trip") {
                    if subscription.isPro || store.isDemo || freeChecks < 3 {
                        summary = store.ai.summariseTrip(trip:trip,plans:store.plans,conflicts:store.conflicts)
                        if !subscription.isPro && !store.isDemo { freeChecks += 1 }
                    } else { paywall = true }
                }.buttonStyle(PrimaryButton())
                if let summary { Text(summary).font(.subheadline).accessibilityLabel("Trip check complete. \(summary)") }
            }
            Section("Trip timeline") {
                ForEach(store.plans.filter { $0.tripID == trip.id }) { plan in
                    NavigationLink { PlanDetailView(planID:plan.id) } label: { PlanRow(plan:plan) }
                }
            }
            Section { Button("Delete trip and its imported bookings",role:.destructive) { confirmDelete = true } }
        }.navigationTitle(trip.name).navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented:$paywall) { NavigationStack { PaywallView() } }
            .confirmationDialog("Delete this trip and its PlanBridge bookings?",isPresented:$confirmDelete,titleVisibility:.visible) {
                Button("Delete trip",role:.destructive) { store.removeTrip(trip); dismiss() }
            } message: { Text("Provider bookings and Apple Calendar events are not cancelled or deleted.") }
    }
}
