import Foundation
import Observation

// MARK: - RecordStep

nonisolated enum RecordStep: Int, Sendable {
    case songSearch = 0
    case moodSelection = 1
    case entryWrite = 2
}

// MARK: - RecordFlowViewModel

@MainActor
@Observable
final class RecordFlowViewModel {
    private(set) var currentStep: RecordStep = .songSearch
    var selectedSong: SearchedSong?
    var selectedMoodTags: Set<String> = []
    var entryText: String = ""
    var selectedYear: Int = DateFormatters.currentYear
    var location: String = ""
    var isManualInput: Bool = false
    var manualSongTitle: String = ""
    var manualArtistName: String = ""
    private(set) var isSaving: Bool = false
    private(set) var errorMessage: String?
    private(set) var savedSuccessfully: Bool = false

    private let memoryService: any SongMemoryServiceProtocol
    private let authService: any AuthServiceProtocol

    init(
        memoryService: any SongMemoryServiceProtocol = SongMemoryService(),
        authService: any AuthServiceProtocol = AuthService(),
        preselectedSong: SearchedSong? = nil
    ) {
        self.memoryService = memoryService
        self.authService = authService
        if let song = preselectedSong {
            self.selectedSong = song
            self.currentStep = .moodSelection
        }
    }

    var canProceedFromSongSearch: Bool {
        if isManualInput {
            return !manualSongTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !manualArtistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return selectedSong != nil
    }

    var canProceedFromMoodSelection: Bool {
        !selectedMoodTags.isEmpty
    }

    var effectiveSongTitle: String {
        if isManualInput {
            return manualSongTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return selectedSong?.title ?? ""
    }

    var effectiveArtistName: String {
        if isManualInput {
            return manualArtistName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return selectedSong?.artistName ?? ""
    }

    var effectiveArtworkURL: String? {
        if isManualInput { return nil }
        return selectedSong?.artworkURL?.absoluteString
    }

    var effectiveAppleMusicId: String? {
        if isManualInput { return nil }
        return selectedSong?.id
    }

    func goToNextStep() {
        switch currentStep {
        case .songSearch:
            guard canProceedFromSongSearch else { return }
            currentStep = .moodSelection
        case .moodSelection:
            guard canProceedFromMoodSelection else { return }
            currentStep = .entryWrite
        case .entryWrite:
            break
        }
    }

    func goToPreviousStep() {
        switch currentStep {
        case .moodSelection:
            currentStep = .songSearch
        case .entryWrite:
            currentStep = .moodSelection
        case .songSearch:
            break
        }
    }

    func save() async {
        isSaving = true
        defer { isSaving = false }
        errorMessage = nil

        do {
            let ownerId = try await authService.getCurrentUserId()
            let listenedAt = DateFormatters.date(fromYear: selectedYear)
            let entry = Entry(
                id: UUID(),
                text: entryText.trimmingCharacters(in: .whitespacesAndNewlines),
                writtenAt: Date()
            )

            // 동일 곡+년도 조합 존재 여부 확인
            if let existing = try await memoryService.findExistingMemory(
                ownerId: ownerId,
                appleMusicId: effectiveAppleMusicId,
                songTitle: effectiveSongTitle,
                artistName: effectiveArtistName,
                listenedAt: listenedAt
            ) {
                // 기존 행 → entries에 추가
                try await memoryService.addEntry(memoryId: existing.id, entry: entry)
            } else {
                // 새 행 생성
                let memory = SongMemory(
                    id: UUID(),
                    ownerId: ownerId,
                    appleMusicId: effectiveAppleMusicId,
                    songTitle: effectiveSongTitle,
                    artistName: effectiveArtistName,
                    artworkUrl: effectiveArtworkURL,
                    listenedAt: listenedAt,
                    moodTags: Array(selectedMoodTags),
                    location: location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : location.trimmingCharacters(in: .whitespacesAndNewlines),
                    entries: [entry],
                    attachments: [],
                    createdAt: Date(),
                    updatedAt: Date()
                )
                try await memoryService.createMemory(memory)
            }

            savedSuccessfully = true
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = AppError.unknown(error.localizedDescription).errorDescription
        }
    }
}
