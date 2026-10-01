import CloudKit
import Foundation

/// Explicit CloudKit archive storage, separate from SwiftData's local store.
/// The current SwiftData schema cannot use automatic CloudKit mirroring.
struct CloudDatabaseStore {
    static var isConfigured: Bool {
        guard let identifier = Bundle.main.object(
            forInfoDictionaryKey: "TeachTrackCloudKitContainer"
        ) as? String else { return false }
        return !identifier.isEmpty
    }

    struct RemoteCopy {
        let snapshot: DatabaseSnapshot
        let revision: String
    }

    enum StorageError: LocalizedError {
        case missingContainer
        case noAccount
        case incompleteRecord
        case conflict

        var errorDescription: String? {
            switch self {
            case .missingContainer:
                "No CloudKit container is configured for TeachTrack in Xcode."
            case .noAccount:
                "Sign in to iCloud on this device before choosing cloud storage."
            case .incompleteRecord:
                "The cloud database copy is incomplete. Local data was not changed."
            case .conflict:
                "The cloud database changed on another device. Nothing was overwritten; review the cloud copy before retrying."
            }
        }
    }

    private let recordID = CKRecord.ID(recordName: "TeachTrackDatabase-v1")
    private let recordType = "TeachTrackDatabase"

    private func configuredContainer() throws -> CKContainer {
        guard let identifier = Bundle.main.object(
            forInfoDictionaryKey: "TeachTrackCloudKitContainer"
        ) as? String, !identifier.isEmpty else {
            throw StorageError.missingContainer
        }
        return CKContainer(identifier: identifier)
    }

    private func database() throws -> CKDatabase {
        try configuredContainer().privateCloudDatabase
    }

    func verifyAvailability() async throws {
        guard try await configuredContainer().accountStatus() == .available else {
            throw StorageError.noAccount
        }
    }

    private func existingRecord() async throws -> CKRecord? {
        do {
            return try await database().record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }

    func download() async throws -> RemoteCopy? {
        try await verifyAvailability()
        guard let record = try await existingRecord() else { return nil }
        guard let asset = record["archive"] as? CKAsset,
              let fileURL = asset.fileURL,
              let revision = record["revision"] as? String else {
            throw StorageError.incompleteRecord
        }
        let data = try Data(contentsOf: fileURL)
        let snapshot = try JSONDecoder().decode(DatabaseSnapshot.self, from: data)
        try snapshot.validate()
        return RemoteCopy(snapshot: snapshot, revision: revision)
    }

    func upload(_ snapshot: DatabaseSnapshot, expectedRevision: String?) async throws -> String {
        try await verifyAvailability()
        try snapshot.validate()
        let current = try await existingRecord()
        let currentRevision = current?["revision"] as? String
        guard currentRevision == expectedRevision else { throw StorageError.conflict }

        let record = current ?? CKRecord(recordType: recordType, recordID: recordID)
        let revision = UUID().uuidString
        let temporaryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("TeachTrack-\(revision).json")
        defer { try? FileManager.default.removeItem(at: temporaryURL) }
        try JSONEncoder().encode(snapshot).write(to: temporaryURL, options: .atomic)
        record["archive"] = CKAsset(fileURL: temporaryURL)
        record["revision"] = revision as CKRecordValue
        do {
            _ = try await database().save(record)
        } catch let error as CKError where error.code == .serverRecordChanged {
            throw StorageError.conflict
        }
        return revision
    }

    func delete(expectedRevision: String?) async throws {
        try await verifyAvailability()
        guard let current = try await existingRecord() else { return }
        guard (current["revision"] as? String) == expectedRevision else {
            throw StorageError.conflict
        }
        _ = try await database().deleteRecord(withID: recordID)
    }
}
