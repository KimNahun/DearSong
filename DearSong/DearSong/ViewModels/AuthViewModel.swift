import Foundation
import Observation
import AuthenticationServices
import CryptoKit

// MARK: - AuthViewModel

@MainActor
@Observable
final class AuthViewModel {
    private(set) var isAuthenticated: Bool = false
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    private let service: any AuthServiceProtocol
    private var currentNonce: String?

    init(service: any AuthServiceProtocol = AuthService()) {
        self.service = service
    }

    func checkSession() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let session = try await service.getCurrentSession()
            isAuthenticated = session != nil
        } catch {
            isAuthenticated = false
        }
    }

    func signInWithApple(authorization: ASAuthorization) async {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8),
              let nonce = currentNonce else {
            errorMessage = "Apple Sign In 정보를 처리할 수 없습니다."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await service.signInWithApple(idToken: idToken, nonce: nonce)
            isAuthenticated = true
            errorMessage = nil
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = AppError.unknown(error.localizedDescription).errorDescription
        }
    }

    func signOut() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await service.signOut()
            isAuthenticated = false
            errorMessage = nil
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = AppError.unknown(error.localizedDescription).errorDescription
        }
    }

    /// Apple Sign In 요청 준비 — nonce 생성 후 반환
    func prepareSignInRequest() -> ASAuthorizationAppleIDRequest {
        let nonce = randomNonceString()
        currentNonce = nonce
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        return request
    }

    // MARK: - Private Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            return UUID().uuidString.replacingOccurrences(of: "-", with: "")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
