import Foundation
import Observation

// MARK: - SongCollectionViewModel

@MainActor
@Observable
final class SongCollectionViewModel {
    private(set) var groupedSongs: [GroupedSong] = []
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

    func loadMemories() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            let ownerId = try await authService.getCurrentUserId()
            let memories = try await memoryService.fetchAllMemories(ownerId: ownerId)
            groupedSongs = groupMemories(memories)
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = AppError.unknown(error.localizedDescription).errorDescription
        }
    }

    func refresh() async {
        await loadMemories()
    }

    // MARK: - Private

    private func groupMemories(_ memories: [SongMemory]) -> [GroupedSong] {
        var groups: [String: [SongMemory]] = [:]

        for memory in memories {
            let key: String
            if let musicId = memory.appleMusicId, !musicId.isEmpty {
                key = "musicId:\(musicId)"
            } else {
                key = "manual:\(memory.songTitle)-\(memory.artistName)"
            }
            groups[key, default: []].append(memory)
        }

        return groups.values
            .map { GroupedSong(memories: $0) }
            .sorted { lhs, rhs in
                let lDate = lhs.memories.first?.listenedAt ?? Date.distantPast
                let rDate = rhs.memories.first?.listenedAt ?? Date.distantPast
                return lDate > rDate
            }
    }
}
