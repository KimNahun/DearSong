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
                VStack(spacing: DesignSpacing.xl) {
                    // 헤더: 앨범 커버 + 곡 정보
                    songHeader

                    // "새 시기 추가" 버튼
                    addNewPeriodButton
                        .padding(.horizontal, DesignSpacing.lg)

                    // 타임라인
                    if viewModel.isLoading {
                        VStack(spacing: DesignSpacing.md) {
                            ShimmerPlaceholder(height: 160, cornerRadius: DesignCornerRadius.lg)
                            ShimmerPlaceholder(height: 160, cornerRadius: DesignCornerRadius.lg)
                            ShimmerPlaceholder(height: 160, cornerRadius: DesignCornerRadius.lg)
                        }
                        .padding(.horizontal, DesignSpacing.lg)
                        .padding(.top, DesignSpacing.sm)
                    } else if viewModel.memories.isEmpty {
                        emptyMemoriesView
                    } else {
                        timelineSection
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, DesignSpacing.xxl)
            }
            .scrollIndicators(.hidden)
            .refreshable {
                await viewModel.loadMemories(
                    appleMusicId: groupedSong.appleMusicId,
                    songTitle: groupedSong.songTitle,
                    artistName: groupedSong.artistName
                )
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
            if let urlString = groupedSong.artworkUrl, let url = URL(string: urlString) {
                GeometryReader { geo in
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                                .blur(radius: 80)
                                .opacity(0.18)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                }
                .overlay(
                    LinearGradient(
                        colors: [
                            palette.background.opacity(0.0),
                            palette.background.opacity(0.6),
                            palette.background
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .ignoresSafeArea()
    }

    private var songHeader: some View {
        VStack(spacing: DesignSpacing.md) {
            GeometryReader { geo in
                let size = min(geo.size.width * 0.62, 240)
                AlbumArtworkView(urlString: groupedSong.artworkUrl, size: size, cornerRadius: DesignCornerRadius.lg)
                    .shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 12)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 240)

            VStack(spacing: DesignSpacing.xxs) {
                Text(groupedSong.songTitle)
                    .font(.ssTitle1)
                    .fontWeight(.semibold)
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)

                Text(groupedSong.artistName)
                    .font(.ssBody)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity)
            }

            // 메모리 카운트 칩 — 더 풍부한 정보 전달
            if !viewModel.memories.isEmpty {
                HStack(spacing: DesignSpacing.xxs) {
                    Image(systemName: "book.pages.fill")
                        .font(.ssCaption)
                    Text(verbatim: "\(viewModel.memories.count)개의 시기")
                        .font(.ssCaption.weight(.medium))
                }
                .foregroundStyle(palette.primaryAction)
                .padding(.horizontal, DesignSpacing.sm)
                .padding(.vertical, DesignSpacing.xxs)
                .background(
                    Capsule().fill(palette.primaryAction.opacity(0.12))
                )
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DesignSpacing.lg)
        .padding(.top, DesignSpacing.md)
    }

    private var addNewPeriodButton: some View {
        Button {
            showRecordFlow = true
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: DesignSpacing.xs) {
                Image(systemName: "plus")
                    .font(.ssBody.weight(.semibold))
                Text("action.add_period")
                    .font(.ssBody.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSpacing.sm + 2)
            .background(
                LinearGradient(
                    colors: [
                        palette.primaryAction,
                        palette.primaryAction.opacity(0.85)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignCornerRadius.md))
            .shadow(color: palette.primaryAction.opacity(0.25), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.pressScale)
        .frame(minHeight: 44)
        .accessibilityLabel(Text("action.add_period"))
    }

    private var emptyMemoriesView: some View {
        VStack(spacing: DesignSpacing.md) {
            Spacer(minLength: DesignSpacing.xl)
            ZStack {
                Circle()
                    .fill(palette.primaryAction.opacity(0.08))
                    .frame(width: 84, height: 84)
                Image(systemName: "book.closed")
                    .font(.ssTitle1)
                    .foregroundStyle(palette.primaryAction.opacity(0.7))
            }
            .accessibilityHidden(true)

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
            ForEach(Array(viewModel.memories.enumerated()), id: \.element.id) { index, memory in
                HStack(alignment: .top, spacing: DesignSpacing.sm) {
                    // 타임라인 인디케이터 (도트 + 라인)
                    VStack(spacing: 0) {
                        Circle()
                            .fill(palette.primaryAction)
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(palette.primaryAction.opacity(0.3), lineWidth: 4)
                            )
                            .padding(.top, DesignSpacing.md)

                        if index < viewModel.memories.count - 1 {
                            Rectangle()
                                .fill(palette.border.opacity(0.5))
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(width: 14)
                    .accessibilityHidden(true)

                    TimelineEntryView(memory: memory, onAddEntry: {
                        selectedMemory = memory
                        showAddEntry = true
                    })
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DesignSpacing.lg)
            }
        }
        .frame(maxWidth: .infinity)
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
