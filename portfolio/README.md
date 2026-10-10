# QA Tester Portfolio — Spa POS

**Mục tiêu:** ứng tuyển QA Tester Intern / Fresher. Cập nhật: 10/10/2026.

## Giới thiệu

Portfolio ghi lại quá trình thực hành QA trên Spa POS: phân tích yêu cầu, thiết kế test case, kiểm thử UI/API, xác minh dữ liệu, ghi nhận defect, retest và regression.

## Phạm vi thực hành

- Manual, UI, Functional và Validation Testing.
- Role & Permission Testing theo vai trò.
- API Testing bằng Postman và Supabase REST/RPC.
- Backend data verification với Supabase.
- Defect reporting, retest và regression.
- Requirement traceability theo Requirement Baseline v1.0.

## Tài liệu

- [Test Strategy](test-strategy.md)
- [Test Execution Samples](test-execution-samples.md)
- [API Test Report](api-test-report.md)
- [Defect Log](defect-log.md)
- [Requirement Baseline Highlights](requirement-baseline.md)

## Trạng thái hiện tại

- Ca làm việc và các luồng thanh toán/hủy hóa đơn đã được kiểm thử qua API.
- Đồng bộ khách hàng, phương thức thanh toán, phân loại dịch vụ/hàng hóa: PASS trong đợt retest đã ghi nhận.
- Đồng bộ hồ sơ nhân viên: 4 test case đang FAIL.
- Xác minh toàn vẹn dữ liệu sau khi từ chối hủy hóa đơn đã thanh toán: pending.

## Nguyên tắc QA

Tôi không xem response API là bằng chứng duy nhất khi cần kiểm tra dữ liệu. Tôi phân biệt PASS, FAIL, BLOCKED, N/A và Pending verification; không kết luận nguyên nhân gốc nếu chưa có bằng chứng.

## Công cụ

Postman, Supabase REST/RPC, Supabase SQL Editor, Browser DevTools, GitHub, Markdown/Excel.

## Bảo mật

Không đưa mật khẩu, JWT, service-role key, secret môi trường hoặc dữ liệu khách hàng thật vào repository. Ảnh chụp và response công khai phải được làm sạch thông tin nhạy cảm.
