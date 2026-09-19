import SwiftUI
import PlanBridgeCore

struct HomeView: View {
    @Environment(PlanStore.self) private var store
    @Binding var sheet: AppSheet?
    var ask: () -> Void
    private var relevant: [PlanConflict] { let ids = Set(store.todayPlans.map(\.id)); return store.conflicts.filter { !$0.planIDs.allSatisfy { !ids.contains($0) } } }
    private var aligned: Int { let ids = Set(relevant.flatMap(\.planIDs)); return store.todayPlans.filter { !ids.contains($0.id) }.count }
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:24) {
                HStack {
                    Label("PlanBridge",systemImage:"point.topleft.down.to.point.bottomright.curvepath").font(.headline)
                    Spacer()
                    Button { sheet = .settings } label: { Image(systemName:"slider.horizontal.3").frame(width:44,height:44).background(BridgeTheme.card,in:Circle()) }.accessibilityLabel("Settings")
                }
                if store.isDemo {
                    HStack { StatusPill(text:"DEMO DATA"); Spacer(); Button("Use my plans") { store.isDemo = false; store.refreshCalendars() }.font(.caption.weight(.semibold)) }
                }
                VStack(alignment:.leading,spacing:8) {
                    Eyebrow(text:Date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    Text(greeting).font(.system(.largeTitle,design:.serif))
                    Text("Your daily calendar planner").font(.subheadline).foregroundStyle(.secondary)
                }
                VStack(alignment:.leading,spacing:24) {
                    HStack { Eyebrow(text:"Your day, at a glance"); Spacer(); Image(systemName:"sun.max").foregroundStyle(BridgeTheme.green) }
                    HStack(alignment:.firstTextBaseline,spacing:8) { Text("\(store.todayPlans.count)").font(.system(size:54,weight:.light,design:.rounded)); Text("plans today").foregroundStyle(.secondary) }
                    HStack(spacing:24) {
                        Label("\(aligned) without flags",systemImage:"checkmark.circle.fill").foregroundStyle(BridgeTheme.green)
                        Label("\(relevant.count) to check",systemImage:"exclamationmark.circle").foregroundStyle(BridgeTheme.amber)
                    }.font(.caption.weight(.medium)).accessibilityElement(children:.combine)
                }.bridgeCard()
                if let conflict = relevant.first {
                    VStack(alignment:.leading,spacing:18) {
                        HStack { Eyebrow(text:"Needs attention"); Spacer(); StatusPill(text:conflict.severity.rawValue,warning:true) }
                        Text(conflict.title).font(.title2.weight(.semibold))
                        ForEach(store.plans.filter { conflict.planIDs.contains($0.id) }) { plan in
                            HStack {
                                Label(plan.title,systemImage:plan.kind.symbol).font(.subheadline)
                                Spacer()
                                Text(PlanFormatting.time(plan.kind.isTransport ? plan.end : plan.start,zone:plan.kind.isTransport ? plan.arrivalTimeZoneID : plan.timeZoneID)).font(.title3.weight(.medium)).monospacedDigit()
                            }
                        }
                        Divider()
                        Text(conflict.explanation).font(.subheadline).foregroundStyle(.secondary).lineSpacing(4)
                        NavigationLink { ConflictDetailView(conflict:conflict) } label: { HStack { Text("Review conflict"); Spacer(); Image(systemName:"arrow.right") }.font(.subheadline.weight(.semibold)) }
                    }.bridgeCard()
                } else if store.todayPlans.isEmpty { EmptyPlans() }
                else {
                    Label("No conflicts found in today's supplied plans.",systemImage:"checkmark.seal").font(.subheadline).foregroundStyle(BridgeTheme.green).bridgeCard()
                }
                Button(action:ask) {
                    HStack(spacing:16) {
                        Image(systemName:"waveform").font(.title2).frame(width:48,height:48).background(.white.opacity(0.12),in:Circle())
                        VStack(alignment:.leading,spacing:5) { Text("One question. A clearer day.").font(.headline); Text("Ask PlanBridge about your plans").font(.caption).opacity(0.8) }
                        Spacer(); Image(systemName:"arrow.up.right")
                    }.padding(20).foregroundStyle(.white).background(BridgeTheme.green,in:RoundedRectangle(cornerRadius:24))
                }
                HStack { Eyebrow(text:"Coming up"); Spacer(); Button { sheet = .add } label: { Label("Add plan",systemImage:"plus").font(.subheadline) } }
                VStack(spacing:6) {
                    ForEach(Array(store.plans.filter { $0.end >= Date() && $0.status != .cancelled }.prefix(4))) { plan in
                        NavigationLink { PlanDetailView(planID:plan.id) } label: { PlanRow(plan:plan,flagged:store.conflicts.contains { $0.planIDs.contains(plan.id) }) }
                    }
                }.bridgeCard()
                Button { sheet = .connections } label: {
                    Label(store.isDemo ? "Demo plans · no services connected" : "Manage your calendars and imports",systemImage:"link").font(.caption).foregroundStyle(.secondary).frame(maxWidth:.infinity)
                }
            }.padding(24).frame(maxWidth:760).frame(maxWidth:.infinity)
        }.background(BridgeTheme.canvas).toolbar(.hidden,for:.navigationBar)
    }
    private var greeting: String {
        let hour = Calendar.current.component(.hour,from:Date())
        return hour < 12 ? "Good morning." : hour < 18 ? "Good afternoon." : "Good evening."
    }
}
