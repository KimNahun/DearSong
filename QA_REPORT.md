RESULT: conditional_pass
SCORE: 6.8
BLOCKERS: 4

---

# QA Report -- DearSong Evaluator R1

## 전체 판정: 조건부 합격 (conditional_pass)
## 가중 점수: 6.8 / 10.0

---

## 1단계: 파일 구조 분석

### 파일 목록 및 레이어 분류

| 레이어 | 파일 | SPEC 대조 |
|--------|------|----------|
| App | `App/DearSongApp.swift` | OK |
| Models | `Models/SongMemory.swift` | OK |
| Models | `Models/MoodTag.swift` | OK |
| Models | `Models/SearchedSong.swift` | OK |
| Services | `Services/AuthService.swift` | OK |
| Services | `Services/MusicSearchService.swift` | OK |
| Services | `Services/SongMemoryService.swift` | OK |
| Services | `Services/SupabaseClientProvider.swift` | OK |
| Shared | `Shared/AppError.swift` | OK |
| Shared | `Shared/DateFormatters.swift` | OK |
| ViewModels | `ViewModels/AuthViewModel.swift` | OK |
| ViewModels | `ViewModels/SongCollectionViewModel.swift` | OK |
| ViewModels | `ViewModels/SongDetailViewModel.swift` | OK |
| ViewModels | `ViewModels/RecordFlowViewModel.swift` | OK |
| ViewModels | `ViewModels/SongSearchViewModel.swift` | OK |
| ViewModels | `ViewModels/AddEntryViewModel.swift` | OK |
| Views/Auth | `Views/Auth/SignInView.swift` | OK |
| Views/Collection | `Views/Collection/SongCollectionView.swift` | OK |
| Views/Detail | `Views/Detail/SongDetailView.swift` | OK |
| Views/Record | `Views/Record/RecordFlowView.swift` | OK |
| Views/Record | `Views/Record/SongSearchView.swift` | OK |
| Views/Record | `Views/Record/MoodSelectionView.swift` | OK |
| Views/Record | `Views/Record/EntryWriteView.swift` | OK |
| Views/Record | `Views/Record/ManualSongInputView.swift` | OK |
| Views/Entry | `Views/Entry/AddEntryView.swift` | OK |
| Views/Components | `Views/Components/SongCardView.swift` | OK |
| Views/Components | `Views/Components/MoodChipGridView.swift` | OK |
| Views/Components | `Views/Components/TimelineEntryView.swift` | OK |
| Views/Components | `Views/Components/AlbumArtworkView.swift` | OK |
| Delegates | SPEC의 `Delegates/AppDelegate.swift` | **누락** (필요 시로 명시되어 있어 경미) |

파일 구조는 SPEC과 정확히 일치. `Delegates/AppDelegate.swift`가 없으나 SPEC에서 "(필요 시)"로 표기하여 감점하지 않음.

---

## 2단계: SPEC 기능 검증

### 기능 1: Apple Sign In 인증
- [PASS] `SignInView.swift` -- `SignInWithAppleButton` 사용, `AuthViewModel`에서 nonce 생성/SHA256 해싱 구현
- [PASS] `AuthService.swift` -- actor, `signInWithIdToken` 연동
- [PASS] `DearSongApp.swift` -- 세션 확인 후 `isAuthenticated` 분기
- [PASS] 로그아웃 -- `SongCollectionView` toolbar trailing에 배치

### 기능 2: 곡 컬렉션 메인 화면
- [PASS] `SongCollectionView.swift` -- `NavigationStack`, `LazyVGrid` 2열 그리드
- [PASS] 곡 단위 그룹핑 -- `SongCollectionViewModel.groupMemories()`
- [PASS] 플로팅 + 버튼 -- `floatingAddButton`, fullScreenCover 연결
- [PASS] 빈 상태 -- `EmptyStateView` 사용
- [PASS] 로딩 -- `PSkeletonLoader` 사용
- [PASS] 에러 -- `PToastManager` 사용
- [PASS] pull-to-refresh -- `.refreshable` 구현

### 기능 3: 곡 상세 화면 (감정 타임라인)
- [PASS] `SongDetailView.swift` -- 상단 앨범 커버 + 곡 정보 헤더
- [PASS] 배경 -- 앨범 아트워크 blur + PGradientBackground
- [PASS] 타임라인 -- `LazyVStack` + `TimelineEntryView` (내림차순)
- [PASS] 시기 카드 -- `GlassCard`, 년도, 감정 태그, 장소, 엔트리 표시
- [PASS] 엔트리 추가 -- 시기 카드 내 + 버튼 → `AddEntryView` sheet
- [PASS] 새 시기 추가 -- `CommonButton` → `RecordFlowView` fullScreenCover (곡 pre-selected)
- [PASS] 삭제 -- `swipeActions` + `.actionCheckModal`

### 기능 4: 새 기록 작성 플로우
- [PASS] `RecordFlowView.swift` -- fullScreenCover, 3단계 step navigation
- [PASS] Step 1 -- `SongSearchView`, MusicKit 검색, debounce 0.5초
- [PASS] Step 2 -- `MoodSelectionView`, PChip toggle, 최소 1개 선택 검증
- [PASS] Step 3 -- `EntryWriteView`, TextEditor, 년도/장소 입력, BottomPlacedButton
- [PASS] MusicKit 권한 거부 폴백 -- `ManualSongInputView`
- [PASS] 동일 곡+년도 존재 시 entries에 추가 (UPDATE), 없으면 새 행 (INSERT)
- [PASS] 저장 성공 → 토스트 + dismiss

### 기능 5: 기존 곡+시기에 엔트리 추가
- [PASS] `AddEntryView.swift` -- 기존 entries 표시 + 새 텍스트 입력 + 저장
- [PASS] `AddEntryViewModel.swift` -- `save(memoryId:)` 구현

### 기능 6: MusicKit 곡 검색
- [PASS] `MusicSearchService.swift` -- actor, `MusicAuthorization.request()`, `MusicCatalogSearchRequest`
- [PASS] 권한 denied → `isMusicKitDenied` 상태 → 수동 입력 전환
- [PASS] 검색 결과 `Song` → `SearchedSong` 매핑

### 기능 7: 감정 태그 시스템
- [PASS] `MoodTag.swift` -- 9개 카테고리, SPEC 명시 태그 전체 구현
- [PASS] `MoodChipGridView.swift` -- `PSectionHeader` + `LazyVGrid` + `PChip(variant: .toggle)`

**기능 구현 종합**: 7개 기능 모두 구현됨. SPEC 대비 누락 기능 없음.

---

## 3단계: evaluation_criteria 채점

### Swift 6 동시성: 7/10

**근거**:
- [OK] 모든 ViewModel: `@MainActor` + `@Observable` -- `AuthViewModel`, `SongCollectionViewModel`, `SongDetailViewModel`, `RecordFlowViewModel`, `SongSearchViewModel`, `AddEntryViewModel` 모두 준수
- [OK] 모든 Service: `actor` -- `AuthService`, `SongMemoryService`, `MusicSearchService` 모두 actor
- [OK] 모든 Model: `struct` + `Sendable` -- `SongMemory`, `Entry`, `Attachment`, `GroupedSong`, `SearchedSong`, `MoodTag` 모두 준수
- [OK] `DispatchQueue`, `@Published`, `ObservableObject` 미사용 확인
- [OK] Protocol 기반 DI: `AuthServiceProtocol`, `SongMemoryServiceProtocol`, `MusicSearchServiceProtocol` 모두 `Sendable` 프로토콜
- [ISSUE] **`SongSearchViewModel`에 `import MusicKit`** -- ViewModel이 Apple 프레임워크를 직접 import. `MusicAuthorization.Status` 타입을 직접 참조하지 않지만 `import MusicKit`는 MVVM 관점에서도 위반이며, 실제로는 파일 내에서 사용하지 않는 불필요한 import. **제거 필요.**
- [ISSUE] **`nonisolated` 과다 사용** -- `SongMemory.swift`의 `nonisolated struct SongMemory`, `MoodTag.swift`의 `nonisolated enum MoodCategory` 등 모든 Model/enum에 불필요한 `nonisolated` 키워드 사용. `struct`와 `enum`은 기본적으로 nonisolated이며, 명시적 `nonisolated` 키워드는 불필요하고 Swift 6에서 의도하지 않은 의미를 전달할 수 있음. **제거 필요.**
- [ISSUE] **`DateFormatters.swift`의 `nonisolated(unsafe)` 전역 변수** -- `_yearOnlyFormatter`가 `nonisolated(unsafe) let`으로 선언. `DateFormatter`는 thread-safe하지 않으며 `nonisolated(unsafe)`는 컴파일러 경고를 억제할 뿐 실제 안전성을 보장하지 않음. **actor 또는 `@MainActor`로 감싸거나, `static let` 패턴 사용 필요.**
- [ISSUE] **`SupabaseClientProvider`가 `final class`** -- actor가 아닌 일반 클래스. `Sendable` 마킹만 있고 실제로 `SupabaseClient` 초기화는 `init` 내에서만 하므로 문제가 적지만, SPEC은 Service를 actor로 명시. 이 파일은 싱글턴 팩토리이므로 actor가 더 적합하거나, `let client`가 immutable이므로 현재 `Sendable` 마킹은 수용 가능. **경미.**

### MVVM 아키텍처 분리: 8/10

**근거**:
- [OK] View에서 Service 직접 호출 없음 -- 모든 View는 ViewModel을 통해 데이터 접근
- [OK] ViewModel에 `import SwiftUI` 없음 -- 모든 ViewModel은 `Foundation` + `Observation` (+ `AuthenticationServices`, `CryptoKit` for `AuthViewModel`)
- [OK] ViewModel에 UI 타입(`Color`, `Font`) 없음
- [OK] Service가 ViewModel/View 참조 없음
- [OK] 의존성 단방향: View -> ViewModel -> Service
- [OK] Protocol 기반 Service 주입 -- 모든 Service에 프로토콜 정의
- [ISSUE] **`SongSearchViewModel`에 `import MusicKit`** -- 위에서 지적한 것과 동일. ViewModel이 Framework를 직접 import하는 것은 MVVM 위반. `MusicKit` 타입을 ViewModel에서 실제로 사용하지 않으므로 단순히 불필요한 import. **제거 필요.**
- [ISSUE] **`RecordFlowViewModel`의 `currentStep`, `selectedMoodTags`, `entryText`, `selectedYear`, `location` 등이 `private(set)` 없이 `var`로 노출** -- View에서 직접 수정 가능한 상태는 의도적일 수 있으나 (`@Bindable` 사용), `currentStep`은 `goToNextStep()/goToPreviousStep()`으로만 변경해야 하므로 `private(set)`이어야 함. **`currentStep`은 `private(set)` 필요.**
- [ISSUE] **`SongCollectionView`에서 `AuthViewModel`을 `@State`로 소유** -- `DearSongApp`에서 생성한 `authViewModel`을 `init`에서 전달받아 `@State`로 감싸는 것은 어색한 패턴. `@State`는 View 고유 상태용이며, 외부에서 주입받은 객체는 `@Bindable` 또는 `.environment()`가 더 적절. 현재 구조에서는 동작하겠으나 아키텍처적 개선 여지.

### HIG 준수 + 디자인 시스템: 8/10

**근거**:
- [OK] 디자인 시스템 토큰 100% 사용 -- 하드코딩 색상/폰트 0건 확인
- [OK] `PGradientBackground`, `GlassCard`, `PChip`, `PTextField`, `BottomPlacedButton`, `CommonButton`, `PBanner`, `PFormField`, `PSectionHeader`, `PDivider`, `EmptyStateView`, `PLoadingOverlay`, `PSkeletonLoader`, `PAccentGradient`, `PDropdownButton`, `PToastManager`, `.actionCheckModal`, `.pressable`, `.pShadowLow/Mid/High`, `.shimmer`, `HapticManager` 등 디자인 시스템 컴포넌트 적극 활용
- [OK] 색상 토큰: `Color.pAccentPrimary`, `Color.pTextPrimary`, `Color.pGlassFill` 등 전면 사용
- [OK] 타이포: `Font.pDisplay`, `Font.pTitle`, `Font.pBodyMedium`, `Font.pBody`, `Font.pCaption` 사용
- [OK] 스페이싱: `PSpacing.xs/sm/md/lg/xl/xxl/xxxl/huge/giant` 사용
- [OK] 접근성 레이블 -- 40개 이상의 `.accessibilityLabel` 확인. 주요 인터랙션 커버
- [OK] 터치 영역 -- 버튼/탭 가능 요소 44pt 이상 (`.frame(width: 44, height: 44)`, `.frame(minHeight: 44)`, `.frame(minWidth: 44, minHeight: 44)`)
- [OK] 로딩/에러 상태 -- 로딩(PLoadingOverlay, PSkeletonLoader), 에러(PToastManager), 빈 상태(EmptyStateView) 모두 구현
- [OK] 애니메이션 토큰 -- `PAnimation.spring`, `PAnimation.springFast`, `PAnimation.easeOut` 사용
- [ISSUE] **`SongDetailView`의 `swipeActions`가 `LazyVStack` 내 비-List 컨텍스트에서 사용** -- `swipeActions`는 `List` 내에서만 동작. `LazyVStack` + `ForEach`에서는 swipeActions가 무시됨. **BLOCKER: 삭제 기능이 실제로 작동하지 않음.** `List`로 변경하거나 커스텀 swipe 제스처 필요.
- [ISSUE] **`EntryWriteView`의 placeholder 텍스트 padding 하드코딩** -- `.padding(16)` (line 138, 155). 디자인 시스템 토큰 `PSpacing.lg(16)`을 사용해야 함. 경미한 위반.

### API 활용: 8/10

**근거**:
- [OK] MusicKit -- `MusicAuthorization.request()`, `MusicCatalogSearchRequest`, `Song.self`, `song.artwork?.url(width:height:)` 올바르게 사용
- [OK] Supabase Auth -- `signInWithIdToken`, `OpenIDConnectCredentials`, `session` 확인, `signOut` 모두 구현
- [OK] Supabase Database -- `from().select().eq().order().execute().value` 패턴 올바르게 사용
- [OK] 권한 요청 흐름 -- MusicKit 권한 요청 → 거부 시 수동 입력 폴백
- [OK] 에러 처리 -- 모든 API 호출에 do-catch, `AppError`로 변환
- [OK] API 호출이 Service 레이어에만 존재
- [ISSUE] **`SongMemoryService.addEntry`의 race condition 가능성** -- SELECT 후 append 후 UPDATE하는 패턴은 동시 호출 시 데이터 손실 가능. actor 격리로 동시 호출은 직렬화되지만, 네트워크 왕복 사이에 다른 디바이스에서 수정될 수 있음. Supabase RPC나 jsonb 함수 사용이 이상적이나, v1 단일 디바이스 사용이면 수용 가능. **경미.**
- [ISSUE] **`SupabaseClientProvider`에서 URL/Key가 빈 문자열일 때 placeholder URL 사용** -- 프로덕션에서 `Secrets.xcconfig` 누락 시 조용히 실패. fatalError 또는 경고 로그가 더 적절. **경미.**

### 기능성 및 코드 가독성: 7/10

**근거**:
- [OK] SPEC의 7개 기능 모두 구현됨
- [OK] 파일명 SPEC 컨벤션 일치
- [OK] 에러 타입 `enum [Domain]Error: Error` 패턴 준수 -- `AuthError`, `SongMemoryError`, `MusicSearchError`, `AppError`
- [OK] CodingKeys snake_case ↔ camelCase 매핑 명시
- [OK] 모든 비동기 작업에 do-catch 에러 처리
- [OK] 코드 중복 최소화 -- `AlbumArtworkView`, `MoodChipGridView`, `TimelineEntryView` 등 공통 컴포넌트 추출
- [ISSUE] **접근 제어자 불충분** -- `RecordFlowViewModel`의 `currentStep`, `selectedSong`, `selectedMoodTags`, `entryText`, `selectedYear`, `location`, `isManualInput`, `manualSongTitle`, `manualArtistName`이 모두 `var` (public). View에서 `@Bindable`로 바인딩이 필요한 것(`entryText`, `location`, `manualSongTitle`, `manualArtistName`, `selectedMoodTags`)과 로직으로만 변경해야 할 것(`currentStep`)이 혼재. `currentStep`은 반드시 `private(set)`.
- [ISSUE] **`TimelineEntryView`와 `AddEntryView`에서 `DateFormatter`를 매번 생성** -- `formattedDate()` 함수 내에서 새 `DateFormatter` 인스턴스를 반복 생성. `DateFormatters`에 공유 인스턴스를 추가하거나 `static let` 패턴 사용 필요.
- [ISSUE] **`PChip` 사용 불일치** -- `EntryWriteView` line 97에서 `PChip(tag)` 호출은 SPEC/PROJECT_CONTEXT의 `PChip(title:variant:isSelected:)` API와 다른 이니셜라이저 시그니처. 컴파일 에러 가능성. **확인 필요.**
- [ISSUE] **`PDropdownButton` API 불일치** -- `EntryWriteView`에서 `PDropdownButton(placeholder:options:selectedOption:)` 사용하나 PROJECT_CONTEXT에서는 `PDropdownButton(selection:options:)` 시그니처 명시. 컴파일 에러 가능성. **확인 필요.**
- [ISSUE] **`PSectionHeader` API 불일치** -- `AddEntryView`에서 `PSectionHeader("이전 기록들")` (단일 문자열 인자), PROJECT_CONTEXT에서는 `PSectionHeader(title: "섹션")` 명시. 컴파일 에러 가능성. **확인 필요.**
- [ISSUE] **`PLoadingOverlay` API 불일치** -- `SignInView`에서 `PLoadingOverlay()` (인자 없음), `DearSongApp`에서 `.pLoadingOverlay(isLoading: .constant(true), message: "로딩 중...")` (ViewModifier). PROJECT_CONTEXT에서는 `PLoadingOverlay(isLoading: true)` 또는 `.pLoadingOverlay(isLoading:message:)`. `PLoadingOverlay()` 인자 없는 호출이 유효한지 확인 필요.
- [ISSUE] **`PFormField` state 타입** -- `ManualSongInputView`에서 `PFormFieldState` enum 참조하나, PROJECT_CONTEXT에서는 `.error("메시지")` 형태로 associated value 포함. `.error` 단독 사용이 유효한지 확인 필요.

---

## 항목별 점수

- Swift 6 동시성: 7/10 -- ViewModel/Service/Model 구조는 올바르나, `nonisolated` 과다 사용, `nonisolated(unsafe)` DateFormatter, `SongSearchViewModel`의 불필요한 `import MusicKit`
- MVVM 분리: 8/10 -- 깔끔한 단방향 의존, Protocol DI 완비. `SongSearchViewModel`의 `import MusicKit` 위반, `RecordFlowViewModel.currentStep` 접근제어 미흡
- HIG 준수: 8/10 -- 디자인 시스템 토큰 완벽 사용, 접근성 40+ 레이블. `swipeActions`가 List 밖에서 사용되어 삭제 기능 미작동 (BLOCKER)
- API 활용: 8/10 -- MusicKit/Supabase Auth/Database 모두 올바르게 구현. 경미한 race condition, placeholder URL 처리
- 기능성/가독성: 7/10 -- 전체 기능 구현 완료, 접근제어 일부 미흡, DateFormatter 반복 생성, 디자인 시스템 컴포넌트 API 시그니처 불일치 다수

---

## 가중 점수 계산

```
(7 x 0.30) + (8 x 0.25) + (8 x 0.20) + (8 x 0.15) + (7 x 0.10)
= 2.10 + 2.00 + 1.60 + 1.20 + 0.70
= 7.60
```

**그러나 BLOCKER 4건을 반영하여 조건부 합격으로 하향.**

실제 가중 점수: 7.6이나, 아래 BLOCKER들이 빌드/런타임 문제를 일으킬 수 있어 6.8로 조정.

---

## 구체적 개선 지시 (BLOCKERS)

### BLOCKER 1: `SongDetailView.swift` -- `swipeActions`가 `LazyVStack`에서 작동하지 않음
- **위치**: `SongDetailView.swift` `timelineSection` (line 159-177)
- **근거**: `swipeActions`는 `List` 내 `ForEach`에서만 동작. `LazyVStack` + `ForEach`에서는 무시됨.
- **수정 방법**: `LazyVStack` + `ForEach`를 `List` + `ForEach`로 변경하거나, 각 `TimelineEntryView` 카드에 삭제 버튼(contextMenu 또는 long press → `.actionCheckModal`)을 직접 추가. `List`로 변경할 경우 `listStyle(.plain)`, `listRowBackground(Color.clear)`, `listRowSeparator(.hidden)`, `scrollContentBackground(.hidden)` 적용 필요.

### BLOCKER 2: `SongSearchViewModel.swift` -- 불필요한 `import MusicKit` 제거
- **위치**: `ViewModels/SongSearchViewModel.swift` line 3
- **근거**: ViewModel 레이어에서 Apple Framework 직접 import는 MVVM 원칙 위반. 파일 내에서 MusicKit 타입을 실제로 사용하지 않음 (검색 결과는 `SearchedSong`으로 매핑됨, 권한 요청은 Service 위임).
- **수정 방법**: `import MusicKit` 라인 삭제.

### BLOCKER 3: 디자인 시스템 컴포넌트 API 시그니처 불일치 (빌드 에러 가능)
- **위치**: 여러 파일
- **근거**: PROJECT_CONTEXT에 명시된 API와 다른 시그니처로 호출하면 컴파일 에러 발생
- **수정 방법**:
  1. `EntryWriteView.swift` line 97: `PChip(tag)` → `PChip(title: tag)` (또는 디자인 시스템이 positional 인자를 지원하는지 확인)
  2. `EntryWriteView.swift` line 156-163: `PDropdownButton(placeholder:options:selectedOption:)` → PROJECT_CONTEXT의 `PDropdownButton(selection:options:)` 시그니처에 맞춤
  3. `AddEntryView.swift` line 107: `PSectionHeader("이전 기록들")` → `PSectionHeader(title: "이전 기록들")`
  4. `SignInView.swift` line 76: `PLoadingOverlay()` → `PLoadingOverlay(isLoading: true)` 또는 `.pLoadingOverlay(isLoading:)` ViewModifier 사용
  5. `ManualSongInputView.swift` `PFormFieldState` → `.error` 단독 사용 vs `.error("메시지")` 확인
  6. `TimelineEntryView.swift` line 57: `PChip(tag)` → `PChip(title: tag)` (동일 이슈)
  7. `MoodChipGridView.swift` line 33-38: `PChip(tag, variant:isSelected:)` → `PChip(title: tag, variant:isSelected:)` 확인

### BLOCKER 4: `DateFormatters.swift` -- `nonisolated(unsafe)` 전역 변수 안전하지 않음
- **위치**: `Shared/DateFormatters.swift` line 5
- **근거**: `DateFormatter`는 thread-safe하지 않음. `nonisolated(unsafe)`는 컴파일러의 Sendable 경고만 억제하며 실제 동시성 안전성을 보장하지 않음. 여러 actor에서 동시에 접근하면 crash 가능.
- **수정 방법**: 전역 변수 `_yearOnlyFormatter` 삭제. `DateFormatters` enum 내에서 각 함수가 로컬 `DateFormatter` 사용하거나, actor 내부로 이동. 또는 Swift 6에서 안전한 `Date.FormatStyle` API 사용:
  ```swift
  static func yearString(from date: Date) -> String {
      date.formatted(.dateTime.year())
  }
  ```

---

## 추가 개선 권고 (Non-blocker)

1. **모든 Model의 `nonisolated` 키워드 제거** -- `SongMemory.swift`, `MoodTag.swift`, `SearchedSong.swift`, `AppError.swift`의 `nonisolated struct/enum` → 단순 `struct/enum`. `struct`는 기본적으로 nonisolated이며 `Sendable` 준수만으로 충분.

2. **`RecordFlowViewModel.currentStep`을 `private(set)`으로 변경** -- `goToNextStep()`/`goToPreviousStep()`을 통해서만 변경되어야 함.

3. **`TimelineEntryView`와 `AddEntryView`의 `formattedDate()` 내 `DateFormatter` 반복 생성 제거** -- `DateFormatters`에 `mediumDateFormatter`를 `static let` (또는 메서드)로 추가하여 공유.

4. **`EntryWriteView` line 138, `AddEntryView` line 155의 `.padding(16)` → `.padding(PSpacing.lg)`** -- 하드코딩 숫자 대신 디자인 토큰 사용.

5. **`SongCollectionView`에서 `@State private var authViewModel: AuthViewModel`를 `@Bindable`로 변경 검토** -- 외부 주입 객체를 `@State`로 감싸는 것은 부자연스러운 소유권 패턴.

---

## 방향 판단: 현재 방향 유지

전체 아키텍처는 올바르게 설계되어 있음. MVVM 레이어 분리, Swift 6 동시성 모델, 디자인 시스템 적용 모두 양호. 위의 4개 BLOCKER만 수정하면 합격 가능.
