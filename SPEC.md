# DearSong - 버그 수정 & 디자인 개선 SPEC

## 개요

기존 DearSong 앱의 3가지 이슈를 수정한다:
1. EntryWriteView 레이아웃 짤림 버그 수정
2. 감정 태그 칩(MoodChipGridView) 너비 동적화
3. 디자인 테마 전면 개선 (red/airbnb -> 감성 다이어리 테마)

이것은 **기존 앱의 유지보수**이며, 신규 기능 추가가 아니다.
기존 아키텍처(MVVM, Swift 6 동시성, TopDesignSystem)를 그대로 유지한다.

## 타겟 플랫폼

- iOS 17.0 이상
- Swift 6 (엄격 동시성)
- UI 프레임워크: SwiftUI + TopDesignSystem

## 수정 사항

---

### 수정 1: EntryWriteView 레이아웃 짤림 버그

**현상**: 감정 선택 후 기록 작성 화면(EntryWriteView)으로 진입하면, 최초 렌더링 시 콘텐츠가 디바이스 화면을 초과하여 짤린다. 텍스트 필드 등에 1회 탭하면 정상 레이아웃으로 잡힌다.

**원인 분석**:
- EntryWriteView의 `ScrollView` 내부에 `Picker(.wheel)` + `frame(height: 120)` 고정 높이가 초기 레이아웃 계산을 불안정하게 만듦
- `artworkBackground` ZStack의 `AsyncImage(.fill)` + `ignoresSafeArea()`가 콘텐츠 레이아웃 흐름에 간섭
- `safeAreaInset(edge: .bottom)`의 `saveButton`이 초기 렌더링 시 높이 계산에 영향
- 포커스/키보드 이벤트 발생 시 레이아웃 재계산으로 정상화되는 패턴

**수정 방향**:
1. `Picker(.wheel)`을 `Picker(.menu)` 스타일로 교체 -- 고정 높이 의존 제거, 컴팩트한 드롭다운 형태
2. `artworkBackground`를 ZStack의 별도 레이어가 아닌, `.background()` modifier로 적용하여 레이아웃 흐름에서 완전 분리
3. `TextEditor`의 `frame(minHeight: 160)` 유지하되, 불필요한 중첩 ZStack 단순화
4. `saveButton`의 `safeAreaInset` 내에서 명시적 높이 확보 (패딩 충분히)
5. ScrollView에 `.contentMargins`나 충분한 bottom padding으로 safeAreaInset 영역과의 간섭 방지

**관련 파일**:
- `output/Views/Record/EntryWriteView.swift`

**검증 기준**:
- 최초 진입 시 모든 콘텐츠가 스크롤 가능 영역 내에 정상 표시
- 텍스트 필드 탭 없이도 레이아웃이 올바름
- iPhone SE ~ iPhone Pro Max 전체 크기에서 정상 동작

---

### 수정 2: 감정 태그 칩 너비 동적화

**현상**: MoodChipGridView에서 감정 태그 칩들이 `LazyVGrid(columns: [GridItem(.adaptive(minimum: 84))])`로 구현되어 있어, 짧은 텍스트("슬픔")와 긴 텍스트("비 오는 날")가 동일한 셀 너비를 차지한다. 결과적으로 짧은 태그에 불필요한 여백이 생기고, 화면 공간이 낭비된다.

**수정 방향**:
1. `LazyVGrid(.adaptive)` 대신 **FlowLayout**(가변 너비 래핑 레이아웃)으로 교체
2. iOS 16+ `Layout` 프로토콜로 커스텀 FlowLayout 구현
3. 각 칩 너비 = 텍스트 intrinsic width + 양쪽 padding (약 `DesignSpacing.xs` ~ 5pt 수준)
4. 칩 내부 패딩: `.padding(.horizontal, DesignSpacing.xs)` + `.padding(.vertical, DesignSpacing.xxs)`
5. 칩 간 간격: `DesignSpacing.xs` (4pt)

**구현 상세**:
- `Shared/FlowLayout.swift` 신규 생성 -- `Layout` 프로토콜 준수 FlowLayout 구조체
- `MoodChipGridView`에서 `LazyVGrid` -> `FlowLayout` 교체
- `TimelineEntryView`의 감정 태그 표시도 동일하게 `LazyVGrid` -> `FlowLayout` 교체

**관련 파일**:
- `output/Shared/FlowLayout.swift` (신규)
- `output/Views/Components/MoodChipGridView.swift` (수정)
- `output/Views/Components/TimelineEntryView.swift` (수정)

**검증 기준**:
- "슬픔" 칩은 좁고, "비 오는 날" 칩은 넓게 -- 텍스트에 맞는 자연스러운 너비
- 한 줄에 공간이 있으면 최대한 많은 칩이 들어감
- 줄 바꿈이 자연스럽게 발생
- 선택/비선택 상태 전환 시 레이아웃 깨짐 없음

---

### 수정 3: 디자인 테마 전면 개선

**현상**: 현재 `.designTheme(.airbnb)` 테마가 적용되어 있어 red 기반의 화려한 색상이 사용됨. 감성 다이어리 앱의 따뜻하고 차분한 분위기와 맞지 않음.

**수정 방향**:

1. **테마 변경**: `.designTheme(.airbnb)` -> 감성적이고 따뜻한 테마로 교체
   - TopDesignSystem의 `DesignTheme` enum에서 가용한 테마 중 선택
   - 우선순위: journal > earth > nature > warmVibrant > 기타 따뜻한 톤
   - red/orange 기반 테마 사용 금지
   - 따뜻한 톤 (베이지, 크림, 코랄, 브라운 계열) 우선

2. **종이 질감 느낌 강화**:
   - 배경에 미세한 종이 느낌 효과 (매우 연한 overlay 또는 미세 grain -- TopDesignSystem 토큰 범위 내)
   - GlassCard 배경을 약간 더 불투명하게 조정 가능 여부 확인
   - 전체적으로 따뜻한 크림/아이보리 베이스 (테마 수준에서 해결)

3. **감성적 디테일**:
   - SignInView: 앱 아이콘 SF Symbol을 더 감성적으로 (예: `book.closed.fill`, `heart.text.square` 등 음악+감정 조합)
   - 빈 상태 화면: 감성적 문구/아이콘 강화
   - 기록 작성 배경: 앨범 아트 블러 미세 조정

4. **색상 톤** (테마 레벨에서 해결):
   - `palette.primaryAction`: 차분한 따뜻한 색상
   - `palette.background`: 크림/아이보리 톤
   - `palette.textPrimary`: 다크 브라운/차콜 (순수 블랙 아님)
   - 모든 색상은 TopDesignSystem 테마 선택으로 해결 -- 하드코딩 색상 절대 금지

**관련 파일**:
- `output/App/DearSongApp.swift` (테마 변경)
- `output/Views/Auth/SignInView.swift` (감성 디테일)
- `output/Views/Collection/SongCollectionView.swift` (빈 상태 개선)
- `output/Views/Detail/SongDetailView.swift` (배경 톤 미세 조정)
- `output/Views/Record/EntryWriteView.swift` (배경 톤 미세 조정)

**검증 기준**:
- 전체 앱이 따뜻하고 감성적인 톤으로 통일
- red 계열 색상이 사라지고 따뜻한 톤으로 교체
- 하드코딩 색상 없음 (모두 palette 토큰 사용)
- 다크모드에서도 감성적 톤 유지

---

## 아키텍처 (변경 없음)

```
View -> ViewModel -> Service -> (Supabase / MusicKit)
```

- View: `@MainActor struct`, SwiftUI View
- ViewModel: `@MainActor @Observable final class`
- Service: `actor` + Protocol
- Model: `struct` + `Sendable`

### 수정 범위

| 레이어 | 수정 대상 | 내용 |
|--------|-----------|------|
| View | EntryWriteView | 레이아웃 버그 수정 |
| View | MoodChipGridView | FlowLayout 적용 |
| View | TimelineEntryView | FlowLayout 적용 |
| View | DearSongApp | 테마 변경 |
| View | SignInView | 감성 디테일 |
| View | SongCollectionView | 빈 상태 개선 |
| View | SongDetailView | 배경 톤 미세 조정 |
| Shared | FlowLayout (신규) | Layout 프로토콜 FlowLayout |

### 신규 파일

| 파일 | 레이어 | 설명 |
|------|--------|------|
| `output/Shared/FlowLayout.swift` | Shared | iOS 16+ Layout 프로토콜 기반 FlowLayout |

### 수정 파일 목록

| 파일 | 변경 내용 |
|------|-----------|
| `output/App/DearSongApp.swift` | `.designTheme(.airbnb)` -> 감성 테마 |
| `output/Views/Record/EntryWriteView.swift` | 레이아웃 안정화 + Picker 교체 |
| `output/Views/Components/MoodChipGridView.swift` | LazyVGrid -> FlowLayout |
| `output/Views/Components/TimelineEntryView.swift` | LazyVGrid -> FlowLayout |
| `output/Views/Auth/SignInView.swift` | 감성 아이콘/문구 |
| `output/Views/Collection/SongCollectionView.swift` | 빈 상태 감성 개선 |
| `output/Views/Detail/SongDetailView.swift` | 배경 톤 미세 조정 |

---

## 동시성 경계 (변경 없음)

- **View**: `@MainActor` struct -- UI만 담당
- **ViewModel**: `@MainActor final class` + `@Observable` -- UI 상태 소유
- **Service**: `actor` -- 비동기 데이터 처리
- **Model**: `struct` + `Sendable` -- 순수 데이터

---

## 뷰 계층 (변경 없음)

```
DearSongApp
  |- SignInView (미인증)
  +- SongCollectionView (인증됨)
       |- NavigationLink -> SongDetailView
       |    |- sheet -> AddEntryView
       |    +- fullScreenCover -> RecordFlowView
       +- fullScreenCover -> RecordFlowView
             |- SongSearchView (step 0)
             |    +- ManualSongInputView (MusicKit 거부 시)
             |- MoodSelectionView (step 1)
             |    +- MoodChipGridView
             +- EntryWriteView (step 2)
```

---

## 코드 컨벤션

- **디자인 시스템**: TopDesignSystem 토큰만 사용 (하드코딩 색상/폰트 금지)
- **테마**: `palette.*` 토큰으로 모든 색상 접근 (`@Environment(\.designPalette)`)
- **스페이싱**: `DesignSpacing.*` 토큰
- **코너 반경**: `DesignCornerRadius.*` 토큰
- **폰트**: `.ssBody`, `.ssTitle2`, `.ssFootnote`, `.ssCaption`, `.ssLargeTitle` 등
- **애니메이션**: `SpringAnimation.gentle` 등 TopDesignSystem 토큰
- **접근 제어자**: 모든 프로퍼티/메서드에 명시
- **FlowLayout**: `Layout` 프로토콜 준수, `struct`

---

## 주의사항

1. **기존 기능 회귀 금지**: 레이아웃/디자인 수정이 기존 기능(저장, 검색, 인증 등)에 영향을 주지 않을 것
2. **ViewModel/Service/Model 변경 최소화**: View 레이어 중심 수정. ViewModel 로직 변경 불필요
3. **TopDesignSystem 의존**: 모든 스타일링은 TopDesignSystem 토큰 경유. 커스텀 색상/폰트 정의 금지
4. **FlowLayout은 순수 SwiftUI**: UIKit 브리징 없이 `Layout` 프로토콜로 구현
5. **import 규칙**: View 파일은 `import SwiftUI` + `import TopDesignSystem`. ViewModel은 `import Foundation` + `import Observation`만
