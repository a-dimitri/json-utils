import SwiftUI
import AppKit

/// A transparent AppKit layer for the diff overlay's backdrop. It forces the
/// arrow pointer within its bounds — SwiftUI can't reset the cursor before
/// macOS 15, so without this the editors' I-beam bleeds through the dimmed area —
/// and reports a click so tapping outside the modal dismisses it.
@MainActor
struct ArrowCursorBackdrop: NSViewRepresentable {
    var onClick: () -> Void

    func makeNSView(context: Context) -> NSView { CursorView(onClick: onClick) }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? CursorView)?.onClick = onClick
    }

    final class CursorView: NSView {
        var onClick: () -> Void

        init(onClick: @escaping () -> Void) {
            self.onClick = onClick
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func resetCursorRects() {
            addCursorRect(bounds, cursor: .arrow)
        }

        override func cursorUpdate(with event: NSEvent) {
            NSCursor.arrow.set()
        }

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            trackingAreas.forEach(removeTrackingArea)
            addTrackingArea(NSTrackingArea(
                rect: .zero,
                options: [.activeInActiveApp, .inVisibleRect, .cursorUpdate],
                owner: self))
        }

        override func mouseDown(with event: NSEvent) {
            onClick()
        }
    }
}
