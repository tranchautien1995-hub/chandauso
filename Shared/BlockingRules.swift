import Foundation

struct PrefixRule: Codable, Equatable, Identifiable {
    var id = UUID()
    var prefix: String
    var nationalLength: Int
    var enabled = true
}

struct RuleSet: Codable, Equatable {
    var rules: [PrefixRule] = []
    // Stored in international digits, e.g. 84901234567.
    var exceptions: [String] = []
}

struct NumberRange: Equatable {
    var lower: Int64
    var upper: Int64
    var count: Int64 { upper - lower + 1 }
}

enum RuleError: LocalizedError {
    case invalid(String)
    case tooMany(Int64)
    var errorDescription: String? {
        switch self {
        case .invalid(let message): return message
        case .tooMany(let count):
            return "Dải này tạo \(count.formatted()) số, vượt giới hạn 1.000.000 số của app. Hãy nhập đầu số dài hơn hoặc tắt bớt quy tắc."
        }
    }
}

enum RuleEngine {
    static let maximumEntries: Int64 = 1_000_000

    static func clean(_ input: String) throws -> String {
        let value = input.filter { !" +()-\t\r\n".contains($0) }
        guard !value.isEmpty, value.utf8.allSatisfy({ $0 >= 48 && $0 <= 57 }) else {
            throw RuleError.invalid("Chỉ nhập chữ số; không dùng * hoặc ký tự đại diện.")
        }
        return value
    }

    static func international(_ input: String, country: String = "84") throws -> String {
        let raw = input.trimmingCharacters(in: .whitespacesAndNewlines)
        var digits = try clean(raw)
        if raw.hasPrefix("+") { /* explicit country code */ }
        else if digits.hasPrefix("00") { digits = String(digits.dropFirst(2)) }
        else if digits.hasPrefix("0") { digits = country + digits.dropFirst() }
        // Otherwise assume the user supplied an international number without +.
        guard !digits.isEmpty, !digits.hasPrefix("0"), digits.count <= 15 else {
            throw RuleError.invalid("Số quốc tế phải có mã nước và tối đa 15 chữ số.")
        }
        return digits
    }

    static func range(for rule: PrefixRule) throws -> NumberRange {
        let raw = rule.prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = try clean(raw)
        let domestic = digits.hasPrefix("0") && !digits.hasPrefix("00") && !raw.hasPrefix("+")
        let prefix = try international(raw)
        guard (4...15).contains(rule.nationalLength) else {
            throw RuleError.invalid("Độ dài số phải từ 4 đến 15 chữ số.")
        }
        // Domestic input counts the leading 0; international input counts country code.
        let fullLength = domestic ? rule.nationalLength + 1 : rule.nationalLength
        let suffixLength = fullLength - prefix.count
        guard fullLength <= 15, suffixLength >= 0 else {
            throw RuleError.invalid("Độ dài toàn bộ số ngắn hơn đầu số hoặc vượt 15 chữ số.")
        }
        var size: Int64 = 1
        for _ in 0..<suffixLength { size *= 10 }
        guard let value = Int64(prefix) else { throw RuleError.invalid("Đầu số không hợp lệ.") }
        let start = value * size
        return NumberRange(lower: start, upper: start + size - 1)
    }

    static func ranges(for set: RuleSet, enforceLimit: Bool = true) throws -> [NumberRange] {
        let sorted = try set.rules.filter(\.enabled).map { try range(for: $0) }
            .sorted { $0.lower < $1.lower }
        var merged: [NumberRange] = []
        for item in sorted {
            if let last = merged.last, item.lower <= last.upper + 1 {
                merged[merged.count - 1].upper = max(last.upper, item.upper)
            } else { merged.append(item) }
        }
        let exceptions = try Set(set.exceptions.map { value -> Int64 in
            let normalized = try international(value)
            guard let number = Int64(normalized) else { throw RuleError.invalid("Số ngoại lệ không hợp lệ.") }
            return number
        }).sorted()
        var result: [NumberRange] = []
        var exceptionIndex = 0
        for item in merged {
            var start = item.lower
            while exceptionIndex < exceptions.count && exceptions[exceptionIndex] < start { exceptionIndex += 1 }
            while exceptionIndex < exceptions.count && exceptions[exceptionIndex] <= item.upper {
                let number = exceptions[exceptionIndex]
                if start < number { result.append(NumberRange(lower: start, upper: number - 1)) }
                start = number + 1
                exceptionIndex += 1
            }
            if start <= item.upper { result.append(NumberRange(lower: start, upper: item.upper)) }
        }
        let total = result.reduce(Int64(0)) { $0 + $1.count }
        if enforceLimit && total > maximumEntries { throw RuleError.tooMany(total) }
        return result
    }
}
