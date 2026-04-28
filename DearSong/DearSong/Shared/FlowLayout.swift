import SwiftUI

// MARK: - FlowLayout
/// iOS 16+ Layout 프로토콜 기반 가변 너비 래핑 레이아웃.
/// 짧은 칩은 좁고, 긴 칩은 넓게 — 텍스트 intrinsic 너비를 그대로 사용한다.
/// 줄이 가득 차면 다음 줄로 자연스럽게 넘어간다.
struct FlowLayout: Layout {

    /// 아이템 간 수평 간격 (pt)
    var horizontalSpacing: CGFloat = 4

    /// 줄 간 수직 간격 (pt)
    var verticalSpacing: CGFloat = 4

    // MARK: - Layout

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        // proposal.width가 nil/∞이면 그대로 ∞를 반환하면 안 된다.
        // 부모(HStack/VStack)가 자식의 ideal width를 묻는 측정 패스에서
        // ∞가 새어 나가면 부모 분배가 깨져 좌우로 콘텐츠가 흘러나간다.
        let containerWidth = proposal.width ?? .infinity
        let rows = computeRows(containerWidth: containerWidth, subviews: subviews)
        let totalHeight = rows.map { $0.maxHeight }.reduce(0, +)
            + CGFloat(max(0, rows.count - 1)) * verticalSpacing

        let resolvedWidth: CGFloat
        if containerWidth.isFinite {
            resolvedWidth = containerWidth
        } else {
            // 측정 패스: 가장 넓은 행의 실제 너비를 반환
            resolvedWidth = rows.map { row -> CGFloat in
                let itemsWidth = row.items.reduce(CGFloat(0)) { $0 + $1.width }
                let spacingWidth = CGFloat(max(0, row.items.count - 1)) * horizontalSpacing
                return itemsWidth + spacingWidth
            }.max() ?? 0
        }

        return CGSize(width: resolvedWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let rows = computeRows(containerWidth: bounds.width, subviews: subviews)

        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for item in row.items {
                let itemSize = item.subview.sizeThatFits(.unspecified)
                item.subview.place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: itemSize.width, height: itemSize.height)
                )
                x += itemSize.width + horizontalSpacing
            }
            y += row.maxHeight + verticalSpacing
        }
    }

    // MARK: - Private

    private struct RowItem {
        let subview: LayoutSubview
        let width: CGFloat
    }

    private struct Row {
        var items: [RowItem] = []
        var maxHeight: CGFloat = 0
    }

    private func computeRows(containerWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()
        var currentRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let neededWidth = currentRowWidth > 0
                ? currentRowWidth + horizontalSpacing + size.width
                : size.width

            if neededWidth > containerWidth && !currentRow.items.isEmpty {
                // 현재 줄 확정, 새 줄 시작
                rows.append(currentRow)
                currentRow = Row()
                currentRowWidth = 0
            }

            currentRow.items.append(RowItem(subview: subview, width: size.width))
            currentRow.maxHeight = max(currentRow.maxHeight, size.height)
            currentRowWidth = currentRowWidth > 0
                ? currentRowWidth + horizontalSpacing + size.width
                : size.width
        }

        if !currentRow.items.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }
}
