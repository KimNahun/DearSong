import Foundation
import Observation
import MusicKit

// MARK: - SongSearchViewModel

@MainActor
@Observable
final class SongSearchViewModel {
    var query: String = ""
    private(set) var results: [SearchedSong] = []
    private(set) var isSearching: Bool = false
    private(set) var isMusicKitDenied: Bool = false
    private(set) var errorMessage: String?

    private let service: any MusicSearchServiceProtocol
    private var debounceTask: Task<Void, Never>?

    init(service: any MusicSearchServiceProtocol = MusicSearchService()) {
        self.service = service
    }

    func requestAuthorization() async {
        let status = await service.requestAuthorization()
        switch status {
        case .authorized:
            isMusicKitDenied = false
        case .denied, .restricted:
            isMusicKitDenied = true
        case .notDetermined:
            isMusicKitDenied = false
        @unknown default:
            isMusicKitDenied = false
        }
    }

    func onQueryChanged() {
        debounceTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            results = []
            return
        }
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초 debounce
            guard !Task.isCancelled else { return }
            await search()
        }
    }

    func search() async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            results = []
            return
        }

        isSearching = true
        defer { isSearching = false }
        errorMessage = nil

        do {
            results = try await service.searchSongs(query: trimmedQuery, limit: 25)
        } catch let error as AppError {
            if case .musicSearch(.unauthorized) = error {
                isMusicKitDenied = true
            } else {
                errorMessage = error.errorDescription
            }
        } catch {
            errorMessage = AppError.unknown(error.localizedDescription).errorDescription
        }
    }
}
