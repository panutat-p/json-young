import Foundation

public struct JSONLintResult: Equatable, Sendable {
    public enum Status: Equatable, Sendable {
        case neutral
        case valid
        case invalid(message: String)
    }

    public let status: Status

    public init(status: Status) {
        self.status = status
    }
}

public enum JSONLinterError: LocalizedError, Equatable, Sendable {
    case emptyInput
    case invalidJSON(String)

    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Input is empty."
        case .invalidJSON(let message):
            return message
        }
    }
}

public enum JSONLinter {
    private static let parseOptions: JSONSerialization.ReadingOptions = [.fragmentsAllowed]
    private static let smartDoubleQuotes: Set<Character> = [
        "\u{201C}", "\u{201D}", "\u{201E}", "\u{201F}", "\u{FF02}"
    ]

    public static func lint(_ text: String) -> JSONLintResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return JSONLintResult(status: .neutral)
        }

        do {
            _ = try parse(trimmed)
            return JSONLintResult(status: .valid)
        } catch {
            return JSONLintResult(status: .invalid(message: errorMessage(from: error)))
        }
    }

    public static func format(_ text: String, sortedKeys: Bool = false) throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw JSONLinterError.emptyInput
        }

        let object: Any
        do {
            object = try parse(trimmed)
        } catch {
            throw JSONLinterError.invalidJSON(errorMessage(from: error))
        }

        var writeOptions: JSONSerialization.WritingOptions = [.prettyPrinted]
        if sortedKeys {
            writeOptions.insert(.sortedKeys)
        }

        let data: Data
        if JSONSerialization.isValidJSONObject(object) {
            data = try JSONSerialization.data(withJSONObject: object, options: writeOptions)
        } else {
            data = try JSONSerialization.data(withJSONObject: [object], options: writeOptions)
            guard let wrapped = String(data: data, encoding: .utf8) else {
                throw JSONLinterError.invalidJSON("Unable to encode formatted JSON as UTF-8.")
            }
            return unwrapSingleElementArray(wrapped)
        }

        guard let formatted = String(data: data, encoding: .utf8) else {
            throw JSONLinterError.invalidJSON("Unable to encode formatted JSON as UTF-8.")
        }

        return formatted
    }

    private static func unwrapSingleElementArray(_ wrapped: String) -> String {
        var lines = wrapped.split(separator: "\n", omittingEmptySubsequences: false)
        if let first = lines.first, first.trimmingCharacters(in: .whitespaces) == "[" {
            lines.removeFirst()
        }
        if let last = lines.last, last.trimmingCharacters(in: .whitespaces) == "]" {
            lines.removeLast()
        }

        let dedented = lines.map { line -> String in
            if line.hasPrefix("  ") {
                return String(line.dropFirst(2))
            }
            return String(line)
        }

        return dedented.joined(separator: "\n")
    }

    private static func parse(_ text: String) throws -> Any {
        guard let data = text.data(using: .utf8) else {
            throw JSONLinterError.invalidJSON("Input is not valid UTF-8.")
        }

        do {
            return try JSONSerialization.jsonObject(with: data, options: parseOptions)
        } catch let originalError {
            if containsSmartDoubleQuotes(text) {
                let normalized = normalizeSmartDoubleQuotes(text)
                if normalized != text,
                   let normalizedData = normalized.data(using: .utf8) {
                    do {
                        return try JSONSerialization.jsonObject(with: normalizedData, options: parseOptions)
                    } catch {
                        throw JSONLinterError.invalidJSON(
                            errorMessage(from: originalError, text: text)
                        )
                    }
                }
            }

            throw JSONLinterError.invalidJSON(errorMessage(from: originalError, text: text))
        }
    }

    private static func containsSmartDoubleQuotes(_ text: String) -> Bool {
        text.contains { smartDoubleQuotes.contains($0) }
    }

    private static func normalizeSmartDoubleQuotes(_ text: String) -> String {
        String(text.map { smartDoubleQuotes.contains($0) ? "\"" : $0 })
    }

    private static func errorMessage(from error: Error, text: String) -> String {
        let message: String
        if let linterError = error as? JSONLinterError,
           let description = linterError.errorDescription {
            message = description
        } else {
            let nsError = error as NSError
            if let debugDescription = nsError.userInfo["NSDebugDescription"] as? String,
               !debugDescription.isEmpty {
                message = debugDescription
            } else {
                message = nsError.localizedDescription
            }
        }

        if containsSmartDoubleQuotes(text) {
            return message + " Replace curly quotes (“ ”) with straight quotes (\")."
        }

        return message
    }

    private static func errorMessage(from error: Error) -> String {
        errorMessage(from: error, text: "")
    }
}
