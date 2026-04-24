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
            VStack(spacing: PSpacing.sm) {
                PTextField(placeholder: "곡 제목 또는 아티스트 검색", text: $searchViewModel.query)
                    .padding(.horizontal, PSpacing.lg)
                    .accessibilityLabel("곡 검색 입력")

                if searchViewModel.isMusicKitDenied {
                    Button("직접 입력하기") {
                        viewModel.isManualInput = true
                    }
                    .font(.pBody(14))
                    .foregroundStyle(Color.pAccentPrimary)
                    .accessibilityLabel("곡을 직접 입력하는 모드로 전환")
                }
            }
            .padding(.vertical, PSpacing.md)

            PDivider()

            // 검색 결과
            searchResultList
        }
    }

    @ViewBuilder
    private var searchResultList: some View {
        if searchViewModel.isSearching {
            VStack(spacing: PSpacing.sm) {
                ForEach(0..<5, id: \.self) { _ in
                    PSkeletonLoader(preset: .listRow)
                        .padding(.horizontal, PSpacing.lg)
                }
            }
            .padding(.top, PSpacing.md)
        } else if !searchViewModel.query.isEmpty && searchViewModel.results.isEmpty {
            VStack(spacing: PSpacing.md) {
                Spacer()
                Text("검색 결과가 없어요")
                    .font(.pBody(15))
                    .foregroundStyle(.secondary)

                Button("직접 입력하기") {
                    viewModel.isManualInput = true
                }
                .font(.pBodyMedium(15))
                .foregroundStyle(Color.pAccentPrimary)
                .accessibilityLabel("곡을 직접 입력하는 모드로 전환")
                Spacer()
            }
        } else if searchViewModel.results.isEmpty {
            VStack {
                Spacer()
                Text("검색어를 입력하면\n곡을 찾아드려요")
                    .font(.pBody(15))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .multilineTextAlignment(.center)
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(searchViewModel.results) { song in
                        songResultRow(song)
                        PDivider()
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
            HStack(spacing: PSpacing.md) {
                AlbumArtworkView(urlString: song.artworkURL?.absoluteString, size: 48, cornerRadius: PRadius.sm)

                VStack(alignment: .leading, spacing: PSpacing.xs) {
                    Text(song.title)
                        .font(.pBodyMedium(15))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(song.artistName)
                        .font(.pBody(13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if viewModel.selectedSong?.id == song.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.pAccentPrimary)
                        .accessibilityLabel("선택됨")
                }
            }
            .padding(.horizontal, PSpacing.lg)
            .padding(.vertical, PSpacing.md)
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(song.title), \(song.artistName)")
    }
}
