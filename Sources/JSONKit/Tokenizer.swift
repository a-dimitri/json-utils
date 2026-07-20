import Foundation

public enum TokenKind: Sendable {
    case key        // "name":
    case string     // string value
    case number
    case keyword    // true / false
    case null
    case punct      // { } [ ] , :
    case plain      // whitespace / anything else
}

public struct Token: Sendable {
    public let text: String
    public let kind: TokenKind
}

/// Splits JSON-ish text into coloured tokens. Tolerant of partial/invalid input
/// so it can highlight while the user is still typing. Concatenating the token
/// texts reproduces the input exactly.
public enum Tokenizer {
    public static func tokenize(_ s: String) -> [Token] {
        let chars = Array(s)
        let n = chars.count
        var tokens: [Token] = []
        var plain = ""
        var i = 0

        func flushPlain() {
            if !plain.isEmpty { tokens.append(Token(text: plain, kind: .plain)); plain = "" }
        }
        func isDigit(_ c: Character) -> Bool { c >= "0" && c <= "9" }
        func isWordChar(_ c: Character) -> Bool { c.isLetter || c.isNumber || c == "_" }

        func matchesWord(_ word: [Character], at idx: Int) -> Bool {
            guard idx + word.count <= n else { return false }
            for k in 0..<word.count where chars[idx + k] != word[k] { return false }
            // Ensure a boundary so we don't match "trueish".
            let after = idx + word.count
            if after < n && isWordChar(chars[after]) { return false }
            return true
        }

        let trueW = Array("true"), falseW = Array("false"), nullW = Array("null")

        while i < n {
            let c = chars[i]
            if c == "\"" {
                // Consume a string, respecting escapes.
                var j = i + 1
                var str = "\""
                while j < n {
                    let d = chars[j]
                    str.append(d)
                    if d == "\\" && j + 1 < n {
                        str.append(chars[j + 1]); j += 2; continue
                    }
                    j += 1
                    if d == "\"" { break }
                }
                // A key is a string immediately followed (past whitespace) by ':'.
                var k = j
                while k < n, chars[k] == " " || chars[k] == "\t" || chars[k] == "\n" || chars[k] == "\r" { k += 1 }
                let isKey = k < n && chars[k] == ":"
                flushPlain()
                tokens.append(Token(text: str, kind: isKey ? .key : .string))
                i = j
            } else if c == "-" || isDigit(c) {
                var j = i
                var num = ""
                if chars[j] == "-" { num.append(chars[j]); j += 1 }
                while j < n && isDigit(chars[j]) { num.append(chars[j]); j += 1 }
                if j < n && chars[j] == "." {
                    num.append(chars[j]); j += 1
                    while j < n && isDigit(chars[j]) { num.append(chars[j]); j += 1 }
                }
                if j < n && (chars[j] == "e" || chars[j] == "E") {
                    num.append(chars[j]); j += 1
                    if j < n && (chars[j] == "+" || chars[j] == "-") { num.append(chars[j]); j += 1 }
                    while j < n && isDigit(chars[j]) { num.append(chars[j]); j += 1 }
                }
                if num.contains(where: isDigit) {
                    flushPlain(); tokens.append(Token(text: num, kind: .number)); i = j
                } else {
                    plain.append(c); i += 1
                }
            } else if matchesWord(trueW, at: i) || matchesWord(falseW, at: i) {
                let word = matchesWord(trueW, at: i) ? "true" : "false"
                flushPlain(); tokens.append(Token(text: word, kind: .keyword)); i += word.count
            } else if matchesWord(nullW, at: i) {
                flushPlain(); tokens.append(Token(text: "null", kind: .null)); i += 4
            } else if "{}[],:".contains(c) {
                flushPlain(); tokens.append(Token(text: String(c), kind: .punct)); i += 1
            } else {
                plain.append(c); i += 1
            }
        }
        flushPlain()
        return tokens
    }
}
