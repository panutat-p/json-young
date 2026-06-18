import Testing
@testable import JSONLinterLib

@Test func lintValidObject() {
    let result = JSONLinter.lint(#"{"name":"Alice","items":[1,2,3]}"#)
    #expect(result.status == .valid)
}

@Test func lintInvalidJSON() {
    let result = JSONLinter.lint(#"{"name":}"#)
    guard case .invalid = result.status else {
        Issue.record("Expected invalid status for malformed JSON")
        return
    }
}

@Test func lintEmptyStringIsNeutral() {
    let result = JSONLinter.lint("")
    #expect(result.status == .neutral)
}

@Test func lintWhitespaceOnlyIsNeutral() {
    let result = JSONLinter.lint("   \n\t  ")
    #expect(result.status == .neutral)
}

@Test func lintJSONFragments() {
    #expect(JSONLinter.lint("true").status == .valid)
    #expect(JSONLinter.lint(#""hello""#).status == .valid)
    #expect(JSONLinter.lint("null").status == .valid)
    #expect(JSONLinter.lint("42").status == .valid)
}

@Test func formatValidObject() throws {
    let formatted = try JSONLinter.format(#"{"b":2,"a":1}"#)
    #expect(formatted.contains("\"a\""))
    #expect(formatted.contains("\"b\""))
    #expect(formatted.contains("\n"))
}

@Test func formatPreservesKeyOrder() throws {
    let formatted = try JSONLinter.format(#"{"z":1,"a":2,"m":3}"#)
    let zRange = formatted.range(of: "\"z\"")
    let aRange = formatted.range(of: "\"a\"")
    let mRange = formatted.range(of: "\"m\"")
    #expect(zRange != nil)
    #expect(aRange != nil)
    #expect(mRange != nil)
    if let zRange, let aRange, let mRange {
        #expect(zRange.lowerBound < aRange.lowerBound)
        #expect(aRange.lowerBound < mRange.lowerBound)
    }
}

@Test func formatInvalidJSONThrows() {
    #expect(throws: JSONLinterError.self) {
        _ = try JSONLinter.format(#"{"broken":}"#)
    }
}

@Test func formatEmptyInputThrows() {
    #expect(throws: JSONLinterError.self) {
        _ = try JSONLinter.format("")
    }
}

@Test func formatJSONFragment() throws {
    let formatted = try JSONLinter.format(#""hello""#)
    #expect(formatted == "\"hello\"")
}

@Test func lintSmartQuotesAreAccepted() {
    let json = """
    {
      "kyc" : {
        "factor" : \u{201C}B\u{201D},
        "level" : "3"
      }
    }
    """
    #expect(JSONLinter.lint(json).status == .valid)
}

@Test func formatSmartQuotesAreNormalized() throws {
    let json = #"{"factor":\#(String(UnicodeScalar(0x201C)!))B\#(String(UnicodeScalar(0x201D)!))}"#
    let formatted = try JSONLinter.format(json)
    #expect(formatted.contains("\"B\""))
    #expect(!formatted.contains(String(UnicodeScalar(0x201C)!)))
}
