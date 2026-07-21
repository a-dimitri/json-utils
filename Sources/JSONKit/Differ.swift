import Foundation

public enum DiffLineType: Sendable {
    case same
    case add
    case del
}

public struct DiffLine: Identifiable, Sendable {
    public let id: Int
    public let type: DiffLineType
    public let text: String
    public let leftNumber: Int?
    public let rightNumber: Int?
}

public enum Differ {
    /// Line-by-line diff using a longest-common-subsequence table.
    /// Returns rows in display order.
    public static func lineDiff(_ aStr: String, _ bStr: String) -> [DiffLine] {
        let a = aStr.components(separatedBy: "\n")
        let b = bStr.components(separatedBy: "\n")
        let n = a.count
        let m = b.count

        // dp[i][j] = length of LCS of a[i...] and b[j...]
        var dp = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        if n > 0 && m > 0 {
            for i in stride(from: n - 1, through: 0, by: -1) {
                for j in stride(from: m - 1, through: 0, by: -1) {
                    dp[i][j] = a[i] == b[j]
                        ? dp[i + 1][j + 1] + 1
                        : max(dp[i + 1][j], dp[i][j + 1])
                }
            }
        }

        var rows: [DiffLine] = []
        var id = 0
        func push(_ type: DiffLineType, _ text: String, _ left: Int?, _ right: Int?) {
            rows.append(DiffLine(id: id, type: type, text: text, leftNumber: left, rightNumber: right))
            id += 1
        }

        var i = 0, j = 0
        while i < n && j < m {
            if a[i] == b[j] {
                push(.same, a[i], i + 1, j + 1); i += 1; j += 1
            } else if dp[i + 1][j] >= dp[i][j + 1] {
                push(.del, a[i], i + 1, nil); i += 1
            } else {
                push(.add, b[j], nil, j + 1); j += 1
            }
        }
        while i < n { push(.del, a[i], i + 1, nil); i += 1 }
        while j < m { push(.add, b[j], nil, j + 1); j += 1 }
        return rows
    }
}
