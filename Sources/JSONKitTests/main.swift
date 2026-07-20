import JSONKit

// A minimal assertion-based test runner. XCTest is unavailable under the
// Command Line Tools toolchain, so we run checks and exit non-zero on failure.
//   swift run JSONKitTests

var failures = 0
var passed = 0

func check(_ name: String, _ condition: Bool) {
    if condition { passed += 1 }
    else { failures += 1; print("FAIL - \(name)") }
}

func checkEqual(_ name: String, _ got: String, _ want: String) {
    if got == want { passed += 1 }
    else {
        failures += 1
        print("FAIL - \(name)")
        print("  got:  \(got.debugDescription)")
        print("  want: \(want.debugDescription)")
    }
}

func run(_ op: Operation, _ input: String) -> String {
    (try? JSONTools.run(op, input: input)) ?? "<error>"
}

// MARK: - Order & fidelity

checkEqual("format preserves key order",
    run(.format, #"{"b":1,"a":2}"#),
    "{\n  \"b\": 1,\n  \"a\": 2\n}")

checkEqual("format preserves number lexeme",
    run(.format, #"{"x":98.60}"#),
    "{\n  \"x\": 98.60\n}")

checkEqual("minify strips whitespace",
    run(.minify, "{\n  \"a\" : [1, 2, 3]\n}"),
    #"{"a":[1,2,3]}"#)

checkEqual("empty containers",
    run(.format, #"{"a":[],"b":{}}"#),
    "{\n  \"a\": [],\n  \"b\": {}\n}")

// MARK: - Marshal / unmarshal

checkEqual("marshal encodes minified JSON as a string",
    run(.marshal, #"{"a":1}"#),
    #""{\"a\":1}""#)

checkEqual("unmarshal decodes a JSON string value",
    run(.unmarshal, #""{\"a\":1}""#),
    "{\n  \"a\": 1\n}")

checkEqual("deep unmarshal untangles nested stringified JSON",
    run(.deepUnmarshal, #"{"meta":"{\"k\":true}"}"#),
    "{\n  \"meta\": {\n    \"k\": true\n  }\n}")

// MARK: - Errors

check("invalid JSON throws", (try? JSONTools.run(.format, input: "{oops}")) == nil)
check("trailing characters rejected", (try? JSONParser.parse("{} junk")) == nil)

// MARK: - Escapes / unicode

checkEqual("unicode escape decodes and re-encodes as literal",
    run(.minify, #"{"s":"abc"}"#),
    #"{"s":"abc"}"#)

checkEqual("control chars re-escaped on output",
    run(.minify, "{\"s\":\"a\\nb\"}"),
    #"{"s":"a\nb"}"#)

// MARK: - Diff

do {
    let rows = Differ.lineDiff("a\nb\nc", "a\nx\nc")
    let types = rows.map { $0.type }
    check("diff keeps common lines and marks the change",
        types.filter { $0 == .same }.count == 2 &&
        types.contains(.del) && types.contains(.add))
}

// MARK: - Tokenizer

do {
    let tokens = Tokenizer.tokenize(#"{"k": 12, "b": true}"#)
    let reconstructed = tokens.map { $0.text }.joined()
    check("tokenizer round-trips the input", reconstructed == #"{"k": 12, "b": true}"#)
    check("tokenizer tags a key", tokens.contains { $0.kind == .key && $0.text == "\"k\"" })
    check("tokenizer tags a number", tokens.contains { $0.kind == .number && $0.text == "12" })
    check("tokenizer tags a keyword", tokens.contains { $0.kind == .keyword && $0.text == "true" })
}

// MARK: - Summary

print("\n\(passed) passed, \(failures) failed")
if failures > 0 { exit(1) }
