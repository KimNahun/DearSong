import Testing
import Foundation
@testable import DearSong

// MARK: - SongCollectionViewModel Tests

@Suite("SongCollectionViewModel")
struct SongCollectionViewModelTests {

    @Test("빈 기억 목록 로딩")
    @MainActor
    func loadEmptyMemories() async {
        let ownerId = UUID()
        let viewModel = SongCollectionViewModel(
            memoryService: MockSongMemoryService(),
            authService: MockAuthService(sessionUserId: ownerId)
        )
        await viewModel.loadMemories()
        #expect(viewModel.groupedSongs.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("기억 그룹핑 — 같은 곡 두 시기")
    @MainActor
    func memoriesGroupedBySong() async {
        let ownerId = UUID()
        let musicId = "song-abc"
        let mem1 = SongMemory(
            id: UUID(), ownerId: ownerId, appleMusicId: musicId,
            songTitle: "봄날", artistName: "BTS",
            artworkUrl: nil, listenedAt: DateFormatters.date(fromYear: 2020),
            moodTags: ["그리움"], location: nil,
            entries: [], attachments: [],
            createdAt: Date(), updatedAt: Date()
        )
        let mem2 = SongMemory(
            id: UUID(), ownerId: ownerId, appleMusicId: musicId,
            songTitle: "봄날", artistName: "BTS",
            artworkUrl: nil, listenedAt: DateFormatters.date(fromYear: 2022),
            moodTags: ["설렘"], location: nil,
            entries: [], attachments: [],
            createdAt: Date(), updatedAt: Date()
        )
        let viewModel = SongCollectionViewModel(
            memoryService: MockSongMemoryService(memoriesStore: [mem1, mem2]),
            authService: MockAuthService(sessionUserId: ownerId)
        )
        await viewModel.loadMemories()
        #expect(viewModel.groupedSongs.count == 1)
        #expect(viewModel.groupedSongs[0].memoryCount == 2)
    }

    @Test("서비스 오류 시 errorMessage 설정")
    @MainActor
    func serviceErrorSetsErrorMessage() async {
        let viewModel = SongCollectionViewModel(
            memoryService: MockSongMemoryService(shouldFail: true),
            authService: MockAuthService(sessionUserId: UUID())
        )
        await viewModel.loadMemories()
        #expect(viewModel.errorMessage != nil)
    }
}

// MARK: - SongDetailViewModel Tests

@Suite("SongDetailViewModel")
struct SongDetailViewModelTests {

    @Test("곡 기억 로딩 — appleMusicId 기준")
    @MainActor
    func loadMemoriesByAppleMusicId() async {
        let ownerId = UUID()
        let musicId = "test-id"
        let memory = SongMemory(
            id: UUID(), ownerId: ownerId, appleMusicId: musicId,
            songTitle: "Test", artistName: "Artist",
            artworkUrl: nil, listenedAt: DateFormatters.date(fromYear: 2021),
            moodTags: [], location: nil,
            entries: [], attachments: [],
            createdAt: Date(), updatedAt: Date()
        )
        let viewModel = SongDetailViewModel(
            memoryService: MockSongMemoryService(memoriesStore: [memory]),
            authService: MockAuthService(sessionUserId: ownerId)
        )
        await viewModel.loadMemories(appleMusicId: musicId, songTitle: "Test", artistName: "Artist")
        #expect(viewModel.memories.count == 1)
    }

    @Test("기억 삭제")
    @MainActor
    func deleteMemory() async {
        let ownerId = UUID()
        let memId = UUID()
        let memory = SongMemory(
            id: memId, ownerId: ownerId, appleMusicId: nil,
            songTitle: "Test", artistName: "Artist",
            artworkUrl: nil, listenedAt: DateFormatters.date(fromYear: 2021),
            moodTags: [], location: nil,
            entries: [], attachments: [],
            createdAt: Date(), updatedAt: Date()
        )
        let viewModel = SongDetailViewModel(
            memoryService: MockSongMemoryService(memoriesStore: [memory]),
            authService: MockAuthService(sessionUserId: ownerId)
        )
        // 먼저 로딩하여 memories 채우기
        await viewModel.loadMemories(appleMusicId: nil, songTitle: "Test", artistName: "Artist")
        #expect(viewModel.memories.count == 1)
        await viewModel.deleteMemory(id: memId)
        #expect(viewModel.memories.isEmpty)
    }

    @Test("seed — 컬렉션에서 가져온 데이터로 즉시 시드, listenedAt 내림차순 정렬")
    @MainActor
    func seedSortsByListenedAtDesc() {
        let ownerId = UUID()
        let older = SongMemory(
            id: UUID(), ownerId: ownerId, appleMusicId: "1",
            songTitle: "S", artistName: "A",
            artworkUrl: nil, listenedAt: DateFormatters.date(fromYear: 2020),
            moodTags: [], location: nil, entries: [], attachments: [],
            createdAt: Date(), updatedAt: Date()
        )
        let newer = SongMemory(
            id: UUID(), ownerId: ownerId, appleMusicId: "1",
            songTitle: "S", artistName: "A",
            artworkUrl: nil, listenedAt: DateFormatters.date(fromYear: 2024),
            moodTags: [], location: nil, entries: [], attachments: [],
            createdAt: Date(), updatedAt: Date()
        )
        let viewModel = SongDetailViewModel(
            memoryService: MockSongMemoryService(memoriesStore: []),
            authService: MockAuthService(sessionUserId: ownerId)
        )

        viewModel.seed([older, newer])

        #expect(viewModel.memories.count == 2)
        #expect(viewModel.memories[0].id == newer.id)
        #expect(viewModel.memories[1].id == older.id)
    }

    @Test("loadMemories — 시드 후 서비스 에러 시 시드 데이터 보존, errorMessage 미설정")
    @MainActor
    func loadMemoriesPreservesSeedOnError() async {
        let ownerId = UUID()
        let seedMemory = SongMemory(
            id: UUID(), ownerId: ownerId, appleMusicId: "x",
            songTitle: "Cached", artistName: "Cached",
            artworkUrl: nil, listenedAt: DateFormatters.date(fromYear: 2023),
            moodTags: [], location: nil, entries: [], attachments: [],
            createdAt: Date(), updatedAt: Date()
        )
        let viewModel = SongDetailViewModel(
            memoryService: MockSongMemoryService(memoriesStore: [], shouldFail: true),
            authService: MockAuthService(sessionUserId: ownerId)
        )
        viewModel.seed([seedMemory])

        await viewModel.loadMemories(appleMusicId: "x", songTitle: "Cached", artistName: "Cached")

        #expect(viewModel.memories.count == 1)
        #expect(viewModel.memories.first?.id == seedMemory.id)
        #expect(viewModel.errorMessage == nil)
    }
}
