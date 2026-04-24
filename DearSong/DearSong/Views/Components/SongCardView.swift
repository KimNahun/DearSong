import SwiftUI
import PersonalColorDesignSystem

// MARK: - SongCardView

struct SongCardView: View {
    let groupedSong: GroupedSong

    var body: some View {
        VStack(alignment: .leading, spacing: PSpacing.sm) {
            AlbumArtworkView(urlString: groupedSong.artworkUrl, size: 120, cornerRadius: PRadius.sm)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: PSpacing.xs) {
                Text(groupedSong.songTitle)
                    .font(.pBodyMedium(15))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .accessibilityLabel("곡 제목: \(groupedSong.songTitle)")

                Text(groupedSong.artistName)
                    .font(.pBody(13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .accessibilityLabel("아티스트: \(groupedSong.artistName)")

                HStack(spacing: PSpacing.xs) {
                    Image(systemName: "heart.fill")
                        .font(.pCaption(11))
                        .foregroundStyle(Color.pAccentPrimary)
                    Text("\(groupedSong.memoryCount)개의 기록")
                        .font(.pCaption(11))
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            }
            .padding(.horizontal, PSpacing.sm)
            .padding(.bottom, PSpacing.sm)
        }
        .cardStyle()
        .pressable(scale: 0.97)
    }
}
