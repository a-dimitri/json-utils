import SwiftUI
import JSONKit

@MainActor
struct RootView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        let t = model.theme
        VStack(spacing: 0) {
            toolbar(t)
            Divider().overlay(t.border)
            panes(t)
            Divider().overlay(t.border)
            statusBar(t)
        }
        .background(t.bg)
        .foregroundStyle(t.text)
        .overlay {
            if model.showDiff {
                diffOverlay(t)
            }
        }
    }

    // MARK: - Diff overlay

    /// A custom modal overlay (instead of `.sheet`) so clicking the dimmed
    /// backdrop dismisses it, matching the design. Escape and the ✕ also close.
    private func diffOverlay(_ t: Theme) -> some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { model.showDiff = false }

            DiffView(rows: model.diffLines, theme: t) { model.showDiff = false }
                .shadow(color: .black.opacity(0.5), radius: 30, y: 12)

            // Reliable Escape-to-close (an overlay doesn't get the sheet's default).
            Button("", action: { model.showDiff = false })
                .keyboardShortcut(.cancelAction)
                .hidden()
        }
    }

    // MARK: - Toolbar (operation selector + Run + theme)

    private func toolbar(_ t: Theme) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 2) {
                ForEach(JSONKit.Operation.allCases) { op in
                    let selected = model.op == op
                    Button(action: { model.op = op }) {
                        Text(op.label)
                            .font(.system(size: 12, weight: selected ? .semibold : .medium))
                            .foregroundStyle(selected ? t.text : t.muted)
                            .padding(.vertical, 6).padding(.horizontal, 11)
                            .background(selected ? t.segActive : .clear, in: RoundedRectangle(cornerRadius: 6))
                            // Make the whole padded pill clickable, not just the text glyph.
                            .contentShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(t.track, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.border))

            Spacer()

            Picker("Theme", selection: $model.themeID) {
                ForEach(ThemeID.allCases) { Text($0.label).tag($0) }
            }
            .labelsHidden()
            .fixedSize()

            Button(action: { model.run() }) {
                Label(model.op.isDiff ? "Compare" : model.op.label, systemImage: "play.fill")
                    .font(.system(size: 12.5, weight: .semibold))
                    .padding(.vertical, 8).padding(.horizontal, 16)
                    .foregroundStyle(t.accentText)
                    .background(t.accent, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .frame(height: 50)
        .background(t.bar)
    }

    // MARK: - Editor panes

    private func panes(_ t: Theme) -> some View {
        HStack(spacing: 0) {
            pane(t, header: model.op.isDiff ? "Input A" : "Input", trailing: clearButton(t)) {
                editor(text: $model.input, t: t)
            }
            Divider().overlay(t.border)
            pane(t, header: model.op.isDiff ? "Input B" : "Output", trailing: rightHeaderButton(t)) {
                if model.op.isDiff {
                    editor(text: $model.inputRight, t: t)
                } else if let error = model.errorMessage {
                    errorBox(error, t)
                } else {
                    outputView(t)
                }
            }
        }
    }

    private func pane<Header: View, Content: View>(
        _ t: Theme, header: String, trailing: Header, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(header.uppercased())
                    .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(t.muted)
                Spacer()
                trailing
            }
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(t.paneHeader)
            Divider().overlay(t.border)
            content()
        }
        .background(t.pane)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func editor(text: Binding<String>, t: Theme) -> some View {
        CodeTextView(text: text, themeID: model.themeID, isEditable: true)
    }

    private func outputView(_ t: Theme) -> some View {
        CodeTextView(text: .constant(model.output), themeID: model.themeID, isEditable: false)
    }

    private func errorBox(_ message: String, _ t: Theme) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("⚠ Parse error")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(t.errorText)
            Text(message)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(t.text.opacity(0.85))
        }
        .padding(14)
        .background(t.errorBg, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.errorText.opacity(0.27)))
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Header buttons

    private func clearButton(_ t: Theme) -> some View {
        ghostButton("Clear", t) { model.clearInput() }
    }

    private func rightHeaderButton(_ t: Theme) -> some View {
        Group {
            if model.op.isDiff {
                ghostButton("Clear", t) { model.inputRight = "" }
            } else {
                ghostButton("Copy", t) { model.copyOutput() }
            }
        }
    }

    private func ghostButton(_ title: String, _ t: Theme, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(t.muted)
                .padding(.vertical, 3).padding(.horizontal, 9)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(t.border))
                .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Status bar

    private func statusBar(_ t: Theme) -> some View {
        HStack {
            HStack(spacing: 10) {
                Text(model.op.label)
                    .font(.system(size: 10, weight: .medium))
                    .padding(.vertical, 2).padding(.horizontal, 8)
                    .background(t.track, in: RoundedRectangle(cornerRadius: 5))
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(t.border))
                Text(model.op.isDiff
                     ? "A: \(model.lineCount) lines"
                     : "\(model.lineCount) lines · \(model.charCount) chars")
            }
            Spacer()
            HStack(spacing: 7) {
                Circle()
                    .fill(model.op.isDiff ? t.accent : (model.isValid ? t.number : t.null))
                    .frame(width: 7, height: 7)
                Text(model.op.isDiff ? "Compare mode" : (model.isValid ? "Valid JSON" : "Invalid JSON"))
            }
        }
        .font(.system(size: 11, design: .monospaced))
        .foregroundStyle(t.muted)
        .padding(.horizontal, 14)
        .frame(height: 30)
        .background(t.chrome)
    }
}
