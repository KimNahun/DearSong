import SwiftUI

// MARK: - AppTheme

nonisolated enum AppTheme {
    // 노트 종이 배경
    static let background = Color(red: 0.97, green: 0.95, blue: 0.91)
    static let cardBackground = Color(red: 0.99, green: 0.97, blue: 0.94)

    // 가을 톤 액센트
    static let accent = Color(red: 0.76, green: 0.42, blue: 0.26)        // 테라코타
    static let accentSecondary = Color(red: 0.82, green: 0.65, blue: 0.38) // 앰버/골드
    static let accentSoft = Color(red: 0.76, green: 0.42, blue: 0.26).opacity(0.12)

    // 텍스트
    static let textPrimary = Color(red: 0.15, green: 0.12, blue: 0.10)    // 거의 검정
    static let textSecondary = Color(red: 0.40, green: 0.36, blue: 0.32)  // 진한 브라운 그레이
    static let textTertiary = Color(red: 0.58, green: 0.54, blue: 0.50)   // 중간 브라운 그레이

    // 구분선 / 보더
    static let divider = Color(red: 0.85, green: 0.82, blue: 0.78)
    static let border = Color(red: 0.88, green: 0.85, blue: 0.80)

    // 노트 줄선
    static let ruleLine = Color(red: 0.85, green: 0.82, blue: 0.78).opacity(0.4)
    static let marginLine = Color(red: 0.88, green: 0.72, blue: 0.68).opacity(0.25)

    // 칩 / 태그
    static let chipBackground = Color(red: 0.94, green: 0.91, blue: 0.86)
    static let chipSelectedBackground = Color(red: 0.76, green: 0.42, blue: 0.26).opacity(0.15)
    static let chipSelectedBorder = Color(red: 0.76, green: 0.42, blue: 0.26).opacity(0.5)

    // 라운드
    static let cornerRadius: CGFloat = 16
    static let cornerRadiusSm: CGFloat = 12
    static let cornerRadiusXs: CGFloat = 8
}

// MARK: - NotebookTexture

nonisolated struct NotebookTexture: View {
    var showRuledLines: Bool = true
    var lineSpacing: CGFloat = 28

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.97, green: 0.95, blue: 0.91),
                        Color(red: 0.96, green: 0.93, blue: 0.89),
                        Color(red: 0.97, green: 0.94, blue: 0.90)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Canvas { context, size in
                    if showRuledLines {
                        let lineCount = Int(size.height / lineSpacing)
                        for i in 1...max(lineCount, 1) {
                            let y = CGFloat(i) * lineSpacing
                            var path = Path()
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: size.width, y: y))
                            context.stroke(path, with: .color(AppTheme.ruleLine), lineWidth: 0.5)
                        }
                    }

                    var marginPath = Path()
                    marginPath.move(to: CGPoint(x: 36, y: 0))
                    marginPath.addLine(to: CGPoint(x: 36, y: size.height))
                    context.stroke(marginPath, with: .color(AppTheme.marginLine), lineWidth: 0.8)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - AppBackground

nonisolated struct AppBackground: View {
    var showLines: Bool = false

    var body: some View {
        if showLines {
            NotebookTexture(showRuledLines: true)
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.97, green: 0.95, blue: 0.91),
                        Color(red: 0.96, green: 0.93, blue: 0.89),
                        Color(red: 0.975, green: 0.945, blue: 0.905)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Canvas { context, size in
                    for i in stride(from: 0, to: size.height, by: 4) {
                        let opacity = 0.015 + 0.01 * sin(Double(Int(i)) * 0.7)
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: i))
                        path.addLine(to: CGPoint(x: size.width, y: i))
                        context.stroke(path, with: .color(Color.brown.opacity(opacity)), lineWidth: 0.5)
                    }
                }
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle(cornerRadius: CGFloat = AppTheme.cornerRadius) -> some View {
        self
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    func accentGradient() -> LinearGradient {
        LinearGradient(
            colors: [AppTheme.accent, AppTheme.accentSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - FlowLayout

/// 자연스럽게 줄바꿈되는 컬렉션뷰 스타일 레이아웃
nonisolated struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (positions, CGSize(width: maxWidth, height: y + rowHeight))
    }
}

// MARK: - MoodChipButton

/// 디자인시스템 대신 직접 사용하는 감정 칩
nonisolated struct MoodChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected ? AppTheme.chipSelectedBackground : AppTheme.chipBackground
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? AppTheme.chipSelectedBorder : Color.clear, lineWidth: 1.2)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
