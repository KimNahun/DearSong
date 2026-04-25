import SwiftUI
import TopDesignSystem

// MARK: - EntryWriteView

struct EntryWriteView: View {
    @Bindable var viewModel: RecordFlowViewModel
    @FocusState private var isTextEditorFocused: Bool
    @Environment(\.designPalette) private var palette

    @State private var showSuccessToast = false
    @State private var showErrorToast = false
    @State private var errorToastMessage = ""

    private var yearOptions: [String] {
        DateFormatters.selectableYears.map { String($0) }
    }

    var body: some View {
        ZStack {
            artworkBackground

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
                .padding(.bottom, DesignSpacing.xxl)
            }
            .scrollDismissesKeyboard(.interactively)

            if viewModel.isSaving {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView()
                        .tint(palette.primaryAction)
                        .scaleEffect(1.5)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            saveButton
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

    private var saveButton: some View {
        RoundedActionButton(String(localized: "action.save.record")) {
            isTextEditorFocused = false
            Task { await viewModel.save() }
        }
        .disabled(viewModel.isSaving)
        .opacity(viewModel.isSaving ? 0.6 : 1)
        .padding(.horizontal, DesignSpacing.lg)
        .padding(.vertical, DesignSpacing.sm)
        .background(palette.background)
        .accessibilityLabel(Text("action.save.record"))
    }

    @ViewBuilder
    private var artworkBackground: some View {
        ZStack {
            palette.background
                .ignoresSafeArea()
            // 줄선 패턴 (얇은 수평선만)
            palette.border.opacity(0.05)
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

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.entryText)
                    .font(.ssBody)
                    .foregroundStyle(palette.textPrimary)
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .frame(minHeight: 160)
                    .padding(DesignSpacing.sm)
                    .focused($isTextEditorFocused)
                    .accessibilityLabel(Text("screen.entry.placeholder"))

                if viewModel.entryText.isEmpty {
                    Text("screen.entry.placeholder")
                        .font(.ssBody)
                        .foregroundStyle(palette.textSecondary.opacity(0.7))
                        .padding(DesignSpacing.sm + 2)
                        .allowsHitTesting(false)
                }
            }
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
            // 년도 선택
            VStack(alignment: .leading, spacing: DesignSpacing.xs) {
                Text("screen.entry.year_label")
                    .font(.ssTitle2)
                    .foregroundStyle(palette.textPrimary)

                // PDropdownButton 대체: Picker wheel
                HStack {
                    Picker(String(localized: "screen.entry.year_label"), selection: $viewModel.selectedYear) {
                        ForEach(DateFormatters.selectableYears, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .clipped()
                }
                .borderedContainer(padding: DesignSpacing.xs)
                .accessibilityLabel("\(String(localized: "screen.entry.year_label")): \(viewModel.selectedYear)")
            }

            // 장소 입력 — PTextField 대체: HStack + TextField + borderedContainer
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
