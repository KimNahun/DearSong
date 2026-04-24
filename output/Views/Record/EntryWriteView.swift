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
            // 배경: 크림 베이스 + 옵셔널 아트워크 (저불투명도)
            artworkBackground

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: PSpacing.xl) {
                        // 선택된 곡 + 태그 요약
                        summaryCard

                        // 텍스트 에디터
                        textEditorSection

                        // 년도 + 장소
                        metadataSection
                    }
                    .padding(.horizontal, PSpacing.lg)
                    .padding(.top, PSpacing.md)
                    .padding(.bottom, PSpacing.huge)
                }
            }
            .bottomButtons {
                BottomPlacedButton(title: "기록 남기기") {
                    isTextEditorFocused = false
                    Task { await viewModel.save() }
                }
                .disabled(viewModel.isSaving)
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
        HStack(spacing: PSpacing.md) {
            AlbumArtworkView(
                urlString: viewModel.effectiveArtworkURL,
                size: 52,
                cornerRadius: PRadius.xs
            )

            VStack(alignment: .leading, spacing: PSpacing.xs) {
                Text(viewModel.effectiveSongTitle)
                    .font(.pBodyMedium(15))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(viewModel.effectiveArtistName)
                    .font(.pBody(13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // 선택된 감정 태그들
                if !viewModel.selectedMoodTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: PSpacing.xs) {
                            ForEach(Array(viewModel.selectedMoodTags).sorted(), id: \.self) { tag in
                                PChip(tag)
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(PSpacing.md)
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("선택: \(viewModel.effectiveSongTitle), \(viewModel.effectiveArtistName)")
    }

    private var textEditorSection: some View {
        VStack(alignment: .leading, spacing: PSpacing.sm) {
            Text("이 곡과 함께했던 순간")
                .font(.pTitle(17))
                .foregroundStyle(.primary)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: PRadius.md)
                    .fill(AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: PRadius.md)
                            .stroke(isTextEditorFocused ? Color.pAccentPrimary : Color(.systemGray5), lineWidth: PBorder.thin)
                    )

                TextEditor(text: $viewModel.entryText)
                    .font(.pBody(15))
                    .foregroundStyle(.primary)
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .frame(minHeight: 140)
                    .padding(PSpacing.md)
                    .focused($isTextEditorFocused)
                    .accessibilityLabel("감정 기록 텍스트 입력")

                if viewModel.entryText.isEmpty {
                    Text("이 노래를 들었을 때 어떤 감정이었나요?\n그때의 기억을 자유롭게 적어보세요.")
                        .font(.pBody(15))
                        .foregroundStyle(Color(.tertiaryLabel))
                        .padding(PSpacing.lg)
                        .allowsHitTesting(false)
                }
            }
            .animation(PAnimation.easeOut, value: isTextEditorFocused)
            .pFocusBorder(isFocused: isTextEditorFocused)
        }
    }

    private var metadataSection: some View {
        VStack(spacing: PSpacing.lg) {
            // 년도 선택
            VStack(alignment: .leading, spacing: PSpacing.sm) {
                Text("들었던 시기")
                    .font(.pTitle(17))
                    .foregroundStyle(.primary)

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
            VStack(alignment: .leading, spacing: PSpacing.sm) {
                Text("들었던 장소 (선택)")
                    .font(.pTitle(17))
                    .foregroundStyle(.primary)

                PTextField(placeholder: "예: 학교 옥상, 버스 안, 카페...", text: $viewModel.location)
                    .accessibilityLabel("들었던 장소 입력 (선택 사항)")
            }
        }
    }
}
