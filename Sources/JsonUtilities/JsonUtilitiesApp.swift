import SwiftUI
import JSONKit

@main
@MainActor
struct JsonUtilitiesApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("JSON Utilities") {
            RootView()
                .environmentObject(model)
                .frame(minWidth: 760, minHeight: 480)
        }
        .windowResizability(.contentMinSize)
        .commands {
            // Keyboard-driven, snappy operation switching.
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Operation") {
                Button("Run") { model.run() }
                    .keyboardShortcut(.return, modifiers: .command)
                Divider()
                ForEach(Array(JSONKit.Operation.allCases.enumerated()), id: \.element.id) { index, op in
                    Button(op.label) { model.op = op }
                        .keyboardShortcut(KeyEquivalent("\(index + 1)".first!), modifiers: .command)
                }
            }
        }
    }
}

/// Under a bare `swift run` (no .app bundle), the process launches as a
/// background agent by default. Promote it to a regular foreground app so the
/// window appears and takes focus.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
