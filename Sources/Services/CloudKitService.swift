import CloudKit

final class CloudKitService {
    static let containerIdentifier = "iCloud.com.babyucreate.wagayanokondate"
    static let familyZoneName = "FamilyZone"

    let container: CKContainer

    init(container: CKContainer = CKContainer(identifier: CloudKitService.containerIdentifier)) {
        self.container = container
    }

    var privateDatabase: CKDatabase { container.privateCloudDatabase }
    var sharedDatabase: CKDatabase { container.sharedCloudDatabase }

    /// 家族で共有するデータを保持する共有ゾーン。オーナーの Private DB に作成し、CKShare で家族を招待する。
    private(set) lazy var familyZoneID = CKRecordZone.ID(zoneName: CloudKitService.familyZoneName, ownerName: CKCurrentUserDefaultName)

    func ensureFamilyZoneExists() async throws {
        let zone = CKRecordZone(zoneID: familyZoneID)
        _ = try await privateDatabase.save(zone)
    }

    /// アプリ起動時に一度だけ呼ぶ想定のゾーン準備処理。
    /// すでに誰かの家族に招待されている（Shared DBにFamilyZoneがある）場合は何もしない。
    /// そうでなければ、自分がオーナーとして家族ゾーンを（まだ無ければ）作成する。
    /// これを呼ばずに各画面が先にデータへアクセスすると、初回起動時に familyZoneNotFound で失敗する。
    func bootstrapFamilyZoneIfNeeded() async {
        if let sharedZones = try? await sharedDatabase.allRecordZones(),
           sharedZones.contains(where: { $0.zoneID.zoneName == CloudKitService.familyZoneName }) {
            return
        }
        _ = try? await ensureFamilyZoneExists()
    }

    /// 家族ゾーンの CKShare を作成する。まだ共有されていない場合は新規作成し、招待用の UICloudSharingController に渡す。
    func fetchOrCreateFamilyShare() async throws -> CKShare {
        let zone = try await privateDatabase.recordZone(for: familyZoneID)

        if let existingShareReference = zone.share {
            let record = try await privateDatabase.record(for: existingShareReference.recordID)
            if let share = record as? CKShare {
                return share
            }
        }

        let share = CKShare(recordZoneID: familyZoneID)
        share[CKShare.SystemFieldKey.title] = "わが家の献立" as CKRecordValue
        let saveResult = try await privateDatabase.modifyRecords(saving: [share], deleting: [])
        guard let savedShare = try saveResult.saveResults[share.recordID]?.get() as? CKShare else {
            throw CloudKitServiceError.shareCreationFailed
        }
        return savedShare
    }

    /// 現在このデバイスが「共有される側（参加者）」かどうかを判定し、書き込みに使うデータベースとゾーンを返す。
    func resolveWritableTarget() async throws -> (database: CKDatabase, zoneID: CKRecordZone.ID) {
        do {
            _ = try await privateDatabase.recordZone(for: familyZoneID)
            return (privateDatabase, familyZoneID)
        } catch {
            let sharedZones = try await sharedDatabase.allRecordZones()
            guard let zone = sharedZones.first(where: { $0.zoneID.zoneName == CloudKitService.familyZoneName }) else {
                throw CloudKitServiceError.familyZoneNotFound
            }
            return (sharedDatabase, zone.zoneID)
        }
    }

    /// 既存レコードでも上書き保存する（家族の共同編集なので「最後の書き込みを優先」）。
    ///
    /// `CKDatabase.save(_:)` は `.ifServerRecordUnchanged` ポリシーのため、
    /// 決定的ID（レシピID・評価のrecipeID_memberID等）で作り直したレコードを再保存すると、
    /// ローカルの変更タグがサーバーと一致せず `serverRecordChanged` で失敗してしまう。
    /// レシピ編集・評価の付け直し・投票のやり直し・名前/アイコン変更などが実運用で失敗するため、
    /// 上書きを許す `.allKeys` ポリシーで modifyRecords を使う。
    func upsert(_ record: CKRecord, in database: CKDatabase) async throws -> CKRecord {
        let result = try await database.modifyRecords(saving: [record], deleting: [], savePolicy: .allKeys)
        guard let saved = try result.saveResults[record.recordID]?.get() else {
            throw CloudKitServiceError.saveFailed
        }
        return saved
    }
}

enum CloudKitServiceError: Error {
    case shareCreationFailed
    case familyZoneNotFound
    case saveFailed
}
