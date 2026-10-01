import Combine
import Foundation
import SwiftData

enum DatabaseLocation: String, CaseIterable, Identifiable {
    case phone
    case cloud

    var id: String { rawValue }
    var title: String { self == .phone ? "On This iPhone" : "iCloud" }
}

@MainActor
final class StorageCoordinator: ObservableObject {
    enum StorageError: LocalizedError {
        case unavailable
        case cloudCopyExists

        var errorDescription: String? {
            switch self {
            case .unavailable: "The database is still opening. Try again shortly."
            case .cloudCopyExists:
                "iCloud already contains a TeachTrack database. Confirm replacing that copy before continuing."
            }
        }
    }

    @Published private(set) var location: DatabaseLocation
    @Published private(set) var isWorking = false
    @Published private(set) var status = ""
    @Published private(set) var generation = 0

    private enum Keys {
        static let location = "TeachTrack.databaseLocation"
        static let cloudRevision = "TeachTrack.cloudRevision"
        static let pendingUpload = "TeachTrack.pendingCloudUpload"
    }

    private let cloud = CloudDatabaseStore()
    private var context: ModelContext?
    private var saveObserver: NSObjectProtocol?
    private var uploadTask: Task<Void, Never>?
    private var cloudRevision: String?
    private var pendingUpload: Bool
    private var changeCounter = 0

    init() {
        let defaults = UserDefaults.standard
        location = DatabaseLocation(rawValue: defaults.string(forKey: Keys.location) ?? "") ?? .phone
        cloudRevision = defaults.string(forKey: Keys.cloudRevision)
        pendingUpload = defaults.bool(forKey: Keys.pendingUpload)
    }

    deinit {
        if let saveObserver { NotificationCenter.default.removeObserver(saveObserver) }
        uploadTask?.cancel()
    }

    func connect(_ modelContext: ModelContext) {
        guard context !== modelContext || saveObserver == nil else { return }
        if let saveObserver { NotificationCenter.default.removeObserver(saveObserver) }
        context = modelContext
        saveObserver = NotificationCenter.default.addObserver(
            forName: ModelContext.didSave, object: modelContext, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.didSave() }
        }
    }

    private func didSave() {
        changeCounter += 1
        guard location == .cloud else { return }
        setPendingUpload(true)
        scheduleUpload()
    }

    private func setLocation(_ newLocation: DatabaseLocation) {
        location = newLocation
        UserDefaults.standard.set(newLocation.rawValue, forKey: Keys.location)
    }

    private func setCloudRevision(_ revision: String?) {
        cloudRevision = revision
        UserDefaults.standard.set(revision, forKey: Keys.cloudRevision)
    }

    private func setPendingUpload(_ pending: Bool) {
        pendingUpload = pending
        UserDefaults.standard.set(pending, forKey: Keys.pendingUpload)
    }

    private func scheduleUpload() {
        uploadTask?.cancel()
        uploadTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            await self?.refresh()
        }
    }

    private func suspendSaveObservation() {
        if let saveObserver { NotificationCenter.default.removeObserver(saveObserver) }
        saveObserver = nil
    }

    private func resumeSaveObservation() {
        if let context { connect(context) }
    }

    private func saveAndCapture() throws -> DatabaseSnapshot {
        guard let context else { throw StorageError.unavailable }
        suspendSaveObservation()
        defer { resumeSaveObservation() }
        if context.hasChanges { try context.save() }
        return try DatabaseSnapshot.capture(from: context)
    }

    private func uploadPendingChanges() async throws {
        guard pendingUpload else { return }
        let currentChange = changeCounter
        let snapshot = try saveAndCapture()
        let revision = try await cloud.upload(snapshot, expectedRevision: cloudRevision)
        setCloudRevision(revision)
        if changeCounter == currentChange {
            setPendingUpload(false)
            status = "Saved to iCloud"
        } else {
            scheduleUpload()
        }
    }

    func enableCloud(replaceExisting: Bool = false) async throws {
        guard location == .phone else { return }
        guard !isWorking else { return }
        isWorking = true
        status = "Copying database to iCloud…"
        defer { isWorking = false }

        let snapshot = try saveAndCapture()
        let capturedChange = changeCounter
        let existing = try await cloud.download()
        guard existing == nil || replaceExisting else {
            status = "Cloud copy already exists"
            throw StorageError.cloudCopyExists
        }
        let revision = try await cloud.upload(
            snapshot, expectedRevision: existing?.revision
        )
        setCloudRevision(revision)
        setLocation(.cloud)
        let changedDuringTransfer = changeCounter != capturedChange || context?.hasChanges == true
        setPendingUpload(changedDuringTransfer)
        if changedDuringTransfer { scheduleUpload() }
        status = changedDuringTransfer
            ? "Cloud copy created; recent changes are still syncing"
            : "Database copied to iCloud"
    }

    func disableCloud() async throws {
        guard location == .cloud else { return }
        guard !isWorking else { return }
        isWorking = true
        status = "Copying database to this iPhone…"
        uploadTask?.cancel()
        defer { isWorking = false }

        if pendingUpload { try await uploadPendingChanges() }
        let capturedChange = changeCounter
        if let remote = try await cloud.download() {
            // A save during the download must not be overwritten by a remote restore.
            guard changeCounter == capturedChange, context?.hasChanges != true,
                  !pendingUpload else {
                throw CloudDatabaseStore.StorageError.conflict
            }
            if remote.revision != cloudRevision {
                try restore(remote.snapshot)
                generation += 1
            }
            try await cloud.delete(expectedRevision: remote.revision)
        }
        setLocation(.phone)
        setCloudRevision(nil)
        setPendingUpload(false)
        status = "Stored only on this iPhone; cloud copy deleted"
    }

    func clearDatabase() async throws {
        guard !isWorking else { return }
        guard let context else { throw StorageError.unavailable }
        isWorking = true
        status = "Deleting database…"
        uploadTask?.cancel()
        defer { isWorking = false }

        if location == .cloud {
            // Never remove the local copy if CloudKit cannot confirm deletion.
            let remote = try await cloud.download()
            try await cloud.delete(expectedRevision: remote?.revision)
        }
        suspendSaveObservation()
        defer { resumeSaveObservation() }
        try DatabaseSnapshot.clear(context)
        setLocation(.phone)
        setCloudRevision(nil)
        setPendingUpload(false)
        status = "Database deleted"
        generation += 1
    }

    func checkCloudConnection() async throws {
        guard !isWorking else { return }
        isWorking = true
        status = "Checking iCloud…"
        defer { isWorking = false }

        do {
            let remote = try await cloud.download()
            status = remote == nil
                ? "iCloud is available; no TeachTrack database is stored there"
                : "iCloud is available; a TeachTrack database is stored there"
        } catch {
            status = "iCloud connection failed"
            throw error
        }
    }

    func refresh() async {
        guard location == .cloud, !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            if context?.hasChanges == true { setPendingUpload(true) }
            if pendingUpload {
                try await uploadPendingChanges()
                return
            }
            let capturedChange = changeCounter
            guard let remote = try await cloud.download() else {
                // Another device removed the cloud database. Keep the local copy.
                setLocation(.phone)
                setCloudRevision(nil)
                status = "Cloud copy is gone; local database kept"
                return
            }
            if changeCounter != capturedChange || context?.hasChanges == true || pendingUpload {
                setPendingUpload(true)
                scheduleUpload()
                return
            }
            if remote.revision != cloudRevision {
                try restore(remote.snapshot)
                setCloudRevision(remote.revision)
                generation += 1
            }
            status = "iCloud is up to date"
        } catch {
            status = "iCloud sync paused: \(error.localizedDescription)"
        }
    }

    private func restore(_ snapshot: DatabaseSnapshot) throws {
        guard let context else { throw StorageError.unavailable }
        suspendSaveObservation()
        defer { resumeSaveObservation() }
        try snapshot.restore(into: context)
    }
}
