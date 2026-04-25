import SwiftUI
import TopDesignSystem

// MARK: - SongCardView

struct SongCardView: View {
    let groupedSong: GroupedSong
    @Environment(\.designPalette) private var palette

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: DesignSpacing.xs) {
                AlbumArtworkView(urlString: groupedSong.artworkUrl, size: nil, cornerRadius: DesignCornerRadius.sm)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: DesignCornerRadius.sm))

                VStack(alignment: .leading, spacing: DesignSpacing.xxs) {
                    Text(groupedSong.songTitle)
                        .font(.ssFootnote.weight(.medium))
                        .foregroundStyle(palette.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)

                    Text(groupedSong.artistName)
                        .font(.ssCaption)
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    HStack(spacing: DesignSpacing.xxs) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(palette.primaryAction)
                        Text("songcard.records.count \(groupedSong.memoryCount)")
                            .font(.ssCaption)
                            .foregroundStyle(palette.textSecondary.opacity(0.7))
                    }
                    .padding(.top, DesignSpacing.xxs)
                }
                .padding(.horizontal, DesignSpacing.xs)
                .padding(.bottom, DesignSpacing.xs)
            }
        }
        .buttonStyle(.pressScale)
    }
}
