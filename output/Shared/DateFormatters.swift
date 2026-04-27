import Foundation

// MARK: - DateFormatters

nonisolated enum DateFormatters: Sendable {
    /// 날짜 → 년도 문자열 (예: "2016")
    nonisolated static func yearString(from date: Date) -> String {
        date.formatted(.dateTime.year())
    }

    /// 년도 Int → Date (1월 1일 기준)
    nonisolated static func date(fromYear year: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = 1
        components.day = 1
        return Calendar.current.date(from: components) ?? Date()
    }

    /// Date → 년도 Int
    nonisolated static func year(from date: Date) -> Int {
        Calendar.current.component(.year, from: date)
    }

    /// 현재 년도
    static var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    /// 선택 가능한 년도 목록 (2000 ~ 현재)
    static var selectableYears: [Int] {
        (2000...currentYear).reversed().map { $0 }
    }

    /// 날짜 → 중간 형식 문자열 (예: "2026년 4월 24일")
    nonisolated static func mediumDateString(from date: Date) -> String {
        date.formatted(.dateTime.year().month().day().locale(Locale(identifier: "ko_KR")))
    }

    /// 년도 Int → 표시 문자열 (예: 2026 → "2026년")
    /// Int를 직접 interpolation 하면 NumberFormatter가 "2,026년"으로 표시하는 버그를 방지한다.
    nonisolated static func yearDisplayString(_ year: Int) -> String {
        "\(year)년"
    }
}
