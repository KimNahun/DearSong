import SwiftUI
import PersonalColorDesignSystem

// MARK: - AlbumArtworkView

struct AlbumArtworkView: View {
    let urlString: String?
    let size: CGFloat
    var cornerRadius: CGFloat = PRadius.md

    var body: some View {
        Group {
            if let urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        artworkPlaceholder
                            .shimmer(isActive: true)
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
            Color.pGlassFill
            Image(systemName: "music.note")
                .font(.pBody(size * 0.35))
                .foregroundStyle(Color.pTextTertiary)
        }
    }
}
