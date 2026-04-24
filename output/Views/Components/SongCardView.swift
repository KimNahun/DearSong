import SwiftUI

// MARK: - SongCardView

struct SongCardView: View {
    let groupedSong: GroupedSong

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AlbumArtworkView(urlString: groupedSong.artworkUrl, size: nil, cornerRadius: AppTheme.cornerRadiusSm)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSm))

            VStack(alignment: .leading, spacing: 4) {
                Text(groupedSong.songTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)

                Text(groupedSong.artistName)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.accent)
                    Text("\(groupedSong.memoryCount)개의 기록")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 12)
        }
        .cardStyle(cornerRadius: AppTheme.cornerRadius)
    }
}
