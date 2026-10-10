# Spa POS — QA Tester Portfolio

Portfolio thực hành kiểm thử phần mềm hướng tới vị trí **QA Tester Intern / Fresher**.

Dự án này ghi lại quá trình kiểm thử một ứng dụng quản lý bán hàng và vận hành spa: từ phân tích yêu cầu, thiết kế test case, kiểm thử UI/API, xác minh dữ liệu, báo cáo defect đến retest và regression.

## About this project

- **Product:** Spa POS — ứng dụng POS cho spa.
- **QA focus:** Manual Testing, Functional Testing, Role & Permission Testing, API Testing, Data Integrity, Defect Management.
- **Tools:** Postman, Supabase REST/RPC, Supabase SQL Editor, Browser DevTools, GitHub, Markdown/Excel.
- **Requirement source:** Requirement Baseline v1.0 đã thống nhất cho test scenario, test case, RTM và regression.
- **Last documented update:** 10 October 2026.

## Portfolio documents

| Document | What it demonstrates |
|---|---|
| [QA Portfolio Overview](portfolio/README.md) | Tổng quan dự án, kỹ năng và trạng thái hiện tại |
| [Test Strategy](portfolio/test-strategy.md) | Phạm vi, risk-based approach và tiêu chí kiểm thử |
| [Test Execution Samples](portfolio/test-execution-samples.md) | Test case, expected/actual result và trạng thái thực thi |
| [API Test Report](portfolio/api-test-report.md) | Kiểm thử ca làm việc, thanh toán và hủy hóa đơn |
| [Defect Log](portfolio/defect-log.md) | Báo cáo lỗi, retest và defect còn mở |
| [Requirement Baseline Highlights](portfolio/requirement-baseline.md) | Quy tắc nghiệp vụ và định hướng traceability |

## Practical work completed

- Kiểm thử mở/đóng ca, kiểm soát ca thuộc người dùng và dữ liệu đầu ca.
- Kiểm thử thanh toán đủ, thanh toán một phần, số tiền bằng 0/vượt số còn phải trả.
- Kiểm thử hủy hóa đơn chưa thanh toán và chặn hủy trực tiếp hóa đơn đã thanh toán.
- Retest đồng bộ khách hàng, sản phẩm/dịch vụ và phương thức thanh toán.
- Phát hiện nhóm lỗi đồng bộ hồ sơ nhân viên và ghi nhận 4 test case FAIL để tiếp tục điều tra.

## Current QA status

**Đã có kết quả thực hành:** các luồng API ca làm việc và thanh toán nêu trong báo cáo; các test đồng bộ khách hàng, phương thức thanh toán và phân loại sản phẩm/dịch vụ đã PASS trong đợt retest được ghi nhận.

**Còn mở / cần xác minh:** 4 test case đồng bộ hồ sơ nhân viên đang FAIL; kiểm tra toàn vẹn dữ liệu sau khi từ chối hủy hóa đơn đã thanh toán còn pending. Chi tiết tại [Defect Log](portfolio/defect-log.md) và [API Test Report](portfolio/api-test-report.md).

## How I approach testing

1. Đọc yêu cầu và xác định rủi ro nghiệp vụ.
2. Viết test scenario/test case có precondition, steps và expected result rõ ràng.
3. Kiểm thử positive, negative, validation và permission.
4. Đối chiếu response API với trạng thái dữ liệu backend.
5. Ghi defect có thể tái hiện; retest sau sửa và kiểm tra regression.
6. Báo cáo trung thực PASS / FAIL / BLOCKED / N/A / Pending verification.

## Learning roadmap

- Tiếp tục hoàn thiện API test collection và evidence đã loại bỏ credential.
- Hoàn tất defect đồng bộ hồ sơ nhân viên.
- Bổ sung SQL cơ bản và truy vấn xác minh dữ liệu chỉ đọc.
- Tăng độ bao phủ regression và chuẩn hóa RTM.

## Security note

Repository công khai không chứa mật khẩu, JWT, Supabase service-role key, secret môi trường hoặc dữ liệu khách hàng thật. Mọi ảnh chụp và request/response bổ sung phải che thông tin nhạy cảm.

---

*Portfolio cá nhân được xây dựng từ thực hành dự án. Các kết quả chỉ phản ánh phạm vi đã thực thi và bằng chứng đã ghi nhận; những mục pending được nêu rõ thay vì tuyên bố đã hoàn tất.*
