import Foundation
import Supabase
import os

// MARK: - SongMemoryServiceProtocol

protocol SongMemoryServiceProtocol: Sendable {
    func fetchAllMemories(ownerId: UUID) async throws -> [SongMemory]
    func fetchMemoriesBySong(ownerId: UUID, appleMusicId: String) async throws -> [SongMemory]
    func fetchMemoriesBySongTitle(ownerId: UUID, songTitle: String, artistName: String) async throws -> [SongMemory]
    func createMemory(_ memory: SongMemory) async throws
    func addEntry(memoryId: UUID, entry: Entry) async throws
    func deleteMemory(memoryId: UUID) async throws
    func findExistingMemory(ownerId: UUID, appleMusicId: String?, songTitle: String, artistName: String, listenedAt: Date) async throws -> SongMemory?
}

// MARK: - NewSongMemoryPayload (INSERT 전용)

private struct NewSongMemoryPayload: Encodable {
    let ownerId: UUID
    let appleMusicId: String?
    let songTitle: String
    let artistName: String
    let artworkUrl: String?
    let listenedAt: String
    let moodTags: [String]
    let location: String?
    let entries: [Entry]
    let attachments: [Attachment]

    enum CodingKeys: String, CodingKey {
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
    }
}

// MARK: - UpdateEntriesPayload

private struct UpdateEntriesPayload: Encodable {
    let entries: [Entry]
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case entries
        case updatedAt = "updated_at"
    }
}

// MARK: - SongMemoryService

actor SongMemoryService: SongMemoryServiceProtocol {
    private let supabase: SupabaseClient
    private static let tableName = "song_memories"
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.nahun.DearSong", category: "SongMemoryService")

    init(supabase: SupabaseClient = SupabaseClientProvider.shared.client) {
        self.supabase = supabase
    }

    func fetchAllMemories(ownerId: UUID) async throws -> [SongMemory] {
        logger.info("전체 기억 로딩 시작")
        do {
            let memories: [SongMemory] = try await supabase
                .from(Self.tableName)
                .select()
                .eq("owner_id", value: ownerId.uuidString)
                .order("listened_at", ascending: false)
                .execute()
                .value
            logger.info("전체 기억 로딩 완료: \(memories.count)건")
            return memories
        } catch {
            logger.error("전체 기억 로딩 실패: \(error)")
            throw AppError.songMemory(.fetchFailed)
        }
    }

    func fetchMemoriesBySong(ownerId: UUID, appleMusicId: String) async throws -> [SongMemory] {
        do {
            let memories: [SongMemory] = try await supabase
                .from(Self.tableName)
                .select()
                .eq("owner_id", value: ownerId.uuidString)
                .eq("apple_music_id", value: appleMusicId)
                .order("listened_at", ascending: false)
                .execute()
                .value
            return memories
        } catch {
            throw AppError.songMemory(.fetchFailed)
        }
    }

    func fetchMemoriesBySongTitle(ownerId: UUID, songTitle: String, artistName: String) async throws -> [SongMemory] {
        do {
            let memories: [SongMemory] = try await supabase
                .from(Self.tableName)
                .select()
                .eq("owner_id", value: ownerId.uuidString)
                .eq("song_title", value: songTitle)
                .eq("artist_name", value: artistName)
                .order("listened_at", ascending: false)
                .execute()
                .value
            return memories
        } catch {
            throw AppError.songMemory(.fetchFailed)
        }
    }

    func createMemory(_ memory: SongMemory) async throws {
        logger.info("기억 생성 시작: \(memory.songTitle)")
        let listenedAtString = DateFormatters.yearOnly.string(from: memory.listenedAt) + "-01-01"
        let payload = NewSongMemoryPayload(
            ownerId: memory.ownerId,
            appleMusicId: memory.appleMusicId,
            songTitle: memory.songTitle,
            artistName: memory.artistName,
            artworkUrl: memory.artworkUrl,
            listenedAt: listenedAtString,
            moodTags: memory.moodTags,
            location: memory.location,
            entries: memory.entries,
            attachments: memory.attachments
        )
        do {
            try await supabase
                .from(Self.tableName)
                .insert(payload)
                .execute()
            logger.info("기억 생성 완료: \(memory.songTitle)")
        } catch {
            logger.error("기억 생성 실패: \(error)")
            throw AppError.songMemory(.createFailed)
        }
    }

    func addEntry(memoryId: UUID, entry: Entry) async throws {
        // 현재 entries를 가져온 뒤 append
        do {
            let memories: [SongMemory] = try await supabase
                .from(Self.tableName)
                .select()
                .eq("id", value: memoryId.uuidString)
                .limit(1)
                .execute()
                .value

            guard var memory = memories.first else {
                throw AppError.songMemory(.notFound)
            }

            memory.entries.append(entry)

            let isoFormatter = ISO8601DateFormatter()
            let payload = UpdateEntriesPayload(
                entries: memory.entries,
                updatedAt: isoFormatter.string(from: Date())
            )

            try await supabase
                .from(Self.tableName)
                .update(payload)
                .eq("id", value: memoryId.uuidString)
                .execute()
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.songMemory(.updateFailed)
        }
    }

    func deleteMemory(memoryId: UUID) async throws {
        logger.info("기억 삭제 시작: \(memoryId)")
        do {
            try await supabase
                .from(Self.tableName)
                .delete()
                .eq("id", value: memoryId.uuidString)
                .execute()
            logger.info("기억 삭제 완료: \(memoryId)")
        } catch {
            logger.error("기억 삭제 실패: \(error)")
            throw AppError.songMemory(.deleteFailed)
        }
    }

    func findExistingMemory(ownerId: UUID, appleMusicId: String?, songTitle: String, artistName: String, listenedAt: Date) async throws -> SongMemory? {
        let year = DateFormatters.year(from: listenedAt)
        let startDate = "\(year)-01-01"
        let endDate = "\(year)-12-31"

        do {
            var query = supabase
                .from(Self.tableName)
                .select()
                .eq("owner_id", value: ownerId.uuidString)
                .gte("listened_at", value: startDate)
                .lte("listened_at", value: endDate)

            if let musicId = appleMusicId, !musicId.isEmpty {
                query = query.eq("apple_music_id", value: musicId)
            } else {
                query = query
                    .eq("song_title", value: songTitle)
                    .eq("artist_name", value: artistName)
            }

            let memories: [SongMemory] = try await query
                .limit(1)
                .execute()
                .value

            return memories.first
        } catch {
            throw AppError.songMemory(.fetchFailed)
        }
    }
}
