import Foundation

// MARK: - SongMemory

struct SongMemory: Identifiable, Sendable, Codable {
    let id: UUID
    let ownerId: UUID
    var appleMusicId: String?
    var songTitle: String
    var artistName: String
    var artworkUrl: String?
    var listenedAt: Date
    var moodTags: [String]
    var location: String?
    var entries: [Entry]
    var attachments: [Attachment]
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case appleMusicId = "apple_music_id"
        case songTitle = "song_title"
        case artistName = "artist_name"
        case artworkUrl = "artwork_url"
        case listenedAt = "listened_at"
        case moodTags = "mood_tags"
        case location
        case entries
        case attachments
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Entry

struct Entry: Identifiable, Sendable, Codable {
    let id: UUID
    var text: String
    var writtenAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case writtenAt = "written_at"
    }
}

// MARK: - Attachment (v1 미사용 — 스키마 예비)

struct Attachment: Identifiable, Sendable, Codable {
    let id: UUID
    var type: String
    var url: String
}

// MARK: - GroupedSong (View 전용 구조체)

struct GroupedSong: Identifiable, Sendable {
    let id: String
    let appleMusicId: String?
    let songTitle: String
    let artistName: String
    let artworkUrl: String?
    let memoryCount: Int
    let memories: [SongMemory]

    init(memories: [SongMemory]) {
        self.memories = memories
        let first = memories[0]
        self.appleMusicId = first.appleMusicId
        self.songTitle = first.songTitle
        self.artistName = first.artistName
        self.artworkUrl = first.artworkUrl
        self.memoryCount = memories.count
        self.id = first.appleMusicId ?? "\(first.songTitle)-\(first.artistName)"
    }
}
