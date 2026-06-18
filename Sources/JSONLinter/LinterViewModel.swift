import Foundation
import JSONLinterLib
import Observation

@Observable
@MainActor
final class LinterViewModel {
    var text = ""
    var status: JSONLintResult.Status = .neutral
    var isFormatting = false

    private var lintTask: Task<Void, Never>?

    var canFormat: Bool {
        switch status {
        case .valid:
            return !isFormatting
        case .neutral, .invalid:
            return false
        }
    }

    var footerMessage: String {
        switch status {
        case .neutral:
            return "Enter JSON to validate and format."
        case .valid:
            return "Valid JSON"
        case .invalid(let message):
            return message
        }
    }

    var statusBadgeText: String {
        switch status {
        case .neutral:
            return "Ready"
        case .valid:
            return "Valid"
        case .invalid:
            return "Invalid"
        }
    }

    func textDidChange() {
        lintTask?.cancel()
        lintTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            status = JSONLinter.lint(text).status
        }
    }

    func format() {
        guard canFormat else { return }

        isFormatting = true
        defer { isFormatting = false }

        do {
            text = try JSONLinter.format(text)
            status = .valid
        } catch {
            status = .invalid(message: error.localizedDescription)
        }
    }

    func clear() {
        lintTask?.cancel()
        text = ""
        status = .neutral
    }
}
