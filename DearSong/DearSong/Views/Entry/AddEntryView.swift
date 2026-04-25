import SwiftUI
import PersonalColorDesignSystem

// MARK: - AddEntryView

struct AddEntryView: View {
    let memory: SongMemory
    let onDismiss: () -> Void

    @State private var viewModel: AddEntryViewModel
    @FocusState private var isTextEditorFocused: Bool
    @Environment(PToastManager.self) private var toastManager

    init(memory: SongMemory, onDismiss: @escaping () -> Void) {
        self.memory = memory
        self.onDismiss = onDismiss
        _viewModel = State(initialValue: AddEntryViewModel(existingEntries: memory.entries))
    }

    private var listenedYear: Int {
        DateFormatters.year(from: memory.listenedAt)
    }

    var body: some View {
        ZStack {
            PGradientBackground()
                .ignoresSafeArea()
            // 줄선 패턴 (얇은 — NotebookTexture 대체)
            Color.pGlassBorder.opacity(0.05)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader

                PDivider()

                ScrollView {
                    VStack(spacing: PSpacing.lg) {
                        if !viewModel.existingEntries.isEmpty {
                            existingEntriesSection
                        }
                        newEntrySection
                    }
                    .padding(.horizontal, PSpacing.lg)
                    .padding(.top, PSpacing.md)
                    .padding(.bottom, PSpacing.xxl)
                }
                .scrollDismissesKeyboard(.interactively)
            }

            if viewModel.isSaving {
                PLoadingOverlay()
            }
        }
        .safeAreaInset(edge: .bottom) {
            saveButton
        }
        .onChange(of: viewModel.savedSuccessfully) { _, saved in
            if saved {
                toastManager.show(String(localized: "toast.entry.added"), type: .success)
                HapticManager.notification(.success)
                onDismiss()
            }
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            if let message {
                toastManager.show(message, type: .error)
            }
        }
    }

    // MARK: - Subviews

    private var saveButton: some View {
        BottomPlacedButton(title: String(localized: "action.save.entry")) {
            isTextEditorFocused = false
            Task { await viewModel.save(memoryId: memory.id) }
        }
        .disabled(viewModel.isSaving || viewModel.entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity((viewModel.isSaving || viewModel.entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.5 : 1)
        .accessibilityLabel(Text("action.save.entry"))
    }

    private var sheetHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: PSpacing.xxs) {
                Text(memory.songTitle)
                    .font(Font.pBodyMedium(17))
                    .foregroundStyle(Color.pTextPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("\(listenedYear)\(String(localized: "timeline.year_suffix")) · \(memory.artistName)")
                    .font(Font.pCaption(12))
                    .foregroundStyle(Color.pTextSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(Font.pTitle(24))
                    .foregroundStyle(Color.pTextSecondary.opacity(0.7))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(Text("action.cancel"))
        }
        .padding(.horizontal, PSpacing.lg)
        .padding(.vertical, PSpacing.sm)
    }

    private var existingEntriesSection: some View {
        VStack(alignment: .leading, spacing: PSpacing.xs) {
            Text("screen.addentry.previous")
                .font(Font.pBodyMedium(15))
                .foregroundStyle(Color.pTextPrimary)

            ForEach(viewModel.existingEntries) { entry in
                GlassCard {
                    VStack(alignment: .leading, spacing: PSpacing.xxs) {
                        Text(entry.text)
                            .font(Font.pBody(14))
                            .foregroundStyle(Color.pTextPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(formattedDate(entry.writtenAt))
                            .font(Font.pCaption(11))
                            .foregroundStyle(Color.pTextSecondary.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(entry.text)
            }
        }
    }

    private var newEntrySection: some View {
        VStack(alignment: .leading, spacing: PSpacing.xs) {
            Text("screen.addentry.new")
                .font(Font.pBodyMedium(15))
                .foregroundStyle(Color.pTextPrimary)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.entryText)
                    .font(Font.pBody(15))
                    .foregroundStyle(Color.pTextPrimary)
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .frame(minHeight: 140)
                    .padding(PSpacing.sm)
                    .focused($isTextEditorFocused)
                    .accessibilityLabel(Text("screen.addentry.placeholder"))

                if viewModel.entryText.isEmpty {
                    Text("screen.addentry.placeholder")
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

    private func formattedDate(_ date: Date) -> String {
        DateFormatters.mediumDateString(from: date)
    }
}
