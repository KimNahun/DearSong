import SwiftUI
import PersonalColorDesignSystem

// MARK: - SongSearchView

struct SongSearchView: View {
    var viewModel: RecordFlowViewModel
    @State private var searchViewModel = SongSearchViewModel()

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isManualInput {
                ManualSongInputView(viewModel: viewModel)
            } else {
                searchContent
            }
        }
        .task {
            await searchViewModel.requestAuthorization()
            if searchViewModel.isMusicKitDenied {
                viewModel.isManualInput = true
            }
        }
        .onChange(of: searchViewModel.query) { _, _ in
            searchViewModel.onQueryChanged()
        }
    }

    private var searchContent: some View {
        VStack(spacing: 0) {
            // 검색 필드
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppTheme.textTertiary)
                    TextField("곡 제목 또는 아티스트 검색", text: $searchViewModel.query)
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.textPrimary)
                        .accessibilityLabel("곡 검색 입력")
                }
                .padding(14)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSm))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSm)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
                .padding(.horizontal, 20)

                if searchViewModel.isMusicKitDenied {
                    Button("직접 입력하기") {
                        viewModel.isManualInput = true
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.accent)
                    .accessibilityLabel("곡을 직접 입력하는 모드로 전환")
                }
            }
            .padding(.vertical, 12)

            Divider()
                .foregroundStyle(AppTheme.divider)

            // 검색 결과
            searchResultList
        }
    }

    @ViewBuilder
    private var searchResultList: some View {
        if searchViewModel.isSearching {
            VStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { _ in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXs)
                            .fill(AppTheme.chipBackground)
                            .frame(width: 48, height: 48)
                        VStack(alignment: .leading, spacing: 6) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.chipBackground)
                                .frame(height: 14)
                                .frame(maxWidth: 180)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.chipBackground)
                                .frame(height: 12)
                                .frame(maxWidth: 120)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 16)
        } else if !searchViewModel.query.isEmpty && searchViewModel.results.isEmpty {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "music.note.list")
                    .font(.system(size: 40))
                    .foregroundStyle(AppTheme.textTertiary)
                Text("검색 결과가 없어요")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.textSecondary)

                Button("직접 입력하기") {
                    viewModel.isManualInput = true
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(AppTheme.accentSoft)
                .clipShape(Capsule())
                .accessibilityLabel("곡을 직접 입력하는 모드로 전환")
                Spacer()
            }
        } else if searchViewModel.results.isEmpty {
            VStack {
                Spacer()
                Image(systemName: "music.magnifyingglass")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.textTertiary)
                    .padding(.bottom, 8)
                Text("검색어를 입력하면\n곡을 찾아드려요")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.textTertiary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(searchViewModel.results) { song in
                        songResultRow(song)
                    }
                }
            }
        }
    }

    private func songResultRow(_ song: SearchedSong) -> some View {
        Button {
            viewModel.selectedSong = song
            viewModel.isManualInput = false
            viewModel.goToNextStep()
            HapticManager.selection()
        } label: {
            HStack(spacing: 14) {
                AlbumArtworkView(urlString: song.artworkURL?.absoluteString, size: 52, cornerRadius: AppTheme.cornerRadiusXs)

                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                        .lineLimit(1)

                    Text(song.artistName)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)

                    if let album = song.albumTitle {
                        Text(album)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.textTertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if viewModel.selectedSong?.id == song.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.accent)
                        .font(.system(size: 20))
                        .accessibilityLabel("선택됨")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                viewModel.selectedSong?.id == song.id
                    ? AppTheme.accentSoft
                    : Color.clear
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(song.title), \(song.artistName)")
    }
}
