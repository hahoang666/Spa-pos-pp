# Requirement Baseline — Spa POS v1.0

Requirement Baseline v1.0 đã được thống nhất làm nguồn yêu cầu chuẩn cho test scenario, test case, RTM, regression và reconciliation. Thay đổi sau baseline cần quản lý phiên bản tiếp theo, ví dụ v1.1.

## Quy tắc nghiệp vụ trọng yếu

| ID / Chủ đề | Quy tắc | Hướng kiểm thử |
|---|---|---|
| AUTH-08 | Reset password không tự mở khóa tài khoản bị khóa thủ công | So sánh trạng thái lock trước/sau reset |
| INV-03 | Hủy HĐĐT phải theo workflow hủy/điều chỉnh HĐĐT | Không xem thao tác hủy hóa đơn thường là đủ |
| APPT-01 | Một nhân viên không được có lịch hẹn chồng lấn | Kiểm tra cùng nhân viên và thời gian giao nhau |
| APPT-02 | Sửa/hủy/thay đổi trạng thái lịch hẹn thuộc phạm vi | Kiểm tra các chuyển trạng thái |
| ATT-02 | Chấm công phải dùng GPS thực | Không thay bằng vị trí giả lập khi nghiệm thu |
| CUST-01 | Số điện thoại khách hàng đúng 10 chữ số | Kiểm tra thiếu/thừa và ký tự không phải số |
| RPT-02 | Doanh thu thuần là giá trị dòng bán trước VAT sau giảm giá, trừ giá trị trả hàng trước VAT | Loại VAT, tiền thu, khoản thu khác và chuyển quỹ |

## Công thức RPT-02

Doanh thu thuần = tổng (giá trị dòng hàng trước VAT − giảm giá) của hóa đơn bán chưa hủy − tổng giá trị trả hàng trước VAT.

Không đồng nhất doanh thu thuần với tổng tiền đã thu hoặc số dư quỹ.

## Quyền và mô hình nhân sự

- Vai trò nghiệp vụ baseline: Admin, Quản lý và Nhân viên.
- Nhân viên được cập nhật thông tin khách hàng nhưng không được xóa.
- Nhân viên chỉ xem hồ sơ nhân sự của chính mình.
- Hồ sơ nhân viên tách biệt tài khoản đăng nhập; nhân viên có thể chưa có tài khoản.
- Nhân viên được xem tồn kho nhưng không được chỉnh sửa.
- Nhân viên không được dùng chức năng reset dữ liệu mẫu.
- Thu ngân phải mở ca trước khi bán hàng.

## Quy tắc tài chính và bán hàng

- Không cho khách lẻ ghi nợ.
- Thu nợ tạo phiếu thu sổ quỹ và gắn ca theo ngày thu.
- Chiết khấu tuân theo ngưỡng quyền/PIN.
- Trả hàng và hủy phải đảo tác động kế toán đúng.
- Bán gói tự tạo thẻ liệu trình.
- Buổi liệu trình cần người thực hiện, xác nhận khách hàng/chữ ký, vật tư, hoa hồng và khả năng hoàn tác.
- Quy tắc commissionRules phải hoạt động.

## Quản lý thay đổi

Dùng v1.0 làm baseline. Yêu cầu mới phải được version hóa và phân tích ảnh hưởng tới test case, RTM và regression. Tài liệu này là bản tóm tắt phục vụ portfolio, không thay thế file nguồn REQUIREMENT_BASELINE_V1.0.md trong repository.
