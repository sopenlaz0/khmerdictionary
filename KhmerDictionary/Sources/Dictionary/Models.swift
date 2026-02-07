import Foundation

struct WordSummary: Identifiable, Equatable, Sendable {
    let id: Int64
    let word: String
    let definition: String
    let previewDefinition: String
    var isBookmarked: Bool
}

struct WordDetail: Identifiable, Equatable, Sendable {
    let id: Int64
    let word: String
    let definition: String
    var isBookmarked: Bool
}
