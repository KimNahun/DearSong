import SwiftUI
import PersonalColorDesignSystem

// MARK: - SongCollectionView

struct SongCollectionView: View {
    @State private var viewModel = SongCollectionViewModel()
    @State private var authViewModel: AuthViewModel
    @State private var showRecordFlow = false
    @Environment(PToastManager.self) private var toastManager

    private let columns = [
        GridItem(.flexible(), spacing: PSpacing.md(12)),
        GridItem(.flexible(), spacing: PSpacing.md(12))
    ]

    init(authViewModel: AuthViewModel) {
        _authViewModel = State(initialValue: authViewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PGradientBackground()

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
                            .padding(.trailing, PSpacing.xl(20))
                            .padding(.bottom, PSpacing.xl(20))
                    }
                }
            }
            .navigationTitle("DearSong")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("로그아웃") {
                        Task { await authViewModel.signOut() }
                    }
                    .font(.pBody(14))
                    .foregroundStyle(Color.pTextSecondary)
                    .accessibilityLabel("로그아웃")
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
                toastManager.show(message, type: .error)
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack {
            PSkeletonLoader(preset: .card)
            PSkeletonLoader(preset: .card)
        }
        .padding(.horizontal, PSpacing.lg(16))
    }

    private var emptyStateView: some View {
        EmptyStateView(
            title: "아직 기록된 곡이 없어요",
            message: "오늘 들은 노래에\n어떤 감정이 담겨 있나요?",
            actionTitle: "첫 기록 남기기",
            action: { showRecordFlow = true }
        )
        .padding(.horizontal, PSpacing.xl(20))
    }

    private var songGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: PSpacing.md(12)) {
                ForEach(viewModel.groupedSongs) { group in
                    NavigationLink(destination: SongDetailView(groupedSong: group)) {
                        SongCardView(groupedSong: group)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, PSpacing.lg(16))
            .padding(.vertical, PSpacing.md(12))
            .padding(.bottom, PSpacing.giant(64)) // 플로팅 버튼 공간
        }
    }

    private var floatingAddButton: some View {
        Button {
            showRecordFlow = true
            HapticManager.impact(.medium)
        } label: {
            ZStack {
                PAccentGradient(direction: .diagonal)
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    .pShadowMid()

                Image(systemName: "plus")
                    .font(.pTitle(22))
                    .foregroundStyle(Color.pTextPrimary)
            }
        }
        .frame(width: 56, height: 56)
        .accessibilityLabel("새 기록 작성")
    }
}
