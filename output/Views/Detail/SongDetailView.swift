import SwiftUI
import PersonalColorDesignSystem

// MARK: - SongDetailView

struct SongDetailView: View {
    let groupedSong: GroupedSong

    @State private var viewModel = SongDetailViewModel()
    @State private var selectedMemory: SongMemory?
    @State private var showAddEntry = false
    @State private var showRecordFlow = false
    @State private var memoryToDelete: SongMemory?
    @State private var showDeleteConfirm = false
    @Environment(PToastManager.self) private var toastManager

    var body: some View {
        ZStack {
            // 배경: 앨범 아트워크 블러
            backgroundView

            ScrollView {
                VStack(spacing: PSpacing.xl) {
                    // 헤더: 앨범 커버 + 곡 정보
                    songHeader

                    // "새 시기 추가" 버튼
                    addNewPeriodButton
                        .padding(.horizontal, PSpacing.lg)

                    // 타임라인
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(Color.pAccentPrimary)
                            .padding(.top, PSpacing.xxxl)
                    } else if viewModel.memories.isEmpty {
                        EmptyStateView(
                            title: "아직 기록이 없어요",
                            description: "이 곡을 들었던 시기를\n기록해보세요"
                        )
                    } else {
                        timelineSection
                    }
                }
                .padding(.bottom, PSpacing.huge)
            }
        }
        .navigationTitle(groupedSong.songTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadMemories(
                appleMusicId: groupedSong.appleMusicId,
                songTitle: groupedSong.songTitle,
                artistName: groupedSong.artistName
            )
        }
        .sheet(isPresented: $showAddEntry) {
            if let memory = selectedMemory {
                AddEntryView(
                    memory: memory,
                    onDismiss: {
                        showAddEntry = false
                        Task {
                            await viewModel.loadMemories(
                                appleMusicId: groupedSong.appleMusicId,
                                songTitle: groupedSong.songTitle,
                                artistName: groupedSong.artistName
                            )
                        }
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showRecordFlow) {
            RecordFlowView(
                preselectedSong: preselectedSong,
                onDismiss: {
                    showRecordFlow = false
                    Task {
                        await viewModel.loadMemories(
                            appleMusicId: groupedSong.appleMusicId,
                            songTitle: groupedSong.songTitle,
                            artistName: groupedSong.artistName
                        )
                    }
                }
            )
        }
        .actionCheckModal(
            isPresented: $showDeleteConfirm,
            title: "이 기록을 삭제할까요?",
            onConfirm: {
                if let memory = memoryToDelete {
                    Task { await viewModel.deleteMemory(id: memory.id) }
                }
                memoryToDelete = nil
            }
        )
        .onChange(of: viewModel.errorMessage) { _, message in
            if let message {
                toastManager.show(message, type: .error)
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var backgroundView: some View {
        ZStack {
            PGradientBackground()
            if let urlString = groupedSong.artworkUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: 40)
                            .opacity(0.3)
                            .ignoresSafeArea()
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    private var songHeader: some View {
        VStack(spacing: PSpacing.lg) {
            AlbumArtworkView(urlString: groupedSong.artworkUrl, size: 160, cornerRadius: PRadius.lg)
                .pShadowHigh()

            VStack(spacing: PSpacing.xs) {
                Text(groupedSong.songTitle)
                    .font(.pTitle(20))
                    .foregroundStyle(Color.pTextPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel("곡 제목: \(groupedSong.songTitle)")

                Text(groupedSong.artistName)
                    .font(.pBody(15))
                    .foregroundStyle(Color.pTextSecondary)
                    .accessibilityLabel("아티스트: \(groupedSong.artistName)")
            }
        }
        .padding(.top, PSpacing.lg)
    }

    private var addNewPeriodButton: some View {
        CommonButton(
            title: "이 곡의 새 시기 추가",
            style: .outlined,
            action: { showRecordFlow = true }
        )
        .accessibilityLabel("이 곡의 새 시기 기록 추가")
    }

    private var timelineSection: some View {
        LazyVStack(spacing: PSpacing.md) {
            ForEach(viewModel.memories) { memory in
                TimelineEntryView(memory: memory, onAddEntry: {
                    selectedMemory = memory
                    showAddEntry = true
                })
                .padding(.horizontal, PSpacing.lg)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        memoryToDelete = memory
                        showDeleteConfirm = true
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                    .accessibilityLabel("이 시기 기록 삭제")
                }
            }
        }
    }

    private var preselectedSong: SearchedSong? {
        guard let musicId = groupedSong.appleMusicId else { return nil }
        return SearchedSong(
            id: musicId,
            title: groupedSong.songTitle,
            artistName: groupedSong.artistName,
            artworkURL: groupedSong.artworkUrl.flatMap { URL(string: $0) },
            albumTitle: nil
        )
    }
}
