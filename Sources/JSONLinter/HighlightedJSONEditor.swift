import AppKit
import JSONLinterLib
import SwiftUI

struct HighlightedJSONEditor: NSViewRepresentable {
    @Binding var text: String
    var onTextChange: () -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.textContainerInset = NSSize(width: 0, height: 0)
        textView.string = text

        context.coordinator.textView = textView
        context.coordinator.applyHighlighting()

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
            context.coordinator.applyHighlighting()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: HighlightedJSONEditor
        weak var textView: NSTextView?

        init(parent: HighlightedJSONEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            applyHighlighting()
            parent.onTextChange()
        }

        func applyHighlighting() {
            guard let textView else { return }

            let content = textView.string
            guard let textStorage = textView.textStorage else { return }

            let fullRange = NSRange(location: 0, length: (content as NSString).length)
            let selectedRanges = textView.selectedRanges
            let font = textView.font ?? NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

            textStorage.beginEditing()
            textStorage.setAttributes(
                [
                    .font: font,
                    .foregroundColor: NSColor.labelColor
                ],
                range: fullRange
            )

            for token in JSONHighlighter.tokenize(content) {
                guard let range = token.range.nsRange(in: content) else { continue }
                guard let color = Self.color(for: token.kind) else { continue }
                textStorage.addAttribute(.foregroundColor, value: color, range: range)
            }

            textStorage.endEditing()
            textView.selectedRanges = selectedRanges
        }

        private static func color(for kind: JSONTokenKind) -> NSColor? {
            switch kind {
            case .key:
                return NSColor.systemIndigo
            case .string:
                return NSColor.systemGreen
            case .number:
                return NSColor.systemTeal
            case .boolean, .null:
                return NSColor.systemPurple
            case .punctuation:
                return NSColor.secondaryLabelColor
            case .whitespace, .other:
                return nil
            }
        }
    }
}

private extension Range where Bound == String.Index {
    func nsRange(in text: String) -> NSRange? {
        guard let lower = lowerBound.samePosition(in: text.utf16),
              let upper = upperBound.samePosition(in: text.utf16) else {
            return nil
        }

        let location = text.utf16.distance(from: text.utf16.startIndex, to: lower)
        let length = text.utf16.distance(from: lower, to: upper)
        return NSRange(location: location, length: length)
    }
}
