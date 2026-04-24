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
            backgroundView

            ScrollView {
                VStack(spacing: 24) {
                    // 헤더: 앨범 커버 + 곡 정보
                    songHeader

                    // "새 시기 추가" 버튼
                    addNewPeriodButton
                        .padding(.horizontal, 20)

                    // 타임라인
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(AppTheme.accent)
                            .padding(.top, 40)
                    } else if viewModel.memories.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 40))
                                .foregroundStyle(AppTheme.textTertiary)
                            Text("아직 기록이 없어요")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("이 곡을 들었던 시기를\n기록해보세요")
                                .font(.system(size: 14))
                                .foregroundStyle(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                    } else {
                        timelineSection
                    }
                }
                .padding(.bottom, 60)
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
            AppBackground()
            if let urlString = groupedSong.artworkUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: 60)
                            .opacity(0.08)
                            .ignoresSafeArea()
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    private var songHeader: some View {
        VStack(spacing: 16) {
            AlbumArtworkView(urlString: groupedSong.artworkUrl, size: 160, cornerRadius: AppTheme.cornerRadius)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)

            VStack(spacing: 6) {
                Text(groupedSong.songTitle)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(groupedSong.artistName)
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(.top, 20)
    }

    private var addNewPeriodButton: some View {
        Button {
            showRecordFlow = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                Text("이 곡의 새 시기 추가")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(AppTheme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.accentSoft)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSm))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSm)
                    .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
            )
        }
        .accessibilityLabel("이 곡의 새 시기 기록 추가")
    }

    private var timelineSection: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.memories) { memory in
                TimelineEntryView(memory: memory, onAddEntry: {
                    selectedMemory = memory
                    showAddEntry = true
                })
                .padding(.horizontal, 20)
                .contextMenu {
                    Button(role: .destructive) {
                        memoryToDelete = memory
                        showDeleteConfirm = true
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                }
                .accessibilityAction(named: "삭제") {
                    memoryToDelete = memory
                    showDeleteConfirm = true
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
