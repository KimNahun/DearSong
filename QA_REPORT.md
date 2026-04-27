RESULT: conditional_pass
SCORE: 7.8
DATE: 2026-04-27
ROUND: 4 (사용자 피드백 8항목)
BLOCKERS: 5

---

# QA Report — Round 4 (사용자 피드백 8항목 검수)

## 1단계: 파일 구조 분석

output/ 폴더에 34개 Swift 파일이 존재하며, SPEC.md의 파일 구조와 완전 일치.

| 레이어 | 파일 수 | 주요 파일 |
|--------|---------|----------|
| App | 1 | DearSongApp.swift |
| Views | 13 | SignInView, SongCollectionView, SongDetailView, RecordFlowView, SongSearchView, MoodSelectionView, EntryWriteView, ManualSongInputView, AddEntryView, SongCardView, MoodChipGridView, TimelineEntryView, AlbumArtworkView |
| ViewModels | 6 | AuthViewModel, SongCollectionViewModel, SongDetailViewModel, RecordFlowViewModel, SongSearchViewModel, AddEntryViewModel |
| Models | 3 | SongMemory, MoodTag, SearchedSong |
| Services | 4 | AuthService, SongMemoryService, MusicSearchService, SupabaseClientProvider |
| Shared | 2 | AppError, DateFormatters |
| Tests | 5 | Mocks, MoodTagTests, AuthServiceTests, SongMemoryServiceTests, RecordFlowViewModelTests |

---

## 2단계: 사용자 요청 8항목 기능 검증

### 항목 1: 바깥 탭 시 키보드 닫기 (글로벌) — [FAIL]

**증거**: output/ 전체에서 keyboard dismiss 관련 글로벌 처리가 없음.
- `EntryWriteView.swift`와 `AddEntryView.swift`에 `.scrollDismissesKeyboard(.interactively)`가 있지만, 이는 ScrollView 내 드래그 시에만 동작.
- 바깥 영역(배경, 비입력 영역) 탭으로 키보드를 닫는 글로벌 제스처가 없음.
- `SongSearchView.swift`의 검색 필드, `ManualSongInputView.swift`의 입력 필드에도 키보드 닫기 처리 없음.
- `DearSongApp.swift` 또는 공통 ViewModifier에도 `UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), ...)` 같은 글로벌 키보드 닫기 처리 없음.
- `onTapGesture`로 키보드를 닫는 로직도 어디에도 없음.

**결론**: 미구현.

### 항목 2: count 값을 사용자 친화적 텍스트로 (예: "3개 선택됨") — [PASS]

**증거**:
- `MoodSelectionView.swift` line 33: `Text("mood.selected.count \(viewModel.selectedMoodTags.count)")` — String Catalog 키 사용 ("N개 선택됨").
- `SongCardView.swift` line 35: `Text("songcard.records.count \(groupedSong.memoryCount)")` — String Catalog 키 사용 ("N개의 기록").

**결론**: 구현됨.

### 항목 3: 메인 컬렉션 새로고침 시 정렬 고정 — [PASS]

**증거**:
- `SongCollectionViewModel.swift` line 40-42: `refresh()`는 `loadMemories()`를 호출.
- `groupMemories()` (line 46-66)에서 매번 `sorted { lDate > rDate }` (listened_at 내림차순) 적���.
- 서버 쿼리도 `SongMemoryService.swift` line 71: `.order("listened_at", ascending: false)`.

**결론**: 구현됨.

### 항목 4: AddEntryView 가로 레이아웃 짤림 수정 — [PASS]

**증거**:
- `AddEntryView.swift`: ScrollView (line 43) + `.scrollDismissesKeyboard(.interactively)` (line 54) + `.safeAreaInset(edge: .bottom)` (line 66-68).
- `.padding(.horizontal, DesignSpacing.lg)` 좌우 여백 확보.
- `.frame(maxWidth: .infinity, alignment: .leading)` 적용.

**결론**: 구현됨.

### 항목 5: 년도 "2,026" -> "2026" 포맷 수정 — [FAIL]

**증거**:
- `TimelineEntryView.swift` line 21: `Text("timeline.year \(listenedYear)")` — `listenedYear`는 `Int`. Swift의 `Text(LocalizedStringKey)` 보간에서 Int는 NumberFormatter를 적용하여 한국어 로케일에서 "2,026"으로 표시됨.
- `AddEntryView.swift` line 109: `Text("\(listenedYear)\(String(localized: "timeline.year_suffix")) · \(memory.artistName)")` — 동일 문제.
- `EntryWriteView.swift` line 201: `Text(String(year)).tag(year)` — 이것은 `String(year)`로 명시 변환되어 정상.
- `DateFormatters.yearString(from:)`: `date.formatted(.dateTime.year())` — 로케일에 따라 쉼표 포함 가능.

**결론**: 미수정. TimelineEntryView와 AddEntryView에서 Int→LocalizedStringKey 보간으로 "2,026" 표시 위험.

### 항목 6: 감정 칩 섹션 제거 + 높이 축소 — [FAIL]

**증거**:
- `TimelineEntryView.swift` line 57-72: 감정 태그 LazyVGrid 섹션이 그대로 존재.
```swift
if !memory.moodTags.isEmpty {
    LazyVGrid(...) {
        ForEach(memory.moodTags, id: \.self) { tag in ... }
    }
}
```
- 사용자 요청 "감정 칩 섹션 제거"가 이루어지지 않음.

**���론**: 미구현.

### 항목 7: 감정 선택 단계에서 장소 필드 제거 — [PASS]

**증거**:
- `MoodSelectionView.swift`: 전체 코드에 location/장소 관련 입력 필드 없음.
- 장소 입력은 `EntryWriteView.swift`의 Step 3에서만 존재.

**결론**: 구현됨.

### 항목 8: 날씨 관련 UI/태그 제거 — [FAIL]

**증거**:
- `MoodTag.swift` line 13: `case season` 카테고리 존재.
- line 25: `case .season: return "계절/날씨"`.
- line 46-47: `case .season: return ["비 오는 날", "눈 오는 날", "바람 부는 날", "여름밤", "가을 햇살", "봄바람"]` — 날씨 관련 태그 6개.
- `MoodChipGridView.swift` line 13: `ForEach(MoodCategory.allCases, ...)` — allCases에 `.season` 포함.

**결론**: 미구현.

---

### 기능 검증 요약

| # | 항목 | 판정 |
|---|------|------|
| 1 | 바깥 탭 시 키보드 닫기 (글로벌) | **FAIL** |
| 2 | count 값 사용자 친화적 텍스트 | PASS |
| 3 | 메인 컬렉션 새로고침 시 정렬 고정 | PASS |
| 4 | AddEntryView 가로 레이아웃 짤림 수정 | PASS |
| 5 | 년도 "2,026" -> "2026" 포맷 수정 | **FAIL** |
| 6 | 감정 칩 섹션 제거 + 높이 축소 | **FAIL** |
| 7 | 감정 선택 단계에서 장소 필드 제거 | PASS |
| 8 | 날씨 관련 UI/태그 제거 | **FAIL** |

**합격: 4/8, 불합격: 4/8**

---

## 3단계: evaluation_criteria 채점

### 1. Swift 6 동시성: 9/10

- 모든 ViewModel: `@MainActor` + `@Observable` ✓
- 모든 Service: `actor` ✓
- 모든 Model: `struct` + `Sendable` ✓
- `DispatchQueue`/`@Published`/`ObservableObject` 사용 0건 ✓
- Protocol 기반 DI ✓
- 감점: `nonisolated` 불필요 사용 (MoodTag.swift, SongMemory.swift 등) -1

### 2. MVVM 아키텍처 분리: 9/10

- View→ViewModel→Service 단방향 흐름 ✓
- ViewModel에 `import SwiftUI` 없음 ✓
- Service가 ViewModel/View 미참조 ✓
- 감점: `AuthViewModel.swift` line 39에 한국어 리터럴 하드코딩 -0.5
- 감점: 일부 ViewModel 프로퍼티에 `private(set)` 미적용 (RecordFlowViewModel의 `selectedSong`, `entryText` 등이 `var`로 공개) -0.5

### 3. HIG 준수 + 디자인 시스템: 8/10

- TopDesignSystem 토큰 대부분 적용 ✓
- 44pt 터치 영역 대부분 보장 ✓
- .accessibilityLabel 다수 적용 ✓
- 로딩/에러 상태 UI ✓
- 감점: `SongCardView.swift` line 33: `.font(.system(size: 10))` — 하드코딩 폰트 잔존 -0.5
- ���점: `Color.black.opacity(0.3)` 2곳 (EntryWriteView line 42, AddEntryView line 59) -0.5
- 감점: `.shadow(color: .black.opacity(0.15), ...)` (SongDetailView line 141) -0.5
- 감점: 글로벌 키보드 닫기 미구현 -0.5

### 4. API 활용: 10/10

- MusicKit: 카탈로그 검색 + 권한 요청 + 폴백 ✓
- Supabase Auth: signInWithIdToken + session 확인 + signOut ✓
- Supabase Database: CRUD 전체 Service 레이어에서 구현 ✓
- 에러 처리: AppError enum ✓

### 5. 기능성 및 코드 가독성: 5/10

- SPEC R1 7개 기능 유지 ✓
- 접근 제어자 명시 ✓
- 에러 타입 체계 ✓
- 파일 구조 일치 ✓
- **치명적 감점: 사용자 요청 8항목 중 4항목(50%) 미구현 -4**
- 감점: 년도 ���맷 잠재 버그 -0.5
- 감점: AuthViewModel 에러 메시지 한국어 하드코딩 -0.5

---

## 최종 점수 계산

```
가중 점수 = (9 x 0.30) + (9 x 0.25) + (8 x 0.20) + (10 x 0.15) + (5 x 0.10)
         = 2.70 + 2.25 + 1.60 + 1.50 + 0.50
         = 8.55
```

사용자 피드백 라운드에서 요청 반영률 50%는 중대한 미완성이므로 보정 적용: **7.8/10**

---

**전체 판정**: 조건부 합격 (conditional_pass)
**가중 점수**: 7.8 / 10.0

**항목별 점수**:
- Swift 6 동시성: 9/10 — @MainActor/@Observable 일관 적용. nonisolated 경미한 남용.
- MVVM 분리: 9/10 — 레이어 분리 우수. AuthViewModel에 한국어 하드코딩 경미.
- HIG 준수: 8/10 — TopDesignSystem 토큰 적용 양호. `.font(.system(size:10))` 잔존, 글로벌 키보드 닫기 미구현.
- API 활용: 10/10 — MusicKit/Supabase Auth/Database 정상 구현.
- 기능성/가독성: 5/10 — 사용자 요청 8항목 중 4항목(50%) 미구현.

**구체적 개선 지시**:

1. **[BLOCKER] `App/DearSongApp.swift`**: 글로벌 키보드 닫기 구현. `rootView`��� 아래 ��드 추가:
   ```swift
   .onTapGesture {
       UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
   }
   ```
   또는 공통 ViewModifier를 만들어 키보드가 표시되는 모든 화면에 적용.

2. **[BLOCKER] `Views/Components/TimelineEntryView.swift` line 21**: `Text("timeline.year \(listenedYear)")` → Int를 String으로 명시 변환하여 NumberFormatter 적용 방지:
   ```swift
   Text("\(String(listenedYear))년")
   ```
   또는 `Text(verbatim: "\(listenedYear)년")` 사용.

3. **[BLOCKER] `Views/Entry/AddEntryView.swift` line 109**: 동일 년도 포맷 문제. `\(listenedYear)` → `\(String(listenedYear))` 로 변경.

4. **[BLOCKER] `Views/Components/TimelineEntryView.swift` line 57-72**: 감정 태그 LazyVGrid 섹션 전체 삭제:
   ```swift
   // 이 블록 전체 제거:
   if !memory.moodTags.isEmpty {
       LazyVGrid(...) { ... }
   }
   ```

5. **[BLOCKER] `Models/MoodTag.swift`**: `case season` 카테고리 및 관련 코드 전부 제거:
   - line 13: `case season` 삭제
   - line 25: `case .season: return "계절/날씨"` 삭제
   - line 46-47: `case .season: return [...]` 삭���

6. **[경미] `Views/Components/SongCardView.swift` line 33**: `.font(.system(size: 10))` → `.font(.ssCaption)` 교체.

7. **[경미] `Views/Record/EntryWriteView.swift` line 42, `Views/Entry/AddEntryView.swift` line 59**: `Color.black.opacity(0.3)` → `palette.textPrimary.opacity(0.3)`.

8. **[경미] `Views/Detail/SongDetailView.swift` line 141**: `.shadow(color: .black.opacity(0.15), ...)` → semantic 토큰 사용.

**방향 판단**: 현재 방향 유지. 아키텍처 우수하며, 누락 항목은 국소적 코드 수��으로 해결 가능.
