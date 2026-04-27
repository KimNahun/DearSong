import SwiftUI
import TopDesignSystem

// MARK: - SongCollectionView

struct SongCollectionView: View {
    @State private var viewModel = SongCollectionViewModel()
    @State private var authViewModel: AuthViewModel
    @State private var showRecordFlow = false
    @Environment(\.designPalette) private var palette

    @State private var showErrorToast = false
    @State private var errorToastMessage = ""

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: DesignSpacing.md)
    ]

    init(authViewModel: AuthViewModel) {
        _authViewModel = State(initialValue: authViewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                palette.background
                    .ignoresSafeArea()

                Group {
                    if viewModel.isLoading && viewModel.groupedSongs.isEmpty {
                        loadingView
                    } else if viewModel.groupedSongs.isEmpty {
                        emptyStateView
                    } else {
                        songGrid
                    }
                }

                // 플로팅 + 버튼
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        floatingAddButton
                            .padding(.trailing, DesignSpacing.lg)
                            .padding(.bottom, DesignSpacing.lg)
                    }
                }
            }
            .navigationTitle(Text("screen.home.title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await authViewModel.signOut() }
                    } label: {
                        Text("action.signout")
                            .font(.ssFootnote)
                            .foregroundStyle(palette.textSecondary.opacity(0.7))
                    }
                    .accessibilityLabel(Text("action.signout"))
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .fullScreenCover(isPresented: $showRecordFlow) {
                RecordFlowView(onDismiss: {
                    showRecordFlow = false
                    Task { await viewModel.loadMemories() }
                })
            }
        }
        .task {
            await viewModel.loadMemories()
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            if let message {
                errorToastMessage = message
                showErrorToast = true
            }
        }
        .bottomToast(isPresented: $showErrorToast, message: errorToastMessage, style: .error)
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: DesignSpacing.md) {
            HStack(spacing: DesignSpacing.md) {
                ForEach(0..<2, id: \.self) { _ in
                    ShimmerPlaceholder(height: 160, cornerRadius: DesignCornerRadius.md)
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            HStack(spacing: DesignSpacing.md) {
                ForEach(0..<2, id: \.self) { _ in
                    ShimmerPlaceholder(height: 160, cornerRadius: DesignCornerRadius.md)
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
        .padding(.horizontal, DesignSpacing.lg)
    }

    private var emptyStateView: some View {
        VStack(spacing: DesignSpacing.lg) {
            Spacer()

            // 감성적 아이콘: 노트 + 하트 조합
            ZStack {
                Circle()
                    .fill(palette.primaryAction.opacity(0.08))
                    .frame(width: 100, height: 100)
                VStack(spacing: DesignSpacing.xxs) {
                    Image(systemName: "music.note")
                        .font(.ssTitle1)
                        .foregroundStyle(palette.primaryAction.opacity(0.7))
                    Image(systemName: "heart.fill")
                        .font(.ssFootnote)
                        .foregroundStyle(palette.primaryAction.opacity(0.5))
                }
            }
            .accessibilityHidden(true)

            VStack(spacing: DesignSpacing.xs) {
                Text("empty.home.title")
                    .font(.ssTitle2)
                    .foregroundStyle(palette.textPrimary)
                Text("empty.home.message")
                    .font(.ssFootnote)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            PillButton(String(localized: "action.first_record")) {
                showRecordFlow = true
            }
            .frame(minHeight: 44)
            .accessibilityLabel(Text("action.first_record"))

            Spacer()
        }
        .padding(.horizontal, DesignSpacing.xl)
    }

    private var songGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: DesignSpacing.md) {
                ForEach(viewModel.groupedSongs) { group in
                    NavigationLink(destination: SongDetailView(groupedSong: group)) {
                        SongCardView(groupedSong: group)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DesignSpacing.lg)
            .padding(.vertical, DesignSpacing.md)
            .padding(.bottom, DesignSpacing.xxl + DesignSpacing.lg)
        }
    }

    private var floatingAddButton: some View {
        Button {
            showRecordFlow = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } label: {
            Image(systemName: "plus")
                .font(.ssTitle2)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(palette.primaryAction)
                .clipShape(Circle())
                .shadow(color: palette.primaryAction.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .accessibilityLabel(Text("action.first_record"))
    }
}
