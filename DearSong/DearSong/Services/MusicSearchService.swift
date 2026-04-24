import Foundation
import MusicKit
import os

// MARK: - MusicAuthStatus

nonisolated enum MusicAuthStatus: Sendable {
    case authorized
    case denied
    case restricted
    case notDetermined
}

// MARK: - MusicSearchServiceProtocol

protocol MusicSearchServiceProtocol: Sendable {
    func requestAuthorization() async -> MusicAuthStatus
    func searchSongs(query: String, limit: Int) async throws -> [SearchedSong]
}

// MARK: - MusicSearchService

actor MusicSearchService: MusicSearchServiceProtocol {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.nahun.DearSong", category: "MusicSearchService")

    func requestAuthorization() async -> MusicAuthStatus {
        logger.info("MusicKit 권한 요청")
        let status = await MusicAuthorization.request()
        logger.info("MusicKit 권한 상태: \(String(describing: status))")
        switch status {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }

    func searchSongs(query: String, limit: Int = 25) async throws -> [SearchedSong] {
        let status = await MusicAuthorization.currentStatus
        guard status == .authorized else {
            throw AppError.musicSearch(.unauthorized)
        }

        logger.info("곡 검색 시작: \(query)")
        do {
            var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
            request.limit = limit

            let response = try await request.response()
            let results = response.songs.map { song in
                SearchedSong(
                    id: song.id.rawValue,
                    title: song.title,
                    artistName: song.artistName,
                    artworkURL: song.artwork?.url(width: 300, height: 300),
                    albumTitle: song.albumTitle
                )
            }
            logger.info("곡 검색 완료: \(results.count)건")
            return results
        } catch let error as AppError {
            throw error
        } catch {
            logger.error("곡 검색 실패: \(error)")
            throw AppError.musicSearch(.searchFailed)
        }
    }
}
