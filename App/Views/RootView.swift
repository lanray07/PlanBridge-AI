import SwiftUI
import PlanBridgeCore

enum AppSheet: String, Identifiable { case add, settings, connections, paywall, importBooking; var id: String { rawValue } }
struct RootView: View {
    @Environment(PlanStore.self) private var store
    @AppStorage("onboarded") private var onboarded = false
    @State private var tab = 0
    @State private var sheet: AppSheet?
    var body: some View {
        Group {
            if onboarded {
                TabView(selection:$tab) {
                    NavigationStack { HomeView(sheet:$sheet,ask:{ tab = 3 }) }.tabItem { Label("Today",systemImage:"square.grid.2x2") }.tag(0)
                    NavigationStack { TimelineView(sheet:$sheet) }.tabItem { Label("Timeline",systemImage:"calendar") }.tag(1)
                    NavigationStack { TripsView() }.tabItem { Label("My trips",systemImage:"suitcase.rolling") }.tag(2)
                    NavigationStack { AskView() }.tabItem { Label("Ask",systemImage:"waveform") }.tag(3)
                }
                .sheet(item:$sheet) { destination in
                    NavigationStack {
                        switch destination {
                        case .add: BookingEditor(plan:nil)
                        case .settings: SettingsView()
                        case .connections: ConnectionsView()
                        case .paywall: PaywallView()
                        case .importBooking: ImportView()
                        }
                    }
                }
            } else { OnboardingView { demo in store.isDemo = demo; onboarded = true } }
        }
        .alert("PlanBridge",isPresented:Binding(get:{ store.error != nil },set:{ if !$0 { store.error = nil } })) {
            Button("OK",role:.cancel) { store.error = nil }
        } message: { Text(store.error ?? "") }
    }
}

struct OnboardingView: View {
    var finish: (Bool) -> Void
    @State private var page = 0
    private let titles = ["Your plans live in\ndifferent places.","Catch conflicts before\nthey catch you.","Know when\nsomething changes.","Ask about\nyour plans.","Start the day knowing\nwhat needs attention.","Your plans\nare personal."]
    private let details = ["Calendars, travel and bookings — finally on the same page.","Your train arrives at 19:42. Dinner starts at 19:30. That's worth checking.","Compare updated bookings with the calendar details you saved.","Ask a question. Get a clear answer based on the plans you've added.","A calm daily check, with the important details brought forward.","You choose the calendars. Voice stays on device when supported. No account or cloud AI is required."]
    var body: some View {
        VStack(spacing:0) {
            HStack { Label("PlanBridge",systemImage:"point.topleft.down.to.point.bottomright.curvepath").font(.headline); Spacer(); Button("Skip") { page = 5 }.font(.subheadline) }.padding(24)
            TabView(selection:$page) {
                ForEach(0..<6) { i in
                    ScrollView {
                        VStack(alignment:.leading,spacing:22) {
                            if i == 0 || i == 3 {
                                Image("Morning").resizable().scaledToFill().frame(height:300).clipped().clipShape(RoundedRectangle(cornerRadius:28)).accessibilityLabel("A traveller preparing for the day")
                            } else {
                                VStack(alignment:.leading,spacing:22) {
                                    Image(systemName:["calendar","arrow.triangle.branch","clock.arrow.circlepath","waveform","sun.max","lock.shield"][i]).font(.system(size:45)).foregroundStyle(BridgeTheme.green)
                                    Eyebrow(text:i == 5 ? "Private by design" : "Example · demo data")
                                    Text(["","Dinner 19:30\nTrain arrival 19:42","16:20 → 18:05\nCalendar still 16:20","","6 plans · 1 timing conflict","Your device.\nYour connections.\nYour choice."][i]).font(.title2.weight(.medium)).lineSpacing(12)
                                }.frame(maxWidth:.infinity,alignment:.leading).frame(minHeight:250).bridgeCard()
                            }
                            Text(titles[i]).font(.system(.largeTitle,design:.serif).weight(.medium)).fixedSize(horizontal:false,vertical:true)
                            Text(details[i]).font(.body).foregroundStyle(.secondary).lineSpacing(5)
                        }.padding(24).frame(maxWidth:600)
                    }.tag(i)
                }
            }.tabViewStyle(.page(indexDisplayMode:.never))
            HStack(spacing:7) { ForEach(0..<6) { i in Capsule().fill(i == page ? BridgeTheme.green : .gray.opacity(0.2)).frame(width:i == page ? 24 : 6,height:6) } }.padding(16)
            VStack(spacing:14) {
                Button(page == 5 ? "Check My Plans" : "Continue") { if page == 5 { finish(false) } else { withAnimation { page += 1 } } }.buttonStyle(PrimaryButton())
                Button("Explore with demo plans") { finish(true) }.font(.subheadline)
            }.padding(.horizontal,24).padding(.bottom,20).frame(maxWidth:600)
        }.background(BridgeTheme.canvas)
    }
}
