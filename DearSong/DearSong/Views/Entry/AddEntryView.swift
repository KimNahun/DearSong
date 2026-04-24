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

    private var yearString: String {
        DateFormatters.yearString(from: memory.listenedAt)
    }

    var body: some View {
        ZStack {
            AppBackground(showLines: true)

            VStack(spacing: 0) {
                sheetHeader

                Rectangle()
                    .fill(AppTheme.divider)
                    .frame(height: 1)

                ScrollView {
                    VStack(spacing: 24) {
                        if !viewModel.existingEntries.isEmpty {
                            existingEntriesSection
                        }
                        newEntrySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }

            // 저장 버튼
            VStack {
                Spacer()
                Button {
                    isTextEditorFocused = false
                    Task { await viewModel.save(memoryId: memory.id) }
                } label: {
                    Text("기록 추가")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            (viewModel.isSaving || viewModel.entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                ? AppTheme.textTertiary
                                : AppTheme.accent
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusSm))
                }
                .disabled(viewModel.isSaving || viewModel.entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .background(
                    LinearGradient(
                        colors: [AppTheme.background.opacity(0), AppTheme.background],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .accessibilityLabel("기록 추가 저장")
            }

            if viewModel.isSaving {
                PLoadingOverlay()
            }
        }
        .onChange(of: viewModel.savedSuccessfully) { _, saved in
            if saved {
                toastManager.show("기록이 추가되었어요", type: .success)
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

    private var sheetHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(memory.songTitle)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                Text("\(yearString)년 · \(memory.artistName)")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AppTheme.textTertiary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("닫기")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var existingEntriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("이전 기록들")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)

            ForEach(viewModel.existingEntries) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.text)
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(formattedDate(entry.writtenAt))
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(AppTheme.chipBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusXs))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("이전 기록: \(entry.text)")
            }
        }
    }

    private var newEntrySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("새 기록")
                .font(.system(size: 15, weight: .semibold))
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
                    .frame(minHeight: 140)
                    .padding(14)
                    .focused($isTextEditorFocused)
                    .accessibilityLabel("새 기록 입력")

                if viewModel.entryText.isEmpty {
                    Text("오늘 이 곡을 다시 들으며 느낀 점을 적어보세요.")
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.textTertiary)
                        .padding(18)
                        .allowsHitTesting(false)
                }
            }
            .animation(.easeOut(duration: 0.2), value: isTextEditorFocused)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        DateFormatters.mediumDateString(from: date)
    }
}
