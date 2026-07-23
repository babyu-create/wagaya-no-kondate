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
    let familyMemberRepository: FamilyMemberRepository
    let memberDirectory: MemberDirectory

    @Published private(set) var currentMemberID: String
    @Published private(set) var isBootstrapped = false

    private static let memberIDDefaultsKey = "local.currentMemberID"
    private static let familyMemberID = "family-member-2"

    /// XCTestのホストアプリとして起動された場合はtrue（ユニットテストはこの方式で検知できる）。
    private static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    /// UIテストのランナーから起動された場合はtrue。UIテストはアプリを別プロセスとして起動するため
    /// XCTestConfigurationFilePathでは検知できず、launchArgumentsで明示的にフラグを渡す。
    private static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("UI_TESTING")
    }

    /// 実機/実iCloudアカウントのないCI環境で実CloudKitへアクセスするとハング・クラッシュするため、
    /// テスト実行時は一切CloudKitに触れずインメモリ実装で動作させる。
    private static var shouldUseInMemoryRepositories: Bool {
        isRunningUnitTests || isUITesting
    }

    init() {
        if AppEnvironment.shouldUseInMemoryRepositories {
            self.cloudKitService = nil
            self.recipeRepository = InMemoryRecipeRepository()
            self.reviewRepository = InMemoryReviewRepository()
            self.fridgeItemRepository = InMemoryFridgeItemRepository()
            self.pollRepository = InMemoryPollRepository()
            self.weeklyWishRepository = InMemoryWeeklyWishRepository()
            self.familyMemberRepository = InMemoryFamilyMemberRepository()
            self.currentMemberID = "test-member"
        } else {
            let service = CloudKitService()
            self.cloudKitService = service
            self.recipeRepository = CloudKitRecipeRepository(service: service)
            self.reviewRepository = CloudKitReviewRepository(service: service)
            self.fridgeItemRepository = CloudKitFridgeItemRepository(service: service)
            self.pollRepository = CloudKitPollRepository(service: service)
            self.weeklyWishRepository = CloudKitWeeklyWishRepository(service: service)
            self.familyMemberRepository = CloudKitFamilyMemberRepository(service: service)
            self.currentMemberID = AppEnvironment.loadLocalMemberID()
        }
        self.memberDirectory = MemberDirectory(repository: familyMemberRepository)
    }

    /// アプリ起動時に一度だけ呼ぶ。実際の iCloud ユーザーID解決・家族ゾーンの準備・
    /// メンバー名簿の読み込みが終わるまで isBootstrapped は false のままにし、
    /// 呼び出し側（WagayaNoKondateApp）はこれが true になるまで画面表示を待つ。
    /// これにより、ゾーンが無い状態で各タブが先にデータへアクセスして
    /// familyZoneNotFound エラーになる問題を防ぐ。
    func bootstrap() async {
        await resolveCurrentMemberID()
        await seedSampleDataIfNeeded()
        if let cloudKitService {
            await cloudKitService.bootstrapFamilyZoneIfNeeded()
        }
        await memberDirectory.loadAll()
        isBootstrapped = true
    }

    /// 実際の iCloud ユーザーIDが解決できたら、ローカル生成の仮IDから差し替える。
    private func resolveCurrentMemberID() async {
        guard let cloudKitService else { return }
        guard let recordID = try? await cloudKitService.container.userRecordID() else { return }
        currentMemberID = recordID.recordName
        UserDefaults.standard.set(recordID.recordName, forKey: Self.memberIDDefaultsKey)
    }

    /// UIテスト（スクリーンショット撮影）でアプリの見た目を確認しやすくするためのサンプルデータ投入。
    /// UIテスト実行時のみ動作し、実アプリ・ユニットテストには一切影響しない。
    private func seedSampleDataIfNeeded() async {
        guard AppEnvironment.isUITesting else { return }

        _ = try? await familyMemberRepository.upsert(FamilyMember(id: currentMemberID, displayName: "あなた"))
        _ = try? await familyMemberRepository.upsert(FamilyMember(id: Self.familyMemberID, displayName: "お母さん"))

        let curry = Recipe(
            title: "鶏肉の甘辛カレー",
            instructions: "1. 鶏肉と野菜を一口大に切る\n2. 油で炒めて水を加え煮込む\n3. ルーを溶かして完成",
            servings: 4,
            costPerServing: 180,
            genre: .other,
            ingredients: [
                Ingredient(displayName: "鶏もも肉", amount: "300g"),
                Ingredient(displayName: "じゃがいも", amount: "2個"),
                Ingredient(displayName: "にんじん", amount: "1本"),
                Ingredient(displayName: "カレールー", amount: "1箱")
            ],
            createdByMemberID: currentMemberID
        )
        let misoSoup = Recipe(
            title: "豆腐とわかめの味噌汁",
            instructions: "1. 出汁をとる\n2. 具材を入れて味噌を溶く",
            servings: 4,
            costPerServing: 60,
            genre: .japanese,
            ingredients: [
                Ingredient(displayName: "豆腐", amount: "半丁"),
                Ingredient(displayName: "わかめ", amount: "少々"),
                Ingredient(displayName: "味噌", amount: "大さじ2")
            ],
            createdByMemberID: currentMemberID
        )
        let pasta = Recipe(
            title: "トマトとバジルのパスタ",
            instructions: "1. パスタを茹でる\n2. ソースを絡めて盛り付ける",
            servings: 2,
            costPerServing: 220,
            genre: .western,
            ingredients: [
                Ingredient(displayName: "パスタ", amount: "200g"),
                Ingredient(displayName: "トマト缶", amount: "1缶"),
                Ingredient(displayName: "バジル", amount: "少々")
            ],
            createdByMemberID: currentMemberID
        )

        let savedCurry = try? await recipeRepository.save(curry)
        let savedMiso = try? await recipeRepository.save(misoSoup)
        let savedPasta = try? await recipeRepository.save(pasta)

        if let savedCurry {
            _ = try? await reviewRepository.upsert(recipeID: savedCurry.id, memberID: currentMemberID, rating: 5, comment: nil)
            _ = try? await reviewRepository.upsert(recipeID: savedCurry.id, memberID: Self.familyMemberID, rating: 4, comment: nil)
        }
        if let savedMiso {
            _ = try? await reviewRepository.upsert(recipeID: savedMiso.id, memberID: currentMemberID, rating: 4, comment: nil)
        }

        for name in ["じゃがいも", "にんじん", "豆腐", "わかめ", "味噌"] {
            _ = try? await fridgeItemRepository.save(FridgeItem(displayName: name, updatedByMemberID: currentMemberID))
        }

        if let savedCurry, let savedMiso, let savedPasta {
            let created = try? await pollRepository.createPoll(
                type: .curated,
                genre: nil,
                deadline: nil,
                recipeIDs: [savedCurry.id, savedMiso.id, savedPasta.id],
                createdByMemberID: currentMemberID
            )
            if let created {
                if let firstOption = created.options.first {
                    _ = try? await pollRepository.vote(pollID: created.poll.id, pollOptionID: firstOption.id, memberID: currentMemberID)
                }
                if created.options.count > 1 {
                    _ = try? await pollRepository.vote(
                        pollID: created.poll.id,
                        pollOptionID: created.options[1].id,
                        memberID: Self.familyMemberID
                    )
                }
            }
        }

        if let savedCurry {
            _ = try? await weeklyWishRepository.toggle(
                recipeID: savedCurry.id,
                memberID: currentMemberID,
                weekOf: WeekIdentifier.current()
            )
        }
        if let savedPasta {
            _ = try? await weeklyWishRepository.toggle(
                recipeID: savedPasta.id,
                memberID: Self.familyMemberID,
                weekOf: WeekIdentifier.current()
            )
        }
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
