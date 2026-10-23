import SwiftUI

/// Opened deliberately by a long press on the version row in Settings.
struct BackupToolsView: View {
    private enum ImportMode { case full, newStudents }
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var storage: StorageCoordinator

    @State private var document: NumbersWorkbookDocument?
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var showRestoreConfirmation = false
    @State private var showStudentsConfirmation = false
    @State private var pendingSnapshot: DatabaseSnapshot?
    @State private var pendingStudents: [NumbersWorkbookBackup.NewStudent] = []
    @State private var importMode: ImportMode = .full
    @State private var message: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        export()
                    } label: {
                        Label("Save Database Workbook", systemImage: "square.and.arrow.up")
                    }
                    .accessibilityIdentifier("exportDatabaseWorkbookButton")

                    Button {
                        importMode = .full
                        showImporter = true
                    } label: {
                        Label("Restore from Workbook", systemImage: "square.and.arrow.down")
                    }
                    .accessibilityIdentifier("importDatabaseWorkbookButton")

                    Button {
                        importMode = .newStudents
                        showImporter = true
                    } label: {
                        Label("Add New Students from Workbook", systemImage: "person.crop.circle.badge.plus")
                    }
                    .accessibilityIdentifier("importNewStudentsWorkbookButton")
                } header: {
                    Text("Numbers-compatible backup")
                } footer: {
                    Text("Visible columns can be edited in Numbers. Hidden IDs preserve links between records. Add students on New Students. Private students need an existing private organization and lesson rate.")
                }

                Section("Included Data") {
                    Text("Organizations, students, groups, contacts, enrollments, schedules, lessons, attendance, payments, and notes.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Database Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .disabled(storage.isWorking)
            .overlay {
                if storage.isWorking {
                    ProgressView(storage.status)
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .fileExporter(
                isPresented: $showExporter,
                document: document,
                contentType: NumbersWorkbookBackup.contentType,
                defaultFilename: "TeacherOrganizer-Backup-\(Date.now.formatted(.iso8601.year().month().day().dateSeparator(.dash)))"
            ) { result in
                if case .failure(let error) = result {
                    message = error.localizedDescription
                }
                document = nil
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [NumbersWorkbookBackup.contentType]
            ) { result in
                do {
                    let url = try result.get()
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                    let data = try Data(contentsOf: url)
                    switch importMode {
                    case .full:
                        pendingSnapshot = try NumbersWorkbookBackup.read(data)
                        showRestoreConfirmation = true
                    case .newStudents:
                        pendingStudents = try NumbersWorkbookBackup.readNewStudents(data)
                        if pendingStudents.isEmpty {
                            message = "The New Students sheet has no students to add."
                        } else {
                            showStudentsConfirmation = true
                        }
                    }
                } catch {
                    message = error.localizedDescription
                }
            }
            .confirmationDialog(
                "Replace the complete database?",
                isPresented: $showRestoreConfirmation
            ) {
                Button("Restore \(pendingSnapshot?.recordCount ?? 0) Records", role: .destructive) {
                    guard let snapshot = pendingSnapshot else { return }
                    pendingSnapshot = nil
                    Task {
                        do {
                            try await storage.importBackup(snapshot)
                            dismiss()
                        } catch {
                            message = error.localizedDescription
                        }
                    }
                }
                Button("Cancel", role: .cancel) { pendingSnapshot = nil }
            } message: {
                Text("This replaces all current records on this device. If iCloud database storage is enabled, the restored records will also replace its cloud copy after sync.")
            }
            .confirmationDialog(
                "Add \(pendingStudents.count) students?",
                isPresented: $showStudentsConfirmation
            ) {
                Button("Add Students") {
                    let students = pendingStudents
                    pendingStudents = []
                    Task {
                        do {
                            let count = try await storage.importNewStudents(students)
                            message = count == 0
                                ? "These rows were already imported from this workbook."
                                : "Added \(count) students. Other records were unchanged."
                        } catch {
                            message = error.localizedDescription
                        }
                    }
                }
                Button("Cancel", role: .cancel) { pendingStudents = [] }
            } message: {
                Text("Only rows on New Students will be added. Private students also get an individual group and enrollment. Existing records stay unchanged. Reimporting the same workbook skips rows already added.")
            }
            .alert("Database Workbook", isPresented: Binding(
                get: { message != nil },
                set: { if !$0 { message = nil } }
            )) {
                Button("OK") { message = nil }
            } message: {
                Text(message ?? "Unknown error")
            }
        }
    }

    private func export() {
        do {
            let snapshot = try storage.exportBackup()
            document = NumbersWorkbookDocument(data: try NumbersWorkbookBackup.make(snapshot))
            showExporter = true
        } catch {
            message = error.localizedDescription
        }
    }
}
