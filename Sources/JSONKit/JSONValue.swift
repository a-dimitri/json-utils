import Foundation

/// An order-preserving JSON value.
///
/// Unlike `JSONSerialization`/`Codable`, object keys keep their original order
/// and numbers keep their exact source lexeme (so `98.60`, `1e3`, `-0` survive a
/// round trip unchanged). That fidelity is the whole point of a JSON formatter.
public indirect enum JSONValue {
    case null
    case bool(Bool)
    case number(String)          // raw lexeme, e.g. "98.6", "1e10", "-0"
    case string(String)          // decoded value
    case array([JSONValue])
    case object([(key: String, value: JSONValue)])   // insertion order preserved
}

public extension JSONValue {
    /// Serialize to text. `pretty` uses `indent`-space indentation; otherwise compact.
    func serialized(pretty: Bool, indent: Int = 2) -> String {
        var out = ""
        write(into: &out, level: 0, pretty: pretty, indent: indent)
        return out
    }

    private func write(into out: inout String, level: Int, pretty: Bool, indent: Int) {
        switch self {
        case .null:
            out += "null"
        case .bool(let b):
            out += b ? "true" : "false"
        case .number(let n):
            out += n
        case .string(let s):
            out += JSONValue.encodeString(s)
        case .array(let arr):
            if arr.isEmpty { out += "[]"; return }
            if pretty {
                out += "[\n"
                let pad = String(repeating: " ", count: (level + 1) * indent)
                for (idx, el) in arr.enumerated() {
                    out += pad
                    el.write(into: &out, level: level + 1, pretty: true, indent: indent)
                    out += idx < arr.count - 1 ? ",\n" : "\n"
                }
                out += String(repeating: " ", count: level * indent) + "]"
            } else {
                out += "["
                for (idx, el) in arr.enumerated() {
                    el.write(into: &out, level: 0, pretty: false, indent: indent)
                    if idx < arr.count - 1 { out += "," }
                }
                out += "]"
            }
        case .object(let pairs):
            if pairs.isEmpty { out += "{}"; return }
            if pretty {
                out += "{\n"
                let pad = String(repeating: " ", count: (level + 1) * indent)
                for (idx, kv) in pairs.enumerated() {
                    out += pad + JSONValue.encodeString(kv.key) + ": "
                    kv.value.write(into: &out, level: level + 1, pretty: true, indent: indent)
                    out += idx < pairs.count - 1 ? ",\n" : "\n"
                }
                out += String(repeating: " ", count: level * indent) + "}"
            } else {
                out += "{"
                for (idx, kv) in pairs.enumerated() {
                    out += JSONValue.encodeString(kv.key) + ":"
                    kv.value.write(into: &out, level: 0, pretty: false, indent: indent)
                    if idx < pairs.count - 1 { out += "," }
                }
                out += "}"
            }
        }
    }

    /// Encode a Swift string as a JSON string literal (including surrounding quotes).
    static func encodeString(_ s: String) -> String {
        var out = "\""
        for scalar in s.unicodeScalars {
            switch scalar {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\t": out += "\\t"
            case "\r": out += "\\r"
            case "\u{08}": out += "\\b"
            case "\u{0C}": out += "\\f"
            default:
                if scalar.value < 0x20 {
                    out += String(format: "\\u%04x", scalar.value)
                } else {
                    out.unicodeScalars.append(scalar)
                }
            }
        }
        out += "\""
        return out
    }
}
