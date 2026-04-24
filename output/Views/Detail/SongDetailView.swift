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
                VStack(spacing: PSpacing.xl(20)) {
                    // 헤더: 앨범 커버 + 곡 정보
                    songHeader

                    // "새 시기 추가" 버튼
                    addNewPeriodButton
                        .padding(.horizontal, PSpacing.lg(16))

                    // 타임라인
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(Color.pAccentPrimary)
                            .padding(.top, PSpacing.xxxl(32))
                    } else if viewModel.memories.isEmpty {
                        EmptyStateView(
                            title: "아직 기록이 없어요",
                            message: "이 곡을 들었던 시기를\n기록해보세요",
                            actionTitle: nil,
                            action: nil
                        )
                    } else {
                        timelineSection
                    }
                }
                .padding(.bottom, PSpacing.huge(48))
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
        VStack(spacing: PSpacing.lg(16)) {
            AlbumArtworkView(urlString: groupedSong.artworkUrl, size: 160, cornerRadius: PRadius.lg(16))
                .pShadowHigh()

            VStack(spacing: PSpacing.xs(4)) {
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
        .padding(.top, PSpacing.lg(16))
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
        LazyVStack(spacing: PSpacing.md(12)) {
            ForEach(viewModel.memories) { memory in
                TimelineEntryView(memory: memory, onAddEntry: {
                    selectedMemory = memory
                    showAddEntry = true
                })
                .padding(.horizontal, PSpacing.lg(16))
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
