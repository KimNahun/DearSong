# DearSong

## 개요

DearSong은 노래에 감정을 기록하는 음악 감성 다이어리 앱이다. 사용자는 Apple Music 카탈로그에서 곡을 검색하고, 그 곡을 들었던 시기(년도)와 장소, 그때의 감정을 기록한다. 같은 노래라도 다른 시기에 다른 감정으로 기록할 수 있으며, 하나의 곡+시기 조합에 텍스트 엔트리를 누적하여 감정의 변화를 돌아본다.

## 타겟 플랫폼

- iOS 17.0 이상
- Swift 버전: Swift 6 (엄격 동시성 필수)
- 번들 ID: com.nahun.DearSong
- 개발팀 ID: AHW642SXDF

## 필요 권한

- `NSAppleMusicUsageDescription`: MusicKit 카탈로그 곡 검색용 (거부 시 수동 입력 폴백)
- `com.apple.developer.applesignin`: Apple Sign In 인증 엔타이틀먼트 (설정 완료)

## 외부 의존성

| 패키지 | 버전 | 용도 |
|--------|------|------|
| PersonalColorDesignSystem | main branch | 디자인 시스템 (색상, 타이포, 컴포넌트) |
| supabase-swift | 2.0.0+ | Auth, Database (Supabase 백엔드) |
| MusicKit (Apple) | iOS 17+ 내장 | Apple Music 카탈로그 곡 검색 |
| AuthenticationServices (Apple) | iOS 17+ 내장 | Apple Sign In |

---

## 아키텍처

### 레이어 구조

```
DearSong/
├── App/
│   └── DearSongApp.swift              # @main, 의존성 주입 루트, PToastManager 환경 설정
├── Views/
│   ├── Auth/
│   │   └── SignInView.swift           # Apple Sign In 화면
│   ├── Collection/
│   │   └── SongCollectionView.swift   # 곡 컬렉션 메인 화면 (앨범 커버 그리드)
│   ├── Detail/
│   │   └── SongDetailView.swift       # 곡 상세 — 감정 타임라인
│   ├── Record/
│   │   ├── RecordFlowView.swift       # 새 기록 작성 플로우 컨테이너 (step navigation)
│   │   ├── SongSearchView.swift       # Step 1: 곡 검색 / 수동 입력
│   │   ├── MoodSelectionView.swift    # Step 2: 감정 태그 다중 선택
│   │   ├── EntryWriteView.swift       # Step 3: 텍스트 작성 + 년도/장소 입력
│   │   └── ManualSongInputView.swift  # MusicKit 권한 거부 시 수동 입력
│   ├── Entry/
│   │   └── AddEntryView.swift         # 기존 곡+시기에 엔트리 추가 시트
│   └── Components/
│       ├── SongCardView.swift         # 앨범 커버 카드 컴포넌트
│       ├── MoodChipGridView.swift     # 감정 태그 칩 그리드 컴포넌트
│       ├── TimelineEntryView.swift    # 타임라인 엔트리 셀 컴포넌트
│       └── AlbumArtworkView.swift     # AsyncImage 래퍼 (아트워크 표시)
├── ViewModels/
│   ├── AuthViewModel.swift            # Apple Sign In + Supabase Auth 상태 관리
│   ├── SongCollectionViewModel.swift  # 곡 목록 로딩, 검색/필터
│   ├── SongDetailViewModel.swift      # 특정 곡의 시기별 기록 목록
│   ├── RecordFlowViewModel.swift      # 새 기록 작성 플로우 상태 관리
│   ├── SongSearchViewModel.swift      # MusicKit 곡 검색 상태
│   └── AddEntryViewModel.swift        # 기존 곡+시기에 엔트리 추가
├── Models/
│   ├── SongMemory.swift               # SongMemory, Entry, Attachment 모델
│   ├── MoodTag.swift                  # MoodCategory, MoodTag 정의 (감정 태그 전체 목록)
│   └── SearchedSong.swift             # MusicKit 검색 결과 매핑 모델
├── Services/
│   ├── AuthService.swift              # actor — Apple Sign In + Supabase Auth
│   ├── SongMemoryService.swift        # actor — song_memories CRUD (Supabase)
│   ├── MusicSearchService.swift       # actor — MusicKit 카탈로그 검색
│   └── SupabaseClientProvider.swift   # SupabaseClient 싱글턴 (Info.plist에서 URL/Key 로드)
├── Shared/
│   ├── AppError.swift                 # enum AppError: Error (도메인 에러 통합)
│   └── DateFormatters.swift           # 년도 표시 포맷 유틸리티
└── Delegates/
    └── AppDelegate.swift              # UIApplicationDelegate (필요 시)
```

### 동시성 경계

| 레이어 | 어노테이션 | 규칙 |
|--------|-----------|------|
| View | `@MainActor struct` | UI 선언만. 상태 소유 없음 |
| ViewModel | `@MainActor final class` + `@Observable` | UI 상태 소유. Service 호출 후 상태 업데이트 |
| Service | `actor` | 비동기 데이터 처리. ViewModel/View 참조 금지 |
| Model | `struct` + `Sendable` + `Codable` | 순수 데이터. actor 경계 넘어 안전 전달 |

### 의존성 흐름

```
View -> ViewModel -> Service -> (Supabase / MusicKit / Apple Auth)
```

역방향 의존 금지. Service는 ViewModel을 모른다. ViewModel은 View를 모른다.

---

## 기능 목록

### 기능 1: Apple Sign In 인증

- **설명**: Apple 계정으로 로그인하여 Supabase Auth 세션을 생성한다.
- **사용자 스토리**: 사용자가 앱을 처음 열면 Apple Sign In 버튼이 표시되고, 탭하면 Apple 인증 시트가 올라온다. 인증 성공 시 Supabase Auth에 세션이 생성되고 메인 화면(곡 컬렉션)으로 전환된다.
- **관련 파일**:
  - View: `SignInView.swift`
  - ViewModel: `AuthViewModel.swift`
  - Service: `AuthService.swift`, `SupabaseClientProvider.swift`
- **사용 API**: AuthenticationServices (ASAuthorizationController), Supabase Auth (`signInWithIdToken`)
- **HIG 패턴**: 전체 화면 Sign In, `SignInWithAppleButton` 사용
- **세부 동작**:
  - 앱 시작 시 `supabase.auth.session`으로 기존 세션 확인 → 있으면 자동 진입
  - 로그아웃: 설정 또는 프로필 영역에서 `supabase.auth.signOut()` 호출
  - `AuthViewModel`이 `isAuthenticated` 상태를 관리, `DearSongApp`에서 분기

### 기능 2: 곡 컬렉션 메인 화면

- **설명**: 사용자가 기록한 모든 곡을 앨범 커버 중심의 그리드로 표시한다.
- **사용자 스토리**: 로그인 후 메인 화면에 기록한 곡들이 앨범 커버 그리드로 나타난다. 각 카드는 앨범 커버, 곡 제목, 아티스트명을 보여준다. 곡이 없으면 감성적인 빈 상태 뷰가 표시된다.
- **관련 파일**:
  - View: `SongCollectionView.swift`, `SongCardView.swift`
  - ViewModel: `SongCollectionViewModel.swift`
  - Service: `SongMemoryService.swift`
- **사용 API**: Supabase Database (SELECT)
- **HIG 패턴**: `NavigationStack`, `LazyVGrid`, `EmptyStateView`
- **세부 동작**:
  - 같은 곡(apple_music_id 기준)이 여러 시기로 기록되어 있어도 **곡 단위로 그룹핑**하여 표시
  - 그리드 카드 탭 → `SongDetailView`로 NavigationLink push
  - 플로팅 `+` 버튼으로 새 기록 작성 플로우 진입 (fullScreenCover)
  - 로딩 중: `PLoadingOverlay` 표시
  - 에러 시: 토스트(`PToastManager`)로 안내
  - pull-to-refresh 지원
  - 로그아웃 버튼은 toolbar trailing에 배치

### 기능 3: 곡 상세 화면 (감정 타임라인)

- **설명**: 특정 곡의 시기별 감정 기록을 타임라인으로 보여준다. "같은 노래, 다른 시기의 감정"을 시간순으로 돌아본다.
- **사용자 스토리**: 곡 컬렉션에서 곡을 탭하면 그 곡의 모든 시기별 기록이 타임라인 형태로 표시된다. 각 시기(년도)마다 감정 태그, 장소, 텍스트 엔트리들이 보인다. 배경은 앨범 아트워크 블러 처리.
- **관련 파일**:
  - View: `SongDetailView.swift`, `TimelineEntryView.swift`, `MoodChipGridView.swift`
  - ViewModel: `SongDetailViewModel.swift`
  - Service: `SongMemoryService.swift`
- **사용 API**: Supabase Database (SELECT, filter by apple_music_id or song_title+artist_name)
- **HIG 패턴**: NavigationStack push, ScrollView 세로 타임라인
- **세부 동작**:
  - 상단: 앨범 커버 크게 + 곡 제목 + 아티스트명
  - 배경: 앨범 아트워크를 blur 처리한 `PGradientBackground` 위에 오버레이
  - 타임라인: 시기(년도) 내림차순 정렬. 각 시기 카드에 `GlassCard` 적용
  - 각 시기 카드 내용: 년도 라벨, 감정 태그(PChip 나열), 장소, entries(텍스트 목록)
  - 시기 카드 탭 → 해당 곡+시기에 엔트리 추가 시트 표시 가능
  - "이 곡에 새 시기 추가" 버튼 → RecordFlowView를 곡이 미리 선택된 상태로 열기
  - 삭제: 시기 카드를 swipeActions로 삭제 (확인 모달 `.actionCheckModal`)

### 기능 4: 새 기록 작성 플로우

- **설명**: 플로팅 버튼을 눌러 새 곡 기록을 작성한다. 단계별 플로우로 진행된다.
- **사용자 스토리**: 메인 화면의 `+` 버튼을 탭하면 전체 화면으로 기록 작성 플로우가 시작된다. Step 1에서 곡을 검색/선택하고, Step 2에서 감정 태그를 고르고, Step 3에서 텍스트를 쓰고 년도와 장소를 입력한 뒤 저장한다.
- **관련 파일**:
  - View: `RecordFlowView.swift`, `SongSearchView.swift`, `MoodSelectionView.swift`, `EntryWriteView.swift`, `ManualSongInputView.swift`
  - ViewModel: `RecordFlowViewModel.swift`, `SongSearchViewModel.swift`
  - Service: `MusicSearchService.swift`, `SongMemoryService.swift`
- **사용 API**: MusicKit (MusicCatalogSearchRequest), Supabase Database (INSERT)
- **HIG 패턴**: fullScreenCover, 단계별 진행 (TabView style page 또는 custom step navigation), 하단 고정 버튼(`BottomPlacedButton`)
- **세부 동작**:

  **Step 1 — 곡 검색**:
  - `PTextField`로 검색어 입력, debounce 0.5초
  - MusicKit `MusicCatalogSearchRequest`로 카탈로그 검색
  - 결과를 `SearchedSong` 모델로 매핑하여 리스트 표시 (앨범 커버 + 곡 제목 + 아티스트)
  - 곡 탭 → 선택 완료, 다음 단계로
  - MusicKit 권한 거부 시: `ManualSongInputView`로 전환 (곡 제목/아티스트명 직접 입력)
  - MusicKit 권한 상태는 `MusicSearchService`에서 `MusicAuthorization.request()` 호출 후 판단

  **Step 2 — 감정 태그 선택**:
  - `MoodChipGridView`로 카테고리별 감정 태그 표시
  - `PChip(variant: .toggle)` 사용, 다중 선택
  - 카테고리별 `PSectionHeader`로 그룹핑
  - 최소 1개 선택 필수 → 선택 전에는 다음 버튼 비활성화

  **Step 3 — 텍스트 작성 + 년도/장소**:
  - 배경: 선택한 곡의 앨범 아트워크 블러
  - 텍스트 영역: 자유 텍스트 작성 (TextEditor, 글래스 스타일)
  - 년도 선택: `PDropdownButton` 또는 Picker (예: 2000~현재년도)
  - 장소 입력: `PTextField` (선택 사항, 자유 텍스트)
  - 저장 버튼: `BottomPlacedButton(title: "기록 남기기")`
  - 저장 시: 동일 곡+년도 조합이 이미 있으면 해당 행의 entries에 추가 (UPDATE), 없으면 새 행 생성 (INSERT)
  - 저장 성공 → 토스트 표시 + dismiss

### 기능 5: 기존 곡+시기에 엔트리 추가

- **설명**: 이미 기록된 곡+시기 조합에 새 텍스트 엔트리를 추가한다.
- **사용자 스토리**: 곡 상세 타임라인에서 특정 시기 카드를 탭하면 엔트리 추가 시트가 올라온다. 텍스트를 작성하고 저장하면 해당 시기의 entries 배열에 새 엔트리가 누적된다.
- **관련 파일**:
  - View: `AddEntryView.swift`
  - ViewModel: `AddEntryViewModel.swift`
  - Service: `SongMemoryService.swift`
- **사용 API**: Supabase Database (SELECT 기존 entries → append → UPDATE)
- **HIG 패턴**: `.pBottomSheet` 또는 `.sheet`
- **세부 동작**:
  - 기존 entries 목록 표시 (읽기 전용)
  - 하단에 텍스트 입력 + 저장 버튼
  - 저장 시: 기존 entries 배열에 새 Entry 추가 → Supabase UPDATE
  - 성공 → 토스트 + dismiss

### 기능 6: MusicKit 곡 검색 (카탈로그)

- **설명**: Apple Music 카탈로그에서 곡을 검색하여 메타데이터를 가져온다. 재생 기능 없음.
- **사용자 스토리**: 새 기록 작성 시 곡 검색 단계에서 검색어를 입력하면 실시간으로 Apple Music 곡 결과가 표시된다.
- **관련 파일**:
  - ViewModel: `SongSearchViewModel.swift`
  - Service: `MusicSearchService.swift`
  - Model: `SearchedSong.swift`
- **사용 API**: MusicKit (`MusicCatalogSearchRequest`, `Song`, `Artwork`)
- **세부 동작**:
  - `MusicSearchService`가 `MusicAuthorization.request()` 호출
  - 권한 `.authorized` → 카탈로그 검색 활성
  - 권한 `.denied` / `.restricted` → `SongSearchViewModel.isMusicKitDenied = true` → View가 수동 입력 UI로 전환
  - 검색 결과 `Song` → `SearchedSong` 매핑 (id, title, artistName, artworkURL)
  - 검색 limit: 25

### 기능 7: 감정 태그 시스템

- **설명**: 미리 정의된 대량 감정 태그 세트를 카테고리별로 제공하고, PChip으로 다중 선택한다.
- **관련 파일**:
  - Model: `MoodTag.swift`
  - View: `MoodChipGridView.swift`
- **세부 동작**:
  - `MoodCategory` enum: 카테고리 정의 (아래 목록)
  - `MoodTag` struct: 태그명 + 카테고리
  - `MoodChipGridView`: 카테고리별 `PSectionHeader` + `LazyVGrid`의 `PChip(variant: .toggle)`

  **감정 태그 전체 목록** (Generator가 `MoodTag.swift`에 정의):

  | 카테고리 | 태그 |
  |---------|------|
  | 설렘/기쁨 | 설렘, 행복, 기쁨, 벅참, 두근거림, 들뜸, 황홀, 짜릿함 |
  | 평온/감사 | 평온, 감사, 포근함, 따뜻함, 안도, 편안함, 충만함 |
  | 그리움/향수 | 그리움, 아련함, 향수, 먹먹함, 추억, 회상 |
  | 슬픔/외로움 | 슬픔, 외로움, 허전함, 우울, 눈물, 쓸쓸함, 서글픔 |
  | 에너지/자신감 | 신남, 열정, 자신감, 용기, 의지, 에너지, 활력 |
  | 차분/몽환 | 잔잔함, 몽환, 여유, 나른함, 고요함, 사색 |
  | 위로/치유 | 위로, 치유, 공감, 다독임, 희망, 용서 |
  | 계절/날씨 | 비 오는 날, 눈 오는 날, 바람 부는 날, 여름밤, 가을 햇살, 봄바람 |
  | 장소/상황 | 드라이브, 새벽, 밤산책, 혼자인 시간, 여행 중, 카페에서 |

---

## API 활용 계획

### MusicKit

- **사용 타입**: `MusicAuthorization`, `MusicCatalogSearchRequest`, `Song`, `Artwork`, `MusicItemCollection`
- **권한 요청 시점**: `RecordFlowView` 진입 시 (곡 검색 단계 시작 전) `MusicSearchService.requestAuthorization()` 호출
- **연동 기능**: 곡 검색, 앨범 아트워크 URL 추출
- **에러 처리**: 권한 거부 → 수동 입력 폴백, 네트워크 에러 → 토스트 안내
- **제약**: 재생 기능 없음. 카탈로그 조회만.

### Supabase Auth (Apple Sign In)

- **사용 타입**: `SupabaseClient.auth`, `OpenIDConnectCredentials`, `Session`, `User`
- **권한 요청 시점**: `SignInView`에서 사용자가 Apple Sign In 버튼 탭 시
- **연동 기능**: Apple ID Token → Supabase `signInWithIdToken` → 세션 생성
- **에러 처리**: 인증 실패 → 토스트 에러 안내
- **세션 관리**: 앱 시작 시 `supabase.auth.session` 확인, 세션 만료/로그아웃 → `SignInView`로 전환

### Supabase Database

- **사용 타입**: `SupabaseClient.from()`, PostgrestFilterBuilder
- **연동 기능**: `song_memories` 테이블 CRUD
- **RLS**: `owner_id = auth.uid()` 정책. 서버에서 자동 필터하지만 클라이언트에서도 명시적 필터 권장
- **에러 처리**: 네트워크 에러 / RLS 거부 → `AppError`로 변환 → ViewModel → 토스트

---

## 뷰 계층 (Navigation Flow)

```
DearSongApp.swift
├── [인증 확인]
│   ├── 미인증 → SignInView
│   │   └── Apple Sign In → 인증 성공 → SongCollectionView
│   └── 인증됨 → SongCollectionView
│
├── SongCollectionView (NavigationStack root)
│   ├── NavigationLink → SongDetailView (곡 상세)
│   │   ├── 시기 카드 탭 → AddEntryView (.sheet)
│   │   └── "새 시기 추가" → RecordFlowView (.fullScreenCover, 곡 pre-selected)
│   │
│   └── 플로팅 + 버튼 → RecordFlowView (.fullScreenCover)
│       ├── Step 1: SongSearchView (또는 ManualSongInputView)
│       ├── Step 2: MoodSelectionView
│       └── Step 3: EntryWriteView → 저장 → dismiss
│
└── 로그아웃 → SignInView
```

### 내비게이션 패턴

- **메인 → 상세**: `NavigationStack` + `NavigationLink` (HIG 표준 push)
- **새 기록 작성**: `.fullScreenCover` (몰입형 플로우, 취소 가능)
- **엔트리 추가**: `.sheet` 또는 `.pBottomSheet` (간단한 추가 작업)
- **확인/삭제**: `.actionCheckModal` (파괴적 작업 확인)

---

## 데이터 모델 상세

### SongMemory (Models/SongMemory.swift)

```
struct SongMemory: Identifiable, Sendable, Codable
- id: UUID (PK)
- ownerId: UUID (FK auth.users)
- appleMusicId: String? (Apple Music 곡 ID)
- songTitle: String
- artistName: String
- artworkUrl: String? (앨범 커버 URL)
- listenedAt: Date (들었던 시기 — 년도 단위)
- moodTags: [String] (감정 태그 배열)
- location: String? (들었던 장소)
- entries: [Entry] (텍스트 기록 누적)
- attachments: [Attachment] (v1 미사용)
- createdAt: Date
- updatedAt: Date
+ CodingKeys: snake_case ↔ camelCase 매핑
```

### Entry (Models/SongMemory.swift)

```
struct Entry: Identifiable, Sendable, Codable
- id: UUID
- text: String
- writtenAt: Date (작성 시각)
```

### Attachment (Models/SongMemory.swift)

```
struct Attachment: Identifiable, Sendable, Codable
- id: UUID
- type: String
- url: String
(v1 미사용 — 스키마 예비)
```

### SearchedSong (Models/SearchedSong.swift)

```
struct SearchedSong: Identifiable, Sendable
- id: String (MusicItemID → String)
- title: String
- artistName: String
- artworkURL: URL?
- albumTitle: String?
```

### MoodCategory (Models/MoodTag.swift)

```
enum MoodCategory: String, CaseIterable, Sendable
- excitement (설렘/기쁨)
- peace (평온/감사)
- nostalgia (그리움/향수)
- sadness (슬픔/외로움)
- energy (에너지/자신감)
- calm (차분/몽환)
- comfort (위로/치유)
- season (계절/날씨)
- situation (장소/상황)
+ displayName: String (한국어 카테고리명)
+ tags: [String] (해당 카테고리의 태그 목록)
```

---

## Service 계층 상세

### SupabaseClientProvider (Services/SupabaseClientProvider.swift)

- Info.plist에서 `SupabaseURL`, `SupabaseAnonKey` 읽기
- `SupabaseClient` 인스턴스를 싱글턴으로 제공
- 앱 전체에서 하나의 클라이언트 공유

### AuthService (Services/AuthService.swift)

```
actor AuthService
- func signInWithApple(idToken: String, nonce: String) async throws -> UUID
- func getCurrentSession() async throws -> Session?
- func getCurrentUserId() async throws -> UUID
- func signOut() async throws
- 에러: enum AuthError: Error { case invalidCredentials, sessionExpired, signOutFailed }
```

### SongMemoryService (Services/SongMemoryService.swift)

```
actor SongMemoryService
- func fetchAllMemories(ownerId: UUID) async throws -> [SongMemory]
- func fetchMemoriesBySong(ownerId: UUID, appleMusicId: String) async throws -> [SongMemory]
- func fetchMemoriesBySongTitle(ownerId: UUID, songTitle: String, artistName: String) async throws -> [SongMemory]
- func createMemory(_ memory: SongMemory) async throws
- func addEntry(memoryId: UUID, entry: Entry) async throws
- func deleteMemory(memoryId: UUID) async throws
- func findExistingMemory(ownerId: UUID, appleMusicId: String?, songTitle: String, artistName: String, listenedAt: Date) async throws -> SongMemory?
- 에러: enum SongMemoryError: Error { case fetchFailed, createFailed, updateFailed, deleteFailed, notFound }
```

### MusicSearchService (Services/MusicSearchService.swift)

```
actor MusicSearchService
- func requestAuthorization() async -> MusicAuthorization.Status
- func searchSongs(query: String, limit: Int = 25) async throws -> [SearchedSong]
- 에러: enum MusicSearchError: Error { case unauthorized, searchFailed, networkError }
```

---

## ViewModel 계층 상세

### AuthViewModel (ViewModels/AuthViewModel.swift)

```
@MainActor @Observable final class AuthViewModel
- var isAuthenticated: Bool
- var isLoading: Bool
- var errorMessage: String?
- func checkSession() async
- func signInWithApple(authorization: ASAuthorization) async
- func signOut() async
- 의존: AuthService
```

### SongCollectionViewModel (ViewModels/SongCollectionViewModel.swift)

```
@MainActor @Observable final class SongCollectionViewModel
- var groupedSongs: [GroupedSong] (곡 단위 그룹핑)
- var isLoading: Bool
- var errorMessage: String?
- func loadMemories() async
- func refresh() async
- 의존: SongMemoryService, AuthService
```

`GroupedSong`: 동일 곡(appleMusicId 또는 songTitle+artistName)의 SongMemory 배열을 그룹핑한 뷰 전용 구조체. 대표 아트워크, 곡 제목, 아티스트명, 기록 수를 포함.

### SongDetailViewModel (ViewModels/SongDetailViewModel.swift)

```
@MainActor @Observable final class SongDetailViewModel
- var memories: [SongMemory] (시기별 기록, listened_at 내림차순)
- var isLoading: Bool
- var errorMessage: String?
- func loadMemories(appleMusicId: String?, songTitle: String, artistName: String) async
- func deleteMemory(id: UUID) async
- 의존: SongMemoryService, AuthService
```

### RecordFlowViewModel (ViewModels/RecordFlowViewModel.swift)

```
@MainActor @Observable final class RecordFlowViewModel
- var currentStep: RecordStep (enum: songSearch, moodSelection, entryWrite)
- var selectedSong: SearchedSong?
- var selectedMoodTags: Set<String>
- var entryText: String
- var selectedYear: Int
- var location: String
- var isManualInput: Bool
- var manualSongTitle: String
- var manualArtistName: String
- var isSaving: Bool
- var errorMessage: String?
- func goToNextStep()
- func goToPreviousStep()
- func save() async
- 의존: SongMemoryService, AuthService
```

### SongSearchViewModel (ViewModels/SongSearchViewModel.swift)

```
@MainActor @Observable final class SongSearchViewModel
- var query: String
- var results: [SearchedSong]
- var isSearching: Bool
- var isMusicKitDenied: Bool
- var errorMessage: String?
- func requestAuthorization() async
- func search() async (debounce 적용)
- 의존: MusicSearchService
```

### AddEntryViewModel (ViewModels/AddEntryViewModel.swift)

```
@MainActor @Observable final class AddEntryViewModel
- var entryText: String
- var existingEntries: [Entry]
- var isSaving: Bool
- var errorMessage: String?
- func save(memoryId: UUID) async
- 의존: SongMemoryService
```

---

## 에러 처리 전략

### AppError (Shared/AppError.swift)

```
enum AppError: Error, LocalizedError
- case auth(AuthError)
- case songMemory(SongMemoryError)
- case musicSearch(MusicSearchError)
- case network
- case unknown(Error)
+ errorDescription: String? (사용자 친화적 메시지)
```

### 에러 표시 원칙

- 네트워크/서버 에러 → `PToastManager.show(message, type: .error)`
- 입력 검증 에러 → `PFormField(state: .error(message))`
- 권한 거부 → 인라인 안내 문구 + 대안 UI (수동 입력)
- 파괴적 작업 실패 → 토스트 에러

---

## 디자인 시스템 적용 계획

### 전역 설정 (DearSongApp.swift)

- `.pTheme(.autumn)` — 감성 앱에 어울리는 따뜻한 톤 (Generator가 최적 테마 선택)
- `@State var toastManager = PToastManager()` + `.environment(toastManager)` + `.pGlobalToast(toastManager)`

### 배경

- 메인: `PGradientBackground()`
- 곡 상세: 앨범 아트워크 AsyncImage blur + 반투명 오버레이
- 기록 작성: 앨범 아트워크 blur 배경

### 카드/컨테이너

- 곡 카드: `GlassCard { ... }` + `.pShadowLow()`
- 타임라인 시기 카드: `GlassCard { ... }`
- 플로팅 버튼: `PAccentGradient` 배경 + `.pShadowMid()`

### 타이포그래피

- 화면 제목: `Font.pTitle(20)`
- 곡 제목: `Font.pBodyMedium(16)`
- 아티스트명: `Font.pBody(14)` + `Color.pTextSecondary`
- 감정 태그: `Font.pCaption(13)`
- 년도 라벨: `Font.pTitle(17)`
- 엔트리 텍스트: `Font.pBody(15)`
- 빈 상태 메시지: `Font.pBody(16)` + `Color.pTextTertiary`

### 컴포넌트 매핑

| UI 요소 | 디자인 시스템 컴포넌트 |
|---------|---------------------|
| 감정 태그 | `PChip(variant: .toggle, isSelected:)` |
| 검색 필드 | `PTextField(placeholder:, text:)` |
| 저장 버튼 | `BottomPlacedButton(title:, action:)` |
| 삭제 확인 | `.actionCheckModal(isPresented:, title:, onConfirm:)` |
| 로딩 | `.pLoadingOverlay(isLoading:)` |
| 토스트 | `PToastManager.show(_, type:)` |
| 빈 상태 | `EmptyStateView(...)` |
| 카테고리 헤더 | `PSectionHeader(title:)` |
| 구분선 | `PDivider()` |
| 년도 선택 | `PDropdownButton(selection:, options:)` |
| 탭 효과 | `.pressable(scale: 0.95, haptic: true)` |

### 애니메이션

- 화면 전환: `PAnimation.spring`
- 카드 탭: `.pressable(scale: 0.97, haptic: true)`
- 칩 선택: `PAnimation.springFast`
- 리스트 나타남: `PAnimation.easeOut` + stagger
- 저장 성공 피드백: `HapticManager.notification(.success)`

### 금지 사항

- 하드코딩 색상 (`Color.blue`, `Color(red:green:blue:)`) 사용 금지
- 하드코딩 폰트 (`.font(.system(size:))`) 사용 금지
- 디자인 시스템에 있는 컴포넌트 자체 구현 금지

---

## 코드 컨벤션 (Generator가 따를 것)

- 뷰 파일: `[Feature]View.swift`
- 뷰모델 파일: `[Feature]ViewModel.swift`
- 서비스 파일: `[Feature]Service.swift`
- 모델 파일: `[Model].swift`
- 접근 제어자 명시: `private`, `private(set)`, `internal`, `public`
- 에러 타입: `enum [Domain]Error: Error`
- ViewModel에 `import SwiftUI` 금지 (`import Foundation` + `import Observation` 사용)
- View에서 비즈니스 로직 금지 (Service 직접 호출 금지)
- `DispatchQueue`, `@Published`, `ObservableObject` 사용 금지
- CodingKeys로 snake_case ↔ camelCase 매핑 명시
- 모든 비동기 작업에 do-catch 에러 처리

---

## 보존 파일 (Generator 덮어쓰기 금지)

- `DearSong/Assets.xcassets/` — 에셋 카탈로그
- `DearSong.entitlements` — 엔타이틀먼트 설정
- `Secrets.xcconfig` — 시크릿 (gitignore 대상)

---

## 스코프 외 (v1 미구현)

- 음악 재생 기능
- attachments (첨부 파일) UI/로직
- 오프라인 지원
- 검색/필터 기능 (곡 컬렉션 내)
- 다국어 지원
- Widget / AppIntent
