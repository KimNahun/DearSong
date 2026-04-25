import SwiftUI
import PersonalColorDesignSystem

// MARK: - SongCollectionView

struct SongCollectionView: View {
    @State private var viewModel = SongCollectionViewModel()
    @State private var authViewModel: AuthViewModel
    @State private var showRecordFlow = false
    @Environment(PToastManager.self) private var toastManager

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: PSpacing.md)
    ]

    init(authViewModel: AuthViewModel) {
        _authViewModel = State(initialValue: authViewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PGradientBackground()
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
                            .padding(.trailing, PSpacing.lg)
                            .padding(.bottom, PSpacing.lg)
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
                            .font(Font.pBody(14))
                            .foregroundStyle(Color.pTextSecondary.opacity(0.7))
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
                toastManager.show(message, type: .error)
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: PSpacing.md) {
            HStack(spacing: PSpacing.md) {
                ForEach(0..<2, id: \.self) { _ in
                    PSkeletonLoader(preset: .card)
                        .aspectRatio(1, contentMode: .fit)
                }
            }
            HStack(spacing: PSpacing.md) {
                ForEach(0..<2, id: \.self) { _ in
                    PSkeletonLoader(preset: .card)
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
        .padding(.horizontal, PSpacing.lg)
    }

    private var emptyStateView: some View {
        VStack(spacing: PSpacing.lg) {
            Spacer()
            Image(systemName: "music.note.list")
                .font(Font.pDisplay(56))
                .foregroundStyle(Color.pTextSecondary.opacity(0.7))

            VStack(spacing: PSpacing.xs) {
                Text("empty.home.title")
                    .font(Font.pTitle(17))
                    .foregroundStyle(Color.pTextPrimary)
                Text("empty.home.message")
                    .font(Font.pBody(14))
                    .foregroundStyle(Color.pTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                showRecordFlow = true
            } label: {
                Text("action.first_record")
                    .font(Font.pBodyMedium(15))
                    .foregroundStyle(.white)
                    .padding(.horizontal, PSpacing.xl)
                    .padding(.vertical, PSpacing.sm)
                    .background(Color.pAccentPrimary)
                    .clipShape(Capsule())
            }
            .frame(minHeight: 44)
            .accessibilityLabel(Text("action.first_record"))
            Spacer()
        }
        .padding(.horizontal, PSpacing.xl)
    }

    private var songGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: PSpacing.md) {
                ForEach(viewModel.groupedSongs) { group in
                    NavigationLink(destination: SongDetailView(groupedSong: group)) {
                        SongCardView(groupedSong: group)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, PSpacing.lg)
            .padding(.vertical, PSpacing.md)
            .padding(.bottom, PSpacing.xxl + PSpacing.lg)
        }
    }

    private var floatingAddButton: some View {
        Button {
            showRecordFlow = true
            HapticManager.impact(.medium)
        } label: {
            Image(systemName: "plus")
                .font(Font.pTitle(20))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.pAccentPrimary)
                .clipShape(Circle())
                .shadow(color: Color.pAccentPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .accessibilityLabel(Text("action.first_record"))
    }
}
