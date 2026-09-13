import SwiftUI
import UniformTypeIdentifiers
import PlanBridgeCore

struct ImportView: View {
    @Environment(PlanStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var picking = false
    @State private var drafts: [PlanItem] = []
    @State private var warnings: [String] = []
    @State private var fileName = ""
    @State private var message: String?
    var body: some View {
        List {
            Section {
                Text("Bring a booking into the picture.").font(.title2)
                Text("Import an ICS calendar file or a PlanBridge structured itinerary. Nothing is saved until you confirm.").font(.subheadline).foregroundStyle(.secondary)
                Button("Choose file") { picking = true }
            }
            if let message { Text(message).foregroundStyle(.secondary) }
            if !drafts.isEmpty {
                Section("We found · is this correct?") {
                    ForEach($drafts) { $plan in
                        VStack(alignment:.leading,spacing:12) {
                            TextField("Title",text:$plan.title)
                            Picker("Type",selection:$plan.kind) { ForEach(PlanKind.allCases,id:\.self) { Text($0.rawValue.capitalized).tag($0) } }
                            DatePicker("Starts",selection:$plan.start).environment(\.timeZone,TimeZone(identifier:plan.timeZoneID) ?? .current)
                            DatePicker("Ends",selection:$plan.end).environment(\.timeZone,TimeZone(identifier:plan.arrivalTimeZoneID) ?? .current)
                            Text("\(plan.timeZoneID) → \(plan.arrivalTimeZoneID)").font(.caption)
                            if let location = plan.location { Text("Location: \(location.name)").font(.caption) }
                            Text("Provider: \(plan.provider ?? "Not supplied") · Reference: \(plan.confirmationNumber ?? "Not supplied")").font(.caption)
                        }.padding(.vertical,8)
                    }.onDelete { drafts.remove(atOffsets:$0) }
                }
                Section { ForEach(warnings,id:\.self) { Text($0).font(.caption) } }
                Button("Confirm and save \(drafts.count) bookings") {
                    let items = drafts.map { item in var item = item; if store.isDemo { item.source = .demo }; return item }
                    if store.update({ archive in
                        archive.plans.append(contentsOf:items)
                        archive.imports.append(ImportRecord(fileName:fileName,planIDs:items.map(\.id)))
                    }) { dismiss() }
                }.disabled(drafts.contains { !$0.isValid || $0.title.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty })
            }
        }.navigationTitle("Review an import").toolbar { ToolbarItem(placement:.cancellationAction) { Button("Cancel") { dismiss() } } }
            .fileImporter(isPresented:$picking,allowedContentTypes:[.calendarEvent,.json,.plainText]) { result in
                do {
                    let url = try result.get()
                    let granted = url.startAccessingSecurityScopedResource(); defer { if granted { url.stopAccessingSecurityScopedResource() } }
                    let size = try url.resourceValues(forKeys:[.fileSizeKey]).fileSize ?? 0
                    guard size <= 2_000_000 else { throw ImportFailure.unsupported("Choose a file smaller than 2 MB.") }
                    let data = try Data(contentsOf:url)
                    let imported: ImportDraft
                    if url.pathExtension.lowercased() == "json" { imported = try BookingImporter().parseJSON(data) }
                    else { guard let text = String(data:data,encoding:.utf8) else { throw ImportFailure.unsupported("Use a UTF-8 ICS file.") }; imported = try BookingImporter().parseICS(text) }
                    drafts = imported.plans; warnings = imported.warnings; fileName = url.lastPathComponent; message = nil
                } catch { message = error.localizedDescription; drafts = [] }
            }
    }
}
