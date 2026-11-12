import Foundation

var checks = 0
func check(_ condition: @autoclosure () -> Bool, _ name: String) {
    checks += 1
    guard condition() else { fatalError("FAILED: \(name)") }
}
func rejected(_ name: String, _ operation: () throws -> Void) {
    checks += 1
    do { try operation(); fatalError("Expected rejection: \(name)") }
    catch { print("Rejected correctly: \(name)") }
}
func rule(_ prefix: String, _ length: Int, _ enabled: Bool = true) -> PrefixRule {
    PrefixRule(prefix: prefix, nationalLength: length, enabled: enabled)
}
func count(_ set: RuleSet) throws -> Int64 {
    try RuleEngine.ranges(for: set).reduce(0) { $0 + $1.count }
}

let domestic = try RuleEngine.range(for: rule("028730", 11))
check(domestic == NumberRange(lower: 842873000000, upper: 842873099999), "VN landline boundaries")
check(domestic.count == 100_000, "VN range count")
let explicit = try RuleEngine.range(for: rule("+84 28 730", 12))
check(explicit == domestic, "+84 equivalent")
let zeroZero = try RuleEngine.range(for: rule("008428730", 12))
check(zeroZero == domestic, "00 international prefix")
let mobile = try RuleEngine.range(for: rule("090123", 10))
check(mobile.lower == 84901230000 && mobile.upper == 84901239999, "VN mobile boundaries")
let exact = try RuleEngine.range(for: rule("0901234567", 10))
check(exact.count == 1 && exact.lower == 84901234567, "exact number")
let foreign = try RuleEngine.range(for: rule("+1202555", 11))
check(foreign.lower == 12025550000 && foreign.count == 10_000, "foreign country")
let merged = RuleSet(rules: [rule("028730",11),rule("0287300",11),rule("+8428730",12)])
let mergedCount = try count(merged)
check(mergedCount == 100_000, "overlap merged")
let adjacent = try RuleEngine.ranges(for: RuleSet(rules: [rule("0901234568",10),rule("0901234567",10)]))
check(adjacent.count == 1 && adjacent[0].count == 2, "adjacent sorted merged")
let excluded = RuleSet(rules: [rule("090123",10)], exceptions: ["0901230000", "+84901239999", "0901234567", "0901234567", "02873000000"])
let pieces = try RuleEngine.ranges(for: excluded)
check(pieces.reduce(0) { $0 + $1.count } == 9997, "exceptions deduplicated and subtracted")
check(pieces.first?.lower == 84901230001 && pieces.last?.upper == 84901239998, "exclude boundaries")
for pair in zip(pieces, pieces.dropFirst()) { check(pair.0.upper < pair.1.lower, "ascending disjoint pieces") }
let empty = try RuleEngine.ranges(for: RuleSet())
check(empty.isEmpty, "empty removes all")
let disabled = try count(RuleSet(rules: [rule("028",11,false)]))
check(disabled == 0, "disabled broad rule ignored")
let million = try count(RuleSet(rules: [rule("02873",11)]))
check(million == RuleEngine.maximumEntries, "cap boundary inclusive")
rejected("short prefix exceeds cap") { _ = try count(RuleSet(rules: [rule("028",11)])) }
rejected("combined cap") { _ = try count(RuleSet(rules: [rule("02873",11),rule("02473",11)])) }
rejected("wildcard") { _ = try RuleEngine.range(for: rule("028*",11)) }
rejected("empty input") { _ = try RuleEngine.range(for: rule(" ",11)) }
rejected("unicode digits") { _ = try RuleEngine.range(for: rule("０２８",11)) }
rejected("prefix longer than length") { _ = try RuleEngine.range(for: rule("0901234567",9)) }
rejected("overflow prevention") { _ = try RuleEngine.range(for: rule("0",15)) }
let roundTrip = try JSONDecoder().decode(RuleSet.self, from: JSONEncoder().encode(merged))
check(roundTrip == merged, "storage round trip")
print("PASS: \(checks) checks")
