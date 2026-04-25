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
            VStack(spacing: PSpacing.xs) {
                PTextField(
                    placeholder: String(localized: "placeholder.search.song"),
                    text: $searchViewModel.query,
                    leadingIcon: "magnifyingglass"
                )
                .padding(.horizontal, PSpacing.lg)
                .accessibilityLabel(Text("placeholder.search.song"))

                if searchViewModel.isMusicKitDenied {
                    Button {
                        viewModel.isManualInput = true
                    } label: {
                        Text("action.manual_input")
                            .font(Font.pBodyMedium(14))
                            .foregroundStyle(Color.pAccentPrimary)
                    }
                    .frame(minHeight: 44)
                    .accessibilityLabel(Text("action.manual_input"))
                }
            }
            .padding(.vertical, PSpacing.xs)

            PDivider()
                .padding(.horizontal, PSpacing.lg)

            // 검색 결과
            searchResultList
        }
    }

    @ViewBuilder
    private var searchResultList: some View {
        if searchViewModel.isSearching {
            VStack(spacing: PSpacing.xs) {
                ForEach(0..<5, id: \.self) { _ in
                    PSkeletonLoader(preset: .listRow)
                        .frame(minHeight: 64)
                        .padding(.horizontal, PSpacing.lg)
                }
            }
            .padding(.top, PSpacing.md)
        } else if !searchViewModel.query.isEmpty && searchViewModel.results.isEmpty {
            VStack(spacing: PSpacing.md) {
                Spacer()
                Image(systemName: "music.note.list")
                    .font(Font.pDisplay(40))
                    .foregroundStyle(Color.pTextSecondary.opacity(0.7))
                Text("empty.search.title")
                    .font(Font.pBody(15))
                    .foregroundStyle(Color.pTextSecondary)

                Button {
                    viewModel.isManualInput = true
                } label: {
                    Text("action.manual_input")
                        .font(Font.pBodyMedium(15))
                        .foregroundStyle(Color.pAccentPrimary)
                        .padding(.horizontal, PSpacing.lg)
                        .padding(.vertical, PSpacing.xs)
                        .background(Color.pAccentPrimary.opacity(0.12))
                        .clipShape(Capsule())
                }
                .frame(minHeight: 44)
                .accessibilityLabel(Text("action.manual_input"))
                Spacer()
            }
        } else if searchViewModel.results.isEmpty {
            VStack {
                Spacer()
                Image(systemName: "music.magnifyingglass")
                    .font(Font.pDisplay(36))
                    .foregroundStyle(Color.pTextSecondary.opacity(0.7))
                    .padding(.bottom, PSpacing.xs)
                Text("empty.search.placeholder")
                    .font(Font.pBody(15))
                    .foregroundStyle(Color.pTextSecondary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
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
            HStack(spacing: PSpacing.sm) {
                AlbumArtworkView(urlString: song.artworkURL?.absoluteString, size: 52, cornerRadius: AppTheme.cornerRadiusXs)

                VStack(alignment: .leading, spacing: PSpacing.xxs) {
                    Text(song.title)
                        .font(Font.pBodyMedium(15))
                        .foregroundStyle(Color.pTextPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(song.artistName)
                        .font(Font.pBody(13))
                        .foregroundStyle(Color.pTextSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if let album = song.albumTitle {
                        Text(album)
                            .font(Font.pCaption(12))
                            .foregroundStyle(Color.pTextSecondary.opacity(0.7))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }

                Spacer()

                if viewModel.selectedSong?.id == song.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.pAccentPrimary)
                        .font(Font.pTitle(20))
                        .accessibilityLabel(Text("action.selected"))
                }
            }
            .padding(.horizontal, PSpacing.lg)
            .padding(.vertical, PSpacing.xs)
            .frame(minHeight: 64)
            .background(
                viewModel.selectedSong?.id == song.id
                    ? Color.pAccentPrimary.opacity(0.12)
                    : Color.clear
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(song.title), \(song.artistName)")
    }
}
