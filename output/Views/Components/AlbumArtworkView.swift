import SwiftUI
import TopDesignSystem

// MARK: - AlbumArtworkView

struct AlbumArtworkView: View {
    let urlString: String?
    let size: CGFloat?
    var cornerRadius: CGFloat = DesignCornerRadius.sm

    @Environment(\.designPalette) private var palette

    var body: some View {
        Group {
            if let urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        artworkPlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        artworkPlaceholder
                    @unknown default:
                        artworkPlaceholder
                    }
                }
            } else {
                artworkPlaceholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var artworkPlaceholder: some View {
        ZStack {
            palette.surface
            Image(systemName: "music.note")
                .font(.system(size: (size ?? 48) * 0.35))
                .foregroundStyle(palette.textSecondary.opacity(0.7))
        }
    }
}
