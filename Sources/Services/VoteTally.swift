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
}
