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

---

# Round 2 — UI Polish

> 이 섹션은 1차 파이프라인 산출물의 UI 마감 품질을 끌어올리는 **별도 라운드**다.
> Generator는 이 섹션의 작업 지시서를 그대로 따라 기존 화면을 수정한다.
> **새로운 기능 추가 금지.** 화면 구조/네비게이션은 그대로 두고, 디자인 시스템 일관성/반응형/HIG 준수만 끌어올린다.

## 목표

기존 1차 Generator 산출물(`output/Views/*`)의 UI를 다음 기준으로 전수 점검·수정한다:

1. **PROJECT_CONTEXT.md 디자인 시스템(`PersonalColorDesignSystem`) 토큰 100% 적용**
2. **반응형 레이아웃**: iPhone SE 3rd (4.7") ~ iPhone 17 Pro Max (6.9") + Dynamic Island/노치/홈인디케이터 모두 대응
3. **HIG 필수 항목**: Dynamic Type, 44pt 터치 영역, Safe Area 정확 처리, Empty/Loading/Error 상태
4. **String Catalog 키 100% 적용** (`Localizable.xcstrings` 누락 키 자동 추가)
5. **존댓말 톤 유지** (PROJECT_CONTEXT 명시)

---

## 1차 점검 결과 — 발견된 위반 사항

### CRITICAL: AppTheme.swift 자체 구현 (디자인 시스템 위반)

`output/Shared/AppTheme.swift`는 PROJECT_CONTEXT가 명시한 `PersonalColorDesignSystem` 패키지를 우회하여 다음을 자체 정의함:

```
- AppTheme.background / cardBackground / accent / accentSecondary / accentSoft
- AppTheme.textPrimary / textSecondary / textTertiary
- AppTheme.divider / border / chipBackground
- AppTheme.cornerRadius / cornerRadiusSm / cornerRadiusXs
- struct NotebookTexture, struct AppBackground (PGradientBackground 대체)
- struct FlowLayout (Layout)
- struct MoodChipButton (PChip 대체)
- View.cardStyle() (GlassCard 대체)
```

→ 이 모든 토큰은 raw `Color(red: 0.97, green: 0.95, blue: 0.91)` 형태로 정의되어 PROJECT_CONTEXT의 "하드코딩 색상 금지" 규칙을 직접 위반함. 또한 패키지에 이미 있는 `GlassCard`, `GradientBackground`, `PChip` 등을 자체 재구현했음.

### 하드코딩 폰트 크기

다음 13개 View 파일에서 `.font(.system(size:))`가 광범위하게 사용됨 (총 80건+ 추정):
- `SignInView.swift` (line 21, 27, 31, 61)
- `SongCollectionView.swift` (line 54, 104, 109, 112, 121, 154)
- `SongDetailView.swift` (line 38, 41, 44, 143, 148, 161, 163)
- `RecordFlowView.swift` (line 49, 62, 82)
- `SongSearchView.swift` (line 37, 54, 98, 101, 107, 119, 124, 152, 157, 163, 174)
- `MoodSelectionView.swift` (line 21, 29, 32, 64, 68, 84, 93, 97)
- `EntryWriteView.swift` (line 42, 104, 108, 117, 139, 151, 162, 177, 194, 201)
- `ManualSongInputView.swift` (line 17, 30, 38, 53, 61)
- `AddEntryView.swift` (line 56, 104, 108, 117, 130, 136, 141, 156, 169, 180)
- `SongCardView.swift` (line 17, 22, 28, 31)
- `MoodChipGridView.swift` (line 25)
- `TimelineEntryView.swift` (line 19, 25, 28, 40, 57, 85, 90)

### 하드코딩 한국어 리터럴 (String Catalog 키 미사용)

거의 모든 Text/placeholder가 한국어 리터럴 그대로. 예: `Text("로그아웃")`, `Text("DearSong")`, `TextField("곡 제목 또는 아티스트 검색", ...)`. PROJECT_CONTEXT의 로컬라이제이션 규칙 위반.

### 반응형/디바이스 대응 미흡

- **고정 height 의존**: `SignInView` `.frame(height: 52)` (Apple 버튼), `SongDetailView` 헤더 아트워크 `size: 160` 고정
- **PLoadingOverlay/ProgressView 일관성**: `SongDetailView`만 `ProgressView()` 사용, 나머지는 `PLoadingOverlay`
- **수동 입력 필드 빨간 보더**: `Color.red.opacity(0.5)` raw 색상
- **AsyncImage 실패 폴백**에 `Color.brown` 사용 (AppTheme 안)

---

## 변경 영향 매트릭스

| 파일 | 핵심 점검/패치 항목 | 우선순위 |
|---|---|---|
| `Shared/AppTheme.swift` | **삭제 또는 어댑터화**. PersonalColorDesignSystem 토큰으로 1:1 매핑하는 thin shim만 유지하거나, 모든 호출 사이트를 직접 패키지 토큰으로 교체 후 파일 삭제 | **CRITICAL** |
| `Localizable.xcstrings` | 누락 키(`screen.*`, `action.*`, `empty.*`, `error.*`, `placeholder.*` 등) 추가 — ko/en 모두 | **High** |
| `Views/Auth/SignInView.swift` | 로고 영역 폰트/색상, Apple 버튼 height 적응형, 작은 화면 ScrollView 감싸기 | High |
| `Views/Collection/SongCollectionView.swift` | 그리드 컬럼이 작은 화면(SE)에서 깨지지 않도록 컬럼 spacing 검토, 로딩 스켈레톤이 디자인 시스템 컴포넌트로 교체, 빈 상태 CTA 44pt | High |
| `Views/Detail/SongDetailView.swift` | `ProgressView` → `PLoadingOverlay`/`PSkeletonLoader` 일관화, 헤더 아트워크 GeometryReader 비율, 빈 상태 정렬 | High |
| `Views/Record/RecordFlowView.swift` | 단계 인디케이터 색상/폰트 토큰화, navbar 좌우 버튼 44pt 보장(현재 OK), 작은 화면 navbar 텍스트 잘림 검토 | Med |
| `Views/Record/SongSearchView.swift` | 검색바 폰트, 결과 셀의 체크 아이콘 hit target, 검색 결과 행 전체 ScrollView 안전 영역 처리 | High |
| `Views/Record/MoodSelectionView.swift` | FlowLayout(자체) → 디자인 시스템 패턴으로, MoodChipButton → `PChip(variant: .toggle)`, 카테고리 헤더 → `PSectionHeader`, 안내 텍스트 폰트 토큰, **3개 선택 시 4번째 비활성/햅틱 처리는 PROJECT_CONTEXT 규칙(SPEC 1차 명세는 "최소 1개"로만 명시되어 있으나 PROJECT_CONTEXT의 최대 3개 규칙은 v1 우선 — 이번 라운드는 우선 폰트/색상/칩 컴포넌트 교체에 집중하고 3개 제한 로직은 ViewModel 수정 범위로 별도 표기) | **CRITICAL** |
| `Views/Record/EntryWriteView.swift` | TextEditor 키보드 회피(`.scrollDismissesKeyboard(.interactively)` + `.safeAreaInset`), 1000자 카운터(현재 누락), 저장 버튼 그라데이션 배경 토큰, 폰트/색상 전수 교체 | **CRITICAL** |
| `Views/Record/ManualSongInputView.swift` | 빨간 에러 보더 → 디자인 시스템 에러 색 토큰, 폰트/배경 교체, ScrollView 감싸기 | High |
| `Views/Entry/AddEntryView.swift` | 시트 헤더 폰트/색상 토큰, 기존 entries 카드 토큰화, TextEditor 키보드 회피, 저장 버튼 통일 | High |
| `Views/Components/SongCardView.swift` | 폰트/색상 토큰화, `.pressable(scale: 0.97, haptic: true)` 추가, lineLimit/minimumScaleFactor 적용 | Med |
| `Views/Components/MoodChipGridView.swift` | 자체 `MoodChipButton` → `PChip(variant: .toggle)`, FlowLayout 유지 OK | High |
| `Views/Components/TimelineEntryView.swift` | 자체 `cardStyle()` → `GlassCard`, FlowLayout 그대로, 폰트/색상 전수 교체, mood pill을 PChip(variant: .display)로 통일 | High |
| `Views/Components/AlbumArtworkView.swift` | 폴백 placeholder 색상 토큰화, size: nil 케이스 aspectRatio 보장 | Med |

---

## 작업 지시 (Generator에게)

### Step 1 — `Shared/AppTheme.swift` 처리 (선택지 둘 중 하나)

**선택지 A (권장): AppTheme.swift 삭제 + 모든 호출 사이트 직접 교체.**

각 토큰을 다음 매핑으로 일괄 치환:

| 기존 (AppTheme) | 교체 (PersonalColorDesignSystem) |
|---|---|
| `AppTheme.background` | `Color.pBackgroundTop` (혹은 `PGradientBackground()` 컨테이너) |
| `AppTheme.cardBackground` | `Color.pGlassFill` (또는 GlassCard 안으로 이동) |
| `AppTheme.accent` | `Color.pAccentPrimary` |
| `AppTheme.accentSecondary` | `Color.pAccentSecondary` (없으면 `pAccentPrimary.opacity(0.7)`) |
| `AppTheme.accentSoft` | `Color.pAccentPrimary.opacity(0.12)` 또는 `Color.pAccentSoft`가 있으면 그것 |
| `AppTheme.textPrimary` | `Color.pTextPrimary` |
| `AppTheme.textSecondary` | `Color.pTextSecondary` |
| `AppTheme.textTertiary` | `Color.pTextTertiary` (없으면 `pTextSecondary.opacity(0.7)`) |
| `AppTheme.divider` | `Color.pDivider` 또는 `Color.pGlassBorder` |
| `AppTheme.border` | `Color.pGlassBorder` |
| `AppTheme.chipBackground` | `Color.pGlassFill` (PChip 컴포넌트로 대체 시 불필요) |
| `AppTheme.chipSelectedBackground` | `Color.pAccentPrimary.opacity(0.15)` |
| `AppTheme.chipSelectedBorder` | `Color.pAccentPrimary.opacity(0.5)` |
| `AppTheme.cornerRadius` (16) | `PRadius.lg` |
| `AppTheme.cornerRadiusSm` (12) | `PRadius.md` |
| `AppTheme.cornerRadiusXs` (8) | `PRadius.sm` |
| `struct AppBackground` | `PGradientBackground()` |
| `struct NotebookTexture` | **삭제**. 노트 줄선 무늬는 디자인 시스템 토큰만으로 표현 가능한 범위로 축소. 굳이 줄선이 필요한 화면(EntryWriteView/AddEntryView)은 `PGradientBackground()` 위에 매우 얇은 `Color.pGlassBorder.opacity(0.05)` 횡선 패턴만 옵션으로 유지. |
| `struct FlowLayout` | **유지 OK** (디자인 시스템에 동등 컴포넌트 없음). 다만 `Layout` 구현은 `PSpacing.sm`(8) 기본값 사용. |
| `struct MoodChipButton` | **삭제**. 모든 호출을 `PChip(variant: .toggle, isSelected: ...) { Text(tag) }` 형태로 교체. 시그니처가 다르면 `PChipToggle` 등 패키지가 제공하는 동등 API 사용. |
| `View.cardStyle()` | **삭제**. 모든 호출을 `GlassCard { ... }` 컨테이너로 감싸는 방식으로 변경. |
| `accentGradient()` | `PAccentGradient()` 또는 `LinearGradient` + `pAccentPrimary/pAccentSecondary` |

**선택지 B (시간 부족 시 fallback): AppTheme.swift를 thin shim으로 변환.**

```swift
import SwiftUI
import PersonalColorDesignSystem

enum AppTheme {
    static let background = Color.pBackgroundTop
    static let cardBackground = Color.pGlassFill
    static let accent = Color.pAccentPrimary
    static let accentSecondary = Color.pAccentSecondary  // 또는 pAccentPrimary.opacity(0.7)
    static let textPrimary = Color.pTextPrimary
    static let textSecondary = Color.pTextSecondary
    static let textTertiary = Color.pTextTertiary
    static let divider = Color.pDivider
    static let border = Color.pGlassBorder
    static let chipBackground = Color.pGlassFill
    static let chipSelectedBackground = Color.pAccentPrimary.opacity(0.15)
    static let chipSelectedBorder = Color.pAccentPrimary.opacity(0.5)
    static let cornerRadius: CGFloat = PRadius.lg
    static let cornerRadiusSm: CGFloat = PRadius.md
    static let cornerRadiusXs: CGFloat = PRadius.sm
}
```

이 경우라도 `AppBackground`/`NotebookTexture`/`MoodChipButton`/`cardStyle()`/`FlowLayout` 중 디자인 시스템에 동등 컴포넌트가 있는 것은 호출부에서 패키지 컴포넌트로 직접 교체하라.

> Generator 판단: 패키지 API 존재 여부를 컴파일/문서로 확인 후 **선택지 A를 우선 시도**. 패키지에 일부 토큰(예: `pAccentSecondary`, `pTextTertiary`)이 없으면 가까운 토큰(`pAccentPrimary.opacity(0.7)`, `pTextSecondary.opacity(0.7)`)으로 fallback하되, raw `Color(red:green:blue:)`는 절대 금지.

### Step 2 — 폰트 일괄 교체

모든 `.font(.system(size: N, weight: W))`를 다음 매핑으로 교체:

| 기존 size | 교체 |
|---|---|
| 11~12 | `Font.pCaption(12)` 또는 `.font(.caption2)` (둘 다 디자인 시스템에 있는 쪽 우선) |
| 13~14 | `Font.pBody(14)` |
| 15~16 (regular) | `Font.pBody(15)` 또는 `Font.pBodyMedium(15)` (weight=.medium 일 때) |
| 15~16 (semibold/bold) | `Font.pBodyMedium(16)` |
| 17~18 | `Font.pTitle(17)` |
| 20~24 | `Font.pTitle(20)` |
| 28~36 | `Font.pDisplay(32)` |
| 40+ | `Font.pDisplay(40)` |
| design: .serif (SignInView 로고) | `Font.pDisplay(36)` (디자인 시스템 폰트가 충분히 표현력 있다면 serif 옵션 제거) |

또한 모든 텍스트에 다음을 적절히 추가:
- 타이틀/제목류(곡 제목, 화면 제목): `.minimumScaleFactor(0.85)` + `.lineLimit(2)` (이미 있는 곳은 유지)
- 본문(answers, 빈 상태 메시지): `.fixedSize(horizontal: false, vertical: true)`
- 한 줄 메타(아티스트명, 년도): `.lineLimit(1)` + `.truncationMode(.tail)` (이미 있는 곳은 유지)

### Step 3 — 화면별 패치

#### 3.1 `SignInView.swift`
- 전체를 `ScrollView` + `.frame(minHeight: geometry.size.height)` 또는 단순 `VStack` + `Spacer()` 비율 유지로 작은 화면(SE 3rd, 4.7")에서도 잘리지 않게 한다.
- 로고 `Image(systemName: "music.note.list")` → `Font.pDisplay(56)` (또는 패키지 아이콘 사이즈 토큰)
- "DearSong" 로고 텍스트: `Font.pDisplay(36)` + `Color.pTextPrimary`
- 부제 "노래에 감정을 기록하는…" → `Text("screen.signin.tagline")` 키
- Apple 버튼 `.frame(height: 52)` → `.frame(minHeight: 50, maxHeight: 56)` 적응형
- 약관 문구 영역(`Text("Apple ID로 안전하게…")`) → `Text("screen.signin.subtitle")` 키 + `.fixedSize(horizontal: false, vertical: true)`
- 백그라운드 `AppBackground()` → `PGradientBackground()`
- 모든 색상 토큰 교체

#### 3.2 `SongCollectionView.swift`
- 그리드 컬럼: 현재 2열 고정. 작은 화면(SE)에서도 카드 세로 비율(`aspectRatio(1, contentMode: .fit)`) 유지되므로 OK. 다만 `LazyVGrid spacing: 14` → `PSpacing.md` 토큰으로 교체.
- `loadingView`(자체 스켈레톤 그리드) → `PSkeletonLoader(preset: .card)` × 4 또는 디자인 시스템 스켈레톤 컴포넌트 사용. 자체 RoundedRectangle 제거.
- `emptyStateView` → `EmptyStateView(icon: ..., title: Text("empty.home.title"), message: Text("empty.home.message"), action: ...)` 디자인 시스템 컴포넌트로 교체. 만약 디자인 시스템에 없으면 직접 구성하되 모든 폰트/색상은 토큰.
- 빈 상태 CTA 버튼 `.frame(...)` → `BottomPlacedButton` 또는 `CommonButton` 사용. 최소 44pt height 보장.
- 플로팅 + 버튼: `.frame(width: 56, height: 56)` 유지(HIG 권장 FAB 크기). 색상 토큰 교체.
- `.toolbar`의 "로그아웃" Button: `Text("action.signout")` 키 + 폰트 토큰
- `navigationTitle("DearSong")` → `navigationTitle(Text("screen.home.title"))` 키 + LocalizedStringKey
- 모든 `.padding(20)` → `PSpacing.lg`, `.padding(.bottom, 80)` → `PSpacing.xxl + PSpacing.lg` 등

#### 3.3 `SongDetailView.swift`
- 헤더 아트워크 `size: 160` → 작은 화면 대응:
  ```swift
  GeometryReader { geo in
      let size = min(geo.size.width * 0.5, 200)
      AlbumArtworkView(urlString: ..., size: size, ...)
  }
  .frame(height: 200)  // 또는 .aspectRatio
  ```
  또는 단순히 `.frame(maxWidth: 200)` + `.aspectRatio(1, contentMode: .fit)`로 비율 유지.
- 로딩 상태 `ProgressView()` → `PSkeletonLoader(preset: .card)` × 3 (다른 화면 일관성)
- 빈 상태 `VStack` → `EmptyStateView` 컴포넌트로
- 배경의 `AppBackground()` → `PGradientBackground()`
- 곡 제목/아티스트명 폰트 토큰 교체 + `.minimumScaleFactor(0.8)` 추가
- "이 곡의 새 시기 추가" 버튼: 자체 구현 → `CommonButton(style: .secondary)` 또는 동등 컴포넌트
- contextMenu 라벨 → `Label(Text("action.delete"), systemImage: "trash")`
- 모든 텍스트를 `Text("screen.songdetail.*")` 키로

#### 3.4 `RecordFlowView.swift`
- 네비바 stepTitle `Text(stepTitle)`: 폰트 토큰 + `Text("screen.record.step.songsearch")` 등 키 매핑 (`stepTitle` computed property를 LocalizedStringKey 반환으로 변경)
- 단계 인디케이터 Capsule: 토큰 색상 사용
- chevron.left / xmark 버튼: 이미 44x44 OK. 색상만 토큰 교체.
- `.padding(.horizontal, 16)` → `PSpacing.md`

#### 3.5 `SongSearchView.swift`
- 검색바 자체 구현 → `PTextField(placeholder: "placeholder.search.song", text: $query, leadingIcon: "magnifyingglass")` (패키지 컴포넌트 사용)
- 스켈레톤 자체 구현(line 70~92) → `PSkeletonLoader(preset: .row)` × 5
- 빈 결과/초기 상태: `EmptyStateView` 컴포넌트
- "직접 입력하기" 버튼: `CommonButton(style: .text)` 또는 `Button` + `.font(Font.pBodyMedium(15))` + `.frame(minHeight: 44)`
- songResultRow의 체크 아이콘 hit target: 현재 Image만 있어 hit target 부족. 부모 Button이 row 전체이므로 OK이지만, 체크 아이콘 자체를 `Color.pAccentPrimary` 토큰으로
- 모든 폰트/색상 토큰 교체
- 결과 행에 `.frame(minHeight: 64)` 추가 (현재 padding으로 약 60pt — 안전하게 64pt 보장)
- 모든 텍스트 String Catalog 키화

#### 3.6 `MoodSelectionView.swift`
- `MoodChipButton`(자체) → `PChip(variant: .toggle, isSelected:)` 사용으로 변경 (`MoodChipGridView` 안에서)
- 카테고리 헤더 `Text(category.displayName)` → `PSectionHeader(title: category.displayName)`
- 안내 텍스트 `"이 곡을 들었을 때의 감정을 선택하세요"` → `Text("screen.mood.guide")` 키 + `Font.pBody(14)`
- 선택된 태그 수 표시 영역 → `Font.pCaption(12)` + 색상 토큰
- selectedSongBanner / manualSongBanner의 폰트/색상 토큰 교체, `GlassCard` 컨테이너 사용
- 백그라운드는 RecordFlowView가 이미 `AppBackground()` → `PGradientBackground()` 깔고 있으므로 자체 background 추가 금지

#### 3.7 `EntryWriteView.swift`
- 가장 큰 화면. 키보드 회피 필수:
  ```swift
  ScrollView { ... }
      .scrollDismissesKeyboard(.interactively)
  ```
- 저장 버튼: 현재 `VStack { Spacer(); Button { ... } }` 오버레이 → `.safeAreaInset(edge: .bottom) { saveButton }` 패턴으로 변경
- 저장 버튼 자체: 자체 구현 → `BottomPlacedButton(title: Text("action.save.record"), action: { ... })` 사용
- TextEditor 영역: 현재 ZStack + RoundedRectangle 자체 구현 → `PFormField(state: .normal) { TextEditor(...) }` 또는 디자인 시스템 텍스트에디터 컴포넌트
- 1000자 카운터: PROJECT_CONTEXT의 "각 DiaryEntry.answer 최대 1000자, 실시간 카운터 `n/1000`" 규칙에 따라 추가:
  ```swift
  HStack {
      Spacer()
      Text("\(viewModel.entryText.count)/1000")
          .font(Font.pCaption(11))
          .foregroundStyle(viewModel.entryText.count > 1000 ? Color.red : Color.pTextTertiary)
  }
  ```
- 년도 선택 `PDropdownButton`: 이미 패키지 컴포넌트 사용 OK. 라벨 폰트 토큰만 교체.
- 장소 입력 TextField → `PTextField(placeholder: "placeholder.location", text: $location, leadingIcon: "mappin.circle")`
- 모든 라벨/플레이스홀더 String Catalog 키
- summaryCard `.cardStyle()` → `GlassCard { ... }` 컨테이너

#### 3.8 `ManualSongInputView.swift`
- 안내 배너 → `PBanner(style: .info, message: ...)` 또는 동등 컴포넌트
- 입력 필드 → `PTextField` × 2
- 빨간 보더 `Color.red.opacity(0.5)` → `Color.pError` 또는 `Color.pAccentPrimary.opacity(0.5)` (패키지에 에러 토큰 없으면 후자)
- 전체를 `ScrollView`로 감싸기 (작은 화면에서 키보드 올라오면 잘림)
- `Spacer()` → `Spacer(minLength: PSpacing.xl)`

#### 3.9 `AddEntryView.swift`
- 시트 헤더 폰트/색상 토큰
- xmark.circle.fill 닫기 버튼: 이미 44x44 OK. 색상 토큰만.
- 기존 entries 카드: 자체 RoundedRectangle → `GlassCard` 또는 `PCard` 컴포넌트
- TextEditor: EntryWriteView와 동일 패턴 (`PFormField`/`safeAreaInset`)
- 저장 버튼: `BottomPlacedButton`
- 모든 폰트/색상 토큰

#### 3.10 `Components/SongCardView.swift`
- 자체 `cardStyle()` → `GlassCard` 컨테이너
- 폰트 토큰 교체
- `.pressable(scale: 0.97, haptic: true)` 추가 (Evaluator R2 권고 사항)
- 곡 제목 `.lineLimit(2)` 유지 + `.minimumScaleFactor(0.9)` 추가
- "n개의 기록" → `Text("songcard.records.count \(count)")` 또는 `String(localized: "songcard.records.count")` 패턴

#### 3.11 `Components/MoodChipGridView.swift`
- `MoodChipButton`(자체) → `PChip(variant: .toggle, isSelected: isSelected) { Text(tag) }` 형태
- 카테고리 헤더 → `PSectionHeader(title: category.displayName)`
- ScrollView 유지 OK

#### 3.12 `Components/TimelineEntryView.swift`
- 자체 `cardStyle()` → `GlassCard { ... }`
- mood pill → `PChip(variant: .display) { Text(tag) }`
- 폰트/색상 토큰 일괄 교체
- 년도 헤더 `\(yearString)년` → `Text("timeline.year \(year)")` String Catalog 패턴
- entry 카드 `Color.chipBackground` → `Color.pGlassFill` 또는 nested GlassCard

#### 3.13 `Components/AlbumArtworkView.swift`
- placeholder 색상 `AppTheme.chipBackground` → `Color.pGlassFill`
- placeholder 아이콘 색상 토큰 교체
- size: nil 케이스 (`SongCardView`에서 사용) `.aspectRatio(1, contentMode: .fit)` 자동 보장 OK
- placeholder의 `Image(systemName: "music.note")`도 디자인 시스템에 동등 아이콘 토큰이 있으면 사용

### Step 4 — String Catalog (`Localizable.xcstrings`) 업데이트

기존 mood.* / prompt.* 외에 다음 키 추가 (ko/en 표):

| 키 | ko (존댓말) | en |
|---|---|---|
| `screen.signin.tagline` | 노래에 감정을 기록하는 음악 다이어리 | A music diary for the feelings in your songs |
| `screen.signin.subtitle` | Apple ID로 안전하게 로그인하실 수 있어요 | Sign in securely with your Apple ID |
| `screen.home.title` | DearSong | DearSong |
| `screen.songdetail.add_period` | 이 곡의 새 시기를 추가하실까요? | Add a new period for this song |
| `screen.record.step.song` | 곡 선택 | Choose a song |
| `screen.record.step.mood` | 감정 선택 | Choose moods |
| `screen.record.step.write` | 기록 작성 | Write |
| `screen.mood.guide` | 이 곡을 들으셨을 때의 감정을 선택해주세요 | Choose the feelings you had with this song |
| `screen.entry.title` | 이 곡과 함께했던 순간 | The moment with this song |
| `screen.entry.year_label` | 들으셨던 시기 | When you listened |
| `screen.entry.location_label` | 들으셨던 장소 (선택) | Where you listened (optional) |
| `screen.entry.placeholder` | 이 노래를 들으셨을 때 어떤 감정이 드셨나요?\n그때의 기억을 자유롭게 적어주세요. | What did this song feel like? Write your memory freely. |
| `screen.addentry.previous` | 이전 기록들 | Previous entries |
| `screen.addentry.new` | 새 기록 | New entry |
| `screen.addentry.placeholder` | 오늘 이 곡을 다시 들으시며 느끼신 점을 적어주세요. | Write what you feel listening to this song today. |
| `placeholder.search.song` | 곡 제목 또는 아티스트 검색 | Search by title or artist |
| `placeholder.location` | 예: 학교 옥상, 버스 안, 카페... | e.g. School rooftop, bus, café... |
| `placeholder.song.title` | 예: 봄날 | e.g. Spring Day |
| `placeholder.artist.name` | 예: BTS | e.g. BTS |
| `action.signout` | 로그아웃 | Sign out |
| `action.delete` | 삭제 | Delete |
| `action.next` | 다음 | Next |
| `action.previous` | 이전 단계 | Previous |
| `action.save.record` | 기록 남기기 | Save |
| `action.save.entry` | 기록 추가 | Add entry |
| `action.first_record` | 첫 기록 남기기 | Add your first record |
| `action.add_period` | 이 곡의 새 시기 추가 | Add a new period |
| `action.manual_input` | 직접 입력하기 | Enter manually |
| `action.cancel` | 닫기 | Close |
| `empty.home.title` | 아직 기록된 곡이 없어요 | No songs recorded yet |
| `empty.home.message` | 오늘 들으신 노래에\n어떤 감정이 담겨 있었나요? | What feelings did today's songs carry? |
| `empty.songdetail.title` | 아직 기록이 없어요 | No entries yet |
| `empty.songdetail.message` | 이 곡을 들으셨던 시기를\n기록해보세요 | Record a period when you heard this song |
| `empty.search.title` | 검색 결과가 없어요 | No results |
| `empty.search.placeholder` | 검색어를 입력하시면\n곡을 찾아드려요 | Type to search for songs |
| `manualinput.banner` | Apple Music 권한 없이 곡을 직접 입력합니다. | Enter song manually without Apple Music access. |
| `manualinput.song.label` | 곡 제목 | Song title |
| `manualinput.artist.label` | 아티스트 | Artist |
| `mood.selected.count` | %d개 선택됨 | %d selected |
| `songcard.records.count` | %d개의 기록 | %d records |
| `timeline.year` | %d년 | %d |
| `timeline.add_entry_aria` | 이 시기에 새 기록 추가 | Add a new entry to this period |
| `toast.save.success` | 기록이 저장되었어요 | Saved |
| `toast.entry.added` | 기록이 추가되었어요 | Entry added |
| `error.network` | 네트워크 연결을 확인해주세요. | Please check your network connection. |
| `error.server` | 잠시 후 다시 시도해주세요. | Please try again later. |
| `error.auth_expired` | 세션이 만료되었습니다. 다시 로그인해주세요. | Session expired. Please sign in again. |

→ Generator는 `Localizable.xcstrings`를 열어 위 키를 ko/en 모두 추가한다. 기존 키는 보존.

### Step 5 — 반응형/Safe Area 점검 체크리스트

각 ScrollView/Background에 다음 확인:

1. **모든 fullScreenCover/sheet의 최외곽 컨테이너**: `PGradientBackground().ignoresSafeArea()` 또는 동등 처리. 내용은 safe area 안.
2. **하단 고정 버튼이 있는 화면(EntryWriteView, AddEntryView, MoodSelectionView)**: `.safeAreaInset(edge: .bottom) { saveButton }` 패턴으로 변경. ZStack 오버레이 제거.
3. **TextEditor가 있는 화면**: `.scrollDismissesKeyboard(.interactively)` 추가. 키보드 올라올 때 본문이 안 가려지도록.
4. **NavigationStack large title**: `SongCollectionView`에서 large title 사용 중. iPhone SE 등 작은 화면에서 검색바/그리드와 겹치지 않게 spacing 검토.
5. **고정 width/height 제거**:
   - `Apple SignInButton .frame(height: 52)` → `.frame(minHeight: 50, maxHeight: 56)`
   - `SongDetailView` 헤더 `size: 160` → `.frame(maxWidth: 200)` + aspectRatio
   - 플로팅 + 버튼 `56x56`은 HIG FAB 가이드 — 유지
   - 모든 chevron/xmark 버튼 `44x44` — 유지

### Step 6 — Dynamic Type 점검

각 화면에서 `Environment(\.dynamicTypeSize)` 까지 강제로 테스트할 필요 없이, 다음 코드 레벨 보장만 확인하면 된다:

1. 모든 폰트가 `Font.pXxx(N)` 토큰(=내부적으로 Dynamic Type 지원) 또는 `.font(.body)` 등 semantic font 사용
2. 다중 행 텍스트(빈 상태 메시지, 답변 텍스트, placeholder)에 `.fixedSize(horizontal: false, vertical: true)`
3. 카드 내 텍스트 영역에 `maxWidth: .infinity` + `alignment: .leading`로 너비 안정
4. 한 줄 메타에 `.lineLimit(1)` + `.truncationMode(.tail)` + 필요시 `.minimumScaleFactor(0.85)`

### Step 7 — 빌드/실행 시 확인 사항 (Generator가 self-check)

- iPhone SE (3rd gen) / iPhone 17 Pro Max 시뮬레이터로 빌드 후 다음 화면이 잘리지 않는지 코드 레벨 확인:
  - SignInView 로고 + Apple 버튼이 한 화면 안에 들어옴
  - SongCollectionView 그리드 카드가 2열 정상 배치
  - EntryWriteView TextEditor + 1000자 카운터 + 저장 버튼이 키보드 올라와도 안 가려짐
  - SongDetailView 타임라인 헤더 + 첫 카드가 한 화면에 들어옴

- 빌드 명령은 PROJECT_CONTEXT.md `BUILD_COMMAND`로 실행. **BUILD SUCCEEDED** 필수.
- Generator가 이 라운드 종료 시 `output/` 아래 모든 변경 파일을 저장. `Shared/AppTheme.swift`는 삭제 또는 thin shim 둘 중 한 형태로 남김.

---

## Acceptance Criteria (Evaluator R3가 검증)

이 라운드 통과 기준:

1. **하드코딩 색상 0건**: `output/Views/**/*.swift` 와 `output/Shared/AppTheme.swift`에서 다음 패턴 0건
   - `Color(red:` (raw RGB)
   - `Color.red`, `Color.blue`, `Color.brown`, `Color.green` 등 시스템 리터럴 색상 (단, `.white` 는 토큰화 어려운 contrast 용도로 `BottomPlacedButton` 내부 전경색에 한해 허용)
   - `UIColor(red:`
2. **하드코딩 폰트 0건**: `.font(.system(size:`) 패턴 0건. 모든 폰트는 `Font.pXxx(N)` 또는 `.font(.body)` 등 semantic.
3. **자체 컴포넌트 미사용**: `MoodChipButton`, `cardStyle()`, `NotebookTexture`, `AppBackground` 호출 사이트 0건. (struct 자체는 thin shim AppTheme 안에서만 잔존 가능)
4. **String Catalog 적용**: 모든 사용자 대면 `Text("...")`, `TextField("...placeholder...", ...)`, `navigationTitle("...")`이 LocalizedStringKey 또는 `String(localized:)` 패턴. 한국어 리터럴 직접 사용 0건.
5. **Hit target 44pt+**: 모든 인터랙티브 요소(버튼, chip, navigation icon)에 `.frame(minWidth: 44, minHeight: 44)` 또는 부모가 보장.
6. **Dynamic Type 안전**:
   - 다중 행 텍스트에 `.fixedSize(horizontal: false, vertical: true)` 적용
   - 한 줄 텍스트에 `.lineLimit(1)` + `.truncationMode(.tail)`
   - 큰 타이틀에 `.minimumScaleFactor(0.85)` 이상
7. **반응형**:
   - SignInView가 작은 화면(SE 3rd, 667pt height)에서 잘리지 않음 (코드 레벨: ScrollView 또는 비율 기반 layout)
   - EntryWriteView/AddEntryView가 키보드 회피 (`safeAreaInset` 또는 `scrollDismissesKeyboard`)
   - 모든 LazyVGrid 컬럼이 작은 화면에서도 깨지지 않음 (코드 레벨: GridItem `.flexible()` + 적절한 spacing)
8. **존댓말 톤**: 새로 추가/수정한 한국어 리터럴(이번 라운드는 String Catalog 키 안에서만)이 모두 존댓말. (예: "선택해주세요", "기록해주세요", "확인해주세요")
9. **빌드 성공**: `xcodebuild ... | grep -E 'BUILD (SUCCEEDED|FAILED)'`이 SUCCEEDED.
10. **회귀 없음**: 기존 SPEC R1의 7개 기능이 모두 정상 동작. ViewModel/Service/Model 레이어는 이번 라운드에서 변경 금지(EntryWriteView 1000자 카운터 표시는 View-only이며 ViewModel `entryText.count` 읽기만 수행).

### 아웃 오브 스코프 (이번 라운드에서 만지지 않음)

- ViewModel/Service/Model 레이어 로직 변경
- 새 화면/네비게이션 추가
- Apple Sign In 흐름 변경
- Supabase 스키마/쿼리 변경
- MusicKit 호출 변경
- 테스트 코드 (단, View 변경에 따라 컴파일이 깨지면 최소 수정 허용)

---

## Generator 진행 순서 권장

1. PersonalColorDesignSystem 패키지의 실제 공개 API 확인 (있으면 docs/, 없으면 패키지 소스에서 import 후 컴파일러 에러로 검증)
2. `Shared/AppTheme.swift` thin shim 또는 삭제 결정
3. View 파일을 `Components → Auth → Collection → Detail → Record/* → Entry` 순서로 패치 (의존도 낮은 순)
4. `Localizable.xcstrings` 업데이트
5. 빌드 게이트 통과 확인
6. 자가 점검: Acceptance Criteria 1~10번 grep으로 검증

---

# Round 3 — TopDesignSystem Migration

## 목표
PersonalColorDesignSystem(P-prefix)을 TopDesignSystem(.airbnb 테마)으로 1:1 코드 마이그레이션.
기능/네비게이션/UI 구조 변경 금지. 토큰·컴포넌트 호출 사이트만 교체.
SPM 패키지 swap은 오케스트레이터가 이미 완료했다(pbxproj/Package.resolved).

## 사용 테마: .airbnb (확정)
- 이유: DearSong은 "곡 하나에 얽힌 나만의 기억·감정을 따뜻하게 기록하는 가이드 다이어리".
  WarmVibrant 팔레트(부드러운 핑크-레드 액센트, 따뜻한 톤)와 systemScale 타이포(여유로운 큰 글자)가
  감정·노스탤지어 톤에 가장 어울린다.
- `.linear` (생산성/Dense)는 차갑고 데이터 중심이라 기각.
- `.revolut` (핀테크/블루)는 신뢰감·금융 톤이라 기각.
- 적용 위치: App/DearSongApp.swift 의 WindowGroup 루트에 `.designTheme(.airbnb)` 한 줄.

## 토큰 매핑표 (Generator는 이 표 그대로 사전 치환)

### 색상 (모든 View에서)
| 이전 (PersonalColor) | 신규 (TopDesignSystem) |
|---|---|
| `Color.pTextPrimary` | `palette.textPrimary` (또는 `WarmVibrant.textPrimary`) |
| `Color.pTextSecondary` | `palette.textSecondary` |
| `Color.pTextTertiary` | `palette.textSecondary.opacity(0.6)` (TopDesignSystem에 tertiary 미노출 — opacity 보정) |
| `Color.pAccentPrimary` | `palette.primaryAction` |
| `Color.pBackgroundTop/Mid/Bottom` | `palette.background` (단일 토큰. 그라디언트가 필요한 곳은 `LinearGradient(colors: [palette.background, palette.surface], ...)`) |
| `Color.pGlassFill` | `palette.surface.opacity(0.6)` |
| `Color.pGlassBorder` | `palette.border` |
| `Color.pGlassSelected` | `palette.elevated` |
| `Color.pSuccess` | `palette.success` |
| `Color.pWarning` | `palette.warning` |
| `Color.pDestructive` | `palette.error` |
| `Color.pShadow` | (`.designShadow(.card)` 같은 modifier로 대체 — 직접 색상 사용 X) |
| `Color.pToastBackground` | (BottomToast가 패키지 컴포넌트로 대체되므로 사용처 제거) |
| `Color.pTabBarBackground` | (Tab 사용처 없음 — 제거) |

> 컴포넌트 내부에서는 `@Environment(\.designPalette) private var palette` 를 선언해서 사용한다.
> 정적 컨텍스트(struct property literal 등)에서는 `WarmVibrant.*` 직접 토큰을 사용해도 된다.

### 폰트 (모든 View에서)
| 이전 (PersonalColor) | 신규 (TopDesignSystem) |
|---|---|
| `Font.pDisplay(40)`, `Font.pDisplay(36)`, `Font.pDisplay(56)` | `Font.ssLargeTitle` (42pt) — 사이즈 미세 차이 무시. 큰 숫자는 `.ssTitle1` (36pt) 도 가능. |
| `Font.pTitle(17)`, `Font.pTitle(20)` | `Font.ssTitle2` (20pt) 또는 `theme.typography.headline` |
| `Font.pBody(15)`, `Font.pBody(14)`, `Font.pBody(13)` | `Font.ssBody` (16pt) 또는 `Font.ssFootnote` (14pt) — 13/14 → footnote, 15/16 → body |
| `Font.pBodyMedium(14)`, `Font.pBodyMedium(15)` | `Font.ssBody.weight(.medium)` 또는 `Font.ssFootnote.weight(.medium)` |
| `Font.pCaption(11)`, `Font.pCaption(12)`, `Font.pCaption(13)` | `Font.ssCaption` (12pt) |

### 간격 / 코너 / 그림자
| 이전 | 신규 |
|---|---|
| `PSpacing.xxs/xs/sm/md/lg/xl/xxl/xxxl` | `DesignSpacing.xxs/xs/sm/md/lg/xl/xxl/xxxl` |
| `PRadius.sm/md/lg/xl` | `DesignCornerRadius.sm/md/lg/xl` |
| `PRadius.pill` | `DesignCornerRadius.pill` |
| `PBorder.thin / .hairline` | `1` / `0.5` (TopDesignSystem에 PBorder 토큰 없음 — 숫자 리터럴 OK) |

### 컴포넌트
| 이전 (PersonalColor) | 신규 (TopDesignSystem) |
|---|---|
| `PGradientBackground()` | 삭제 후 `palette.background.ignoresSafeArea()` 또는 `LinearGradient(colors:[palette.background, palette.surface], ...).ignoresSafeArea()` |
| `GlassCard { ... }` | `GlassCard { ... }` (TopDesignSystem도 동일 이름. 그대로 사용 가능 — 단 `import TopDesignSystem` 이어야 함) |
| `cardStyle()` ViewModifier (자체) | `view.surfaceContainer()` 또는 `SurfaceCard(elevation: .raised) { content }` |
| `PSkeletonLoader(preset: .listRow / .card / .text(lines:))` | `ShimmerPlaceholder(height: 64)` (listRow), `ShimmerPlaceholder(height: 160)` (card). 텍스트 다중 라인은 `VStack { ShimmerPlaceholder(height: 12) ... }` 로 명시 구성. |
| `PChip(_ title, isSelected: Binding<Bool>)` (toggle) | TopDesignSystem에 동등 컴포넌트 부재 → **인라인 Button + Capsule** 직접 구성 (R3에서 MoodChipGridView가 이미 한 패턴). 다른 사용처(TimelineEntryView의 라벨 칩 등)는 `Capsule().fill(palette.surface).overlay(Text)` 정적 표시로 변환. |
| `PChip(_ title)` (label variant) | 정적 칩 — `Text(...).padding(.horizontal/.vertical).background(Capsule().fill(palette.surface))` |
| `PFormField` | TopDesignSystem 부재 → 직접 `VStack { Text(label) ; content ; Text(message) }` 패턴. 또는 `view.borderedContainer()` 모디파이어 활용. |
| `PTextField(placeholder:, text:, leadingIcon:?)` | TopDesignSystem 부재 → 표준 `TextField(placeholder, text:)` + `view.borderedContainer()` 또는 ContentListItem 스타일. leadingIcon 필요시 HStack 직접 구성. |
| `PSecureField` | 표준 `SecureField(...)` + `borderedContainer()` |
| `PBanner(type: .success/.warning/.error/.info, message:)` | TopDesignSystem 부재 → 인라인 `HStack(아이콘 + Text).padding().background(palette.surface).overlay(border)`. 또는 패키지의 `bottomToast(style:)` modifier로 동일 의미 전달. |
| `PSectionHeader(_ title)` | 직접 `Text(title).font(theme.typography.headline).foregroundStyle(palette.textPrimary)` (간단함) |
| `PDivider()` | 표준 SwiftUI `Divider().overlay(palette.border)` |
| `PToastManager` + `.pGlobalToast` + `.pTheme(.autumn)` | `@State var showToast = false` 로컬 상태 + `.bottomToast(isPresented:$showToast, message:, style:)` modifier per-view 사용. 전역 toastManager 환경 객체 의존성 제거. |
| `.pLoadingOverlay(isLoading: .constant(true), message:)` | TopDesignSystem 부재 → 인라인 `ZStack { content ; if isLoading { ProgressView(message) } }` 또는 `ShimmerPlaceholder` 활용 |
| `.pressable(scale:, haptic:)` (자체 모디파이어) | `.buttonStyle(.pressScale)` (TopDesignSystem이 제공). 비-Button context면 `.scaleEffect`/`.gentleSpring` 조합. |
| `HapticManager.impact(.light)` / `.selection()` | 표준 UIKit `UIImpactFeedbackGenerator(style: .light).impactOccurred()` 또는 `UISelectionFeedbackGenerator().selectionChanged()` (TopDesignSystem에 햅틱 헬퍼 부재 가정. 실제 패키지에 있으면 그걸 우선) |
| `BottomPlacedButton(...)` (자체) | `RoundedActionButton(_ title) { action }` 또는 `PillButton`. `.safeAreaInset(edge: .bottom)` 으로 하단 고정. |
| `FlowLayout` (자체 Layout) | TopDesignSystem 부재 → `LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 8)])` 으로 대체 |
| `EmptyStateView(...)` (자체) | 직접 VStack { Image ; Text("...") } 인라인 구성. SurfaceCard 또는 .surfaceContainer() 위에 배치. |

## 화면별 마이그레이션 체크리스트 (Generator는 이 표를 보고 화면 단위로 작업)

| 파일 | 주요 마이그레이션 포인트 | 예상 난이도 |
|---|---|---|
| App/DearSongApp.swift | `.pTheme(.autumn)` → `.designTheme(.airbnb)`. `PToastManager()` + `.pGlobalToast` 제거 (per-view bottomToast로 변경). `PGradientBackground()` → `palette.background.ignoresSafeArea()`. `pLoadingOverlay` → 인라인 ZStack + ProgressView. | 중 |
| Views/Auth/SignInView.swift | 폰트/색상 토큰만 교체. Sign in with Apple 버튼 그대로. | 하 |
| Views/Collection/SongCollectionView.swift | 색상/폰트 + `PSkeletonLoader` → `ShimmerPlaceholder`. `BottomPlacedButton` → `RoundedActionButton` + safeAreaInset. `EmptyStateView` 인라인. | 중 |
| Views/Detail/SongDetailView.swift | 폰트/색상 + GeometryReader 헤더 그대로. `Label { Text } icon: { Image }` 그대로. | 하 |
| Views/Record/RecordFlowView.swift | `PAnimation.spring` → `SpringAnimation.gentle` 또는 `.snappy`. 색상/폰트. | 하 |
| Views/Record/SongSearchView.swift | `PTextField(leadingIcon:)` → 인라인 HStack {Image + TextField} + `.borderedContainer()`. `PSkeletonLoader(.listRow)` → `ShimmerPlaceholder(height: 64)`. | 중 |
| Views/Record/MoodSelectionView.swift | 칩 그리드 → 인라인 Button + Capsule (이미 R3 MoodChipGridView 패턴 차용). 색상/폰트. safeAreaInset 그대로. | 중 |
| Views/Record/EntryWriteView.swift | TextEditor 인라인 그대로. 1000자 카운터 색상 `Color.pDestructive` → `palette.error`. 색상/폰트. | 하 |
| Views/Record/ManualSongInputView.swift | `PBanner(type: .info)` → 인라인 HStack 배너 또는 `.bottomToast(style: .info)` 안내. `PTextField` → 표준 TextField. | 중 |
| Views/Entry/AddEntryView.swift | EntryWriteView와 동일 패턴. | 하 |
| Views/Components/AlbumArtworkView.swift | 색상 토큰만 교체. AsyncImage 그대로. | 하 |
| Views/Components/MoodChipGridView.swift | R3에서 이미 인라인 Button+Capsule로 만들어둠 — 색상 토큰만 교체. `PSectionHeader` → 인라인 Text. `FlowLayout` → LazyVGrid adaptive. | 중 |
| Views/Components/SongCardView.swift | `GlassCard` 그대로. `.pressable(scale:0.97, haptic:.light)` → `.buttonStyle(.pressScale)` (단 Button 안에서). 색상/폰트. | 중 |
| Views/Components/TimelineEntryView.swift | `GlassCard` 그대로. `PChip(_ title)` → 정적 Capsule + Text. `PDivider()` → Divider. 색상/폰트. | 중 |
| Shared/AppTheme.swift | **PRadius/PSpacing/PChipMath/등 전부 제거.** TopDesignSystem 토큰을 그대로 쓰므로 shim 불필요. **파일 자체를 삭제하거나, `AppPalette` 같은 한 줄 헬퍼만 남기고 비우기.** | 중 |
| Resources/Localizable.xcstrings | 변경 없음. 그대로 보존. | 하 |

## 작업 절차 (Generator에게)

1. 모든 View 파일 상단 `import PersonalColorDesignSystem` → `import TopDesignSystem`.
2. 위 토큰 매핑표 그대로 검색·치환.
3. 환경 의존이 필요한 컴포넌트(palette/theme 사용)에는 `@Environment(\.designPalette) private var palette` (그리고 필요 시 `\.designTheme`) 선언 추가.
4. 화면별 마이그레이션 체크리스트 따라 컴포넌트 호출 사이트 교체.
5. `Shared/AppTheme.swift` 정리 — TopDesignSystem 토큰만 노출하는 파일이라면 삭제. 대체로 비울 것.
6. 빌드 가능한 상태로 만들고, Generator 자체적으로 grep 검증:
   - `import PersonalColorDesignSystem` 0건
   - `Color.p*` 잔존 0건 (단 `palette.` 는 OK)
   - `Font.p*` 잔존 0건
   - `PSpacing/PRadius/PChip/PBanner/PFormField/PTextField/PSecureField/PSkeletonLoader/PSectionHeader/PDivider/PGradientBackground/PToastManager/pLoadingOverlay/pTheme/pGlobalToast/HapticManager` 잔존 0건

## Acceptance Criteria (Evaluator R4가 검증)

1. `import PersonalColorDesignSystem` grep 결과 0건
2. `Color.p[A-Z]` (View 한정) grep 결과 0건
3. `Font.p[A-Z]` grep 결과 0건
4. `PSpacing|PRadius|PChip|PBanner|PFormField|PTextField|PSecureField|PSkeletonLoader|PSectionHeader|PDivider|PGradientBackground|PToastManager|pLoadingOverlay|pTheme|pGlobalToast` grep 결과 0건
5. `import TopDesignSystem` 모든 View와 App에 추가됨
6. App 루트에 `.designTheme(.airbnb)` 적용됨
7. PROJECT_CONTEXT.md의 디자인 시스템 토큰만 사용
8. 빌드 통과 (BUILD SUCCEEDED)
9. 기능 회귀 없음 — SPEC R1의 모든 기능 유지
10. Localizable.xcstrings 키 변경 없음 (마이그레이션 라운드는 코드만)

## 범위 외
- ViewModel/Service/Model 로직 변경 금지 (시그니처 호환).
- 새 화면/네비게이션 금지.
- 새 기능 금지.
- Localizable.xcstrings 키 추가/제거 금지(폰트 토큰 이름이 키처럼 보일 수 있어도 마이그레이션 대상은 코드만).
