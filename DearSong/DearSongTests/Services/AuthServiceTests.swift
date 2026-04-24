import Testing
import Foundation
@testable import DearSong

// MARK: - AuthViewModel Tests

@Suite("AuthViewModel")
struct AuthViewModelTests {

    @Test("초기 상태는 미인증")
    @MainActor
    func initialStateIsUnauthenticated() async {
        let viewModel = AuthViewModel(service: MockAuthService(sessionUserId: nil))
        #expect(viewModel.isAuthenticated == false)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("세션 없으면 체크 후 미인증 상태")
    @MainActor
    func checkSessionWithNoSessionStaysUnauthenticated() async {
        let viewModel = AuthViewModel(service: MockAuthService(sessionUserId: nil))
        await viewModel.checkSession()
        #expect(viewModel.isAuthenticated == false)
    }

    @Test("로그아웃 실패 시 에러 메시지")
    @MainActor
    func signOutFailureSetsErrorMessage() async {
        let viewModel = AuthViewModel(service: MockAuthService(sessionUserId: UUID(), shouldFailSignOut: true))
        await viewModel.signOut()
        #expect(viewModel.errorMessage != nil)
    }
}
