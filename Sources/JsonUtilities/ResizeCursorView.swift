import SwiftUI
import AppKit

/// Forces the left-right resize cursor within its bounds via an AppKit tracking
/// area. SwiftUI's `.onHover` + `NSCursor.push()/pop()` drops enter/leave events
/// (and loses to the adjacent NSTextViews' I-beam), so cursor management is done
/// by AppKit here, where it reliably competes with neighbouring cursor rects.
struct ResizeCursorView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { CursorView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    final class CursorView: NSView {
        override func resetCursorRects() {
            addCursorRect(bounds, cursor: .resizeLeftRight)
        }

        override func cursorUpdate(with event: NSEvent) {
            NSCursor.resizeLeftRight.set()
        }

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            trackingAreas.forEach(removeTrackingArea)
            addTrackingArea(NSTrackingArea(
                rect: .zero,
                options: [.activeInActiveApp, .inVisibleRect, .cursorUpdate],
                owner: self))
        }

        // Let clicks/drags pass through to the SwiftUI drag gesture underneath.
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
    }
}
