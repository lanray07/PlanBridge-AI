import LocalAuthentication
import Security
import SwiftUI

@MainActor @Observable final class PrivacyService {
    var isLocked = false
    var message: String?
    var enabled: Bool { didSet { UserDefaults.standard.set(enabled,forKey:"appLock") } }
    init() { enabled = UserDefaults.standard.bool(forKey:"appLock"); isLocked = enabled }
    func unlock() async {
        let context = LAContext()
        do {
            if try await context.evaluatePolicy(.deviceOwnerAuthentication,localizedReason:"Unlock your private plans") { isLocked = false; message = nil }
        } catch { message = "Your plans remain locked. Try again to use Face ID, Touch ID or your device passcode." }
    }
    func enable() async {
        let context = LAContext()
        do {
            if try await context.evaluatePolicy(.deviceOwnerAuthentication,localizedReason:"Confirm protection for your plans") { enabled = true; isLocked = false }
        } catch { message = "Set up a device passcode to protect your plans." }
    }
}

/// Reserved for future authorised provider tokens. Never used for itinerary storage.
enum KeychainStore {
    static func put(_ data: Data, account: String) throws {
        let query: [String:Any] = [kSecClass as String:kSecClassGenericPassword,
            kSecAttrService as String:"com.planbridge.ai",kSecAttrAccount as String:account]
        let attributes: [String:Any] = [kSecValueData as String:data,
            kSecAttrAccessible as String:kSecAttrAccessibleWhenUnlockedThisDeviceOnly]
        let existing = SecItemUpdate(query as CFDictionary,attributes as CFDictionary)
        let status = existing == errSecItemNotFound ? SecItemAdd(query.merging(attributes) { _,new in new } as CFDictionary,nil) : existing
        guard status == errSecSuccess else { throw NSError(domain:NSOSStatusErrorDomain,code:Int(status)) }
    }
    static func delete(account: String) { SecItemDelete([kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:"com.planbridge.ai",kSecAttrAccount as String:account] as CFDictionary) }
}
