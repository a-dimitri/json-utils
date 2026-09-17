import SwiftUI
import AppKit

/// The interactive split divider, done entirely in AppKit.
///
/// Mixing a SwiftUI `DragGesture` with an AppKit cursor view doesn't work: AppKit
/// only delivers `cursorUpdate` to a view that is hittable, but a hittable NSView
/// swallows the mouse events the SwiftUI gesture needs. So this single NSView owns
/// both — it shows the resize cursor via a tracking area *and* handles the drag,
/// reporting the new split fraction back to the model.
struct NativeSplitHandle: NSViewRepresentable {
    var fraction: Double
    var usableWidth: CGFloat
    var minPaneWidth: CGFloat
    var setFraction: (Double) -> Void

    func makeNSView(context: Context) -> HandleView { HandleView() }

    func updateNSView(_ view: HandleView, context: Context) {
        view.fraction = fraction
        view.usableWidth = usableWidth
        view.minPaneWidth = minPaneWidth
        view.setFraction = setFraction
    }

    final class HandleView: NSView {
        var fraction: Double = 0.5
        var usableWidth: CGFloat = 0
        var minPaneWidth: CGFloat = 220
        var setFraction: (Double) -> Void = { _ in }

        private var dragStartX: CGFloat = 0
        private var dragStartLeft: CGFloat = 0

        // MARK: Cursor

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

        // MARK: Drag

        // Allow starting a drag even when the window isn't yet key.
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

        override func mouseDown(with event: NSEvent) {
            dragStartX = event.locationInWindow.x
            dragStartLeft = CGFloat(fraction) * usableWidth
        }

        override func mouseDragged(with event: NSEvent) {
            guard usableWidth > 0 else { return }
            let delta = event.locationInWindow.x - dragStartX
            let upper = max(minPaneWidth, usableWidth - minPaneWidth)
            let newLeft = min(max(dragStartLeft + delta, minPaneWidth), upper)
            setFraction(Double(newLeft / usableWidth))
        }
    }
}
