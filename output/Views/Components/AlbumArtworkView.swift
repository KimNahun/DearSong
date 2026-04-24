import SwiftUI

// MARK: - AlbumArtworkView

struct AlbumArtworkView: View {
    let urlString: String?
    let size: CGFloat?
    var cornerRadius: CGFloat = AppTheme.cornerRadiusSm

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
            AppTheme.chipBackground
            Image(systemName: "music.note")
                .font(.system(size: (size ?? 48) * 0.35))
                .foregroundStyle(AppTheme.textTertiary)
        }
    }
}
