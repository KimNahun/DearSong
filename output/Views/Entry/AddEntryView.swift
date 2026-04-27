import SwiftUI
import TopDesignSystem

// MARK: - AddEntryView

struct AddEntryView: View {
    let memory: SongMemory
    let onDismiss: () -> Void

    @State private var viewModel: AddEntryViewModel
    @FocusState private var isTextEditorFocused: Bool
    @Environment(\.designPalette) private var palette

    @State private var showSuccessToast = false
    @State private var showErrorToast = false
    @State private var errorToastMessage = ""

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
            palette.background
                .ignoresSafeArea()
            // 줄선 패턴 (얇은)
            palette.border.opacity(0.05)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader

                // 구분선 (PDivider 대체)
                Divider()
                    .overlay(palette.border)

                ScrollView {
                    VStack(spacing: DesignSpacing.lg) {
                        if !viewModel.existingEntries.isEmpty {
                            existingEntriesSection
                        }
                        newEntrySection
                    }
                    .padding(.horizontal, DesignSpacing.lg)
                    .padding(.top, DesignSpacing.md)
                    .padding(.bottom, DesignSpacing.xxl)
                }
                .scrollDismissesKeyboard(.interactively)
            }

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
        .onChange(of: viewModel.savedSuccessfully) { _, saved in
            if saved {
                showSuccessToast = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onDismiss()
            }
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            if let message {
                errorToastMessage = message
                showErrorToast = true
            }
        }
        .bottomToast(isPresented: $showSuccessToast, message: String(localized: "toast.entry.added"), style: .success)
        .bottomToast(isPresented: $showErrorToast, message: errorToastMessage, style: .error)
    }

    // MARK: - Subviews

    private var saveButton: some View {
        RoundedActionButton(String(localized: "action.save.entry")) {
            isTextEditorFocused = false
            Task { await viewModel.save(memoryId: memory.id) }
        }
        .disabled(viewModel.isSaving || viewModel.entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity((viewModel.isSaving || viewModel.entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.5 : 1)
        .padding(.horizontal, DesignSpacing.lg)
        .padding(.vertical, DesignSpacing.sm)
        .background(palette.background)
        .accessibilityLabel(Text("action.save.entry"))
    }

    private var sheetHeader: some View {
        HStack(alignment: .center, spacing: DesignSpacing.xs) {
            VStack(alignment: .leading, spacing: DesignSpacing.xxs) {
                Text(memory.songTitle)
                    .font(.ssBody.weight(.medium))
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(verbatim: "\(DateFormatters.yearDisplayString(listenedYear)) · \(memory.artistName)")
                    .font(.ssCaption)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.ssTitle2)
                    .foregroundStyle(palette.textSecondary.opacity(0.7))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(Text("action.cancel"))
        }
        .padding(.horizontal, DesignSpacing.lg)
        .padding(.vertical, DesignSpacing.sm)
    }

    private var existingEntriesSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.xs) {
            Text("screen.addentry.previous")
                .font(.ssBody.weight(.medium))
                .foregroundStyle(palette.textPrimary)

            ForEach(viewModel.existingEntries) { entry in
                GlassCard {
                    VStack(alignment: .leading, spacing: DesignSpacing.xxs) {
                        Text(entry.text)
                            .font(.ssFootnote)
                            .foregroundStyle(palette.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(formattedDate(entry.writtenAt))
                            .font(.ssCaption)
                            .foregroundStyle(palette.textSecondary.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(entry.text)
            }
        }
    }

    private var newEntrySection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.xs) {
            Text("screen.addentry.new")
                .font(.ssBody.weight(.medium))
                .foregroundStyle(palette.textPrimary)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.entryText)
                    .font(.ssBody)
                    .foregroundStyle(palette.textPrimary)
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .frame(minHeight: 140)
                    .padding(DesignSpacing.sm)
                    .focused($isTextEditorFocused)
                    .accessibilityLabel(Text("screen.addentry.placeholder"))

                if viewModel.entryText.isEmpty {
                    Text("screen.addentry.placeholder")
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

    private func formattedDate(_ date: Date) -> String {
        DateFormatters.mediumDateString(from: date)
    }
}
