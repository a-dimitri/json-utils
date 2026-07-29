import SwiftUI
import AppKit

/// Find / Find & Replace menu items (Cmd+F, etc.) that drive the focused editor's
/// built-in `NSTextView` find bar. Works in whichever pane is focused; NSTextView
/// enables the replace actions only when that text view is editable — so replace
/// is available on the left input (and both inputs in diff mode) but not the
/// read-only output.
struct FindCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .textEditing) {
            Section {
                Button("Find…") { Self.perform(.showFindInterface) }
                    .keyboardShortcut("f", modifiers: .command)
                Button("Find and Replace…") { Self.perform(.showReplaceInterface) }
                    .keyboardShortcut("f", modifiers: [.command, .option])
                Button("Find Next") { Self.perform(.nextMatch) }
                    .keyboardShortcut("g", modifiers: .command)
                Button("Find Previous") { Self.perform(.previousMatch) }
                    .keyboardShortcut("g", modifiers: [.command, .shift])
            }
        }
    }

    /// Routes a text-finder action to the focused `NSTextView`. AppKit reads the
    /// requested action from the sender's `tag`, so we pass it via a menu item.
    /// Command actions run on the main thread, so hopping there is safe.
    static func perform(_ action: NSTextFinder.Action) {
        MainActor.assumeIsolated {
            let sender = NSMenuItem()
            sender.tag = action.rawValue
            NSApp.sendAction(#selector(NSTextView.performTextFinderAction(_:)), to: nil, from: sender)
        }
    }
}
