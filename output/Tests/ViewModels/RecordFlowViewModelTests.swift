import Testing
import Foundation
@testable import DearSong

// MARK: - RecordFlowViewModel Tests

@Suite("RecordFlowViewModel")
struct RecordFlowViewModelTests {

    @Test("초기 단계는 songSearch")
    @MainActor
    func initialStepIsSongSearch() {
        let viewModel = RecordFlowViewModel(
            memoryService: MockSongMemoryService(),
            authService: MockAuthService()
        )
        #expect(viewModel.currentStep == .songSearch)
    }

    @Test("곡 선택 전 다음 단계 이동 불가")
    @MainActor
    func cannotProceedWithoutSongSelection() {
        let viewModel = RecordFlowViewModel(
            memoryService: MockSongMemoryService(),
            authService: MockAuthService()
        )
        viewModel.goToNextStep()
        #expect(viewModel.currentStep == .songSearch)
    }

    @Test("곡 선택 후 다음 단계 이동 가능")
    @MainActor
    func canProceedAfterSongSelection() {
        let viewModel = RecordFlowViewModel(
            memoryService: MockSongMemoryService(),
            authService: MockAuthService()
        )
        viewModel.selectedSong = SearchedSong(id: "1", title: "Test", artistName: "Artist", artworkURL: nil, albumTitle: nil)
        viewModel.goToNextStep()
        #expect(viewModel.currentStep == .moodSelection)
    }

    @Test("감정 태그 없이 다음 단계 이동 불가")
    @MainActor
    func cannotProceedFromMoodSelectionWithoutTags() {
        let viewModel = RecordFlowViewModel(
            memoryService: MockSongMemoryService(),
            authService: MockAuthService()
        )
        viewModel.selectedSong = SearchedSong(id: "1", title: "Test", artistName: "Artist", artworkURL: nil, albumTitle: nil)
        viewModel.currentStep = .moodSelection
        viewModel.goToNextStep()
        #expect(viewModel.currentStep == .moodSelection)
    }

    @Test("이전 단계 복귀")
    @MainActor
    func goToPreviousStep() {
        let viewModel = RecordFlowViewModel(
            memoryService: MockSongMemoryService(),
            authService: MockAuthService()
        )
        viewModel.currentStep = .moodSelection
        viewModel.goToPreviousStep()
        #expect(viewModel.currentStep == .songSearch)
    }

    @Test("수동 입력 — 곡 제목/아티스트 입력 전 진행 불가")
    @MainActor
    func manualInputRequiresBothFields() {
        let viewModel = RecordFlowViewModel(
            memoryService: MockSongMemoryService(),
            authService: MockAuthService()
        )
        viewModel.isManualInput = true
        viewModel.manualSongTitle = "봄날"
        #expect(viewModel.canProceedFromSongSearch == false)
        viewModel.manualArtistName = "BTS"
        #expect(viewModel.canProceedFromSongSearch == true)
    }

    @Test("기록 저장 성공")
    @MainActor
    func saveMemorySuccess() async {
        let ownerId = UUID()
        let viewModel = RecordFlowViewModel(
            memoryService: MockSongMemoryService(),
            authService: MockAuthService(sessionUserId: ownerId)
        )
        viewModel.selectedSong = SearchedSong(id: "song-1", title: "봄날", artistName: "BTS", artworkURL: nil, albumTitle: nil)
        viewModel.selectedMoodTags = ["그리움", "설렘"]
        viewModel.entryText = "이 곡을 처음 들었던 날"
        viewModel.selectedYear = 2020
        await viewModel.save()
        #expect(viewModel.savedSuccessfully == true)
        #expect(viewModel.errorMessage == nil)
    }
}

// MARK: - AddEntryViewModel Tests

@Suite("AddEntryViewModel")
struct AddEntryViewModelTests {

    @Test("빈 텍스트 저장 시도 — 에러")
    @MainActor
    func saveWithEmptyTextSetsError() async {
        let viewModel = AddEntryViewModel(service: MockSongMemoryService())
        await viewModel.save(memoryId: UUID())
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.savedSuccessfully == false)
    }

    @Test("정상 저장")
    @MainActor
    func saveWithValidTextSucceeds() async {
        let memoryId = UUID()
        let ownerId = UUID()
        let memory = SongMemory(
            id: memoryId, ownerId: ownerId, appleMusicId: nil,
            songTitle: "Test", artistName: "Artist",
            artworkUrl: nil, listenedAt: DateFormatters.date(fromYear: 2021),
            moodTags: [], location: nil,
            entries: [], attachments: [],
            createdAt: Date(), updatedAt: Date()
        )
        let viewModel = AddEntryViewModel(service: MockSongMemoryService(memoriesStore: [memory]))
        viewModel.entryText = "오늘 다시 들었다"
        await viewModel.save(memoryId: memoryId)
        #expect(viewModel.savedSuccessfully == true)
    }
}
