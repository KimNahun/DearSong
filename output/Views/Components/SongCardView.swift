import SwiftUI
import PersonalColorDesignSystem

// MARK: - SongCardView

struct SongCardView: View {
    let groupedSong: GroupedSong

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: PSpacing.xs) {
                AlbumArtworkView(urlString: groupedSong.artworkUrl, size: nil, cornerRadius: AppTheme.cornerRadiusSm)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSm))

                VStack(alignment: .leading, spacing: PSpacing.xxs) {
                    Text(groupedSong.songTitle)
                        .font(Font.pBodyMedium(14))
                        .foregroundStyle(Color.pTextPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)

                    Text(groupedSong.artistName)
                        .font(Font.pCaption(12))
                        .foregroundStyle(Color.pTextSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    HStack(spacing: PSpacing.xxs) {
                        Image(systemName: "heart.fill")
                            .font(Font.pCaption(10))
                            .foregroundStyle(Color.pAccentPrimary)
                        Text("songcard.records.count \(groupedSong.memoryCount)")
                            .font(Font.pCaption(11))
                            .foregroundStyle(Color.pTextSecondary.opacity(0.7))
                    }
                    .padding(.top, PSpacing.xxs)
                }
                .padding(.horizontal, PSpacing.xs)
                .padding(.bottom, PSpacing.xs)
            }
        }
        .pressable(scale: 0.97, haptic: .light)
    }
}
