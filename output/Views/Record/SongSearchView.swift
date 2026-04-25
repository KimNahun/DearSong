import SwiftUI
import TopDesignSystem

// MARK: - SongSearchView

struct SongSearchView: View {
    var viewModel: RecordFlowViewModel
    @State private var searchViewModel = SongSearchViewModel()
    @Environment(\.designPalette) private var palette

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
            // 검색 필드 — PTextField 대체: HStack + TextField + borderedContainer
            VStack(spacing: DesignSpacing.xs) {
                HStack(spacing: DesignSpacing.xs) {
                    Image(systemName: "magnifyingglass")
                        .font(.ssBody)
                        .foregroundStyle(palette.textSecondary)
                    TextField(String(localized: "placeholder.search.song"), text: $searchViewModel.query)
                        .font(.ssBody)
                        .foregroundStyle(palette.textPrimary)
                        .autocorrectionDisabled()
                }
                .borderedContainer(padding: DesignSpacing.sm)
                .padding(.horizontal, DesignSpacing.lg)
                .accessibilityLabel(Text("placeholder.search.song"))

                if searchViewModel.isMusicKitDenied {
                    Button {
                        viewModel.isManualInput = true
                    } label: {
                        Text("action.manual_input")
                            .font(.ssFootnote.weight(.medium))
                            .foregroundStyle(palette.primaryAction)
                    }
                    .frame(minHeight: 44)
                    .accessibilityLabel(Text("action.manual_input"))
                }
            }
            .padding(.vertical, DesignSpacing.xs)

            // 구분선 (PDivider 대체)
            Divider()
                .overlay(palette.border)
                .padding(.horizontal, DesignSpacing.lg)

            // 검색 결과
            searchResultList
        }
    }

    @ViewBuilder
    private var searchResultList: some View {
        if searchViewModel.isSearching {
            VStack(spacing: DesignSpacing.xs) {
                ForEach(0..<5, id: \.self) { _ in
                    ShimmerPlaceholder(height: 64)
                        .padding(.horizontal, DesignSpacing.lg)
                }
            }
            .padding(.top, DesignSpacing.md)
        } else if !searchViewModel.query.isEmpty && searchViewModel.results.isEmpty {
            VStack(spacing: DesignSpacing.md) {
                Spacer()
                Image(systemName: "music.note.list")
                    .font(.ssLargeTitle)
                    .foregroundStyle(palette.textSecondary.opacity(0.7))
                Text("empty.search.title")
                    .font(.ssBody)
                    .foregroundStyle(palette.textSecondary)

                Button {
                    viewModel.isManualInput = true
                } label: {
                    Text("action.manual_input")
                        .font(.ssBody.weight(.medium))
                        .foregroundStyle(palette.primaryAction)
                        .padding(.horizontal, DesignSpacing.lg)
                        .padding(.vertical, DesignSpacing.xs)
                        .background(palette.primaryAction.opacity(0.12))
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
                    .font(.ssTitle1)
                    .foregroundStyle(palette.textSecondary.opacity(0.7))
                    .padding(.bottom, DesignSpacing.xs)
                Text("empty.search.placeholder")
                    .font(.ssBody)
                    .foregroundStyle(palette.textSecondary.opacity(0.7))
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
            UISelectionFeedbackGenerator().selectionChanged()
        } label: {
            HStack(spacing: DesignSpacing.sm) {
                AlbumArtworkView(urlString: song.artworkURL?.absoluteString, size: 52, cornerRadius: DesignCornerRadius.sm)

                VStack(alignment: .leading, spacing: DesignSpacing.xxs) {
                    Text(song.title)
                        .font(.ssFootnote.weight(.medium))
                        .foregroundStyle(palette.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(song.artistName)
                        .font(.ssFootnote)
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if let album = song.albumTitle {
                        Text(album)
                            .font(.ssCaption)
                            .foregroundStyle(palette.textSecondary.opacity(0.7))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }

                Spacer()

                if viewModel.selectedSong?.id == song.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(palette.primaryAction)
                        .font(.ssTitle2)
                        .accessibilityLabel(Text("action.selected"))
                }
            }
            .padding(.horizontal, DesignSpacing.lg)
            .padding(.vertical, DesignSpacing.xs)
            .frame(minHeight: 64)
            .background(
                viewModel.selectedSong?.id == song.id
                    ? palette.primaryAction.opacity(0.12)
                    : Color.clear
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(song.title), \(song.artistName)")
    }
}
