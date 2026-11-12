import Foundation

enum SharedStorage {
    static let group = "group.vn.chandauso.local"
    static let extensionID = "vn.chandauso.local.directory"
    static func fileURL() throws -> URL {
        guard let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else {
            throw RuleError.invalid("Không mở được vùng dữ liệu chung. Kiểm tra quyền App Group và bản cài TrollStore.")
        }
        return root.appendingPathComponent("active-rules.json")
    }
    static func read() throws -> RuleSet {
        let url = try fileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return RuleSet() }
        return try JSONDecoder().decode(RuleSet.self, from: Data(contentsOf: url))
    }
    static func write(_ set: RuleSet) throws {
        let data = try JSONEncoder().encode(set)
        try data.write(to: fileURL(), options: [.atomic, .completeUntilFirstUserAuthentication])
    }
}
