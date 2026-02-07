import Foundation

protocol DictionaryRepository: Sendable {
    func searchWords(rawSearchTerm: String, limit: Int) async throws -> [WordSummary]
    func getWordByID(_ wordID: Int64) async throws -> WordDetail?
    func listBookmarks(limit: Int) async throws -> [WordSummary]
    func listHistory(limit: Int) async throws -> [WordSummary]
    func setBookmark(wordID: Int64, isCurrentlyBookmarked: Bool) async throws
    func addToHistory(wordID: Int64) async throws
    func currentDictionaryVersionCode() async throws -> Int?
    func setDictionaryVersionCode(_ versionCode: Int) async throws
}
