import Foundation
import SwiftData
import PlanBridgeCore

@Model final class StoredArchive {
    @Attribute(.unique) var key: String
    var payload: Data
    init(payload: Data) { key = "personal"; self.payload = payload }
}

@MainActor final class ArchiveRepository {
    private let container: ModelContainer
    init() throws {
        let directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor:nil, create:true)
            .appendingPathComponent("PrivatePlans",isDirectory:true)
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true,
            attributes:[.protectionKey:FileProtectionType.complete])
        var protectedDirectory = directory
        var values = URLResourceValues(); values.isExcludedFromBackup = true
        try protectedDirectory.setResourceValues(values)
        let config = ModelConfiguration(url:directory.appendingPathComponent("plans.store"),cloudKitDatabase:.none)
        container = try ModelContainer(for:StoredArchive.self,configurations:config)
        for file in try FileManager.default.contentsOfDirectory(at:directory,includingPropertiesForKeys:nil) {
            try FileManager.default.setAttributes([.protectionKey:FileProtectionType.complete],ofItemAtPath:file.path)
        }
    }
    func load() throws -> PlanArchive {
        guard let item = try container.mainContext.fetch(FetchDescriptor<StoredArchive>()).first else { return PlanArchive() }
        let archive = try JSONDecoder().decode(PlanArchive.self,from:item.payload)
        guard archive.version == 1 else {
            throw NSError(domain:"PlanBridge",code:1,userInfo:[NSLocalizedDescriptionKey:"This data uses a newer version. Update PlanBridge to open it."])
        }
        return archive
    }
    func save(_ archive: PlanArchive) throws {
        let context = container.mainContext
        do {
            let data = try JSONEncoder().encode(archive)
            if let item = try context.fetch(FetchDescriptor<StoredArchive>()).first { item.payload = data }
            else { context.insert(StoredArchive(payload:data)) }
            try context.save()
        } catch { context.rollback(); throw error }
    }
}
