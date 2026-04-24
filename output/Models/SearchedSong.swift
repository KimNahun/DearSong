import Foundation

// MARK: - SearchedSong

nonisolated struct SearchedSong: Identifiable, Sendable {
    let id: String
    var title: String
    var artistName: String
    var artworkURL: URL?
    var albumTitle: String?
}
