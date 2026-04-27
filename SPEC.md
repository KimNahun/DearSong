# DearSong - 버그 수정 및 UI 개선 SPEC (Phase 2)

## 개요

DearSong 앱의 8가지 버그 수정 및 UI 개선 작업. 기존 아키텍처(MVVM + Swift 6 동시성 + TopDesignSystem)를 유지하면서 사용자 경험을 개선한다. 이것은 기존 앱의 유지보수이며, 신규 기능 추가가 아니다.

## 타겟 플랫폼

- iOS 17.0 이상
- Swift 버전: Swift 6 (엄격 동시성)
- UI 프레임워크: SwiftUI + TopDesignSystem
- 필요 권한: MusicKit (Apple Music 검색), Apple Sign In

## 아키텍처 (변경 없음)

```
View -> ViewModel -> Service -> (Supabase / MusicKit)
```

### 동시성 경계 (기존 유지)

- **View**: `@MainActor` struct — UI만 담당
- **ViewModel**: `@MainActor final class` + `@Observable`
- **Service**: `actor` + Protocol
- **Model**: `struct` + `Sendable`

---

## 수정 사항 (8가지)

---

### 수정 1: 글로벌 키보드 닫기

- **설명**: 앱 전체에서 텍스트 입력 바깥 영역을 탭하면 키보드가 닫혀야 함
- **현재 문제**: `scrollDismissesKeyboard(.interactively)`만 일부 화면(EntryWriteView, AddEntryView)에 적용. 스크롤 없는 영역이나 다른 화면에서는 키보드를 닫을 수 없음.
- **수정 방향**:
  - `Shared/` 폴더에 `View` extension으로 `.dismissKeyboardOnTap()` modifier 추가
  - 구현: `UIApplication.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)`을 `onTapGesture`에 연결
  - `DearSongApp.swift`의 `rootView`에 글로벌 적용하여 앱 전체에서 동작
  - 기존 `.scrollDismissesKeyboard(.interactively)` 는 병행 유지 (스크롤 중 키보드 닫기)
- **관련 파일**:
  - `Shared/ViewExtensions.swift` (신규) — `dismissKeyboardOnTap()` modifier 정의
  - `App/DearSongApp.swift` — 글로벌 적용
- **HIG 패턴**: 표준 키보드 dismiss 패턴

---

### 수정 2: 카운트 표시 개선

- **설명**: raw 숫자 표시를 사용자 친화적 한국어 텍스트로 변환
- **현재 문제**:
  - `MoodSelectionView` 33행: `Text("mood.selected.count \(viewModel.selectedMoodTags.count)")` — 로컬라이제이션 키 형태로 숫자만 표시
  - `SongCardView` 35행: `Text("songcard.records.count \(groupedSong.memoryCount)")` — 동일 패턴
- **수정 방향**:
  - `MoodSelectionView`: `"\(count)개 선택됨"` 형태로 변경
  - `SongCardView`: `"기록 \(count)개"` 형태로 변경
  - `Text(verbatim:)` 또는 직접 String 생성으로 LocalizedStringKey 자동 변환 우회
- **관련 파일**:
  - `Views/Record/MoodSelectionView.swift` — 선택 카운트 텍스트
  - `Views/Components/SongCardView.swift` — 기록 수 텍스트

---

### 수정 3: 메인 컬렉션 정렬 고정

- **설명**: 새로고침할 때마다 곡 순서가 바뀌는 버그 수정
- **현재 문제**:
  - `SongCollectionViewModel.groupMemories()` (46행~)에서 `Dictionary.values`의 순서가 비결정적
  - 정렬 기준이 `lhs.memories.first?.listenedAt`인데, 그룹 내 memories 배열이 정렬되지 않아 `first`가 매번 다른 메모리를 가리킬 수 있음
  - 결과적으로 매 새로고침마다 그리드 순서가 뒤섞임
- **수정 방향**:
  1. 그룹 내 memories를 `updatedAt` 내림차순으로 먼저 정렬
  2. 그룹 간 정렬: **가장 최근 updatedAt** 기준 내림차순 (최근 활동 곡이 위)
  3. 동일 시간 시 `songTitle` 오름차순 2차 정렬 (결정적 순서 보장)
- **관련 파일**:
  - `ViewModels/SongCollectionViewModel.swift` — `groupMemories()` 수정

---

### 수정 4: AddEntryView 레이아웃 수정

- **설명**: "이 곡의 새 시기 추가" 화면(AddEntryView)에서 가로 레이아웃 짤림, 글씨 가로 너비 초과, 버튼 꽉 참
- **현재 문제**:
  - `sheetHeader`의 곡 제목 + 년도/아티스트 텍스트가 한 줄에 합쳐져 긴 텍스트가 넘침
  - `saveButton`이 좌우 여백 없이 꽉 차 보임
  - 전체적 여유 공간 부족
- **수정 방향**:
  - `sheetHeader` 내 VStack: 곡 제목 `.lineLimit(1)` 유지, 부제목도 `.lineLimit(1)` + `.truncationMode(.tail)` 확인
  - 년도 포맷 수정 (수정 5와 연동 — 천단위 구분자 제거)
  - `saveButton`에 적절한 수평 패딩 추가/확인
  - `existingEntriesSection`과 `newEntrySection` 간 충분한 스페이싱
  - ScrollView 내부 콘텐츠의 `.padding(.horizontal, DesignSpacing.lg)` 일관성 확인
- **관련 파일**:
  - `Views/Entry/AddEntryView.swift` — 레이아웃 전반 수정

---

### 수정 5: 년도 포맷 수정 (천단위 구분자 제거)

- **설명**: 2026이 "2,026"으로 천단위 구분자가 붙어 표시되는 버그
- **현재 문제**:
  - SwiftUI의 `Text(LocalizedStringKey)` + Int interpolation에서 `NumberFormatter`가 자동 적용
  - `TimelineEntryView` 22행: `Text("timeline.year \(listenedYear)")` → "2,026년"
  - `AddEntryView` 109행: `Text("\(listenedYear)\(String(localized: "timeline.year_suffix")) · \(memory.artistName)")` → "2,026년 · 아티스트"
  - `EntryWriteView` 199행: Picker 내 `Text(String(year)).tag(year)` — 이건 `String` 변환 했으므로 OK
- **수정 방향**:
  - `DateFormatters`에 년도 전용 표시 함수 추가: `static func yearDisplayString(_ year: Int) -> String { "\(year)년" }`
  - 모든 년도 표시 코드에서 Int를 직접 interpolation 하지 않고 `String(year)` 또는 `DateFormatters.yearDisplayString()` 사용
  - `TimelineEntryView`: `Text(verbatim: DateFormatters.yearDisplayString(listenedYear))`
  - `AddEntryView`: `Text(verbatim: "\(DateFormatters.yearDisplayString(listenedYear)) · \(memory.artistName)")`
  - Picker 내 년도도 동일 패턴 통일
- **관련 파일**:
  - `Shared/DateFormatters.swift` — 년도 표시 헬퍼 추가
  - `Views/Components/TimelineEntryView.swift` — 년도 텍스트 수정
  - `Views/Entry/AddEntryView.swift` — 년도 텍스트 수정
  - `Views/Record/EntryWriteView.swift` — Picker 년도 확인/통일

---

### 수정 6: 감정 선택 UI 개선

- **설명**: 감정 태그를 카테고리별 섹션으로 나누지 말고 한 번에 전부 보이게. 감정 칩의 텍스트 높이 축소.
- **현재 문제**:
  - `MoodChipGridView`에서 `MoodCategory.allCases`를 `ForEach`로 순회하며 카테고리별 섹션 헤더 + 칩 그리드 표시
  - 카테고리 헤더("설렘/기쁨", "평온/감사" 등)가 많아 목록이 길고 스크롤이 과도
  - 칩의 `.padding(.vertical, DesignSpacing.xs)` (8pt) + `.frame(minHeight: 36)`으로 높이가 너무 큼
- **수정 방향**:
  1. `MoodChipGridView`: 카테고리 섹션 구조 완전 제거
  2. 전체 태그를 하나의 `FlowLayout`으로 평탄화: `MoodCategory.allCases.flatMap { $0.tags }`
  3. 칩 높이 축소:
     - `.padding(.vertical, DesignSpacing.xxs)` (4pt → 2pt) 또는 최소화
     - `.frame(minHeight: 36)` 제거 또는 `minHeight: 28`로 축소
     - 폰트: `.ssCaption` (12pt 급)으로 축소 (현재 `.ssFootnote`)
  4. 카테고리 헤더 텍스트 제거
  5. 기존 FlowLayout (`Shared/FlowLayout.swift`) 재사용
- **관련 파일**:
  - `Views/Components/MoodChipGridView.swift` — 레이아웃 전면 수정

---

### 수정 7: 장소 필드 제거 (감정 선택 단계)

- **설명**: MoodSelectionView에서 장소 입력이 있다면 제거
- **현재 상태 분석**:
  - `MoodSelectionView.swift` 코드 확인 결과, **장소 입력 필드가 이미 없음**
  - 장소 입력은 `EntryWriteView.swift` 213~228행에만 존재 (올바른 위치)
- **결론**: **수정 불필요. 이미 올바른 상태.**
- **관련 파일**: 없음

---

### 수정 8: 날씨 필드 제거

- **설명**: 날씨 관련 UI가 있다면 제거. 감정 선택 단계에서는 감정 태그만 있으면 됨.
- **현재 상태 분석**:
  - 별도의 날씨 선택 UI(맑음/흐림/비 선택기 등)는 존재하지 않음
  - 그러나 `MoodCategory.season` 카테고리가 존재하며, "비 오는 날", "눈 오는 날", "바람 부는 날" 등 날씨 태그가 포함
  - 이것은 "날씨 입력 필드"가 아니라 "감정/분위기 태그"의 일부이지만, 사용자 요청에 따라 정리
- **수정 방향**:
  - `MoodCategory.season` (계절/날씨) 카테고리를 제거
  - 계절 감성 태그("여름밤", "가을 햇살", "봄바람")는 `.situation`에 병합 (장소/상황 카테고리)
  - 순수 날씨 태그("비 오는 날", "눈 오는 날", "바람 부는 날")는 제거
- **관련 파일**:
  - `Models/MoodTag.swift` — `.season` 카테고리 제거, 일부 태그 `.situation`에 병합

---

## 수정 파일 요약

| 파일 | 수정 내용 | 수정 번호 |
|------|----------|-----------|
| `App/DearSongApp.swift` | 글로벌 키보드 dismiss 적용 | #1 |
| `Shared/ViewExtensions.swift` (신규) | `dismissKeyboardOnTap()` View modifier | #1 |
| `Shared/DateFormatters.swift` | 년도 표시 헬퍼 함수 추가 | #5 |
| `ViewModels/SongCollectionViewModel.swift` | `groupMemories()` 정렬 안정화 | #3 |
| `Views/Record/MoodSelectionView.swift` | 선택 카운트 텍스트 개선 | #2 |
| `Views/Components/MoodChipGridView.swift` | 카테고리 섹션 제거, 평탄 그리드, 칩 높이 축소 | #6 |
| `Views/Components/SongCardView.swift` | 기록 수 표시 텍스트 개선 | #2 |
| `Views/Components/TimelineEntryView.swift` | 년도 포맷 수정 (천단위 구분자 제거) | #5 |
| `Views/Entry/AddEntryView.swift` | 레이아웃 수정 + 년도 포맷 수정 | #4, #5 |
| `Views/Record/EntryWriteView.swift` | 년도 Picker 텍스트 통일 확인 | #5 |
| `Models/MoodTag.swift` | `.season` 카테고리 제거, 태그 병합 | #8 |

## 수정하지 않는 파일

- `Services/` — 서비스 레이어 변경 없음
- `Models/SongMemory.swift` — 모델 구조 변경 없음
- `Views/Auth/` — 인증 화면 변경 없음
- `Views/Record/SongSearchView.swift` — 곡 검색 화면 변경 없음
- `Views/Record/ManualSongInputView.swift` — 수동 입력 화면 변경 없음
- `Shared/FlowLayout.swift` — 이미 존재, 재사용 (수정 불필요)
- `Shared/AppTheme.swift` — 변경 없음

---

## 뷰 계층 (변경 없음)

```
DearSongApp                              ← #1 글로벌 키보드 dismiss 적용
├── SignInView (미인증)
└── SongCollectionView (인증됨, 메인)      ← #3 정렬 고정
    ├── SongDetailView (NavigationLink)
    │   ├── AddEntryView (sheet)          ← #4 레이아웃, #5 년도 포맷
    │   └── RecordFlowView (fullScreenCover)
    └── RecordFlowView (fullScreenCover, 새 기록)
        ├── Step 0: SongSearchView
        ├── Step 1: MoodSelectionView     ← #2 카운트 표시, #6 칩 UI, #7(불필요), #8 날씨 제거
        │   └── MoodChipGridView          ← #6 평탄 그리드
        └── Step 2: EntryWriteView        ← #5 년도 포맷
```

---

## 코드 컨벤션 (Generator가 따를 것)

- 뷰 파일: `[Feature]View.swift`
- 뷰모델 파일: `[Feature]ViewModel.swift`
- 접근 제어자 명시 (`private`, `private(set)`, `internal`)
- 디자인 시스템 토큰 사용 필수 (TopDesignSystem)
- 하드코딩 색상/폰트 절대 금지
- 최소 터치 영역 44x44pt
- `@MainActor` + `@Observable` ViewModel 패턴 유지
- `import` 규칙: View = `SwiftUI` + `TopDesignSystem`, ViewModel = `Foundation` + `Observation`
- 애니메이션: `SpringAnimation.gentle` 등 TopDesignSystem 토큰

---

## 테스트 고려사항

- `SongCollectionViewModel` 정렬 로직 변경 → 기존 테스트 업데이트 필요
- `MoodTag.swift` 카테고리 변경 (.season 제거) → `MoodTagTests` 업데이트 필요
- `DateFormatters` 년도 헬퍼 추가 → 테스트 추가

---

## 검증 기준

1. **키보드**: 모든 텍스트 입력 화면에서 바깥 탭으로 키보드 닫힘
2. **카운트**: "3개 선택됨", "기록 2개" 등 자연스러운 한국어 표시
3. **정렬**: 새로고침 반복해도 메인 컬렉션 순서 일정
4. **AddEntryView**: 긴 곡 제목에서도 레이아웃 짤림 없음, 적절한 패딩
5. **년도**: "2026년"으로 표시 (천단위 구분자 없음)
6. **감정 칩**: 카테고리 헤더 없이 전체 태그 한 번에 표시, 칩 높이 컴팩트
7. **장소**: MoodSelectionView에 장소 필드 없음 (이미 OK)
8. **날씨**: `.season` 카테고리 제거, 순수 날씨 태그 제거

---

## 주의사항

1. **기존 기능 회귀 금지**: UI 수정이 기존 기능(저장, 검색, 인증 등)에 영향을 주지 않을 것
2. **ViewModel/Service 변경 최소화**: View 레이어 중심 수정. SongCollectionViewModel의 정렬 로직만 수정
3. **TopDesignSystem 의존**: 모든 스타일링은 TopDesignSystem 토큰 경유
4. **FlowLayout 재사용**: `Shared/FlowLayout.swift`가 이미 존재하므로 신규 생성 불필요
5. **import 규칙 준수**: View 파일은 `import SwiftUI` + `import TopDesignSystem`, ViewModel은 `import Foundation` + `import Observation`
