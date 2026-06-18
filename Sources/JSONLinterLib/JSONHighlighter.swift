import Foundation

public enum JSONTokenKind: Equatable, Sendable {
    case key
    case string
    case number
    case boolean
    case null
    case punctuation
    case whitespace
    case other
}

public struct JSONToken: Equatable, Sendable {
    public let range: Range<String.Index>
    public let kind: JSONTokenKind

    public init(range: Range<String.Index>, kind: JSONTokenKind) {
        self.range = range
        self.kind = kind
    }
}

public enum JSONHighlighter {
    public static func tokenize(_ text: String) -> [JSONToken] {
        guard !text.isEmpty else { return [] }

        var tokens: [JSONToken] = []
        var index = text.startIndex

        while index < text.endIndex {
            let start = index
            let character = text[index]

            if character.isWhitespace {
                index = text.index(after: index)
                while index < text.endIndex, text[index].isWhitespace {
                    index = text.index(after: index)
                }
                tokens.append(JSONToken(range: start..<index, kind: .whitespace))
                continue
            }

            switch character {
            case "{", "}", "[", "]", ":", ",":
                index = text.index(after: index)
                tokens.append(JSONToken(range: start..<index, kind: .punctuation))
            case "\"":
                guard let stringEnd = endOfJSONString(startingAt: index, in: text) else {
                    index = text.index(after: index)
                    tokens.append(JSONToken(range: start..<index, kind: .other))
                    continue
                }

                let kind: JSONTokenKind = isObjectKey(endingAt: stringEnd, in: text) ? .key : .string
                tokens.append(JSONToken(range: start..<stringEnd, kind: kind))
                index = stringEnd
            case "-", "0"..."9":
                let numberEnd = endOfNumber(startingAt: index, in: text)
                tokens.append(JSONToken(range: start..<numberEnd, kind: .number))
                index = numberEnd
            case "t":
                if let end = endOfLiteral("true", startingAt: index, in: text) {
                    tokens.append(JSONToken(range: start..<end, kind: .boolean))
                    index = end
                } else {
                    index = text.index(after: index)
                    tokens.append(JSONToken(range: start..<index, kind: .other))
                }
            case "f":
                if let end = endOfLiteral("false", startingAt: index, in: text) {
                    tokens.append(JSONToken(range: start..<end, kind: .boolean))
                    index = end
                } else {
                    index = text.index(after: index)
                    tokens.append(JSONToken(range: start..<index, kind: .other))
                }
            case "n":
                if let end = endOfLiteral("null", startingAt: index, in: text) {
                    tokens.append(JSONToken(range: start..<end, kind: .null))
                    index = end
                } else {
                    index = text.index(after: index)
                    tokens.append(JSONToken(range: start..<index, kind: .other))
                }
            default:
                index = text.index(after: index)
                tokens.append(JSONToken(range: start..<index, kind: .other))
            }
        }

        return tokens
    }

    private static func endOfJSONString(startingAt start: String.Index, in text: String) -> String.Index? {
        guard text[start] == "\"" else { return nil }

        var index = text.index(after: start)
        var isEscaped = false

        while index < text.endIndex {
            let character = text[index]

            if isEscaped {
                isEscaped = false
            } else if character == "\\" {
                isEscaped = true
            } else if character == "\"" {
                return text.index(after: index)
            }

            index = text.index(after: index)
        }

        return text.endIndex
    }

    private static func isObjectKey(endingAt stringEnd: String.Index, in text: String) -> Bool {
        var index = stringEnd
        while index < text.endIndex, text[index].isWhitespace {
            index = text.index(after: index)
        }
        return index < text.endIndex && text[index] == ":"
    }

    private static func endOfNumber(startingAt start: String.Index, in text: String) -> String.Index {
        var index = start

        if text[index] == "-" {
            index = text.index(after: index)
            guard index < text.endIndex else { return index }
        }

        if text[index] == "0" {
            index = text.index(after: index)
        } else if text[index].isNumber {
            while index < text.endIndex, text[index].isNumber {
                index = text.index(after: index)
            }
        } else {
            return text.index(after: start)
        }

        if index < text.endIndex, text[index] == "." {
            index = text.index(after: index)
            while index < text.endIndex, text[index].isNumber {
                index = text.index(after: index)
            }
        }

        if index < text.endIndex, text[index] == "e" || text[index] == "E" {
            index = text.index(after: index)
            if index < text.endIndex, text[index] == "+" || text[index] == "-" {
                index = text.index(after: index)
            }
            while index < text.endIndex, text[index].isNumber {
                index = text.index(after: index)
            }
        }

        return index
    }

    private static func endOfLiteral(
        _ literal: String,
        startingAt start: String.Index,
        in text: String
    ) -> String.Index? {
        var index = start
        for character in literal {
            guard index < text.endIndex, text[index] == character else { return nil }
            index = text.index(after: index)
        }

        if index < text.endIndex, isJSONLiteralContinuation(text[index]) {
            return nil
        }

        return index
    }

    private static func isJSONLiteralContinuation(_ character: Character) -> Bool {
        character.isLetter || character.isNumber || character == "_" || character == "-"
    }
}
