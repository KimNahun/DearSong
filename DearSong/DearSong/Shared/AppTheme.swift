import SwiftUI

// MARK: - AppTheme

nonisolated enum AppTheme {
    // 따뜻한 크림색 베이스 (노트 종이 느낌)
    static let background = Color(red: 0.97, green: 0.95, blue: 0.91)
    static let cardBackground = Color(red: 0.99, green: 0.97, blue: 0.94)

    // 노트 줄 색상
    static let ruleLine = Color(red: 0.85, green: 0.82, blue: 0.78).opacity(0.4)
    static let marginLine = Color(red: 0.88, green: 0.72, blue: 0.68).opacity(0.25)
}

// MARK: - NotebookTexture

/// 노트 종이 질감을 표현하는 배경 뷰
nonisolated struct NotebookTexture: View {
    var showRuledLines: Bool = true
    var lineSpacing: CGFloat = 28

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 종이 질감: 미세한 노이즈 그라데이션
                LinearGradient(
                    colors: [
                        Color(red: 0.97, green: 0.95, blue: 0.91),
                        Color(red: 0.96, green: 0.93, blue: 0.89),
                        Color(red: 0.97, green: 0.94, blue: 0.90)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // 미세한 종이 섬유 느낌 (아주 연한 점 패턴)
                Canvas { context, size in
                    // 수평 줄선 (ruled lines)
                    if showRuledLines {
                        let lineCount = Int(size.height / lineSpacing)
                        for i in 1...max(lineCount, 1) {
                            let y = CGFloat(i) * lineSpacing
                            var path = Path()
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: size.width, y: y))
                            context.stroke(
                                path,
                                with: .color(AppTheme.ruleLine),
                                lineWidth: 0.5
                            )
                        }
                    }

                    // 왼쪽 마진 선 (빨간색 세로선)
                    var marginPath = Path()
                    marginPath.move(to: CGPoint(x: 36, y: 0))
                    marginPath.addLine(to: CGPoint(x: 36, y: size.height))
                    context.stroke(
                        marginPath,
                        with: .color(AppTheme.marginLine),
                        lineWidth: 0.8
                    )
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
            // 줄 없는 노트 — 질감만
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

                // 종이 질감 오버레이 — 미세한 가로 섬유 느낌
                Canvas { context, size in
                    for i in stride(from: 0, to: size.height, by: 4) {
                        let index = Int(i)
                        // 결정적 패턴: 줄마다 살짝 다른 불투명도
                        let opacity = 0.015 + 0.01 * sin(Double(index) * 0.7)
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: i))
                        path.addLine(to: CGPoint(x: size.width, y: i))
                        context.stroke(
                            path,
                            with: .color(Color.brown.opacity(opacity)),
                            lineWidth: 0.5
                        )
                    }
                }
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - View+cardStyle

extension View {
    func cardStyle(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}
