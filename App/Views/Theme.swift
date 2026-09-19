import SwiftUI
import PlanBridgeCore

enum BridgeTheme {
    static let green = Color(red:0.20,green:0.36,blue:0.29)
    static let sage = Color(red:0.87,green:0.91,blue:0.86)
    static let amber = Color(red:0.55,green:0.34,blue:0.12)
    static let canvas = Color(uiColor:UIColor { $0.userInterfaceStyle == .dark ? UIColor(red:0.07,green:0.09,blue:0.08,alpha:1) : UIColor(red:0.97,green:0.96,blue:0.94,alpha:1) })
    static let card = Color(uiColor:.secondarySystemGroupedBackground)
}
struct PrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.body.weight(.semibold)).frame(maxWidth:.infinity).padding(.vertical,17)
            .foregroundStyle(.white).background(BridgeTheme.green.opacity(configuration.isPressed ? 0.8 : 1),in:RoundedRectangle(cornerRadius:18))
    }
}
extension View {
    func bridgeCard() -> some View {
        padding(20).background(BridgeTheme.card,in:RoundedRectangle(cornerRadius:24))
            .overlay(RoundedRectangle(cornerRadius:24).stroke(.primary.opacity(0.05),lineWidth:1))
    }
}
struct Eyebrow: View {
    var text: String
    var body: some View { Text(LocalizedStringKey(text)).textCase(.uppercase).font(.caption.weight(.semibold)).tracking(2).foregroundStyle(.secondary) }
}
struct StatusPill: View {
    var text: String
    var warning = false
    var body: some View {
        Text(LocalizedStringKey(text)).font(.caption.weight(.semibold)).padding(.horizontal,10).padding(.vertical,6)
            .foregroundStyle(warning ? BridgeTheme.amber : BridgeTheme.green)
            .background(warning ? Color.orange.opacity(0.12) : BridgeTheme.sage,in:Capsule())
    }
}
struct PlanRow: View {
    var plan: PlanItem
    var flagged = false
    var body: some View {
        HStack(spacing:14) {
            Image(systemName:plan.kind.symbol).font(.title3).foregroundStyle(BridgeTheme.green)
                .frame(width:46,height:46).background(BridgeTheme.sage.opacity(0.6),in:RoundedRectangle(cornerRadius:15))
            VStack(alignment:.leading,spacing:5) {
                Text(plan.title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                Text(plan.location?.name ?? plan.source.rawValue.capitalized).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength:8)
            VStack(alignment:.trailing,spacing:5) {
                Text(PlanFormatting.time(plan.start,zone:plan.timeZoneID)).font(.subheadline.weight(.medium)).monospacedDigit().foregroundStyle(.primary)
                if flagged { Image(systemName:"exclamationmark.circle.fill").foregroundStyle(BridgeTheme.amber).accessibilityLabel("Needs attention") }
                else { Text(plan.start,format:.dateTime.day().month(.abbreviated)).font(.caption2).foregroundStyle(.secondary) }
            }
        }.padding(.vertical,8).accessibilityElement(children:.combine)
    }
}
struct EmptyPlans: View {
    var title = "A clearer picture starts here."
    var detail = "Add a booking or choose a calendar to see what needs attention."
    var body: some View {
        VStack(spacing:16) {
            Image(systemName:"calendar.badge.checkmark").font(.system(size:40)).foregroundStyle(BridgeTheme.green)
            Text(LocalizedStringKey(title)).font(.title3.weight(.semibold))
            Text(LocalizedStringKey(detail)).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }.frame(maxWidth:.infinity).padding(.vertical,30).bridgeCard()
    }
}
