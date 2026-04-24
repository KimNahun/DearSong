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
            PGradientBackground()

            VStack(spacing: 0) {
                // 헤더
                sheetHeader

                PDivider()

                ScrollView {
                    VStack(spacing: PSpacing.xl(20)) {
                        // 기존 엔트리들
                        if !viewModel.existingEntries.isEmpty {
                            existingEntriesSection
                        }

                        // 새 엔트리 입력
                        newEntrySection
                    }
                    .padding(.horizontal, PSpacing.lg(16))
                    .padding(.top, PSpacing.md(12))
                    .padding(.bottom, PSpacing.huge(48))
                }
            }
            .bottomButtons {
                BottomPlacedButton(title: "기록 추가") {
                    isTextEditorFocused = false
                    Task { await viewModel.save(memoryId: memory.id) }
                }
                .disabled(viewModel.isSaving || viewModel.entryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("기록 추가 저장")
            }

            if viewModel.isSaving {
                PLoadingOverlay(isLoading: true)
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
            VStack(alignment: .leading, spacing: PSpacing.xs(2)) {
                Text(memory.songTitle)
                    .font(.pTitle(17))
                    .foregroundStyle(Color.pTextPrimary)
                    .lineLimit(1)
                Text("\(yearString)년 · \(memory.artistName)")
                    .font(.pCaption(12))
                    .foregroundStyle(Color.pTextSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.pTitle(22))
                    .foregroundStyle(Color.pTextTertiary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("닫기")
        }
        .padding(.horizontal, PSpacing.lg(16))
        .padding(.vertical, PSpacing.md(12))
    }

    private var existingEntriesSection: some View {
        VStack(alignment: .leading, spacing: PSpacing.sm(8)) {
            PSectionHeader(title: "이전 기록들")

            ForEach(viewModel.existingEntries) { entry in
                VStack(alignment: .leading, spacing: PSpacing.xs(4)) {
                    Text(entry.text)
                        .font(.pBody(14))
                        .foregroundStyle(Color.pTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(formattedDate(entry.writtenAt))
                        .font(.pCaption(11))
                        .foregroundStyle(Color.pTextTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(PSpacing.md(12))
                .background(Color.pGlassFill)
                .clipShape(RoundedRectangle(cornerRadius: PRadius.sm(8)))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("이전 기록: \(entry.text)")
            }
        }
    }

    private var newEntrySection: some View {
        VStack(alignment: .leading, spacing: PSpacing.sm(8)) {
            PSectionHeader(title: "새 기록")

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: PRadius.md(12))
                    .fill(Color.pGlassFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: PRadius.md(12))
                            .stroke(isTextEditorFocused ? Color.pAccentPrimary : Color.pGlassBorder, lineWidth: PBorder.thin(1.0))
                    )

                TextEditor(text: $viewModel.entryText)
                    .font(.pBody(15))
                    .foregroundStyle(Color.pTextPrimary)
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .frame(minHeight: 120)
                    .padding(PSpacing.md(12))
                    .focused($isTextEditorFocused)
                    .accessibilityLabel("새 기록 입력")

                if viewModel.entryText.isEmpty {
                    Text("오늘 이 곡을 다시 들으며 느낀 점을 적어보세요.")
                        .font(.pBody(15))
                        .foregroundStyle(Color.pTextTertiary)
                        .padding(16)
                        .allowsHitTesting(false)
                }
            }
            .animation(PAnimation.easeOut, value: isTextEditorFocused)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}
