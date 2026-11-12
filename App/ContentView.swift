import SwiftUI

struct ContentView: View {
    @StateObject private var store = RuleStore()
    @Environment(\.scenePhase) private var phase
    @State private var prefix = ""
    @State private var length = 11
    @State private var exception = ""
    @State private var confirmApply = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "phone.down.circle.fill")
                            .font(.system(size: 44)).foregroundColor(.teal)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Cuộc gọi yên tĩnh hơn").font(.headline)
                            Text("Chặn theo đầu số bạn chọn. Dữ liệu chỉ lưu trên máy.")
                                .font(.subheadline).foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    Label(store.enabled ? "Bộ chặn đang bật" : "Bộ chặn chưa bật", systemImage: store.enabled ? "checkmark.shield.fill" : "shield.slash")
                        .foregroundColor(store.enabled ? .green : .orange)
                    Button("Mở cài đặt chặn cuộc gọi") { store.openSettings() }
                }
                Section(header: Text("Thêm đầu số"), footer: Text("Số Việt Nam: nhập 0 ở đầu, chọn tổng độ dài gồm cả số 0. Ví dụ 028730 • 11 chữ số → 100.000 số. Với +84 hoặc mã nước khác, độ dài gồm cả mã nước.")) {
                    TextField("Ví dụ: 028730 hoặc +8428730", text: $prefix).keyboardType(.phonePad)
                    Picker("Độ dài toàn bộ số", selection: $length) {
                        ForEach(4...15, id: \.self) { Text("\($0) chữ số").tag($0) }
                    }
                    Button { if store.add(prefix: prefix, length: length) { prefix = ""; dismissKeyboard() } } label: {
                        Label("Thêm đầu số", systemImage: "plus.circle.fill")
                    }.disabled(prefix.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                Section(header: Text("Danh sách đầu số"), footer: Text("Đổi danh sách xong, nhấn Áp dụng. Vuốt sang trái để xóa. Không có đầu số nào được chặn sẵn.")) {
                    if store.draft.rules.isEmpty { Text("Chưa có đầu số").foregroundColor(.secondary) }
                    ForEach($store.draft.rules) { $rule in
                        Toggle(isOn: $rule.enabled) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(rule.prefix).font(.headline.monospacedDigit())
                                Text("\(rule.nationalLength) chữ số • \(((try? RuleEngine.range(for: rule).count) ?? 0).formatted()) số")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }.onDelete { store.draft.rules.remove(atOffsets: $0) }
                }
                Section(header: Text("Số ngoại lệ"), footer: Text("Các số này được bỏ khỏi danh sách của app. Nhập số đầy đủ, ví dụ 0901234567. Danh bạ không tự động được miễn chặn.")) {
                    HStack {
                        TextField("Số vẫn muốn nhận cuộc gọi", text: $exception).keyboardType(.phonePad)
                        Button { if store.addException(exception) { exception = ""; dismissKeyboard() } } label: { Image(systemName: "plus.circle.fill") }
                            .disabled(exception.isEmpty)
                    }
                    ForEach(store.draft.exceptions, id: \.self) { Text("+" + $0).monospacedDigit() }
                        .onDelete { store.draft.exceptions.remove(atOffsets: $0) }
                }
                Section(footer: Text("App chặn cuộc gọi điện thoại qua SIM; không chặn SMS, Zalo hay Messenger. Đầu số có thể bao gồm cả người quen. Giới hạn app: 1.000.000 số sau khi gộp trùng; iOS vẫn có thể từ chối nạp trên thiết bị thực tế.")) {
                    HStack { Text("Số dự kiến chặn"); Spacer(); Text(store.count.formatted()).bold().monospacedDigit() }
                    Text(store.pending ? "Có thay đổi chưa được xác nhận áp dụng" : "Danh sách khớp lần nạp thành công gần nhất")
                        .font(.caption).foregroundColor(.secondary)
                    Button { dismissKeyboard(); confirmApply = true } label: {
                        HStack { Spacer(); if store.busy { ProgressView() }; Text(store.busy ? "Đang yêu cầu iOS…" : "Áp dụng danh sách chặn").bold(); Spacer() }
                    }
                    Button("Kiểm tra trạng thái") { store.refresh() }
                }
            }
            .disabled(store.busy)
            .navigationTitle("Chặn Đầu Số")
            .toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Xong") { dismissKeyboard() } } }
            .confirmationDialog("Áp dụng chặn \(store.count.formatted()) số?", isPresented: $confirmApply, titleVisibility: .visible) {
                Button("Áp dụng", role: .destructive) { store.message = nil; store.apply() }
            } message: { Text("Mọi số thuộc các đầu số đang bật đều bị chặn, trừ số ngoại lệ. Danh sách rỗng sẽ gỡ toàn bộ chặn của app.") }
            .alert("Thông báo", isPresented: Binding(get: { store.message != nil }, set: { if !$0 { store.message = nil } })) {
                Button("Đóng", role: .cancel) { store.message = nil }
            } message: { Text(store.message ?? "") }
        }
        .navigationViewStyle(.stack)
        .onChange(of: store.draft) { _ in store.save() }
        .onChange(of: phase) { if $0 == .active { store.refresh() } }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
