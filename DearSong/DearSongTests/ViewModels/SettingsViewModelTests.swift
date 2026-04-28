import Testing
import Foundation
@testable import DearSong

// MARK: - SettingsViewModel Tests

@Suite("SettingsViewModel")
struct SettingsViewModelTests {

    @Test("초기 상태 — 사용자 정보 미로드, 버전 정보는 항상 존재")
    @MainActor
    func initialState() {
        let viewModel = SettingsViewModel(authService: MockAuthService())
        #expect(viewModel.userEmail == nil)
        #expect(viewModel.userId == nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.appVersion.isEmpty)
        #expect(!viewModel.buildNumber.isEmpty)
    }

    @Test("loadAccountInfo — 세션 있음: 이메일/ID 채워짐")
    @MainActor
    func loadAccountInfoWithSession() async {
        let userId = UUID()
        let viewModel = SettingsViewModel(
            authService: MockAuthService(sessionUserId: userId, sessionEmail: "user@example.com")
        )
        await viewModel.loadAccountInfo()
        #expect(viewModel.userEmail == "user@example.com")
        #expect(viewModel.userId == userId.uuidString)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }

    @Test("loadAccountInfo — 세션 없음: 에러 메시지 설정")
    @MainActor
    func loadAccountInfoWithoutSession() async {
        let viewModel = SettingsViewModel(authService: MockAuthService())
        await viewModel.loadAccountInfo()
        #expect(viewModel.userEmail == nil)
        #expect(viewModel.userId == nil)
        #expect(viewModel.errorMessage != nil)
    }

    @Test("loadAccountInfo — 이메일 없는 세션도 정상 처리")
    @MainActor
    func loadAccountInfoWithoutEmail() async {
        let userId = UUID()
        let viewModel = SettingsViewModel(
            authService: MockAuthService(sessionUserId: userId, sessionEmail: nil)
        )
        await viewModel.loadAccountInfo()
        #expect(viewModel.userEmail == nil)
        #expect(viewModel.userId == userId.uuidString)
        #expect(viewModel.errorMessage == nil)
    }
}
