import Foundation
import Observation
import os

// MARK: - SettingsViewModel

@MainActor
@Observable
final class SettingsViewModel {
    private(set) var userEmail: String?
    private(set) var userId: String?
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    let appVersion: String
    let buildNumber: String

    private let authService: any AuthServiceProtocol
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.nahun.DearSong",
        category: "SettingsViewModel"
    )

    init(authService: any AuthServiceProtocol = AuthService()) {
        self.authService = authService
        let info = Bundle.main.infoDictionary
        self.appVersion = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        self.buildNumber = info?["CFBundleVersion"] as? String ?? "1"
    }

    func loadAccountInfo() async {
        logger.info("loadAccountInfo() 시작")
        isLoading = true
        defer { isLoading = false }
        do {
            async let emailTask = authService.getCurrentUserEmail()
            async let idTask = authService.getCurrentUserId()
            let email = try await emailTask
            let id = try await idTask
            userEmail = email
            userId = id.uuidString
            logger.info("loadAccountInfo() 완료 - email present: \(email != nil)")
        } catch let error as AppError {
            errorMessage = error.errorDescription
            logger.error("loadAccountInfo() 실패: \(error)")
        } catch {
            errorMessage = AppError.unknown(error.localizedDescription).errorDescription
            logger.error("loadAccountInfo() 실패: \(error.localizedDescription)")
        }
    }
}
