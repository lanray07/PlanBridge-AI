import SwiftUI
import PlanBridgeCore

struct TimelineView: View {
    @Environment(PlanStore.self) private var store
    @Binding var sheet: AppSheet?
    @State private var query = ""
    @State private var attentionOnly = false
    private var visible: [PlanItem] {
        store.plans.filter { plan in
            (query.isEmpty || plan.title.localizedCaseInsensitiveContains(query)) &&
            (!attentionOnly || store.conflicts.contains { $0.planIDs.contains(plan.id) })
        }
    }
    var body: some View {
        List {
            if store.isDemo { StatusPill(text:"DEMO DATA") }
            Toggle("Needs attention only",isOn:$attentionOnly)
            if visible.isEmpty { Text("No matching plans. Add a booking to get started.").foregroundStyle(.secondary) }
            ForEach(visible) { plan in
                NavigationLink { PlanDetailView(planID:plan.id) } label: { PlanRow(plan:plan,flagged:store.conflicts.contains { $0.planIDs.contains(plan.id) }) }
            }
            if !store.archive.changes.isEmpty {
                Section("What changed?") {
                    ForEach(store.archive.changes.sorted { $0.detectedAt > $1.detectedAt }) { change in
                        if let plan = store.plans.first(where: { $0.id == change.planID }) {
                            VStack(alignment:.leading,spacing:7) {
                                Text(plan.title).font(.headline)
                                Text(store.ai.explainChange(change,plan:plan)).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }.scrollContentBackground(.hidden).background(BridgeTheme.canvas).navigationTitle("Your timeline")
            .searchable(text:$query,prompt:"Find a plan")
            .toolbar { ToolbarItem(placement:.primaryAction) { Menu { Button("Add booking") { sheet = .add }; Button("Import ICS or JSON") { sheet = .importBooking } } label: { Image(systemName:"plus").accessibilityLabel("Add or import booking") } } }
    }
}
