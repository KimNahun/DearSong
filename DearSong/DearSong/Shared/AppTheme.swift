import SwiftUI

// MARK: - AppTheme

nonisolated enum AppTheme {
    static let background = Color(red: 0.98, green: 0.96, blue: 0.93)
    static let cardBackground = Color.white
}

// MARK: - AppBackground

nonisolated struct AppBackground: View {
    var body: some View {
        AppTheme.background.ignoresSafeArea()
    }
}

// MARK: - View+cardStyle

extension View {
    func cardStyle(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
