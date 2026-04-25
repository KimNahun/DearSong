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
                VStack(spacing: PSpacing.lg) {
                    // 선택된 곡 + 태그 요약
                    summaryCard

                    // 텍스트 에디터
                    textEditorSection

                    // 년도 + 장소
                    metadataSection
                }
                .padding(.horizontal, PSpacing.lg)
                .padding(.top, PSpacing.md)
                .padding(.bottom, PSpacing.xxl)
            }
            .scrollDismissesKeyboard(.interactively)

            if viewModel.isSaving {
                PLoadingOverlay()
            }
        }
        .safeAreaInset(edge: .bottom) {
            saveButton
        }
    }

    // MARK: - Subviews

    private var saveButton: some View {
        BottomPlacedButton(title: String(localized: "action.save.record")) {
            isTextEditorFocused = false
            Task { await viewModel.save() }
        }
        .disabled(viewModel.isSaving)
        .opacity(viewModel.isSaving ? 0.6 : 1)
        .accessibilityLabel(Text("action.save.record"))
    }

    @ViewBuilder
    private var artworkBackground: some View {
        ZStack {
            PGradientBackground()
                .ignoresSafeArea()
            // 줄선 패턴 (얇은 수평선만 — SPEC NotebookTexture 대체)
            Color.pGlassBorder.opacity(0.05)
                .ignoresSafeArea()
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
        GlassCard {
            HStack(spacing: PSpacing.sm) {
                AlbumArtworkView(
                    urlString: viewModel.effectiveArtworkURL,
                    size: 56,
                    cornerRadius: AppTheme.cornerRadiusXs
                )

                VStack(alignment: .leading, spacing: PSpacing.xxs) {
                    Text(viewModel.effectiveSongTitle)
                        .font(Font.pBodyMedium(16))
                        .foregroundStyle(Color.pTextPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(viewModel.effectiveArtistName)
                        .font(Font.pBody(14))
                        .foregroundStyle(Color.pTextSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if !viewModel.selectedMoodTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: PSpacing.xxs) {
                                ForEach(Array(viewModel.selectedMoodTags).sorted(), id: \.self) { tag in
                                    Text(tag)
                                        .font(Font.pCaption(12))
                                        .foregroundStyle(Color.pAccentPrimary)
                                        .padding(.horizontal, PSpacing.xs)
                                        .padding(.vertical, PSpacing.xxs)
                                        .background(Color.pAccentPrimary.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(String(localized: "action.selected")): \(viewModel.effectiveSongTitle), \(viewModel.effectiveArtistName)")
    }

    private var textEditorSection: some View {
        VStack(alignment: .leading, spacing: PSpacing.xs) {
            Text("screen.entry.title")
                .font(Font.pTitle(17))
                .foregroundStyle(Color.pTextPrimary)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.entryText)
                    .font(Font.pBody(15))
                    .foregroundStyle(Color.pTextPrimary)
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .frame(minHeight: 160)
                    .padding(PSpacing.sm)
                    .focused($isTextEditorFocused)
                    .accessibilityLabel(Text("screen.entry.placeholder"))

                if viewModel.entryText.isEmpty {
                    Text("screen.entry.placeholder")
                        .font(Font.pBody(15))
                        .foregroundStyle(Color.pTextSecondary.opacity(0.7))
                        .padding(PSpacing.sm + 2)
                        .allowsHitTesting(false)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: PRadius.md)
                    .fill(Color.pGlassFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: PRadius.md)
                    .strokeBorder(isTextEditorFocused ? Color.pAccentPrimary.opacity(0.6) : Color.clear, lineWidth: 1)
            )
            .animation(PAnimation.easeOut, value: isTextEditorFocused)

            // 1000자 카운터
            HStack {
                Spacer()
                Text("\(viewModel.entryText.count)/1000")
                    .font(Font.pCaption(11))
                    .foregroundStyle(viewModel.entryText.count >= 1000 ? Color.pDestructive : Color.pTextSecondary.opacity(0.7))
            }
        }
    }

    private var metadataSection: some View {
        VStack(spacing: PSpacing.lg) {
            // 년도 선택
            VStack(alignment: .leading, spacing: PSpacing.xs) {
                Text("screen.entry.year_label")
                    .font(Font.pTitle(17))
                    .foregroundStyle(Color.pTextPrimary)

                PDropdownButton(
                    placeholder: String(localized: "screen.entry.year_label"),
                    options: yearOptions,
                    selectedOption: Binding(
                        get: { String(viewModel.selectedYear) },
                        set: { if let val = $0, let year = Int(val) { viewModel.selectedYear = year } }
                    )
                )
                .accessibilityLabel("\(String(localized: "screen.entry.year_label")): \(viewModel.selectedYear)")
            }

            // 장소 입력
            VStack(alignment: .leading, spacing: PSpacing.xs) {
                Text("screen.entry.location_label")
                    .font(Font.pTitle(17))
                    .foregroundStyle(Color.pTextPrimary)

                PTextField(
                    placeholder: String(localized: "placeholder.location"),
                    text: $viewModel.location,
                    leadingIcon: "mappin.circle"
                )
                .accessibilityLabel(Text("screen.entry.location_label"))
            }
        }
    }
}
