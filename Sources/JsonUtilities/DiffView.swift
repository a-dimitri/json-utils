import SwiftUI
import JSONKit

/// Side-by-side line diff shown as a full panel in place of the editors.
@MainActor
struct DiffView: View {
    let rows: [DiffLine]
    let theme: Theme
    let onClose: () -> Void

    private var additions: Int { rows.filter { $0.type == .add }.count }
    private var deletions: Int { rows.filter { $0.type == .del }.count }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(theme.border)
            columnHeader
            Divider().overlay(theme.border)
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(rows) { row in diffRow(row) }
                }
            }
            .background(theme.bg)
            Divider().overlay(theme.border)
            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.pane)
        .foregroundStyle(theme.text)
        .overlay {
            // Escape closes the diff.
            Button("", action: onClose)
                .keyboardShortcut(.cancelAction)
                .hidden()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("Diff  ·  Input A ↔ Input B")
                .font(.system(size: 12.5, weight: .semibold))
            Spacer()
            Text("+\(additions)  −\(deletions)")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(theme.muted)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 11))
                    .frame(width: 26, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.muted)
        }
        .padding(.horizontal, 16)
        .frame(height: 46)
        .background(theme.chrome)
    }

    private var columnHeader: some View {
        HStack(spacing: 0) {
            columnLabel("Input A")
            columnLabel("Input B").overlay(Rectangle().frame(width: 1).foregroundStyle(theme.border), alignment: .leading)
        }
        .background(theme.chrome)
    }

    private func columnLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .tracking(1.2)
            .foregroundStyle(theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12).padding(.vertical, 7)
    }

    private func diffRow(_ row: DiffLine) -> some View {
        HStack(spacing: 0) {
            cell(number: row.leftNumber,
                 sign: row.type == .del ? "−" : " ",
                 signColor: theme.null,
                 text: row.type == .add ? "" : row.text,
                 background: row.type == .del ? theme.null.opacity(0.13) : .clear)
            cell(number: row.rightNumber,
                 sign: row.type == .add ? "+" : " ",
                 signColor: theme.number,
                 text: row.type == .del ? "" : row.text,
                 background: row.type == .add ? theme.number.opacity(0.13) : .clear)
                .overlay(Rectangle().frame(width: 1).foregroundStyle(theme.border), alignment: .leading)
        }
        .font(.system(size: 12, design: .monospaced))
    }

    private func cell(number: Int?, sign: String, signColor: Color, text: String, background: Color) -> some View {
        HStack(spacing: 0) {
            Text(number.map(String.init) ?? "")
                .frame(width: 30, alignment: .trailing)
                .foregroundStyle(theme.gutter)
            Text(sign).frame(width: 14).foregroundStyle(signColor)
            Text(text)
                .foregroundStyle(theme.text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 8).padding(.vertical, 1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
    }

    private var footer: some View {
        Text("Line-by-line diff of the formatted JSON in each pane. Press ✕ or Esc to close.")
            .font(.system(size: 10.5))
            .foregroundStyle(theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16).padding(.vertical, 9)
            .background(theme.chrome)
    }
}
