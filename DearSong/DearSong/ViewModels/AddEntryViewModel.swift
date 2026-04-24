import Foundation
import Observation

// MARK: - AddEntryViewModel

@MainActor
@Observable
final class AddEntryViewModel {
    var entryText: String = ""
    private(set) var existingEntries: [Entry] = []
    private(set) var isSaving: Bool = false
    private(set) var errorMessage: String?
    private(set) var savedSuccessfully: Bool = false

    private let service: any SongMemoryServiceProtocol

    init(service: any SongMemoryServiceProtocol = SongMemoryService(), existingEntries: [Entry] = []) {
        self.service = service
        self.existingEntries = existingEntries
    }

    func save(memoryId: UUID) async {
        let trimmed = entryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "내용을 입력해주세요."
            return
        }

        isSaving = true
        defer { isSaving = false }
        errorMessage = nil

        let entry = Entry(id: UUID(), text: trimmed, writtenAt: Date())

        do {
            try await service.addEntry(memoryId: memoryId, entry: entry)
            existingEntries.append(entry)
            entryText = ""
            savedSuccessfully = true
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = AppError.unknown(error.localizedDescription).errorDescription
        }
    }
}
