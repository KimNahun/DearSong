import Foundation
import Supabase
import AuthenticationServices
import os

// MARK: - AuthServiceProtocol

protocol AuthServiceProtocol: Sendable {
    func signInWithApple(idToken: String, nonce: String) async throws -> UUID
    func getCurrentSession() async throws -> Session?
    func getCurrentUserId() async throws -> UUID
    func signOut() async throws
}

// MARK: - AuthService

actor AuthService: AuthServiceProtocol {
    private let supabase: SupabaseClient
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.nahun.DearSong", category: "AuthService")

    init(supabase: SupabaseClient = SupabaseClientProvider.shared.client) {
        self.supabase = supabase
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> UUID {
        logger.info("Apple Sign In 시작")
        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )
            logger.info("Apple Sign In 완료: \(session.user.id)")
            return session.user.id
        } catch {
            logger.error("Apple Sign In 실패: \(error)")
            throw AppError.auth(.invalidCredentials)
        }
    }

    func getCurrentSession() async throws -> Session? {
        do {
            return try await supabase.auth.session
        } catch {
            return nil
        }
    }

    func getCurrentUserId() async throws -> UUID {
        do {
            let session = try await supabase.auth.session
            return session.user.id
        } catch {
            throw AppError.auth(.noSession)
        }
    }

    func signOut() async throws {
        logger.info("로그아웃 시작")
        do {
            try await supabase.auth.signOut()
            logger.info("로그아웃 완료")
        } catch {
            logger.error("로그아웃 실패: \(error)")
            throw AppError.auth(.signOutFailed)
        }
    }
}
