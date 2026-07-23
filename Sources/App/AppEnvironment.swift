import CloudKit
import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let cloudKitService: CloudKitService?
    let recipeRepository: RecipeRepository
    let reviewRepository: ReviewRepository
    let fridgeItemRepository: FridgeItemRepository
    let pollRepository: PollRepository
    let weeklyWishRepository: WeeklyWishRepository

    @Published private(set) var currentMemberID: String

    private static let memberIDDefaultsKey = "local.currentMemberID"

    /// XCTestのホストアプリとして起動された場合はtrue。ユニットテスト実行時、実機/実iCloudアカウントの
    /// ないCI環境で実CloudKitへアクセスするとハング・クラッシュするため、この場合は一切CloudKitに触れない。
    private static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    init() {
        if AppEnvironment.isRunningUnitTests {
            self.cloudKitService = nil
            self.recipeRepository = InMemoryRecipeRepository()
            self.reviewRepository = InMemoryReviewRepository()
            self.fridgeItemRepository = InMemoryFridgeItemRepository()
            self.pollRepository = InMemoryPollRepository()
            self.weeklyWishRepository = InMemoryWeeklyWishRepository()
            self.currentMemberID = "test-member"
        } else {
            let service = CloudKitService()
            self.cloudKitService = service
            self.recipeRepository = CloudKitRecipeRepository(service: service)
            self.reviewRepository = CloudKitReviewRepository(service: service)
            self.fridgeItemRepository = CloudKitFridgeItemRepository(service: service)
            self.pollRepository = CloudKitPollRepository(service: service)
            self.weeklyWishRepository = CloudKitWeeklyWishRepository(service: service)
            self.currentMemberID = AppEnvironment.loadLocalMemberID()
        }
    }

    /// 実際の iCloud ユーザーIDが解決できたら、ローカル生成の仮IDから差し替える。
    func resolveCurrentMemberID() async {
        guard let cloudKitService else { return }
        guard let recordID = try? await cloudKitService.container.userRecordID() else { return }
        currentMemberID = recordID.recordName
        UserDefaults.standard.set(recordID.recordName, forKey: Self.memberIDDefaultsKey)
    }

    private static func loadLocalMemberID() -> String {
        if let saved = UserDefaults.standard.string(forKey: memberIDDefaultsKey) {
            return saved
        }
        let generated = UUID().uuidString
        UserDefaults.standard.set(generated, forKey: memberIDDefaultsKey)
        return generated
    }
}
