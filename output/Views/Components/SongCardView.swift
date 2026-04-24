import SwiftUI
import PersonalColorDesignSystem

// MARK: - SongCardView

struct SongCardView: View {
    let groupedSong: GroupedSong

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: PSpacing.sm(8)) {
                AlbumArtworkView(urlString: groupedSong.artworkUrl, size: 120, cornerRadius: PRadius.sm(8))
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: PSpacing.xs(4)) {
                    Text(groupedSong.songTitle)
                        .font(.pBodyMedium(15))
                        .foregroundStyle(Color.pTextPrimary)
                        .lineLimit(2)
                        .accessibilityLabel("곡 제목: \(groupedSong.songTitle)")

                    Text(groupedSong.artistName)
                        .font(.pBody(13))
                        .foregroundStyle(Color.pTextSecondary)
                        .lineLimit(1)
                        .accessibilityLabel("아티스트: \(groupedSong.artistName)")

                    HStack(spacing: PSpacing.xs(4)) {
                        Image(systemName: "heart.fill")
                            .font(.pCaption(11))
                            .foregroundStyle(Color.pAccentPrimary)
                        Text("\(groupedSong.memoryCount)개의 기록")
                            .font(.pCaption(11))
                            .foregroundStyle(Color.pTextTertiary)
                    }
                }
                .padding(.horizontal, PSpacing.sm(8))
                .padding(.bottom, PSpacing.sm(8))
            }
        }
        .pShadowLow()
        .pressable(scale: 0.97, haptic: true)
    }
}
