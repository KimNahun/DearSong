import SwiftUI
import PersonalColorDesignSystem

// MARK: - AppTheme (thin shim → PersonalColorDesignSystem 어댑터)
// 모든 색상/폰트/컴포넌트는 PersonalColorDesignSystem 패키지 토큰을 사용한다.
// 패키지에 없는 토큰만 가장 가까운 토큰으로 fallback하며, raw Color(red:) 사용 금지.

enum AppTheme {
    // 색상 토큰 — PersonalColorDesignSystem 위임
    static let background: Color = .pBackgroundTop
    static let cardBackground: Color = .pGlassFill        // shim: GlassCard 컨테이너 사용 권장
    static let accent: Color = .pAccentPrimary
    static let accentSecondary: Color = .pAccentPrimary.opacity(0.7)  // shim: pAccentSecondary 없을 경우 fallback
    static let accentSoft: Color = .pAccentPrimary.opacity(0.12)

    // 텍스트
    static let textPrimary: Color = .pTextPrimary
    static let textSecondary: Color = .pTextSecondary
    static let textTertiary: Color = .pTextSecondary.opacity(0.7)  // shim: pTextTertiary 없을 경우 fallback

    // 구분선 / 보더
    static let divider: Color = .pGlassBorder
    static let border: Color = .pGlassBorder

    // 칩 / 태그
    static let chipBackground: Color = .pGlassFill
    static let chipSelectedBackground: Color = .pAccentPrimary.opacity(0.15)
    static let chipSelectedBorder: Color = .pAccentPrimary.opacity(0.5)

    // 라운드 — PRadius 토큰 사용
    static let cornerRadius: CGFloat = PRadius.lg
    static let cornerRadiusSm: CGFloat = PRadius.md
    static let cornerRadiusXs: CGFloat = PRadius.sm
}


// MARK: - View Extensions

extension View {
    /// GlassCard 컨테이너를 직접 사용할 수 없는 래거시 호출 사이트 지원.
    /// 새 코드에서는 GlassCard { content } 사용 권장.
    func cardStyle(cornerRadius: CGFloat = AppTheme.cornerRadius) -> some View {
        GlassCard {
            self
        }
    }
}

// MARK: - FlowLayout
// PersonalColorDesignSystem에 동등 컴포넌트 없음 → 유지. PSpacing 토큰 기본값 적용.

struct FlowLayout: Layout {
    var spacing: CGFloat = PSpacing.sm  // 8pt

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
