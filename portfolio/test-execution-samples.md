# Test Execution Samples — Spa POS

**Ngày tổng hợp:** 10/10/2026

## 1. Ca làm việc

| ID | Scenario | Kết quả đã ghi nhận | Status |
|---|---|---|---|
| TC-SHIFT-01 | Mở ca với tiền đầu ca hợp lệ | Mở ca với 1.000.000 thành công | PASS |
| TC-SHIFT-02 | Mở ca lần nữa khi ca đang mở | Bị từ chối với SHIFT_ALREADY_OPEN | PASS |
| TC-SHIFT-03 | Đóng ca với tiền thực tế khác số hệ thống | Tiền thực tế 900.000; chênh lệch -100.000 | PASS |
| TC-SHIFT-04 | Mở ca với dữ liệu tiền không hợp lệ | API từ chối | PASS |
| TC-SHIFT-05 | Đóng ca của người dùng khác | API trả FORBIDDEN | PASS cho kiểm tra quyền |

## 2. Thanh toán và hủy hóa đơn

| ID | Scenario | Kết quả đã ghi nhận | Status |
|---|---|---|---|
| TC-PAYMENT-01 | Thanh toán đủ 110.000 | Hóa đơn chuyển PAID | PASS |
| TC-PAYMENT-02 | Thanh toán 60.000 trên hóa đơn 110.000 | PARTIALLY_PAID | PASS |
| TC-PAYMENT-03 | Thanh toán tiếp 50.000 | Hóa đơn chuyển PAID | PASS |
| TC-PAYMENT-04 | Thanh toán vượt số còn phải trả | API từ chối | PASS |
| TC-PAYMENT-05 | Thanh toán bằng 0 | API từ chối | PASS |
| TC-PAYMENT-08 | Hủy hóa đơn chưa thanh toán | CANCELLED; đã ghi nhận không có payment/cashbook record | PASS |
| TC-PAYMENT-09 | Hủy hóa đơn đã thanh toán | Bị chặn với PAID_INVOICE_REQUIRES_REFUND_WORKFLOW | Rule PASS; data integrity pending |

Lưu ý TC-PAYMENT-09: quy tắc từ chối đã được xác nhận, nhưng cần hoàn tất đối chiếu invoice, payments và cashbook để kết luận về toàn vẹn dữ liệu.

## 3. Đồng bộ dữ liệu nền

| ID | Kiểm tra | Kết quả retest gần nhất |
|---|---|---|
| TC-CUSTOMER-01..04 | Tải khách hàng, ánh xạ mã/tên, phone NULL, không trộn dữ liệu mẫu | PASS |
| TC-PAYMETHOD-01..04 | Tải phương thức thanh toán | PASS |
| DEF-PRODUCT-01 | Phân loại dịch vụ/hàng hóa và loại mặc định khi thêm sản phẩm | PASS |
| TC-EMP-SYNC-01 | Danh sách hồ sơ nhân viên tải được | FAIL |
| TC-EMP-SYNC-02 | Ánh xạ mã và tên nhân viên | FAIL |
| TC-EMP-SYNC-03 | Ánh xạ trạng thái hoạt động | FAIL |
| TC-EMP-SYNC-04 | Tách hồ sơ nhân viên khỏi tài khoản đăng nhập | FAIL |

## 4. Test case mẫu

### TC-SHIFT-05 — Không cho đóng ca của người khác

**Precondition:** User A có ca đang mở; User B đã xác thực nhưng không sở hữu ca đó.

**Steps:**
1. Xác thực bằng User B.
2. Gửi request đóng ca với ID ca của User A.
3. Kiểm tra status/response.
4. Đối chiếu trạng thái ca ở backend.

**Expected:** thao tác bị từ chối; ca của User A không bị thay đổi.

**Actual đã ghi nhận:** API trả FORBIDDEN. Nên bổ sung evidence truy vấn trạng thái ca sau request vào hồ sơ hoàn chỉnh.

### TC-EMP-SYNC-01 — Tải danh sách hồ sơ nhân viên

**Steps:** mở Nhân sự → Hồ sơ; quan sát UI, Network và Console.

**Expected:** danh sách được tải từ nguồn dữ liệu đã cấu hình và hiển thị các trường cần thiết.

**Actual:** danh sách không tải/ánh xạ đúng trong lần retest gần nhất.

**Status:** FAIL. Xem [Defect Log](defect-log.md).

## Evidence checklist

Lưu screenshot UI, request/response đã làm sạch, status code, kết quả query chỉ đọc, ngày kiểm thử, môi trường và phiên bản/commit. Không công khai token, khóa hoặc dữ liệu cá nhân.
