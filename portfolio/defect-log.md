# Defect Log — Spa POS

Bản tóm tắt defect từ quá trình thực hành. Cần gắn thêm issue, commit và evidence cụ thể khi có.

| Defect ID | Mô tả | Tác động | Trạng thái |
|---|---|---|---|
| DEF-AUTH-UI-01 | UI đăng nhập thiếu thông báo rõ về việc không lưu thông tin đăng nhập | Người dùng có thể hiểu sai hành vi ghi nhớ đăng nhập | FAIL đã ghi nhận; cần xác minh trạng thái sửa gần nhất |
| DEF-SHIFT-001 | Lỗi backend trong luồng ca làm việc | Thao tác ca trả lỗi không đúng dự kiến | Đã sửa và retest PASS theo hồ sơ trước đó |
| DEF-EMP-SYNC-001 | Danh sách hồ sơ nhân viên không tải/hiển thị đúng | Khó quản lý và đối chiếu hồ sơ nhân viên | OPEN |
| DEF-EMP-SYNC-002 | Ánh xạ mã và tên nhân viên không đúng | Dữ liệu hiển thị không khớp nguồn | OPEN |
| DEF-EMP-SYNC-003 | Trạng thái hoạt động không ánh xạ đúng | Có nguy cơ hiển thị sai trạng thái | OPEN |
| DEF-EMP-SYNC-004 | Chưa phân biệt đúng hồ sơ nhân viên và tài khoản đăng nhập | Có thể bỏ sót nhân viên chưa có tài khoản hoặc gắn sai dữ liệu | OPEN |

## DEF-EMP-SYNC-001 — Hồ sơ nhân viên không tải được

**Priority đề xuất:** High đối với chức năng quản lý nhân sự; cần đánh giá lại theo phạm vi phát hành.

**Environment:** Spa POS frontend + Supabase.

**Steps to reproduce:**
1. Đăng nhập vào Spa POS.
2. Mở Nhân sự → Hồ sơ.
3. Quan sát danh sách, Network và Console.

**Expected:** danh sách hồ sơ nhân viên tải từ nguồn dữ liệu đúng và hiển thị các trường cần thiết.

**Actual:** danh sách không tải/ánh xạ đúng; TC-EMP-SYNC-01..04 FAIL trong lần retest gần nhất.

**Evidence cần lưu:** response API đã làm sạch, tên bảng được truy vấn, lỗi console, cấu trúc bảng nguồn và ảnh UI.

**Root cause:** chưa kết luận. Trước đó từng có truy vấn tới bảng employee_profiles không tồn tại trong schema; cần xác minh code hiện tại trước khi khẳng định nguyên nhân gốc.

**Retest:** pending.

## DEF-SHIFT-001 — Backend ca làm việc

Kết quả đã ghi nhận: sửa lỗi và retest PASS. Nên bổ sung request/response trước-sau, commit và kiểm tra dữ liệu sau retest. Không đưa token hoặc credential vào evidence.

## Quy tắc ghi defect

Mỗi defect cần có ID, title, environment/build, severity/priority, precondition, steps, expected, actual, evidence, status, retest result và liên kết test case. Không khẳng định root cause khi chưa có bằng chứng kỹ thuật.
