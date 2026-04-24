import SwiftUI
import PersonalColorDesignSystem

// MARK: - EntryWriteView

struct EntryWriteView: View {
    @Bindable var viewModel: RecordFlowViewModel
    @FocusState private var isTextEditorFocused: Bool

    private var yearOptions: [String] {
        DateFormatters.selectableYears.map { String($0) }
    }

    var body: some View {
        ZStack {
            artworkBackground

            ScrollView {
                VStack(spacing: 24) {
                    // 선택된 곡 + 태그 요약
                    summaryCard

                    // 텍스트 에디터
                    textEditorSection

                    // 년도 + 장소
                    metadataSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }

            // 저장 버튼
            VStack {
                Spacer()
                Button {
                    isTextEditorFocused = false
                    Task { await viewModel.save() }
                } label: {
                    Text("기록 남기기")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            viewModel.isSaving
                                ? AppTheme.textTertiary
                                : AppTheme.accent
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSm))
                }
                .disabled(viewModel.isSaving)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .background(
                    LinearGradient(
                        colors: [AppTheme.background.opacity(0), AppTheme.background],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .accessibilityLabel("기록 저장")
            }

            if viewModel.isSaving {
                PLoadingOverlay()
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var artworkBackground: some View {
        ZStack {
            AppBackground(showLines: true)
            if let urlString = viewModel.effectiveArtworkURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: 60)
                            .opacity(0.06)
                            .ignoresSafeArea()
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    private var summaryCard: some View {
        HStack(spacing: 14) {
            AlbumArtworkView(
                urlString: viewModel.effectiveArtworkURL,
                size: 56,
                cornerRadius: AppTheme.cornerRadiusXs
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.effectiveSongTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                Text(viewModel.effectiveArtistName)
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)

                if !viewModel.selectedMoodTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(Array(viewModel.selectedMoodTags).sorted(), id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppTheme.accent)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(AppTheme.accentSoft)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(16)
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("선택: \(viewModel.effectiveSongTitle), \(viewModel.effectiveArtistName)")
    }

    private var textEditorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("이 곡과 함께했던 순간")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSm)
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSm)
                            .stroke(isTextEditorFocused ? AppTheme.accent : AppTheme.border, lineWidth: 1.2)
                    )

                TextEditor(text: $viewModel.entryText)
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .frame(minHeight: 160)
                    .padding(14)
                    .focused($isTextEditorFocused)
                    .accessibilityLabel("감정 기록 텍스트 입력")

                if viewModel.entryText.isEmpty {
                    Text("이 노래를 들었을 때 어떤 감정이었나요?\n그때의 기억을 자유롭게 적어보세요.")
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.textTertiary)
                        .padding(18)
                        .allowsHitTesting(false)
                }
            }
            .animation(.easeOut(duration: 0.2), value: isTextEditorFocused)
        }
    }

    private var metadataSection: some View {
        VStack(spacing: 20) {
            // 년도 선택
            VStack(alignment: .leading, spacing: 10) {
                Text("들었던 시기")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                PDropdownButton(
                    placeholder: "년도 선택",
                    options: yearOptions,
                    selectedOption: Binding(
                        get: { String(viewModel.selectedYear) },
                        set: { if let val = $0, let year = Int(val) { viewModel.selectedYear = year } }
                    )
                )
                .accessibilityLabel("들었던 연도 선택: \(viewModel.selectedYear)년")
            }

            // 장소 입력
            VStack(alignment: .leading, spacing: 10) {
                Text("들었던 장소 (선택)")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                HStack(spacing: 10) {
                    Image(systemName: "mappin.circle")
                        .foregroundStyle(AppTheme.textTertiary)
                    TextField("예: 학교 옥상, 버스 안, 카페...", text: $viewModel.location)
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.textPrimary)
                        .accessibilityLabel("들었던 장소 입력 (선택 사항)")
                }
                .padding(14)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSm))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSm)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
            }
        }
    }
}
