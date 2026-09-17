import SwiftUI
import JSONKit

/// Observable app state. Single-input operations recompute live as you type;
/// `diff` is run on demand and shown in a sheet.
@MainActor
final class AppModel: ObservableObject {
    @Published var op: JSONKit.Operation = .format { didSet { showDiff = false; recompute() } }
    @Published var themeID: ThemeID = .midnight

    @Published var input: String = Samples.a { didSet { recompute() } }
    @Published var inputRight: String = Samples.b

    @Published private(set) var output: String = ""
    @Published private(set) var errorMessage: String? = nil

    @Published var showDiff = false
    @Published private(set) var diffLines: [DiffLine] = []

    /// Left pane's share of the split, as a fraction of total width. Clamped so
    /// neither pane collapses below a usable minimum (see RootView).
    @Published var splitFraction: Double = 0.5

    init() { recompute() }

    var theme: Theme { Theme.palette(themeID) }

    /// Recompute the output pane for the current single-input operation.
    func recompute() {
        guard !op.isDiff else { return }
        if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            output = ""; errorMessage = nil; return
        }
        do {
            output = try JSONTools.run(op, input: input)
            errorMessage = nil
        } catch {
            output = ""
            errorMessage = "\(error)"
        }
    }

    /// The primary action button. Runs diff or re-runs the current operation.
    func run() {
        if op.isDiff {
            diffLines = Differ.lineDiff(
                JSONTools.normalizedForDiff(input),
                JSONTools.normalizedForDiff(inputRight)
            )
            showDiff = true
        } else {
            recompute()
        }
    }

    func clearInput() {
        input = ""
    }

    func copyOutput() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(output, forType: .string)
    }

    // Status-bar helpers
    var lineCount: Int { input.isEmpty ? 0 : input.components(separatedBy: "\n").count }
    var charCount: Int { input.count }
    var isValid: Bool { errorMessage == nil }
}
