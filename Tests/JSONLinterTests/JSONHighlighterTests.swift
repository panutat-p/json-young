import Testing
@testable import JSONLinterLib

@Test func tokenizeObjectWithMixedTypes() {
    let json = #"{"name":"Alice","count":42,"active":true,"value":null}"#
    let kinds = JSONHighlighter.tokenize(json).map(\.kind)

    #expect(kinds.contains(.key))
    #expect(kinds.contains(.string))
    #expect(kinds.contains(.number))
    #expect(kinds.contains(.boolean))
    #expect(kinds.contains(.null))
    #expect(kinds.contains(.punctuation))
}

@Test func tokenizeDistinguishesKeysFromStringValues() {
    let json = #"{"key":"value"}"#
    let tokens = JSONHighlighter.tokenize(json)

    let keyToken = tokens.first { token in
        String(json[token.range]) == "\"key\""
    }
    let valueToken = tokens.first { token in
        String(json[token.range]) == "\"value\""
    }

    #expect(keyToken?.kind == .key)
    #expect(valueToken?.kind == .string)
}

@Test func tokenizeStringFragment() {
    let json = #""hello""#
    let tokens = JSONHighlighter.tokenize(json)

    #expect(tokens.count == 1)
    #expect(tokens[0].kind == .string)
    #expect(String(json[tokens[0].range]) == #""hello""#)
}

@Test func tokenizeNumberFragment() {
    let tokens = JSONHighlighter.tokenize("-12.5e+3")
    #expect(tokens.count == 1)
    #expect(tokens[0].kind == .number)
}

@Test func tokenizeBooleanAndNullFragments() {
    #expect(JSONHighlighter.tokenize("true").map(\.kind) == [.boolean])
    #expect(JSONHighlighter.tokenize("false").map(\.kind) == [.boolean])
    #expect(JSONHighlighter.tokenize("null").map(\.kind) == [.null])
}

@Test func tokenizeEscapedQuotesInsideStrings() {
    let json = #"{"message":"say \"hi\""}"#
    let tokens = JSONHighlighter.tokenize(json)

    let messageToken = tokens.first { token in
        String(json[token.range]).hasPrefix("\"message\"")
    }
    let valueToken = tokens.first { token in
        String(json[token.range]).contains("say")
    }

    #expect(messageToken?.kind == .key)
    #expect(valueToken?.kind == .string)
}

@Test func tokenizeInvalidJSONStillProducesTokens() {
    let json = #"{"broken":}"#
    let tokens = JSONHighlighter.tokenize(json)

    #expect(!tokens.isEmpty)
    #expect(tokens.contains { $0.kind == .key })
    #expect(tokens.contains { $0.kind == .punctuation })
}

@Test func tokenizeWhitespaceTokens() {
    let json = "{\n  \"a\": 1\n}"
    let tokens = JSONHighlighter.tokenize(json)

    #expect(tokens.contains { $0.kind == .whitespace })
}
