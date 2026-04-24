import Foundation

// MARK: - DateFormatters

nonisolated(unsafe) let _yearOnlyFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy"
    formatter.locale = Locale(identifier: "ko_KR")
    return formatter
}()

nonisolated enum DateFormatters: Sendable {
    /// 년도만 표시 (예: "2016")
    static var yearOnly: DateFormatter { _yearOnlyFormatter }

    /// 날짜 → 년도 문자열
    nonisolated static func yearString(from date: Date) -> String {
        _yearOnlyFormatter.string(from: date)
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
}
