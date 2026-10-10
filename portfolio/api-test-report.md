# API Testing Report — Spa POS

**Tools:** Postman, Supabase REST/RPC, Supabase SQL Editor  
**Updated:** 10/10/2026

## Mục tiêu

Kiểm tra request hợp lệ/không hợp lệ, status code, response body, authentication/authorization, business rules và tác động dữ liệu.

## Shift API

Các luồng đã kiểm thử gồm mở ca, lấy ca hiện tại và đóng ca.

- Mở ca với tiền đầu ca hợp lệ thành công.
- Mở ca lần nữa bị từ chối với SHIFT_ALREADY_OPEN.
- Đóng ca lưu tiền thực tế và chênh lệch.
- Dữ liệu đầu vào không hợp lệ bị từ chối.
- Người không sở hữu ca không thể đóng ca đó; API trả FORBIDDEN.
- Lỗi backend ca làm việc trước đó đã được sửa và retest PASS theo hồ sơ học tập.

## Invoice & Payment API

- Thanh toán đủ: hóa đơn chuyển PAID.
- Thanh toán một phần: PARTIALLY_PAID.
- Thanh toán phần còn lại: PAID.
- Số tiền bằng 0 hoặc vượt số còn phải trả bị từ chối.
- Hủy hóa đơn chưa thanh toán: CANCELLED; đã ghi nhận không có payment/cashbook record.
- Hủy hóa đơn đã thanh toán: bị từ chối với PAID_INVOICE_REQUIRES_REFUND_WORKFLOW.

## Scenario: thanh toán một phần

**Given:** hóa đơn 110.000, ca hợp lệ đang mở và phương thức thanh toán hợp lệ.  
**When:** tạo payment 60.000.  
**Then:** số đã thanh toán là 60.000, trạng thái PARTIALLY_PAID.  
**And:** thanh toán tiếp 50.000 thì trạng thái chuyển PAID.

## Scenario: hủy hóa đơn đã thanh toán

**Given:** hóa đơn đã thanh toán.  
**When:** gọi API hủy hóa đơn.  
**Then:** request bị từ chối với PAID_INVOICE_REQUIRES_REFUND_WORKFLOW.

**Pending:** đối chiếu invoice, payments và cashbook trước/sau request để chứng minh dữ liệu không bị thay đổi ngoài ý muốn. Chưa tuyên bố hoàn tất toàn bộ data integrity test.

## Cách đánh giá API

1. Kiểm tra method, endpoint và payload.
2. Xác nhận HTTP status và response body.
3. Đối chiếu trạng thái bản ghi backend.
4. Với request thất bại, xác minh không phát sinh thay đổi sai.
5. Thử user thiếu quyền và các điều kiện nghiệp vụ không hợp lệ.

## Việc cần bổ sung

- Xuất Postman collection đã loại bỏ token/secret.
- Thêm assertion tự động cho status và business rules.
- Hoàn tất kiểm tra toàn vẹn dữ liệu luồng hủy hóa đơn đã thanh toán.
- Bổ sung truy vấn SQL chỉ đọc làm bằng chứng.
- Không commit service-role key, JWT, password hoặc dữ liệu thật.
