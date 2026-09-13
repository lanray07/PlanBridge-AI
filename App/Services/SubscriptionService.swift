import StoreKit
import SwiftUI

@MainActor @Observable final class SubscriptionService {
    static let productIDs: Set<String> = ["com.planbridge.ai.pro.monthly","com.planbridge.ai.pro.annual"]
    var products: [Product] = []
    var isPro = false
    var isBusy = false
    var message: String?
    private var listener: Task<Void,Never>?
    func start() async {
        if listener == nil {
            listener = Task { [weak self] in
                for await result in Transaction.updates {
                    guard let self else { return }
                    if case .verified(let transaction) = result {
                        await self.refreshEntitlements(); await transaction.finish()
                    }
                }
            }
        }
        await refreshEntitlements()
        do { products = try await Product.products(for:Self.productIDs).sorted { $0.price < $1.price } }
        catch { message = "Subscriptions could not be loaded. Please try again." }
    }
    func refreshEntitlements() async {
        var entitled = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               Self.productIDs.contains(transaction.productID), transaction.revocationDate == nil, !transaction.isUpgraded { entitled = true }
        }
        isPro = entitled
    }
    func purchase(_ product: Product) async {
        guard !isBusy else { return }; isBusy = true; defer { isBusy = false }
        do {
            switch try await product.purchase() {
            case .success(.verified(let transaction)): await refreshEntitlements(); await transaction.finish(); message = "PlanBridge Pro is ready."
            case .success(.unverified): message = "This purchase could not be verified. Pro has not been enabled."
            case .pending: message = "Your purchase is awaiting approval."
            case .userCancelled: break
            @unknown default: message = "Please check your purchase status in the App Store."
            }
        } catch { message = error.localizedDescription }
    }
    func restore() async {
        guard !isBusy else { return }; isBusy = true; defer { isBusy = false }
        do { try await AppStore.sync(); await refreshEntitlements(); message = isPro ? "Purchases restored." : "No active PlanBridge Pro subscription was found." }
        catch { message = error.localizedDescription }
    }
}
