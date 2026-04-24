import Foundation
import Supabase
@testable import DearSong

// MARK: - MockAuthService

struct MockAuthService: AuthServiceProtocol {
    var sessionUserId: UUID? = nil
    var shouldFailSignIn: Bool = false
    var shouldFailSignOut: Bool = false

    init(sessionUserId: UUID? = nil, shouldFailSignIn: Bool = false, shouldFailSignOut: Bool = false) {
        self.sessionUserId = sessionUserId
        self.shouldFailSignIn = shouldFailSignIn
        self.shouldFailSignOut = shouldFailSignOut
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> UUID {
        if shouldFailSignIn { throw AppError.auth(.invalidCredentials) }
        return sessionUserId ?? UUID()
    }

    func getCurrentSession() async throws -> Session? {
        return nil
    }

    func getCurrentUserId() async throws -> UUID {
        guard let userId = sessionUserId else {
            throw AppError.auth(.noSession)
        }
        return userId
    }

    func signOut() async throws {
        if shouldFailSignOut { throw AppError.auth(.signOutFailed) }
    }
}

// MARK: - MockSongMemoryService

actor MockSongMemoryService: SongMemoryServiceProtocol {
    var memoriesStore: [SongMemory]
    var shouldFail: Bool
    var addedEntry: Entry?

    init(memoriesStore: [SongMemory] = [], shouldFail: Bool = false) {
        self.memoriesStore = memoriesStore
        self.shouldFail = shouldFail
    }

    func fetchAllMemories(ownerId: UUID) async throws -> [SongMemory] {
        if shouldFail { throw AppError.songMemory(.fetchFailed) }
        return memoriesStore.filter { $0.ownerId == ownerId }
    }

    func fetchMemoriesBySong(ownerId: UUID, appleMusicId: String) async throws -> [SongMemory] {
        if shouldFail { throw AppError.songMemory(.fetchFailed) }
        return memoriesStore.filter { $0.ownerId == ownerId && $0.appleMusicId == appleMusicId }
    }

    func fetchMemoriesBySongTitle(ownerId: UUID, songTitle: String, artistName: String) async throws -> [SongMemory] {
        if shouldFail { throw AppError.songMemory(.fetchFailed) }
        return memoriesStore.filter { $0.ownerId == ownerId && $0.songTitle == songTitle && $0.artistName == artistName }
    }

    func createMemory(_ memory: SongMemory) async throws {
        if shouldFail { throw AppError.songMemory(.createFailed) }
        memoriesStore.append(memory)
    }

    func addEntry(memoryId: UUID, entry: Entry) async throws {
        if shouldFail { throw AppError.songMemory(.updateFailed) }
        addedEntry = entry
        if let index = memoriesStore.firstIndex(where: { $0.id == memoryId }) {
            memoriesStore[index].entries.append(entry)
        }
    }

    func deleteMemory(memoryId: UUID) async throws {
        if shouldFail { throw AppError.songMemory(.deleteFailed) }
        memoriesStore.removeAll { $0.id == memoryId }
    }

    func findExistingMemory(ownerId: UUID, appleMusicId: String?, songTitle: String, artistName: String, listenedAt: Date) async throws -> SongMemory? {
        if shouldFail { throw AppError.songMemory(.fetchFailed) }
        let year = DateFormatters.year(from: listenedAt)
        return memoriesStore.first { memory in
            memory.ownerId == ownerId &&
            DateFormatters.year(from: memory.listenedAt) == year &&
            (appleMusicId != nil ? memory.appleMusicId == appleMusicId : memory.songTitle == songTitle)
        }
    }
}

// MARK: - MockMusicSearchService

actor MockMusicSearchService: MusicSearchServiceProtocol {
    var authStatus: MusicAuthStatus
    var searchResults: [SearchedSong]
    var shouldFail: Bool

    init(
        authStatus: MusicAuthStatus = .authorized,
        searchResults: [SearchedSong] = [],
        shouldFail: Bool = false
    ) {
        self.authStatus = authStatus
        self.searchResults = searchResults
        self.shouldFail = shouldFail
    }

    func requestAuthorization() async -> MusicAuthStatus {
        return authStatus
    }

    func searchSongs(query: String, limit: Int) async throws -> [SearchedSong] {
        if shouldFail { throw AppError.musicSearch(.searchFailed) }
        return searchResults
    }
}
