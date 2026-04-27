RESULT: conditional_pass
SCORE: 7.8
BLOCKERS: 4

---

**전체 판정**: 조건부 합격
**가중 점수**: 7.8 / 10.0

---

## 1단계: 파일 구조 분석

### 파일 목록 및 레이어 분류

| 레이어 | 파일 |
|--------|------|
| App | `App/DearSongApp.swift` |
| View | `Views/Auth/SignInView.swift`, `Views/Collection/SongCollectionView.swift`, `Views/Detail/SongDetailView.swift`, `Views/Record/RecordFlowView.swift`, `Views/Record/SongSearchView.swift`, `Views/Record/MoodSelectionView.swift`, `Views/Record/EntryWriteView.swift`, `Views/Record/ManualSongInputView.swift`, `Views/Entry/AddEntryView.swift` |
| Component | `Views/Components/SongCardView.swift`, `Views/Components/MoodChipGridView.swift`, `Views/Components/TimelineEntryView.swift`, `Views/Components/AlbumArtworkView.swift` |
| ViewModel | `ViewModels/AuthViewModel.swift`, `ViewModels/SongCollectionViewModel.swift`, `ViewModels/SongDetailViewModel.swift`, `ViewModels/RecordFlowViewModel.swift`, `ViewModels/SongSearchViewModel.swift`, `ViewModels/AddEntryViewModel.swift` |
| Model | `Models/SongMemory.swift`, `Models/MoodTag.swift`, `Models/SearchedSong.swift` |
| Service | `Services/AuthService.swift`, `Services/SongMemoryService.swift`, `Services/MusicSearchService.swift`, `Services/SupabaseClientProvider.swift` |
| Shared | `Shared/AppError.swift`, `Shared/DateFormatters.swift` |
| Test | `Tests/Mocks.swift`, `Tests/Models/MoodTagTests.swift`, `Tests/Services/AuthServiceTests.swift`, `Tests/Services/SongMemoryServiceTests.swift`, `Tests/ViewModels/RecordFlowViewModelTests.swift` |

SPEC.md의 파일 구조와 정확히 일치함. `Shared/AppTheme.swift`는 R3에서 제거 완료.

---

## 2단계: 사용자 요청 8가지 수정사항 검증

### [FAIL] 수정사항 1: 바깥 탭 시 키보드 닫기 (글로벌)

**현재 상태**: `scrollDismissesKeyboard(.interactively)`가 `EntryWriteView`, `AddEntryView`, `ManualSongInputView`에만 적용되어 있음. 이 방식은 스크롤 시에만 키보드를 닫는 것이지, 빈 영역 탭 시 닫는 것이 아님.

**미구현 사항**:
- 글로벌 수준에서 빈 영역(바깥) 탭 시 키보드를 닫는 기능이 없음
- `SongSearchView`의 검색 필드에서도 빈 영역 탭으로 키보드를 닫을 수 없음
- `DearSongApp.swift`나 루트 수준에서 `UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)` 패턴 또는 `.onTapGesture`로 키보드 dismiss하는 코드가 없음

**수정 방법**: `DearSongApp.swift`에서 전역적으로 `onTapGesture`를 적용하거나, 각 View의 배경에 `.contentShape(Rectangle()).onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder)...) }` 패턴 적용. 또는 SwiftUI의 `scrollDismissesKeyboard(.immediately)` 활용.

### [PASS] 수정사항 2: count 값을 사용자 친화적 텍스트로

`SongCardView.swift` line 35: `Text("songcard.records.count \(groupedSong.memoryCount)")` -- String Catalog 키를 사용하고 있어 로컬라이제이션 파일에서 "N개의 기록" 같은 사용자 친화적 텍스트로 포맷 가능. 구현 자체는 적절함.

### [PASS] 수정사항 3: 메인 컬렉션 새로고침 시 정렬 고정

`SongCollectionViewModel.swift`의 `refresh()` 메서드가 `loadMemories()`를 호출하고, `groupMemories()`에서 항상 `listenedAt` 내림차순으로 정렬함 (line 61-65). 새로고침 시 정렬 순서가 일관되게 유지됨.

### [PASS] 수정사항 4: AddEntryView 가로 레이아웃 짤림 수정

`AddEntryView.swift`가 `ScrollView`를 사용하고, 모든 콘텐츠에 `DesignSpacing.lg` 패딩 적용, `safeAreaInset(edge: .bottom)`으로 저장 버튼 배치. `lineLimit(1)` + `truncationMode(.tail)`로 긴 텍스트 처리. `fixedSize(horizontal: false, vertical: true)` 적용. 레이아웃 짤림 문제 해결됨.

### [FAIL] 수정사항 5: 년도 "2,026" -> "2026" 포맷 수정

**치명적 문제**: 여전히 `\(listenedYear)` (Int 타입)를 SwiftUI `Text`에서 직접 보간하고 있음.

- `AddEntryView.swift` line 109: `Text("\(listenedYear)\(String(localized: "timeline.year_suffix"))...")` -- SwiftUI `Text`의 `\(Int)` 보간은 `Locale`-aware 포맷팅을 적용하여 "2,026"으로 표시됨.
- `TimelineEntryView.swift` line 21: `Text("timeline.year \(listenedYear)")` -- String Catalog 보간도 동일하게 locale-aware Int 포맷팅이 적용됨.

**예외 (정상)**: `EntryWriteView.swift` line 201: `Text(String(year)).tag(year)` -- `String(year)`는 locale 무관하게 "2026"을 생성하므로 정상.

**수정 방법**:
1. `AddEntryView.swift`: `\(listenedYear)` -> `\(String(listenedYear))` 또는 전용 포맷터 사용
2. `TimelineEntryView.swift`: `Text("timeline.year \(listenedYear)")` -> `Text("timeline.year \(String(listenedYear))")` 또는 `Text(verbatim: "\(listenedYear)년")` 사용

### [FAIL] 수정사항 6: 감정 칩 섹션 제거 + 높이 축소

**미구현**: `TimelineEntryView.swift` lines 57-72에 여전히 감정 태그(mood tags) 섹션이 존재함:

```swift
if !memory.moodTags.isEmpty {
    LazyVGrid(...) {
        ForEach(memory.moodTags, id: \.self) { tag in
            Text(tag)...
        }
    }
}
```

사용자가 요청한 감정 칩 섹션 제거가 이루어지지 않았음. 이에 따라 타임라인 카드 높이 축소도 미반영.

**수정 방법**: `TimelineEntryView.swift`에서 mood tags LazyVGrid 블록(lines 57-72)을 완전히 삭제.

### [PASS] 수정사항 7: 감정 선택 단계에서 장소 필드 제거

`MoodSelectionView.swift`에 장소(location) 관련 필드가 없음. 장소 입력은 `EntryWriteView.swift`(Step 3)에만 존재. 정상.

### [FAIL] 수정사항 8: 날씨 관련 태그 제거

**미구현**: `MoodTag.swift`에 `MoodCategory.season` 케이스가 여전히 존재하며, 날씨 관련 태그 6개("비 오는 날", "눈 오는 날", "바람 부는 날", "여름밤", "가을 햇살", "봄바람")가 정의되어 있음 (lines 13, 25, 46-47).

**수정 방법**:
1. `MoodTag.swift`에서 `case season` 삭제
2. `displayName`의 `.season` 케이스 삭제
3. `tags`의 `.season` 케이스 삭제

---

## 3단계: evaluation_criteria 채점

### Swift 6 동시성: 9/10

**양호한 점**:
- 모든 ViewModel: `@MainActor` + `@Observable` 선언됨 (AuthViewModel, SongCollectionViewModel, SongDetailViewModel, RecordFlowViewModel, SongSearchViewModel, AddEntryViewModel)
- 모든 Service: `actor` 선언됨 (AuthService, SongMemoryService, MusicSearchService)
- 모든 Model: `struct` + `Sendable` 준수 (SongMemory, Entry, Attachment, GroupedSong, SearchedSong, MoodTag, MoodCategory)
- `DispatchQueue`, `@Published`, `ObservableObject` 미사용
- Protocol 기반 DI로 Sendable 경계 준수 (AuthServiceProtocol, SongMemoryServiceProtocol, MusicSearchServiceProtocol 모두 `Sendable`)

**경미한 감점**:
- `SupabaseClientProvider`가 `final class`로 선언. `static let shared` 싱글턴이 `actor`가 아닌 `class`로 구현됨. `let client`이므로 불변이라 실제 위험은 낮지만, actor 패턴이 더 적절.
- `nonisolated` 키워드가 Model/Enum에 과도하게 사용됨. struct와 enum은 기본적으로 Sendable 확인만 하면 됨. 위험하지는 않으나 불필요한 어노테이션.

### MVVM 분리: 9/10

**양호한 점**:
- View: 순수 UI 선언만 포함, Service 직접 호출 없음
- ViewModel: `import Foundation` + `import Observation` 사용, `import SwiftUI` 없음, UI 타입(Color, Font) 없음
- Service: ViewModel/View 참조 없음
- 의존성 단방향: View -> ViewModel -> Service
- Protocol 기반 Service 주입 (테스트 가능성 확보)

**경미한 감점**:
- `AuthViewModel.prepareSignInRequest()`가 `ASAuthorizationAppleIDRequest`를 반환. UI-layer 관련 타입이나, Apple Sign In의 특성상 실무적으로 표준 패턴이므로 가벼운 감점.

### HIG 준수 + 디자인 시스템: 8/10

**양호한 점**:
- TopDesignSystem 토큰 100% 적용 (색상: `palette.*`, 폰트: `.ss*`, 간격: `DesignSpacing.*`, 코너: `DesignCornerRadius.*`)
- `import TopDesignSystem` 모든 View에 적용
- `.designTheme(.airbnb)` 앱 루트에 적용
- 터치 영역 44pt 이상 대부분 준수
- 로딩/에러 상태 UI 제공 (ShimmerPlaceholder, ProgressView, bottomToast)
- 접근성 레이블 주요 인터랙션에 추가

**감점 사항**:
- `AlbumArtworkView.swift` line 42: `.font(.system(size: (size ?? 48) * 0.35))` -- `.system(size:)` 직접 사용. Dynamic Type 미지원.
- `SongCardView.swift` line 33: `.font(.system(size: 10))` -- `.system(size:)` 직접 사용.
- `Color.black.opacity(0.3)` 패턴이 로딩 오버레이에 사용됨 (EntryWriteView, AddEntryView, SignInView) -- semantic color가 아님.

### API 활용: 9/10

**양호한 점**:
- MusicKit: `MusicCatalogSearchRequest`, `MusicAuthorization.request()`, `Song`, `Artwork` 올바르게 사용
- Supabase Auth: `signInWithIdToken`, `OpenIDConnectCredentials`, 세션 관리 정상
- Supabase Database: `from().select().eq().order().execute()` 패턴 정상
- 권한 요청 흐름: MusicKit 권한 거부 시 수동 입력 폴백 구현
- 에러 처리: `AppError` 통합 에러 타입으로 일관된 처리

**경미한 감점**:
- `SongSearchViewModel`에서 `.notDetermined`를 `isMusicKitDenied = false`로 처리하는 것은 권한 요청 전 상태에서 검색을 허용할 수 있어 미세한 논리 결함.

### 기능성 및 코드 가독성: 7/10

**양호한 점**:
- SPEC 기능 1-7 기본 구현 완료
- 접근 제어자 `private(set)`, `private` 잘 명시됨
- 에러 타입 `enum [Domain]Error: Error` 패턴
- CodingKeys snake_case <-> camelCase 매핑 명시
- 파일 구조 SPEC 컨벤션 일치

**감점 사항 (사용자 요청 8가지 중 4가지 미반영)**:
1. 바깥 탭 시 키보드 닫기 미구현 (BLOCKER)
2. 년도 "2,026" 포맷 미수정 (BLOCKER)
3. 감정 칩 섹션 미제거 (BLOCKER)
4. 날씨 관련 태그 미제거 (BLOCKER)

---

## 4단계: 최종 판정 + 피드백

### 점수 계산

```
가중 점수 = (동시성 9 x 0.30) + (MVVM 9 x 0.25) + (HIG 8 x 0.20) + (API 9 x 0.15) + (기능성 7 x 0.10)
         = 2.70 + 2.25 + 1.60 + 1.35 + 0.70
         = 8.60
```

사용자 요청 8가지 중 4가지가 미반영된 점을 반영하여 최종 점수 하향:

```
최종 가중 점수 = 8.6 -> 사용자 요청 미반영 페널티 적용 -> 7.8
```

### 항목별 점수

- Swift 6 동시성: 9/10 -- 모든 레이어 올바른 동시성 모델 적용. SupabaseClientProvider만 class이나 불변 프로퍼티라 실질 위험 없음.
- MVVM 분리: 9/10 -- 완벽한 단방향 의존. AuthViewModel의 ASAuthorizationAppleIDRequest 반환만 미세 감점.
- HIG 준수: 8/10 -- TopDesignSystem 토큰 적용 우수. `.system(size:)` 2건, `Color.black` 오버레이 3건 잔존.
- API 활용: 9/10 -- MusicKit, Supabase Auth/DB 모두 올바르게 구현. 권한 상태 처리 미세 논리 결함 1건.
- 기능성/가독성: 7/10 -- 기본 아키텍처 우수하나 사용자 요청 8가지 중 4가지(키보드 닫기, 년도 포맷, 감정 칩 제거, 날씨 태그 제거) 미반영.

---

## 구체적 개선 지시

### BLOCKER 1: 바깥 탭 시 키보드 닫기 (글로벌)

**파일**: `App/DearSongApp.swift`
**수정 방법**: `rootView`에 글로벌 키보드 dismiss modifier 적용:

```swift
rootView
    .onTapGesture {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
```

또는 별도 ViewModifier를 만들어 `SongSearchView`, `EntryWriteView`, `AddEntryView`, `ManualSongInputView`에 개별 적용. 글로벌 적용 시 Button 등 탭 이벤트와 충돌하지 않도록 `.simultaneousGesture(TapGesture().onEnded { ... })` 사용 권장.

### BLOCKER 2: 년도 "2,026" -> "2026" 포맷

**파일 1**: `Views/Entry/AddEntryView.swift` line 109
**현재**: `Text("\(listenedYear)\(String(localized: "timeline.year_suffix"))...")`
**수정**: `Text("\(String(listenedYear))\(String(localized: "timeline.year_suffix"))...")`

**파일 2**: `Views/Components/TimelineEntryView.swift` line 21
**현재**: `Text("timeline.year \(listenedYear)")`
**수정**: `Text("timeline.year \(String(listenedYear))")` 또는 `Text(verbatim: "\(listenedYear)년")` 사용. `String(listenedYear)`를 통해 locale-independent 변환 보장.

### BLOCKER 3: 감정 칩 섹션 제거 + 높이 축소

**파일**: `Views/Components/TimelineEntryView.swift`
**수정**: lines 52-72의 Divider + mood tags LazyVGrid 블록 전체 삭제:

```swift
// 삭제 대상:
// 구분선 (PDivider 대체)
Divider()
    .overlay(palette.border)

// 감정 태그
if !memory.moodTags.isEmpty {
    LazyVGrid(...) { ... }
}
```

Divider와 mood tags 블록을 모두 제거하면 카드 높이가 자연스럽게 축소됨.

### BLOCKER 4: 날씨 관련 태그 제거

**파일**: `Models/MoodTag.swift`
**수정**:
1. `MoodCategory` enum에서 `case season` 삭제 (line 13)
2. `displayName` switch에서 `.season` 케이스 삭제 (line 25)
3. `tags` switch에서 `.season` 케이스 삭제 (lines 46-47)

---

## 비-BLOCKER 개선 권장사항

1. **AlbumArtworkView.swift** line 42: `.font(.system(size: (size ?? 48) * 0.35))` -- 동적 계산이라도 디자인 시스템 토큰을 기반으로 계산하는 것이 일관성 유지에 좋음.
2. **SongCardView.swift** line 33: `.font(.system(size: 10))` -- `.ssCaption` 또는 더 작은 디자인 토큰으로 교체.
3. **로딩 오버레이**: `Color.black.opacity(0.3)` -> `palette.textPrimary.opacity(0.3)` 등 semantic 색상 사용.
4. **AddEntryViewModel.swift** line 26: `"내용을 입력해주세요."` 하드코딩 한국어 -> String Catalog 키 사용.
5. **AuthViewModel.swift** line 38: `"Apple Sign In 정보를 처리할 수 없습니다."` 하드코딩 한국어 -> String Catalog 키 사용.

---

**방향 판단**: 현재 방향 유지. 아키텍처와 기본 구현은 우수함. BLOCKER 4건만 수정하면 합격.
