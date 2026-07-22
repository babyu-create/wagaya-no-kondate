import Foundation

enum PollType: String, Codable, CaseIterable {
    case curated
    case topRated
    case byGenre
}

enum PollStatus: String, Codable {
    case open
    case closed
}

struct Poll: Identifiable, Codable, Hashable {
    var id: String
    var date: Date
    var type: PollType
    var genre: Genre?
    var status: PollStatus
    var deadline: Date?
    var createdByMemberID: String

    init(
        id: String = UUID().uuidString,
        date: Date = Date(),
        type: PollType,
        genre: Genre? = nil,
        status: PollStatus = .open,
        deadline: Date? = nil,
        createdByMemberID: String
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.genre = genre
        self.status = status
        self.deadline = deadline
        self.createdByMemberID = createdByMemberID
    }
}

struct PollOption: Identifiable, Codable, Hashable {
    var id: String
    var pollID: String
    var recipeID: String

    init(id: String = UUID().uuidString, pollID: String, recipeID: String) {
        self.id = id
        self.pollID = pollID
        self.recipeID = recipeID
    }
}

struct Vote: Identifiable, Codable, Hashable {
    var id: String
    var pollID: String
    var pollOptionID: String
    var memberID: String
    var votedAt: Date

    init(
        id: String = UUID().uuidString,
        pollID: String,
        pollOptionID: String,
        memberID: String,
        votedAt: Date = Date()
    ) {
        self.id = id
        self.pollID = pollID
        self.pollOptionID = pollOptionID
        self.memberID = memberID
        self.votedAt = votedAt
    }
}
