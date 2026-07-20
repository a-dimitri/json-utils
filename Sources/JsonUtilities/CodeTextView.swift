import SwiftUI
import AppKit
import JSONKit

/// A code editor backed by `NSTextView` — the native piece SwiftUI's `TextEditor`
/// can't provide: a line-number gutter (via `NSRulerView`) and live JSON syntax
/// highlighting. Used editable for the input panes and read-only for output.
struct CodeTextView: NSViewRepresentable {
    @Binding var text: String
    let themeID: ThemeID
    var isEditable: Bool

    static let editorFont: NSFont =
        NSFont(name: "JetBrains Mono", size: 12.5)
        ?? .monospacedSystemFont(ofSize: 12.5, weight: .regular)

    private var theme: Theme { Theme.palette(themeID) }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true

        // Build the text system manually so we control wrapping (off → horizontal
        // scroll) and can attach a ruler.
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(
            containerSize: NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = false
        layoutManager.addTextContainer(textContainer)

        let textView = NSTextView(frame: .zero, textContainer: textContainer)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.usesFindBar = true
        textView.smartInsertDeleteEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.textContainerInset = NSSize(width: 6, height: 10)
        textView.font = Self.editorFont
        textView.delegate = context.coordinator
        textView.string = text

        scrollView.documentView = textView

        let ruler = LineNumberRulerView(scrollView: scrollView, textView: textView,
                                        theme: theme, font: Self.editorFont)
        scrollView.verticalRulerView = ruler
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true

        context.coordinator.textView = textView
        context.coordinator.ruler = ruler
        context.coordinator.lastThemeID = themeID

        applyThemeChrome(scrollView: scrollView, textView: textView, ruler: ruler, theme: theme)
        Self.applyHighlight(textView, theme: theme, font: Self.editorFont)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = context.coordinator.textView,
              let ruler = context.coordinator.ruler else { return }
        let theme = self.theme

        textView.isEditable = isEditable

        // External change (clear, sample, mode switch) — replace text, don't fight typing.
        if textView.string != text {
            let selected = textView.selectedRange()
            textView.string = text
            let length = (text as NSString).length
            textView.setSelectedRange(NSRange(location: min(selected.location, length), length: 0))
            Self.applyHighlight(textView, theme: theme, font: Self.editorFont)
            ruler.needsDisplay = true
        }

        // Theme switch — restyle chrome and recolor tokens.
        if context.coordinator.lastThemeID != themeID {
            ruler.theme = theme
            applyThemeChrome(scrollView: scrollView, textView: textView, ruler: ruler, theme: theme)
            Self.applyHighlight(textView, theme: theme, font: Self.editorFont)
            context.coordinator.lastThemeID = themeID
            ruler.needsDisplay = true
        }
    }

    private func applyThemeChrome(scrollView: NSScrollView, textView: NSTextView,
                                  ruler: LineNumberRulerView, theme: Theme) {
        let pane = NSColor(theme.pane)
        scrollView.backgroundColor = pane
        textView.backgroundColor = pane
        textView.insertionPointColor = NSColor(theme.accent)
        textView.selectedTextAttributes = [.backgroundColor: NSColor(theme.accent).withAlphaComponent(0.25)]
    }

    /// Recolor the whole document from the tokenizer. Character offsets use
    /// UTF-16 (NSString) lengths so they line up with `NSTextStorage`.
    static func applyHighlight(_ textView: NSTextView, theme: Theme, font: NSFont) {
        guard let storage = textView.textStorage else { return }
        let text = textView.string
        let full = NSRange(location: 0, length: (text as NSString).length)
        storage.beginEditing()
        storage.setAttributes([.font: font, .foregroundColor: NSColor(theme.text)], range: full)
        var location = 0
        for token in Tokenizer.tokenize(text) {
            let length = (token.text as NSString).length
            if let color = nsColor(for: token.kind, theme: theme) {
                storage.addAttribute(.foregroundColor, value: color,
                                     range: NSRange(location: location, length: length))
            }
            location += length
        }
        storage.endEditing()
    }

    private static func nsColor(for kind: TokenKind, theme: Theme) -> NSColor? {
        switch kind {
        case .key:     return NSColor(theme.key)
        case .string:  return NSColor(theme.string)
        case .number:  return NSColor(theme.number)
        case .keyword: return NSColor(theme.boolean)
        case .null:    return NSColor(theme.null)
        case .punct:   return NSColor(theme.punct)
        case .plain:   return nil
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CodeTextView
        weak var textView: NSTextView?
        weak var ruler: LineNumberRulerView?
        var lastThemeID: ThemeID?

        init(_ parent: CodeTextView) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            CodeTextView.applyHighlight(textView, theme: Theme.palette(parent.themeID),
                                        font: CodeTextView.editorFont)
            ruler?.needsDisplay = true
        }
    }
}

/// Draws line numbers in the scroll view's vertical ruler, tracking the text
/// view's layout so numbers stay aligned through scrolling and wrapping.
final class LineNumberRulerView: NSRulerView {
    var theme: Theme
    private let numberFont: NSFont

    init(scrollView: NSScrollView, textView: NSTextView, theme: Theme, font: NSFont) {
        self.theme = theme
        self.numberFont = font
        super.init(scrollView: scrollView, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = 46
    }

    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = clientView as? NSTextView,
              let layoutManager = textView.layoutManager,
              let container = textView.textContainer else { return }

        NSColor(theme.pane).setFill()
        bounds.fill()

        let content = textView.string as NSString
        let inset = textView.textContainerInset.height
        let relativePoint = convert(NSPoint.zero, from: textView)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: numberFont,
            .foregroundColor: NSColor(theme.gutter),
        ]

        let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: textView.visibleRect, in: container)
        let firstVisibleCharIndex = layoutManager.characterIndexForGlyph(at: visibleGlyphRange.location)

        // Line number of the first visible line = newlines before it + 1.
        var lineNumber = 1
        var i = 0
        while i < firstVisibleCharIndex {
            if content.character(at: i) == 10 { lineNumber += 1 }
            i += 1
        }

        func draw(_ number: Int?, at fragmentRect: NSRect) {
            let string = (number.map(String.init) ?? "") as NSString
            guard string.length > 0 else { return }
            let size = string.size(withAttributes: attrs)
            let x = ruleThickness - size.width - 8
            let y = relativePoint.y + inset + fragmentRect.minY + (fragmentRect.height - size.height) / 2
            string.draw(at: NSPoint(x: x, y: y), withAttributes: attrs)
        }

        var glyphIndexForStringLine = visibleGlyphRange.location
        while glyphIndexForStringLine < NSMaxRange(visibleGlyphRange) {
            let charRange = content.lineRange(
                for: NSRange(location: layoutManager.characterIndexForGlyph(at: glyphIndexForStringLine), length: 0))
            let glyphRangeForLine = layoutManager.glyphRange(forCharacterRange: charRange, actualCharacterRange: nil)

            var glyphIndex = glyphIndexForStringLine
            var wrappedLineCount = 0
            while glyphIndex < NSMaxRange(glyphRangeForLine) {
                var effectiveRange = NSRange()
                let fragmentRect = layoutManager.lineFragmentRect(
                    forGlyphAt: glyphIndex, effectiveRange: &effectiveRange, withoutAdditionalLayout: true)
                // Only the first fragment of a logical line gets a number.
                draw(wrappedLineCount == 0 ? lineNumber : nil, at: fragmentRect)
                wrappedLineCount += 1
                glyphIndex = NSMaxRange(effectiveRange)
            }
            glyphIndexForStringLine = NSMaxRange(glyphRangeForLine)
            lineNumber += 1
        }

        // The empty line after a trailing newline.
        if layoutManager.extraLineFragmentTextContainer != nil {
            draw(lineNumber, at: layoutManager.extraLineFragmentRect)
        }
    }
}
