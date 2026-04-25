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
                VStack(spacing: PSpacing.lg) {
                    // 헤더: 앨범 커버 + 곡 정보
                    songHeader

                    // "새 시기 추가" 버튼
                    addNewPeriodButton
                        .padding(.horizontal, PSpacing.lg)

                    // 타임라인
                    if viewModel.isLoading {
                        PSkeletonLoader(preset: .card)
                            .padding(.horizontal, PSpacing.lg)
                            .padding(.top, PSpacing.xl)
                        PSkeletonLoader(preset: .card)
                            .padding(.horizontal, PSpacing.lg)
                        PSkeletonLoader(preset: .card)
                            .padding(.horizontal, PSpacing.lg)
                    } else if viewModel.memories.isEmpty {
                        emptyMemoriesView
                    } else {
                        timelineSection
                    }
                }
                .padding(.bottom, PSpacing.xxl)
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
            title: String(localized: "action.delete_confirm"),
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
                .ignoresSafeArea()
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
        VStack(spacing: PSpacing.md) {
            GeometryReader { geo in
                let size = min(geo.size.width * 0.5, 200)
                AlbumArtworkView(urlString: groupedSong.artworkUrl, size: size, cornerRadius: AppTheme.cornerRadius)
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 200)

            VStack(spacing: PSpacing.xxs) {
                Text(groupedSong.songTitle)
                    .font(Font.pTitle(20))
                    .foregroundStyle(Color.pTextPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(groupedSong.artistName)
                    .font(Font.pBody(15))
                    .foregroundStyle(Color.pTextSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.top, PSpacing.lg)
    }

    private var addNewPeriodButton: some View {
        Button {
            showRecordFlow = true
        } label: {
            HStack(spacing: PSpacing.xs) {
                Image(systemName: "plus.circle.fill")
                    .font(Font.pBody(16))
                Text("action.add_period")
                    .font(Font.pBodyMedium(15))
            }
            .foregroundStyle(Color.pAccentPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, PSpacing.sm)
            .background(Color.pAccentPrimary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSm))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSm)
                    .stroke(Color.pAccentPrimary.opacity(0.3), lineWidth: 1)
            )
        }
        .frame(minHeight: 44)
        .accessibilityLabel(Text("action.add_period"))
    }

    private var emptyMemoriesView: some View {
        VStack(spacing: PSpacing.md) {
            Spacer(minLength: PSpacing.xl)
            Image(systemName: "book.closed")
                .font(Font.pDisplay(40))
                .foregroundStyle(Color.pTextSecondary.opacity(0.7))
            VStack(spacing: PSpacing.xxs) {
                Text("empty.songdetail.title")
                    .font(Font.pTitle(17))
                    .foregroundStyle(Color.pTextPrimary)
                Text("empty.songdetail.message")
                    .font(Font.pBody(14))
                    .foregroundStyle(Color.pTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: PSpacing.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, PSpacing.xl)
        .padding(.top, PSpacing.xl)
    }

    private var timelineSection: some View {
        LazyVStack(spacing: PSpacing.md) {
            ForEach(viewModel.memories) { memory in
                TimelineEntryView(memory: memory, onAddEntry: {
                    selectedMemory = memory
                    showAddEntry = true
                })
                .padding(.horizontal, PSpacing.lg)
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
