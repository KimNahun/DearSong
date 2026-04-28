import Foundation
import Observation
import os

// MARK: - SongDetailViewModel

@MainActor
@Observable
final class SongDetailViewModel {
    private(set) var memories: [SongMemory] = []
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    private let memoryService: any SongMemoryServiceProtocol
    private let authService: any AuthServiceProtocol
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.nahun.DearSong", category: "SongDetailViewModel")

    init(
        memoryService: any SongMemoryServiceProtocol = SongMemoryService(),
        authService: any AuthServiceProtocol = AuthService()
    ) {
        self.memoryService = memoryService
        self.authService = authService
    }

    /// 컬렉션에서 이미 가져온 memories로 초기 시드. 서버 왕복 없이 즉시 표시.
    func seed(_ initial: [SongMemory]) {
        memories = initial.sorted { $0.listenedAt > $1.listenedAt }
    }

    func loadMemories(appleMusicId: String?, songTitle: String, artistName: String) async {
        // memories가 이미 시드되어 있으면 silent refresh (로딩 UI 깜빡임 방지)
        let hasSeed = !memories.isEmpty
        if !hasSeed { isLoading = true }
        defer { isLoading = false }
        errorMessage = nil

        logger.info("상세 기억 로딩 시작 — title=\(songTitle, privacy: .public), artist=\(artistName, privacy: .public), musicId=\(appleMusicId ?? "nil", privacy: .public)")

        do {
            let ownerId = try await authService.getCurrentUserId()
            let result: [SongMemory]

            if let musicId = appleMusicId, !musicId.isEmpty {
                result = try await memoryService.fetchMemoriesBySong(ownerId: ownerId, appleMusicId: musicId)
            } else {
                result = try await memoryService.fetchMemoriesBySongTitle(ownerId: ownerId, songTitle: songTitle, artistName: artistName)
            }

            logger.info("상세 기억 로딩 완료 — \(result.count)건")
            memories = result.sorted { $0.listenedAt > $1.listenedAt }
        } catch let error as AppError {
            logger.error("상세 기억 로딩 실패(AppError): \(error.errorDescription ?? "")")
            // 시드된 데이터가 있으면 에러 토스트 띄우지 않음
            if !hasSeed { errorMessage = error.errorDescription }
        } catch {
            logger.error("상세 기억 로딩 실패: \(error)")
            if !hasSeed { errorMessage = AppError.unknown(error.localizedDescription).errorDescription }
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
