import Foundation

/// A parse failure with a human-readable message and 1-based position.
public struct JSONError: Error, CustomStringConvertible {
    public let message: String
    public let line: Int
    public let column: Int
    public var description: String { "\(message) (line \(line), column \(column))" }
}

/// A small recursive-descent JSON parser that produces an order-preserving
/// `JSONValue`. Deliberately hand-rolled so object key order and number lexemes
/// are preserved exactly (see `JSONValue`).
public struct JSONParser {
    private let chars: [Character]
    private var i = 0
    private var line = 1
    private var col = 1

    private init(_ s: String) { chars = Array(s) }

    public static func parse(_ s: String) throws -> JSONValue {
        var p = JSONParser(s)
        p.skipWhitespace()
        let value = try p.parseValue()
        p.skipWhitespace()
        if p.i < p.chars.count { throw p.error("Unexpected trailing characters") }
        return value
    }

    // MARK: - Cursor helpers

    private func peek() -> Character? { i < chars.count ? chars[i] : nil }

    @discardableResult
    private mutating func advance() -> Character {
        let c = chars[i]
        i += 1
        if c == "\n" { line += 1; col = 1 } else { col += 1 }
        return c
    }

    private mutating func skipWhitespace() {
        while let c = peek(), c == " " || c == "\n" || c == "\t" || c == "\r" {
            advance()
        }
    }

    private func error(_ message: String) -> JSONError {
        JSONError(message: message, line: line, column: col)
    }

    private func isDigit(_ c: Character) -> Bool { c >= "0" && c <= "9" }

    // MARK: - Grammar

    private mutating func parseValue() throws -> JSONValue {
        skipWhitespace()
        guard let c = peek() else { throw error("Unexpected end of input") }
        switch c {
        case "{": return try parseObject()
        case "[": return try parseArray()
        case "\"": return .string(try parseString())
        case "t", "f": return try parseKeyword()
        case "n": return try parseNull()
        default:
            if c == "-" || isDigit(c) { return .number(try parseNumber()) }
            throw error("Unexpected character '\(c)'")
        }
    }

    private mutating func parseObject() throws -> JSONValue {
        advance() // consume '{'
        var pairs: [(key: String, value: JSONValue)] = []
        skipWhitespace()
        if peek() == "}" { advance(); return .object(pairs) }
        while true {
            skipWhitespace()
            guard peek() == "\"" else { throw error("Expected string key in object") }
            let key = try parseString()
            skipWhitespace()
            guard peek() == ":" else { throw error("Expected ':' after object key") }
            advance()
            let value = try parseValue()
            pairs.append((key, value))
            skipWhitespace()
            switch peek() {
            case ",": advance(); continue
            case "}": advance(); return .object(pairs)
            default: throw error("Expected ',' or '}' in object")
            }
        }
    }

    private mutating func parseArray() throws -> JSONValue {
        advance() // consume '['
        var items: [JSONValue] = []
        skipWhitespace()
        if peek() == "]" { advance(); return .array(items) }
        while true {
            let value = try parseValue()
            items.append(value)
            skipWhitespace()
            switch peek() {
            case ",": advance(); continue
            case "]": advance(); return .array(items)
            default: throw error("Expected ',' or ']' in array")
            }
        }
    }

    private mutating func parseString() throws -> String {
        advance() // consume opening quote
        var out = ""
        while true {
            guard i < chars.count else { throw error("Unterminated string") }
            let c = advance()
            if c == "\"" { return out }
            if c == "\\" {
                guard i < chars.count else { throw error("Unterminated escape sequence") }
                let e = advance()
                switch e {
                case "\"": out.append("\"")
                case "\\": out.append("\\")
                case "/": out.append("/")
                case "n": out.append("\n")
                case "t": out.append("\t")
                case "r": out.append("\r")
                case "b": out.append("\u{08}")
                case "f": out.append("\u{0C}")
                case "u": out.unicodeScalars.append(try parseUnicodeEscape())
                default: throw error("Invalid escape '\\\(e)'")
                }
            } else {
                out.append(c)
            }
        }
    }

    /// Parses the 4 hex digits after `\u`, handling UTF-16 surrogate pairs.
    private mutating func parseUnicodeEscape() throws -> Unicode.Scalar {
        let high = try readHex4()
        if high >= 0xD800 && high <= 0xDBFF {
            guard peek() == "\\" else { throw error("Expected low surrogate") }
            advance()
            guard peek() == "u" else { throw error("Expected low surrogate") }
            advance()
            let low = try readHex4()
            guard low >= 0xDC00 && low <= 0xDFFF else { throw error("Invalid low surrogate") }
            let combined = 0x10000 + ((high - 0xD800) << 10) + (low - 0xDC00)
            guard let scalar = Unicode.Scalar(combined) else { throw error("Invalid surrogate pair") }
            return scalar
        }
        guard let scalar = Unicode.Scalar(high) else { throw error("Invalid unicode scalar") }
        return scalar
    }

    private mutating func readHex4() throws -> UInt32 {
        var hex = ""
        for _ in 0..<4 {
            guard i < chars.count else { throw error("Incomplete unicode escape") }
            hex.append(advance())
        }
        guard let value = UInt32(hex, radix: 16) else { throw error("Invalid unicode escape '\\u\(hex)'") }
        return value
    }

    private mutating func parseNumber() throws -> String {
        var s = ""
        if peek() == "-" { s.append(advance()) }
        while let c = peek(), isDigit(c) { s.append(advance()) }
        if peek() == "." {
            s.append(advance())
            while let c = peek(), isDigit(c) { s.append(advance()) }
        }
        if let c = peek(), c == "e" || c == "E" {
            s.append(advance())
            if let sign = peek(), sign == "+" || sign == "-" { s.append(advance()) }
            while let c = peek(), isDigit(c) { s.append(advance()) }
        }
        // Reject "-" alone or a bare exponent with no mantissa digits.
        if s.isEmpty || s == "-" || !s.contains(where: isDigit) { throw error("Invalid number") }
        return s
    }

    private mutating func parseKeyword() throws -> JSONValue {
        if match("true") { return .bool(true) }
        if match("false") { return .bool(false) }
        throw error("Invalid literal")
    }

    private mutating func parseNull() throws -> JSONValue {
        if match("null") { return .null }
        throw error("Invalid literal")
    }

    private mutating func match(_ word: String) -> Bool {
        let w = Array(word)
        guard i + w.count <= chars.count else { return false }
        for k in 0..<w.count where chars[i + k] != w[k] { return false }
        for _ in 0..<w.count { advance() }
        return true
    }
}
