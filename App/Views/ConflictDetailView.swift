import SwiftUI
import PlanBridgeCore

struct ConflictDetailView: View {
    @Environment(PlanStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var conflict: PlanConflict
    @State private var checkingRoute = false
    @State private var routeMessage: String?
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:24) {
                StatusPill(text:conflict.severity.rawValue,warning:true)
                Text(conflict.title).font(.system(.largeTitle,design:.serif))
                section("What happened?",conflict.explanation)
                VStack(alignment:.leading,spacing:18) {
                    Eyebrow(text:"What information was compared?")
                    ForEach(Array(conflict.evidence.enumerated()),id:\.offset) { _,item in
                        VStack(alignment:.leading,spacing:5) { Text(item.label).font(.headline); Text(item.value).font(.subheadline).foregroundStyle(.secondary) }
                    }
                }.bridgeCard()
                section("Why is this flagged?",conflict.severityReason)
                section(conflict.confidence.rawValue,conflict.confidenceReason)
                VStack(alignment:.leading,spacing:12) {
                    Eyebrow(text:"What should I check?")
                    ForEach(store.plans.filter { conflict.planIDs.contains($0.id) }) { plan in
                        NavigationLink { PlanDetailView(planID:plan.id) } label: { Label("Review \(plan.title)",systemImage:plan.kind.symbol).frame(maxWidth:.infinity,alignment:.leading).padding(.vertical,10) }
                    }
                    NavigationLink("Review my buffers") { BufferSettingsView() }
                    if conflict.planIDs.count == 2 && !store.isDemo {
                        Button(checkingRoute ? "Checking route…" : "Check driving time with Apple Maps") {
                            let items = store.plans.filter { conflict.planIDs.contains($0.id) }.sorted { $0.start < $1.start }
                            guard items.count == 2 else { return }
                            checkingRoute = true
                            Task {
                                defer { checkingRoute = false }
                                do {
                                    let route = try await RouteService().estimate(from:items[0],to:items[1])
                                    store.routes.removeAll { $0.fromID == route.fromID && $0.toID == route.toID }
                                    store.routes.append(route)
                                    routeMessage = "Apple Maps estimates \(route.minutes) minutes driving. Return to Today to review recalculated warnings."
                                } catch { routeMessage = error.localizedDescription }
                            }
                        }.disabled(checkingRoute)
                        Text("This sends the two supplied locations to Apple Maps. The result is a driving estimate, not a guarantee.").font(.caption).foregroundStyle(.secondary)
                        if let routeMessage { Text(routeMessage).font(.subheadline) }
                    }
                }.bridgeCard()
                Button("Mark intentional") { store.resolve(conflict,as:.intentional); dismiss() }.buttonStyle(PrimaryButton())
                Button("Dismiss this warning") { store.resolve(conflict,as:.dismissed); dismiss() }.frame(maxWidth:.infinity)
                Text("This does not change or cancel a booking. A new warning can appear if its evidence changes.").font(.caption).foregroundStyle(.secondary)
            }.padding(24).frame(maxWidth:720).frame(maxWidth:.infinity)
        }.background(BridgeTheme.canvas).navigationTitle("Booking conflicts").navigationBarTitleDisplayMode(.inline)
    }
    private func section(_ title: String,_ text: String) -> some View {
        VStack(alignment:.leading,spacing:12) { Eyebrow(text:title); Text(text).lineSpacing(4) }.frame(maxWidth:.infinity,alignment:.leading).bridgeCard()
    }
}
