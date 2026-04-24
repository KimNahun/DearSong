import Testing
import Foundation
@testable import DearSong

@Suite("MoodTag")
struct MoodTagTests {

    @Test("모든 카테고리에 태그가 있음")
    func allCategoriesHaveTags() {
        for category in MoodCategory.allCases {
            #expect(!category.tags.isEmpty, "카테고리 \(category.rawValue)에 태그가 없음")
        }
    }

    @Test("전체 태그 목록이 비어있지 않음")
    func allTagsNotEmpty() {
        #expect(!MoodTag.allTags.isEmpty)
    }

    @Test("태그 ID는 유일함")
    func tagIdsAreUnique() {
        let ids = MoodTag.allTags.map { $0.id }
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count)
    }

    @Test("카테고리 displayName은 비어있지 않음")
    func categoryDisplayNamesNotEmpty() {
        for category in MoodCategory.allCases {
            #expect(!category.displayName.isEmpty)
        }
    }
}

@Suite("DateFormatters")
struct DateFormattersTests {

    @Test("년도 → Date → 년도 변환 일치")
    func yearToDateToYearRoundTrip() {
        let year = 2022
        let date = DateFormatters.date(fromYear: year)
        let backToYear = DateFormatters.year(from: date)
        #expect(backToYear == year)
    }

    @Test("현재 년도가 2025 이상")
    func currentYearIsReasonable() {
        #expect(DateFormatters.currentYear >= 2025)
    }

    @Test("선택 가능 년도 목록이 2000부터 시작")
    func selectableYearsStartFrom2000() {
        let years = DateFormatters.selectableYears
        #expect(years.contains(2000))
        #expect(years.contains(DateFormatters.currentYear))
    }
}
