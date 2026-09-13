import SwiftUI
import StoreKit

enum ReleaseConfiguration {
    static let privacyURL = URL(string: "https://github.com/lanray07/PlanBridge-AI/blob/main/PRIVACY.md")
    static let termsURL = URL(string: "https://github.com/lanray07/PlanBridge-AI/blob/main/TERMS.md")
    static var purchasesReady: Bool { privacyURL != nil && termsURL != nil }
}
struct PaywallView: View {
    @Environment(SubscriptionService.self) private var subscription
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:24) {
                StatusPill(text:"PlanBridge Pro")
                Text("Know when your plans\ndon't line up.").font(.system(.largeTitle,design:.serif))
                Text("More room to check your trips. A simpler way to ask about your day.").foregroundStyle(.secondary)
                VStack(alignment:.leading,spacing:20) {
                    Label("Unlimited checks of supplied trip bookings",systemImage:"checkmark.circle")
                    Label("On-device voice queries, where supported",systemImage:"mic")
                    Label("Evidence-led answers about your plans",systemImage:"text.bubble")
                }.frame(maxWidth:.infinity,alignment:.leading).bridgeCard()
                if subscription.isPro { Label("Your Pro subscription is active",systemImage:"checkmark.seal.fill").foregroundStyle(BridgeTheme.green) }
                else if subscription.products.isEmpty {
                    Text("Plans are temporarily unavailable. Please check your connection and try again.").font(.subheadline).foregroundStyle(.secondary)
                    Button("Try loading plans again") { Task { await subscription.start() } }
                } else {
                    ForEach(subscription.products) { product in
                        Button { Task { await subscription.purchase(product) } } label: {
                            HStack {
                                VStack(alignment:.leading) {
                                    Text(product.displayName).font(.headline)
                                    Text(product.description).font(.caption)
                                    if let period = product.subscription?.subscriptionPeriod {
                                        Text("Renews every \(period.value) \(String(describing:period.unit))").font(.caption)
                                    }
                                }
                                Spacer(); Text(product.displayPrice).font(.title3)
                            }.bridgeCard()
                        }.accessibilityIdentifier(product.id).disabled(subscription.isBusy || !ReleaseConfiguration.purchasesReady)
                    }
                }
                if !ReleaseConfiguration.purchasesReady { Text("Purchases are disabled until the publisher supplies final public terms and a privacy policy.").font(.caption).foregroundStyle(.secondary) }
                Button("Restore purchases") { Task { await subscription.restore() } }.disabled(subscription.isBusy)
                if let message = subscription.message { Text(message).font(.caption) }
                Text("Subscriptions renew automatically. Manage or cancel in App Store settings. Your privacy controls always remain free.").font(.caption).foregroundStyle(.secondary)
                HStack {
                    if let url = ReleaseConfiguration.termsURL { Link("Terms",destination:url) } else { NavigationLink("Draft terms") { PolicyView(isPrivacy:false) } }
                    Spacer()
                    if let url = ReleaseConfiguration.privacyURL { Link("Privacy",destination:url) } else { NavigationLink("Privacy summary") { PolicyView(isPrivacy:true) } }
                }.font(.caption)
            }.padding(24).frame(maxWidth:650).frame(maxWidth:.infinity)
        }.background(BridgeTheme.canvas).toolbar { ToolbarItem(placement:.confirmationAction) { Button("Done") { dismiss() } } }
    }
}
