# Test Strategy — Spa POS

**Phiên bản:** 1.0  
**Cập nhật:** 10/10/2026

## Mục tiêu

Đánh giá hệ thống theo yêu cầu nghiệp vụ, quyền người dùng và tính toàn vẹn dữ liệu; ưu tiên luồng có rủi ro tài chính và dữ liệu.

## Phạm vi kiểm thử

- Authentication: đăng nhập, đăng xuất và validation.
- Authorization: Admin, Cashier, Employee; quyền xem/sửa và quyền thao tác.
- Dữ liệu nền: sản phẩm/dịch vụ, khách hàng, phương thức thanh toán, hồ sơ nhân viên.
- Ca làm việc: mở ca, lấy ca hiện tại, đóng ca, quyền sở hữu ca.
- Hóa đơn/thanh toán: tạo hóa đơn, thanh toán đủ/một phần, số tiền không hợp lệ, hủy hóa đơn.
- Cashbook/debt: kiểm tra bản ghi liên quan khi nghiệp vụ tạo tác động tài chính.
- Regression sau khi sửa lỗi.

## Cách tiếp cận theo tầng

1. UI: hiển thị, trạng thái, điều hướng, thông báo.
2. Validation: dữ liệu bắt buộc, định dạng, biên giá trị.
3. Functional: luồng chính, trạng thái trước/sau, business rules.
4. Permission / Security / Data: quyền theo vai trò và xác minh dữ liệu backend.

## Kỹ thuật thiết kế test

- Positive và negative testing.
- Boundary/value validation.
- Role-based testing.
- State transition testing.
- Data integrity checks.
- Regression testing.

## Công cụ và môi trường

Frontend Spa POS trên GitHub Pages; backend Supabase Auth, REST API, RPC và PostgreSQL. Công cụ thực hành gồm Postman, Browser DevTools, Supabase SQL Editor, GitHub và Excel/Markdown.

## Quy ước trạng thái

- PASS: actual result đáp ứng expected result và có đủ bằng chứng.
- FAIL: actual result khác expected result.
- BLOCKED: chưa thực thi được do thiếu điều kiện/phụ thuộc.
- N/A: không áp dụng trong phạm vi đã xác định.
- Pending verification: kết quả một phần, chưa đủ bằng chứng để kết luận.

## Tiêu chí kết thúc

Các luồng ưu tiên cao đã được thực thi hoặc ghi rõ pending/blocked; defect có bước tái hiện và bằng chứng; lỗi đã sửa được retest; rủi ro còn mở được nêu trong báo cáo.

## Giới hạn hiện tại

Chưa thực hiện kiểm thử tải quy mô lớn, penetration testing hoặc tự động hóa toàn bộ hệ thống. Một số xác minh toàn vẹn dữ liệu và nhóm lỗi đồng bộ hồ sơ nhân viên vẫn đang mở.
