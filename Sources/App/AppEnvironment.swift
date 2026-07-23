import CloudKit
import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let cloudKitService: CloudKitService
    let recipeRepository: RecipeRepository
    let reviewRepository: ReviewRepository
    let fridgeItemRepository: FridgeItemRepository
    let pollRepository: PollRepository
    let weeklyWishRepository: WeeklyWishRepository

    @Published private(set) var currentMemberID: String

    private static let memberIDDefaultsKey = "local.currentMemberID"

    init(cloudKitService: CloudKitService = CloudKitService()) {
        self.cloudKitService = cloudKitService
        self.recipeRepository = CloudKitRecipeRepository(service: cloudKitService)
        self.reviewRepository = CloudKitReviewRepository(service: cloudKitService)
        self.fridgeItemRepository = CloudKitFridgeItemRepository(service: cloudKitService)
        self.pollRepository = CloudKitPollRepository(service: cloudKitService)
        self.weeklyWishRepository = CloudKitWeeklyWishRepository(service: cloudKitService)
        self.currentMemberID = AppEnvironment.loadLocalMemberID()
    }

    /// 実際の iCloud ユーザーIDが解決できたら、ローカル生成の仮IDから差し替える。
    func resolveCurrentMemberID() async {
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
