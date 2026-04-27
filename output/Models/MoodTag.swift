import Foundation

// MARK: - MoodCategory

nonisolated enum MoodCategory: String, CaseIterable, Sendable {
    case excitement
    case peace
    case nostalgia
    case sadness
    case energy
    case calm
    case comfort
    case situation

    var displayName: String {
        switch self {
        case .excitement: return "설렘/기쁨"
        case .peace: return "평온/감사"
        case .nostalgia: return "그리움/향수"
        case .sadness: return "슬픔/외로움"
        case .energy: return "에너지/자신감"
        case .calm: return "차분/몽환"
        case .comfort: return "위로/치유"
        case .situation: return "장소/상황"
        }
    }

    var tags: [String] {
        switch self {
        case .excitement:
            return ["설렘", "행복", "기쁨", "벅참", "두근거림", "들뜸", "황홀", "짜릿함"]
        case .peace:
            return ["평온", "감사", "포근함", "따뜻함", "안도", "편안함", "충만함"]
        case .nostalgia:
            return ["그리움", "아련함", "향수", "먹먹함", "추억", "회상"]
        case .sadness:
            return ["슬픔", "외로움", "허전함", "우울", "눈물", "쓸쓸함", "서글픔"]
        case .energy:
            return ["신남", "열정", "자신감", "용기", "의지", "에너지", "활력"]
        case .calm:
            return ["잔잔함", "몽환", "여유", "나른함", "고요함", "사색"]
        case .comfort:
            return ["위로", "치유", "공감", "다독임", "희망", "용서"]
        case .situation:
            // 기존 .situation 태그 + .season에서 병합된 계절 감성 태그 (순수 날씨 태그는 제거)
            return ["드라이브", "새벽", "밤산책", "혼자인 시간", "여행 중", "카페에서",
                    "여름밤", "가을 햇살", "봄바람"]
        }
    }
}

// MARK: - MoodTag

nonisolated struct MoodTag: Identifiable, Sendable {
    let id: String
    var name: String
    var category: MoodCategory

    init(name: String, category: MoodCategory) {
        self.id = "\(category.rawValue)-\(name)"
        self.name = name
        self.category = category
    }
}

// MARK: - All Mood Tags

extension MoodTag {
    static var allTags: [MoodTag] {
        MoodCategory.allCases.flatMap { category in
            category.tags.map { MoodTag(name: $0, category: category) }
        }
    }
}
