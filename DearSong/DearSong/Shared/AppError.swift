import Foundation

// MARK: - Domain Errors

nonisolated enum AuthError: Error, Sendable {
    case invalidCredentials
    case sessionExpired
    case signOutFailed
    case noSession
}

nonisolated enum SongMemoryError: Error, Sendable {
    case fetchFailed
    case createFailed
    case updateFailed
    case deleteFailed
    case notFound
}

nonisolated enum MusicSearchError: Error, Sendable {
    case unauthorized
    case searchFailed
    case networkError
}

// MARK: - AppError

nonisolated enum AppError: Error, LocalizedError, Sendable {
    case auth(AuthError)
    case songMemory(SongMemoryError)
    case musicSearch(MusicSearchError)
    case network
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .auth(let err):
            switch err {
            case .invalidCredentials: return "로그인에 실패했습니다. 다시 시도해주세요."
            case .sessionExpired: return "세션이 만료되었습니다. 다시 로그인해주세요."
            case .signOutFailed: return "로그아웃에 실패했습니다."
            case .noSession: return "로그인이 필요합니다."
            }
        case .songMemory(let err):
            switch err {
            case .fetchFailed: return "기록을 불러오지 못했습니다."
            case .createFailed: return "기록을 저장하지 못했습니다."
            case .updateFailed: return "기록 업데이트에 실패했습니다."
            case .deleteFailed: return "기록 삭제에 실패했습니다."
            case .notFound: return "기록을 찾을 수 없습니다."
            }
        case .musicSearch(let err):
            switch err {
            case .unauthorized: return "Apple Music 권한이 없습니다."
            case .searchFailed: return "곡 검색에 실패했습니다."
            case .networkError: return "네트워크 연결을 확인해주세요."
            }
        case .network:
            return "네트워크 연결을 확인해주세요."
        case .unknown(let message):
            return message.isEmpty ? "알 수 없는 오류가 발생했습니다." : message
        }
    }
}
