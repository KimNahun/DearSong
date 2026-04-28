import SwiftUI
import TopDesignSystem

// MARK: - SongDetailView

struct SongDetailView: View {
    let groupedSong: GroupedSong

    @State private var viewModel = SongDetailViewModel()
    @State private var selectedMemory: SongMemory?
    @State private var showAddEntry = false
    @State private var showRecordFlow = false
    @State private var memoryToDelete: SongMemory?
    @State private var showDeleteConfirm = false
    @Environment(\.designPalette) private var palette

    @Environment(ToastManager.self) private var toastManager

    var body: some View {
        ZStack {
            backgroundView

            ScrollView {
                VStack(spacing: DesignSpacing.lg) {
                    // 헤더: 앨범 커버 + 곡 정보
                    songHeader

                    // "새 시기 추가" 버튼
                    addNewPeriodButton
                        .padding(.horizontal, DesignSpacing.lg)

                    // 타임라인
                    if viewModel.isLoading {
                        ShimmerPlaceholder(height: 160, cornerRadius: DesignCornerRadius.md)
                            .padding(.horizontal, DesignSpacing.lg)
                            .padding(.top, DesignSpacing.xl)
                        ShimmerPlaceholder(height: 160, cornerRadius: DesignCornerRadius.md)
                            .padding(.horizontal, DesignSpacing.lg)
                        ShimmerPlaceholder(height: 160, cornerRadius: DesignCornerRadius.md)
                            .padding(.horizontal, DesignSpacing.lg)
                    } else if viewModel.memories.isEmpty {
                        emptyMemoriesView
                    } else {
                        timelineSection
                    }
                }
                .padding(.bottom, DesignSpacing.xxl)
            }
        }
        .navigationTitle(groupedSong.songTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel.memories.isEmpty {
                viewModel.seed(groupedSong.memories)
            }
        }
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
        .confirmationModal(
            isPresented: $showDeleteConfirm,
            title: String(localized: "action.delete_confirm"),
            message: String(localized: "action.delete_confirm_message"),
            isDestructive: true,
            onConfirm: {
                if let memory = memoryToDelete {
                    Task { await viewModel.deleteMemory(id: memory.id) }
                }
                memoryToDelete = nil
            }
        )
        .onChange(of: viewModel.errorMessage) { _, message in
            if let message {
                toastManager.show(message, style: .error)
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var backgroundView: some View {
        ZStack {
            palette.background
                .ignoresSafeArea()
            if let urlString = groupedSong.artworkUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            // linear 테마(CleanNeutral/white 배경)에서 더 섬세한 앨범 아트 틴트
                            .blur(radius: 70)
                            .opacity(0.05)
                            .ignoresSafeArea()
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    private var songHeader: some View {
        VStack(spacing: DesignSpacing.md) {
            GeometryReader { geo in
                let size = min(geo.size.width * 0.5, 200)
                AlbumArtworkView(urlString: groupedSong.artworkUrl, size: size, cornerRadius: DesignCornerRadius.lg)
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 200)

            VStack(spacing: DesignSpacing.xxs) {
                Text(groupedSong.songTitle)
                    .font(.ssTitle2)
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(groupedSong.artistName)
                    .font(.ssBody)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.top, DesignSpacing.lg)
    }

    private var addNewPeriodButton: some View {
        Button {
            showRecordFlow = true
        } label: {
            HStack(spacing: DesignSpacing.xs) {
                Image(systemName: "plus.circle.fill")
                    .font(.ssBody)
                Text("action.add_period")
                    .font(.ssBody.weight(.medium))
            }
            .foregroundStyle(palette.primaryAction)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSpacing.sm)
            .background(palette.primaryAction.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: DesignCornerRadius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: DesignCornerRadius.sm)
                    .stroke(palette.primaryAction.opacity(0.3), lineWidth: 1)
            )
        }
        .frame(minHeight: 44)
        .accessibilityLabel(Text("action.add_period"))
    }

    private var emptyMemoriesView: some View {
        VStack(spacing: DesignSpacing.md) {
            Spacer(minLength: DesignSpacing.xl)
            Image(systemName: "book.closed")
                .font(.ssLargeTitle)
                .foregroundStyle(palette.textSecondary.opacity(0.7))
            VStack(spacing: DesignSpacing.xxs) {
                Text("empty.songdetail.title")
                    .font(.ssTitle2)
                    .foregroundStyle(palette.textPrimary)
                Text("empty.songdetail.message")
                    .font(.ssFootnote)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: DesignSpacing.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DesignSpacing.xl)
        .padding(.top, DesignSpacing.xl)
    }

    private var timelineSection: some View {
        LazyVStack(spacing: DesignSpacing.md) {
            ForEach(viewModel.memories) { memory in
                TimelineEntryView(memory: memory, onAddEntry: {
                    selectedMemory = memory
                    showAddEntry = true
                })
                .padding(.horizontal, DesignSpacing.lg)
                .contextMenu {
                    Button(role: .destructive) {
                        memoryToDelete = memory
                        showDeleteConfirm = true
                    } label: {
                        Label {
                            Text("action.delete")
                        } icon: {
                            Image(systemName: "trash")
                        }
                    }
                }
                .accessibilityAction(named: Text("action.delete")) {
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
