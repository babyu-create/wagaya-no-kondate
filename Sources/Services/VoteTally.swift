import Foundation

enum VoteTally {
    struct Result: Identifiable {
        var id: String { optionID }
        let optionID: String
        let recipeID: String
        let count: Int
    }

    static func tally(options: [PollOption], votes: [Vote]) -> [Result] {
        let counts = Dictionary(grouping: votes, by: \.pollOptionID).mapValues(\.count)
        return options
            .map { option in
                Result(optionID: option.id, recipeID: option.recipeID, count: counts[option.id] ?? 0)
            }
            .sorted { $0.count > $1.count }
    }

    static func winner(options: [PollOption], votes: [Vote]) -> Result? {
        tally(options: options, votes: votes).first
    }

    /// 得票率(0.0〜1.0)。総投票数が0のときは0を返す。得票バーの表示に使う。
    static func share(count: Int, total: Int) -> Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }
}

/// 投票の締め切り判定。締め切り日時が設定されていて、それを過ぎていれば締め切り済みとみなす。
enum PollDeadline {
    static func isExpired(_ poll: Poll, now: Date) -> Bool {
        guard let deadline = poll.deadline else { return false }
        return now >= deadline
    }
}
