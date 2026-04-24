import SwiftUI
import PersonalColorDesignSystem

// MARK: - SongCollectionView

struct SongCollectionView: View {
    @State private var viewModel = SongCollectionViewModel()
    @State private var authViewModel: AuthViewModel
    @State private var showRecordFlow = false
    @Environment(PToastManager.self) private var toastManager

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    init(authViewModel: AuthViewModel) {
        _authViewModel = State(initialValue: authViewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

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
                            .padding(.trailing, 24)
                            .padding(.bottom, 24)
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
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textTertiary)
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
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ForEach(0..<2, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(AppTheme.chipBackground)
                        .frame(height: 200)
                }
            }
            HStack(spacing: 14) {
                ForEach(0..<2, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(AppTheme.chipBackground)
                        .frame(height: 200)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.textTertiary)

            VStack(spacing: 8) {
                Text("아직 기록된 곡이 없어요")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("오늘 들은 노래에\n어떤 감정이 담겨 있나요?")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showRecordFlow = true
            } label: {
                Text("첫 기록 남기기")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(AppTheme.accent)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 32)
    }

    private var songGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(viewModel.groupedSongs) { group in
                    NavigationLink(destination: SongDetailView(groupedSong: group)) {
                        SongCardView(groupedSong: group)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 80)
        }
    }

    private var floatingAddButton: some View {
        Button {
            showRecordFlow = true
            HapticManager.impact(.medium)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(AppTheme.accent)
                .clipShape(Circle())
                .shadow(color: AppTheme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .accessibilityLabel("새 기록 작성")
    }
}
