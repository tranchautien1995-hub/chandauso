import Foundation
import CallKit

final class RuleStore: ObservableObject {
    @Published var draft = RuleSet()
    @Published var enabled = false
    @Published var busy = false
    @Published var message: String?
    @Published var confirmed: RuleSet?
    private let draftURL: URL
    private let confirmedURL: URL

    init() {
        let root = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        draftURL = root.appendingPathComponent("draft.json")
        confirmedURL = root.appendingPathComponent("confirmed.json")
        do {
            if FileManager.default.fileExists(atPath: draftURL.path) {
                draft = try JSONDecoder().decode(RuleSet.self, from: Data(contentsOf: draftURL))
            }
            if FileManager.default.fileExists(atPath: confirmedURL.path) {
                confirmed = try JSONDecoder().decode(RuleSet.self, from: Data(contentsOf: confirmedURL))
            }
        } catch { message = "Không đọc được dữ liệu đã lưu: \(error.localizedDescription)" }
        refresh()
    }

    var count: Int64 { (try? RuleEngine.ranges(for: draft, enforceLimit: false).reduce(0) { $0 + $1.count }) ?? 0 }
    var pending: Bool { confirmed != draft }

    func save() {
        do { try JSONEncoder().encode(draft).write(to: draftURL, options: .atomic) }
        catch { message = "Không lưu được danh sách: \(error.localizedDescription)" }
    }

    func add(prefix: String, length: Int) -> Bool {
        do {
            let rule = PrefixRule(prefix: prefix.trimmingCharacters(in: .whitespacesAndNewlines), nationalLength: length)
            let range = try RuleEngine.range(for: rule)
            guard !draft.rules.contains(where: { (try? RuleEngine.range(for: $0)) == range }) else {
                throw RuleError.invalid("Đầu số và độ dài này đã có trong danh sách.")
            }
            var next = draft
            next.rules.append(rule)
            _ = try RuleEngine.ranges(for: next)
            draft = next
            save()
            return true
        } catch { message = error.localizedDescription; return false }
    }

    func addException(_ input: String) -> Bool {
        do {
            let number = try RuleEngine.international(input)
            guard number.count >= 7 else { throw RuleError.invalid("Nhập đầy đủ số điện thoại ngoại lệ.") }
            if !draft.exceptions.contains(number) { draft.exceptions.append(number); save() }
            return true
        } catch { message = error.localizedDescription; return false }
    }

    func refresh() {
        CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: SharedStorage.extensionID) { status, error in
            DispatchQueue.main.async {
                self.enabled = status == .enabled
                if let error = error { self.message = "Không kiểm tra được bộ chặn: \(error.localizedDescription)" }
            }
        }
    }

    func openSettings() {
        CXCallDirectoryManager.sharedInstance.openSettings { error in
            if let error = error { DispatchQueue.main.async { self.message = error.localizedDescription } }
        }
    }

    func apply() {
        guard !busy else { return }
        do {
            _ = try RuleEngine.ranges(for: draft)
            let snapshot = draft
            try SharedStorage.write(snapshot)
            busy = true
            CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: SharedStorage.extensionID) { error in
                DispatchQueue.main.async {
                    self.busy = false
                    if let error = error {
                        let ns = error as NSError
                        self.message = "iOS chưa xác nhận áp dụng (\(ns.domain), \(ns.code)): \(error.localizedDescription). Bật Chặn Đầu Số trong Cài đặt > Điện thoại > Chặn cuộc gọi & nhận dạng, rồi thử lại. Danh sách yêu cầu đã lưu; iOS có thể nạp khi bạn bật bộ chặn."
                    } else {
                        self.confirmed = snapshot
                        do { try JSONEncoder().encode(snapshot).write(to: self.confirmedURL, options: .atomic) }
                        catch { self.message = "iOS đã nạp nhưng không lưu được trạng thái xác nhận: \(error.localizedDescription)" }
                        self.message = self.message ?? "iOS đã nạp danh sách thành công."
                    }
                    self.refresh()
                }
            }
        } catch { message = error.localizedDescription }
    }
}
