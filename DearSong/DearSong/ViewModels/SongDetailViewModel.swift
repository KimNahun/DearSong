import Foundation
import Observation

// MARK: - SongDetailViewModel

@MainActor
@Observable
final class SongDetailViewModel {
    private(set) var memories: [SongMemory] = []
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    private let memoryService: any SongMemoryServiceProtocol
    private let authService: any AuthServiceProtocol

    init(
        memoryService: any SongMemoryServiceProtocol = SongMemoryService(),
        authService: any AuthServiceProtocol = AuthService()
    ) {
        self.memoryService = memoryService
        self.authService = authService
    }

    func loadMemories(appleMusicId: String?, songTitle: String, artistName: String) async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            let ownerId = try await authService.getCurrentUserId()
            let result: [SongMemory]

            if let musicId = appleMusicId, !musicId.isEmpty {
                result = try await memoryService.fetchMemoriesBySong(ownerId: ownerId, appleMusicId: musicId)
            } else {
                result = try await memoryService.fetchMemoriesBySongTitle(ownerId: ownerId, songTitle: songTitle, artistName: artistName)
            }

            memories = result.sorted { $0.listenedAt > $1.listenedAt }
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = AppError.unknown(error.localizedDescription).errorDescription
        }
    }

    func deleteMemory(id: UUID) async {
        do {
            try await memoryService.deleteMemory(memoryId: id)
            memories.removeAll { $0.id == id }
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = AppError.unknown(error.localizedDescription).errorDescription
        }
    }
}
