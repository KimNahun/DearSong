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
            .map { memories -> GroupedSong in
                // 그룹 내 memories를 updatedAt 내림차순으로 정렬하여 결정적 순서 보장
                let sorted = memories.sorted { $0.updatedAt > $1.updatedAt }
                return GroupedSong(memories: sorted)
            }
            .sorted { lhs, rhs in
                // 그룹 간: 가장 최근 updatedAt 기준 내림차순 (최근 활동 곡이 위)
                let lDate = lhs.memories.first?.updatedAt ?? Date.distantPast
                let rDate = rhs.memories.first?.updatedAt ?? Date.distantPast
                if lDate != rDate {
                    return lDate > rDate
                }
                // 동일 시간 시 songTitle 오름차순 2차 정렬 (결정적 순서 보장)
                return lhs.songTitle < rhs.songTitle
            }
    }
}
