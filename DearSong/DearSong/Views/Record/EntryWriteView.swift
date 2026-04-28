import SwiftUI
import TopDesignSystem

// MARK: - EntryWriteView

struct EntryWriteView: View {
    @Bindable var viewModel: RecordFlowViewModel
    @FocusState private var isTextEditorFocused: Bool
    @Environment(\.designPalette) private var palette
    @Environment(ToastManager.self) private var toastManager

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSpacing.lg) {
                // 선택된 곡 + 태그 요약
                summaryCard

                // 텍스트 에디터
                textEditorSection

                // 년도 + 장소
                metadataSection
            }
            .padding(.horizontal, DesignSpacing.lg)
            .padding(.top, DesignSpacing.md)
            .padding(.bottom, DesignSpacing.xxl + 80)   // safeAreaInset 버튼 높이만큼 여유 확보
        }
        .background(artworkBackground)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            saveButton
        }
        .overlay {
            if viewModel.isSaving {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView()
                        .tint(palette.primaryAction)
                        .scaleEffect(1.5)
                }
            }
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            if let message {
                toastManager.show(message, style: .error)
            }
        }
    }

    // MARK: - Subviews

    private var saveButton: some View {
        RoundedActionButton(String(localized: "action.save.record")) {
            isTextEditorFocused = false
            Task { await viewModel.save() }
        }
        .disabled(viewModel.isSaving)
        .opacity(viewModel.isSaving ? 0.6 : 1)
        .padding(.horizontal, DesignSpacing.lg)
        .padding(.top, DesignSpacing.xs)
        .padding(.bottom, DesignSpacing.md)
        .background(
            palette.background
                .opacity(0.95)
                .ignoresSafeArea(edges: .bottom)
        )
        .accessibilityLabel(Text("action.save.record"))
    }

    // background modifier 용 — 레이아웃 흐름에서 완전 분리
    @ViewBuilder
    private var artworkBackground: some View {
        ZStack {
            palette.background

            if let urlString = viewModel.effectiveArtworkURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: 60)
                            .opacity(0.06)
                    }
                }
                .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
    }

    private var summaryCard: some View {
        GlassCard {
            HStack(spacing: DesignSpacing.sm) {
                AlbumArtworkView(
                    urlString: viewModel.effectiveArtworkURL,
                    size: 56,
                    cornerRadius: DesignCornerRadius.sm
                )

                VStack(alignment: .leading, spacing: DesignSpacing.xxs) {
                    Text(viewModel.effectiveSongTitle)
                        .font(.ssBody.weight(.medium))
                        .foregroundStyle(palette.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(viewModel.effectiveArtistName)
                        .font(.ssFootnote)
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if !viewModel.selectedMoodTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignSpacing.xxs) {
                                ForEach(Array(viewModel.selectedMoodTags).sorted(), id: \.self) { tag in
                                    Text(tag)
                                        .font(.ssCaption)
                                        .foregroundStyle(palette.primaryAction)
                                        .padding(.horizontal, DesignSpacing.xs)
                                        .padding(.vertical, DesignSpacing.xxs)
                                        .background(palette.primaryAction.opacity(0.12))
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
        VStack(alignment: .leading, spacing: DesignSpacing.xs) {
            Text("screen.entry.title")
                .font(.ssTitle2)
                .foregroundStyle(palette.textPrimary)

            TextField(
                String(localized: "screen.entry.placeholder"),
                text: $viewModel.entryText,
                axis: .vertical
            )
            .font(.ssBody)
            .foregroundStyle(palette.textPrimary)
            .lineLimit(6...20)
            .padding(DesignSpacing.sm)
            .frame(minHeight: 160, alignment: .topLeading)
            .focused($isTextEditorFocused)
            .accessibilityLabel(Text("screen.entry.placeholder"))
            .background(
                RoundedRectangle(cornerRadius: DesignCornerRadius.md)
                    .fill(palette.surface.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignCornerRadius.md)
                    .strokeBorder(isTextEditorFocused ? palette.primaryAction.opacity(0.6) : Color.clear, lineWidth: 1)
            )
            .animation(SpringAnimation.gentle, value: isTextEditorFocused)

            // 1000자 카운터
            HStack {
                Spacer()
                Text("\(viewModel.entryText.count)/1000")
                    .font(.ssCaption)
                    .foregroundStyle(viewModel.entryText.count >= 1000 ? palette.error : palette.textSecondary.opacity(0.7))
            }
        }
    }

    private var metadataSection: some View {
        VStack(spacing: DesignSpacing.lg) {
            // 년도 선택 — Picker(.menu): 고정 높이 의존 없는 컴팩트 드롭다운
            VStack(alignment: .leading, spacing: DesignSpacing.xs) {
                Text("screen.entry.year_label")
                    .font(.ssTitle2)
                    .foregroundStyle(palette.textPrimary)

                HStack {
                    Image(systemName: "calendar")
                        .font(.ssBody)
                        .foregroundStyle(palette.textSecondary)

                    Picker(String(localized: "screen.entry.year_label"), selection: $viewModel.selectedYear) {
                        ForEach(DateFormatters.selectableYears, id: \.self) { year in
                            Text(verbatim: DateFormatters.yearDisplayString(year)).tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(palette.primaryAction)
                    .accessibilityLabel("\(String(localized: "screen.entry.year_label")): \(DateFormatters.yearDisplayString(viewModel.selectedYear))")

                    Spacer()
                }
                .borderedContainer(padding: DesignSpacing.sm)
            }

            // 장소 입력
            VStack(alignment: .leading, spacing: DesignSpacing.xs) {
                Text("screen.entry.location_label")
                    .font(.ssTitle2)
                    .foregroundStyle(palette.textPrimary)

                HStack(spacing: DesignSpacing.xs) {
                    Image(systemName: "mappin.circle")
                        .font(.ssBody)
                        .foregroundStyle(palette.textSecondary)
                    TextField(String(localized: "placeholder.location"), text: $viewModel.location)
                        .font(.ssBody)
                        .foregroundStyle(palette.textPrimary)
                }
                .borderedContainer(padding: DesignSpacing.sm)
                .accessibilityLabel(Text("screen.entry.location_label"))
            }
        }
    }
}
