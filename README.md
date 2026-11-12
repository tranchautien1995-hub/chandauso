# Chặn Đầu Số — iPhone, iOS 15.1+

Ứng dụng SwiftUI tiếng Việt và Call Directory extension, hướng tới iPhone XS Max / iOS 15.1 cài bằng TrollStore. Đây là mã nguồn chưa được biên dịch và kiểm thử trên thiết bị thật. Chưa có IPA trong gói mã nguồn này.

## Chức năng

- Tự nhập đầu số bất kỳ, chọn độ dài toàn bộ số, bật/tắt, vuốt xóa.
- Nhận đầu số Việt Nam bắt đầu bằng `0`, hoặc quốc tế bắt đầu bằng `+`, `00`, hay mã nước viết liền.
- Ví dụ `028730`, độ dài `11`: 100.000 số, từ `+842873000000` đến `+842873099999`. Nếu nhập `+8428730`, chọn độ dài `12` vì tính cả mã nước.
- Đầu số `090123`, độ dài `10`: 10.000 số. Một số đầy đủ cũng dùng làm quy tắc chặn một số.
- Gộp dải trùng/lồng nhau; sắp tăng dần; không tạo mảng chứa hàng triệu số trong bộ nhớ.
- Thêm số ngoại lệ đầy đủ, ví dụ `0901234567`. Ngoại lệ chỉ loại khỏi danh sách của app, không gỡ chặn trong app khác hay danh sách chặn của iOS.
- Danh sách sửa được lưu riêng với danh sách gửi cho iOS. Bấm **Áp dụng** và chờ thông báo iOS đã nạp.
- Áp dụng danh sách rỗng để gỡ các mục chặn của app. Tắt từng đầu số cũng cần áp dụng lại.
- Không dùng mạng, không tải danh bạ, không thu thập dữ liệu, không có dịch vụ trả phí.

## Giới hạn cần hiểu

iOS 15 Call Directory nhận từng số cụ thể, không nhận một biểu thức đầu số để khớp trực tiếp mọi cuộc gọi. App mở rộng đầu số thành các số rồi gửi cho iOS.

Giới hạn **do app đặt** là 1.000.000 số sau khi gộp trùng và trừ ngoại lệ. Đây không phải bảo đảm iOS sẽ nạp được một triệu số: bộ nhớ, thời gian chạy extension và giới hạn hệ thống có thể thấp hơn trên máy thực tế. Bắt đầu thử với một số riêng lẻ, rồi dải nhỏ.

`028` với số dài 11 chữ số tạo 100 triệu số nên bị từ chối. Hãy dùng đầu số dài hơn, ví dụ `028730`. App không thể đáp ứng yêu cầu chặn đầu số rộng không giới hạn bằng API này. TrollStore không tự biến Call Directory thành trình chặn theo mẫu trực tiếp.

Chỉ chặn cuộc gọi điện thoại do hệ thống xử lý, không chặn SMS hoặc các cuộc gọi Zalo/Messenger. Không tự miễn chặn danh bạ. Số ẩn danh không có số để so khớp cũng không được xử lý bằng danh sách này.

Nút trạng thái phản ánh extension có bật hay không; dòng xác nhận chỉ so với lần `reloadExtension` thành công gần nhất mà app ghi nhận. Không phải nhật ký cuộc gọi hay bằng chứng từng cuộc gọi đã bị chặn. Nếu nạp thất bại, app không báo thành công; danh sách yêu cầu vẫn được lưu và có thể được iOS nạp khi bật lại extension.

## Tạo IPA trên Windows qua GitHub Actions

Không cần máy Mac cá nhân hay tài khoản Apple Developer cho quy trình TrollStore này; cần tài khoản GitHub có quyền dùng runner macOS. GitHub có thể áp dụng hạn mức hoặc tính phí theo tài khoản của bạn.

1. Tạo một repository riêng cho app.
2. Đưa **nội dung trong thư mục `ChanDauSo`** lên thư mục gốc repository, gồm cả `.github/workflows/build-ipa.yml` và `ChanDauSo.xcodeproj`. Không đưa các thư mục dự án khác hay `.env.local` trong workspace lên.
3. Mở tab **Actions → Build IPA for TrollStore → Run workflow** trên nhánh chứa workflow.
4. Nếu thành công, tải artifact **ChanDauSo-TrollStore**. Giải nén ZIP để lấy `ChanDauSo.ipa`.
5. Chuyển IPA vào ứng dụng Tệp trên iPhone → chia sẻ/mở bằng TrollStore → Install.

Workflow này chưa được chạy trong phiên tạo mã nguồn. Nó chạy kiểm tra logic trước, biên dịch bản arm64 cho iOS 15.1, ký ad-hoc extension và app với quyền App Group, rồi đóng gói IPA. Không tải công cụ ký không rõ nguồn gốc. TrollStore sẽ áp dụng cơ chế ký riêng lúc cài.

## Tạo IPA bằng Mac

Cần macOS 13+ và Xcode có iPhoneOS SDK; chọn Xcode làm developer directory và hoàn thành lần mở đầu tiên. Từ Terminal tại thư mục này:

```sh
bash scripts/build-ipa.sh
```

Kết quả: `build/ChanDauSo.ipa`. Không dùng bản này để cài bằng cơ chế ký thông thường/App Store. Nếu dùng tài khoản Apple Developer, cần đổi bundle identifiers, cấp App Group hợp lệ, và dùng quy trình ký của Apple.

Mở `ChanDauSo.xcodeproj` để sửa giao diện. Project đã có sẵn; chỉ cần Node nếu muốn tạo lại bằng `node scripts/generate-project.cjs`.

## Bật và thử trên XS Max

1. Sau khi cài, mở app một lần.
2. Mở **Cài đặt → Điện thoại → Chặn cuộc gọi & nhận dạng**, bật **Chặn Đầu Số**. Nút trong app cũng yêu cầu iOS mở trang này.
3. Thử nhập một số điện thoại khác của bạn với độ dài chính xác. Bấm **Áp dụng**, chờ thành công, rồi dùng số đó gọi vào iPhone.
4. Thêm số đó vào ngoại lệ, áp dụng lại, gọi thử để kiểm tra bỏ chặn.
5. Thử dải nhỏ, khóa màn hình rồi gọi lại; thử cả hai SIM nếu dùng hai SIM. Kiểm tra sau khi khởi động lại.
6. Xóa/tắt mọi quy tắc, áp dụng danh sách rỗng và gọi thử để kiểm tra gỡ chặn.

Nếu không thấy extension trong Cài đặt hoặc gặp lỗi tìm extension/App Group: giữ lại nội dung thông báo lỗi. Cài app thành công qua TrollStore chưa chứng minh extension đã được iOS đăng ký và cấp vùng dữ liệu chung đúng. Cần kiểm tra bản TrollStore, đăng ký app và quyền ký trên thiết bị; không có cam kết tương thích extension trên cấu hình này khi chưa thử thật. Không cần cập nhật iOS để thử app.

Nếu iOS từ chối danh sách lớn: giảm số quy tắc/nhập đầu số dài hơn rồi áp dụng lại. Sau khi khởi động lại, mở khóa máy ít nhất một lần trước khi thử nạp dữ liệu.

## Kiểm tra và tình trạng bàn giao

- `Tests/main.swift`: kiểm tra biên số Việt Nam/quốc tế, độ dài, gộp trùng, sắp tăng, ngoại lệ ở biên/giữa, quy tắc tắt, danh sách rỗng, giới hạn và dữ liệu sai.
- `scripts/verify-project.cjs`: kiểm tra cấu trúc hai target, nguồn dùng chung, App Group và quy trình đóng gói trên Windows.
- Phiên tạo mã nguồn đã kiểm tra cấu trúc tệp và XML trên Windows. Chưa chạy Swift tests, Xcode build hoặc thử cuộc gọi do không có macOS/Xcode/iPhone kết nối.

## Tài liệu nền tảng

- [Apple: Identifying and blocking calls](https://developer.apple.com/documentation/callkit/identifying-and-blocking-calls)
- [Apple: CXCallDirectoryManager](https://developer.apple.com/documentation/callkit/cxcalldirectorymanager)
- [Apple: incremental requests](https://developer.apple.com/documentation/callkit/cxcalldirectoryextensioncontext/isincremental)
- [TrollStore: mã nguồn và quyền ký](https://github.com/opa334/TrollStore)
