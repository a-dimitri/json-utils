import Foundation

/// The utility operations offered by the app.
public enum Operation: String, CaseIterable, Identifiable, Sendable {
    case format
    case minify
    case marshal
    case unmarshal
    case deepUnmarshal
    case diff

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .format:        return "Format"
        case .minify:        return "Minify"
        case .marshal:       return "Marshal"
        case .unmarshal:     return "Unmarshal"
        case .deepUnmarshal: return "Deep Unmarshal"
        case .diff:          return "Diff"
        }
    }

    /// Diff needs two inputs and produces rows, not a single output string.
    public var isDiff: Bool { self == .diff }
}

public enum JSONTools {
    /// Runs a single-input operation. `diff` is handled by `Differ` instead.
    public static func run(_ op: Operation, input: String) throws -> String {
        switch op {
        case .format:
            return try JSONParser.parse(input).serialized(pretty: true)
        case .minify:
            return try JSONParser.parse(input).serialized(pretty: false)
        case .marshal:
            // Encode the (minified) JSON as a JSON string literal:
            //   {"a":1}  ->  "{\"a\":1}"
            let compact = try JSONParser.parse(input).serialized(pretty: false)
            return JSONValue.encodeString(compact)
        case .unmarshal:
            // If the top-level value is a JSON string, decode and pretty-print it;
            // otherwise just pretty-print the value.
            let value = try JSONParser.parse(input)
            if case .string(let inner) = value {
                return try JSONParser.parse(inner).serialized(pretty: true)
            }
            return value.serialized(pretty: true)
        case .deepUnmarshal:
            return deepParse(try JSONParser.parse(input)).serialized(pretty: true)
        case .diff:
            // Not used directly; kept total so callers can't forget a case.
            return try JSONParser.parse(input).serialized(pretty: true)
        }
    }

    /// Recursively parse any string value whose contents look like JSON.
    /// Great for untangling logs that stuff JSON inside JSON inside JSON.
    static func deepParse(_ value: JSONValue) -> JSONValue {
        switch value {
        case .string(let s):
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if let first = trimmed.first, first == "{" || first == "[",
               let parsed = try? JSONParser.parse(s) {
                return deepParse(parsed)
            }
            return value
        case .array(let items):
            return .array(items.map(deepParse))
        case .object(let pairs):
            return .object(pairs.map { ($0.key, deepParse($0.value)) })
        default:
            return value
        }
    }

    /// Normalize text for diffing: pretty-print if it parses, else use it verbatim.
    public static func normalizedForDiff(_ s: String) -> String {
        (try? JSONParser.parse(s).serialized(pretty: true)) ?? s
    }
}
