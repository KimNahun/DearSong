# DearSong

**노래에 감정을 기록하는 음악 감성 다이어리**

특정 노래를 들었을 때 느꼈던 감정, 그때의 기분, 그 순간의 기억을 기록하는 iOS 앱입니다.
같은 노래라도 듣는 시기에 따라 감정이 다르고, 그 변화 자체가 기록의 가치입니다.

---

## 핵심 기능

### 곡 검색
Apple Music 카탈로그에서 곡을 검색하고, 앨범 커버와 메타데이터를 자동으로 가져옵니다.
MusicKit 권한이 없어도 곡 제목과 아티스트를 직접 입력할 수 있습니다.

### 감정 기록
그 곡을 들었던 시기(년도)와 장소, 그때의 감정을 기록합니다.
9개 카테고리, 50개 이상의 감정 태그에서 다중 선택하고 자유 텍스트로 기록을 남깁니다.

### 감정 타임라인
같은 노래의 시기별 감정 변화를 타임라인으로 돌아봅니다.
"같은 노래, 다른 시기의 감정" — 시간이 지나며 달라지는 감정의 결을 확인할 수 있습니다.

### 곡 컬렉션
기록한 모든 곡을 앨범 커버 중심의 그리드로 한눈에 봅니다.

---

## 화면 흐름

```
[Apple Sign In] → [곡 컬렉션 (메인)]
                        │
                        ├── 곡 탭 → [곡 상세 타임라인]
                        │              ├── 시기 카드 탭 → 엔트리 추가
                        │              └── 새 시기 추가
                        │
                        └── + 버튼 → [새 기록 작성]
                                       ├── Step 1: 곡 검색
                                       ├── Step 2: 감정 태그 선택
                                       └── Step 3: 텍스트 + 년도 + 장소 → 저장
```

---

## 감정 태그

| 카테고리 | 태그 예시 |
|---------|----------|
| 설렘/기쁨 | 설렘, 행복, 기쁨, 벅참, 두근거림 |
| 평온/감사 | 평온, 감사, 포근함, 따뜻함, 편안함 |
| 그리움/향수 | 그리움, 아련함, 향수, 먹먹함, 추억 |
| 슬픔/외로움 | 슬픔, 외로움, 허전함, 우울 |
| 에너지/자신감 | 신남, 열정, 자신감, 용기 |
| 차분/몽환 | 잔잔함, 몽환, 여유, 나른함, 고요함 |
| 위로/치유 | 위로, 치유, 공감, 다독임, 희망 |
| 계절/날씨 | 비 오는 날, 여름밤, 가을 햇살, 봄바람 |
| 장소/상황 | 드라이브, 새벽, 밤산책, 혼자인 시간 |

---

## 기술 스택

| 구분 | 기술 |
|------|------|
| 플랫폼 | iOS 17.0+ |
| 언어 | Swift 6 (엄격 동시성) |
| UI | SwiftUI |
| 아키텍처 | MVVM (View → ViewModel → Service) |
| 인증 | Apple Sign In + Supabase Auth |
| 백엔드 | Supabase (PostgreSQL + RLS) |
| 음악 검색 | MusicKit (Apple Music 카탈로그) |
| 디자인 시스템 | [PersonalColorDesignSystem](https://github.com/KimNahun/PersonalColorDesignSystem) |

---

## 프로젝트 구조

```
DearSong/
├── App/              # 앱 진입점, 의존성 주입
├── Views/            # SwiftUI 뷰
│   ├── Auth/         #   로그인
│   ├── Collection/   #   곡 컬렉션 (메인)
│   ├── Detail/       #   곡 상세 타임라인
│   ├── Record/       #   새 기록 작성 플로우
│   ├── Entry/        #   엔트리 추가
│   └── Components/   #   재사용 컴포넌트
├── ViewModels/       # @MainActor @Observable 뷰모델
├── Models/           # Sendable 데이터 모델
├── Services/         # actor 기반 서비스 (Supabase, MusicKit, Auth)
└── Shared/           # 에러 타입, 유틸리티
```

---

## 설정

### 사전 요구사항

- Xcode 16+
- iOS 17.0+ 시뮬레이터 또는 실기기
- Supabase 프로젝트 (Auth + Database)
- Apple Developer 계정 (MusicKit, Sign In with Apple)

### 빌드

1. 레포지토리를 클론합니다.
   ```bash
   git clone https://github.com/KimNahun/DearSong.git
   cd DearSong
   ```

2. `DearSong/Secrets.xcconfig` 파일을 생성하고 Supabase 키를 설정합니다.
   ```
   SUPABASE_URL = https://your-project.supabase.co
   SUPABASE_ANON_KEY = your-anon-key
   ```

3. Xcode에서 `DearSong/DearSong.xcodeproj`를 열고 빌드합니다.

---

## 코드 품질

이 프로젝트의 코드는 3-Agent 하네스 파이프라인(Planner → Generator → Evaluator)으로 생성되고 검수됩니다.

- **Swift 6 동시성**: `@MainActor`, `actor`, `Sendable` 엄격 적용
- **MVVM 분리**: View ↔ ViewModel ↔ Service 단방향 의존, 레이어 오염 금지
- **HIG 준수**: Dynamic Type, 접근성, 로딩/에러 상태 처리
- **빌드 게이트**: 커밋 전 자동 빌드 검증

---

## License

MIT
