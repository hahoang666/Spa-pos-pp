# SPA POS — REQUIREMENT BASELINE V1.0

> **Trạng thái:** Draft — chờ chủ dự án chốt
> **Mục đích:** Đây là bộ requirement nguồn chính thức dùng để xây dựng RTM, Test Scenario, Test Case và đối soát kết quả kiểm thử.
> **Phạm vi:** Demo Spa POS
> **Timezone:** Việt Nam (UTC+7)

---

# 1. Mục tiêu kiểm thử

Kiểm thử hệ thống Spa POS theo các yêu cầu chức năng, phi chức năng, phân quyền, tính toàn vẹn dữ liệu, báo cáo và các luồng nghiệp vụ liên module.

Các module chính:

* Xác thực & tài khoản
* Bán hàng / Thu ngân
* Hóa đơn / Hủy / Thu nợ
* Trả hàng
* Liệu trình & hoa hồng
* Sổ quỹ
* Hóa đơn điện tử mô phỏng
* Khách hàng
* Lịch hẹn
* Chấm công
* Báo cáo & Dashboard
* Kho / Nguyên liệu / Danh mục
* Dữ liệu & lưu trữ

---

# 2. Quy tắc chung

## 2.1 Tiền

Hiển thị:

`1.234.567 ₫`

## 2.2 Ngày

Hiển thị:

`dd/mm/yyyy`

## 2.3 Múi giờ

Toàn hệ thống sử dụng giờ Việt Nam (UTC+7).

## 2.4 Doanh thu

Định nghĩa thống nhất:

```text
Doanh thu thuần
= Σ (tiền hàng trước VAT − chiết khấu/giảm giá)
  của hóa đơn bán chưa hủy
− Σ (giá trị trả hàng trước VAT)
```

Không bao gồm:

* VAT
* Tiền thu nợ
* Phiếu thu khác
* Chuyển quỹ
* Hóa đơn đã hủy

Dashboard, báo cáo và Kiểm tra dữ liệu phải dùng cùng logic tính doanh thu.

---

# 3. Phạm vi ca

Ca chỉ phục vụ **chấm công**.

Ca không còn là nghiệp vụ quản lý Sổ quỹ.

Không sử dụng trạng thái ca mở/đóng để chặn bán hàng hoặc giao dịch Sổ quỹ.

---

# 4. Yêu cầu chức năng

## 4.1 Xác thực & tài khoản — AUTH

### AUTH-01 — Đăng nhập

* Đăng nhập bằng tên đăng nhập + mật khẩu.
* Thiếu trường → báo lỗi tại đúng trường.
* Sai thông tin → `"Tên đăng nhập hoặc mật khẩu không đúng"` + số lần còn lại.
* Tên đăng nhập không phân biệt hoa/thường.
* Đúng thông tin → vào Tổng quan.

### AUTH-02 — Khóa tạm

* Sai lần thứ 5 → khóa 15 phút.
* Hiển thị số phút còn lại.
* Đăng nhập đúng trước khi đạt 5 lần → reset bộ đếm.

### AUTH-03 — Khóa thủ công

* Tài khoản bị khóa thủ công không đăng nhập được.
* Hiển thị: `"Tài khoản đã bị khóa"`.

### AUTH-04 — Đăng xuất

* Hiển thị lại màn hình đăng nhập.
* Xóa nội dung/menu hệ thống.
* Back/Reload không được truy cập hệ thống nếu chưa đăng nhập.

### AUTH-05 — Phiên đăng nhập

* Hiển thị: `"Không lưu thông tin đăng nhập trên thiết bị"`.
* `localStorage` không chứa mật khẩu.
* Sau logout không lưu session người dùng theo cách vi phạm yêu cầu.

### AUTH-06 — Đổi mật khẩu

Mật khẩu mới:

* ≥ 8 ký tự
* Có chữ hoa
* Có chữ thường
* Có số
* Có ký tự đặc biệt
* Xác nhận mật khẩu khớp
* Khác mật khẩu cũ

Mật khẩu cũ phải đúng.

Sau khi đổi:

* Mật khẩu mới đăng nhập được.
* Mật khẩu cũ đăng nhập thất bại.

### AUTH-07 — Admin tạo tài khoản

* ID tự sinh.
* Không cho sửa ID.
* Username duy nhất, không phân biệt hoa/thường.
* Mật khẩu theo policy.
* Vai trò chỉ gồm:

  * Quản lý
  * Nhân viên

### AUTH-08 — Quản lý tài khoản

Admin có thể:

* Sửa
* Khóa
* Mở khóa
* Xóa
* Reset mật khẩu

Quy tắc:

* Không sửa/xóa/khóa Admin.
* Không tự xóa chính mình.
* Reset mật khẩu **không tự mở khóa tài khoản đang bị khóa thủ công**.

### AUTH-09 — Phân quyền

Khi quyền bị bỏ:

* Menu/nút/trang tương ứng phải bị ẩn nếu phù hợp.
* Thao tác tương ứng phải bị chặn.
* Không được chỉ dựa vào việc ẩn button.

---

# 4.2 Bán hàng — Thu ngân — SALE

### SALE-01

Thêm sản phẩm vào giỏ bằng:

* Click
* Mã vạch
* Tìm kiếm
* Yêu thích
* Lọc nhóm

Yêu cầu:

* Cộng dồn số lượng.
* Hàng có quản lý tồn không được bán vượt tồn.

### SALE-02 — Tính tiền

```text
Tổng
= Σ(đơn giá × số lượng)
− giảm giá dòng
− giảm giá đơn
```

* Giá đã gồm VAT.
* VAT phải được tách đúng theo từng dòng.

### SALE-03 — Giảm giá

* Giảm dòng không vượt thành tiền dòng.
* Giảm đơn không vượt tổng còn lại.
* Vượt hạn mức → yêu cầu PIN.

### SALE-04 — Thanh toán nhiều phương thức

Cho phép:

* Tiền mặt
* Chuyển khoản
* Ví điện tử
* Thẻ

Có nút `"Điền phần còn lại"`.

Nếu thanh toán thiếu:

* Hóa đơn ở trạng thái `"Còn nợ"`.

### SALE-05 — Hoàn tất bán

* Sinh mã `HDxxxxxx`.
* Không trùng.
* Tăng dần.
* Trừ tồn kho.
* Mỗi phương thức thanh toán sinh phiếu thu tương ứng.
* Có gói → sinh thẻ liệu trình.
* Có quy tắc → sinh hoa hồng.

### SALE-06 — Toàn vẹn khi lỗi

Nếu bất kỳ bước nào thất bại:

* Không thay đổi tồn kho.
* Không thay đổi sổ quỹ.
* Không tạo/thay đổi thẻ liệu trình.
* Không tạo trạng thái bán thành công.

### SALE-07 — Nhiều hóa đơn nháp

Chuyển tab không mất:

* Giỏ hàng
* Khách hàng
* Nhân viên

Sau khi thanh toán một đơn:

* Đơn đó biến mất.
* Các đơn khác vẫn nguyên vẹn.

### SALE-08 — Thêm nhanh khách hàng

* Khách mới được chọn ngay tại quầy.
* SĐT trùng → chặn.

### SALE-09 — In hóa đơn gần nhất

* Nội dung đúng hóa đơn.
* Ký tự đặc biệt trong tên khách không phá layout.

### SALE-10 — Tạo hóa đơn từ màn Hóa đơn

Áp dụng cùng quy tắc của:

* SALE-02
* SALE-03
* SALE-04
* SALE-05
* SALE-06

---

# 4.3 Hóa đơn / Hủy / Thu nợ — INV

### INV-01

Danh sách hóa đơn hỗ trợ:

* Lọc
* Tìm kiếm
* Phân trang
* Ẩn/hiện cột
* Xuất Excel

File Excel phải là file Excel hợp lệ, mở được không cảnh báo sai định dạng.

### INV-02 — Hủy hóa đơn

Yêu cầu:

* Có quyền.
* Có lý do.
* Có phê duyệt.
* Không thực hiện khi kỳ bị khóa.
* Không thực hiện khi điều kiện nghiệp vụ bị chặn.

Hoàn kho:

* Đúng số lượng.
* Không hoàn lại phần đã trả hàng trước đó.

Hoàn tiền:

* Đúng phương thức đã thu.
* Đúng số tiền thực thu.

Phải đảo các dữ liệu liên quan:

* Thẻ liệu trình
* Hoa hồng
* Nguyên liệu
* Sổ quỹ

Phải ghi nhật ký.

### INV-03 — Hóa đơn đã cấp HĐĐT

Nếu hóa đơn đã cấp HĐĐT:

* Không được hủy trực tiếp.
* Phải đi qua quy trình HĐĐT:

  * Hủy
  * Thay thế
  * Điều chỉnh
* Có liên kết giữa hóa đơn gốc và hóa đơn liên quan.

### INV-04 — Thu nợ

* Số tiền > 0.
* Không vượt số còn nợ.
* Không áp dụng cho Khách lẻ.
* Sinh phiếu thu `"Thu nợ khách"`.
* Đủ tiền → trạng thái `"Đã thanh toán"`.
* Quyền thu nợ là quyền riêng.
* Không dùng quyền `"Xem thanh toán"` thay thế.

### INV-05 — Công nợ

```text
Công nợ
= Tổng
− Đã thu
− Đã hoàn
```

Dashboard, khách hàng và Công nợ phải thu phải cùng một con số.

---

# 4.4 Trả hàng — RET

### RET-01

* Cho phép trả một phần/nhiều lần.
* SL trả ≤ SL còn trả được.
* Tiền hoàn = giá trị dòng sau phân bổ giảm giá.
* Tổng hoàn ≤ số tiền đã thu.

### RET-02 — Trả gói

* Hoàn = giá trị các buổi chưa dùng + VAT.
* Thẻ chuyển `"Đã hủy"`.
* Hoa hồng các buổi đã dùng bị đảo.
* Sổ cái doanh thu hoãn có bút toán hủy tương ứng.

### RET-03

Hóa đơn đã có HĐĐT:

* Tự sinh hóa đơn `"Điều chỉnh giảm"`.
* Liên kết hóa đơn gốc.

### RET-04 — Toàn vẹn

Nếu quỹ không đủ tiền hoàn:

* Không thay đổi tồn kho.
* Không thay đổi thẻ.
* Không thay đổi hóa đơn.
* Không tạo thành công phiếu trả.

### RET-05

Sau trả hàng:

* Doanh thu thuần của hóa đơn giảm tương ứng.
* Báo cáo giảm tương ứng.

---

# 4.5 Liệu trình & hoa hồng — THER / COMM

### THER-01

Khi bán gói:

```text
Số buổi thẻ
= Số buổi gói × Số lượng
```

Hạn dùng:

```text
Ngày bán + số ngày hiệu lực
```

Tính theo giờ Việt Nam, không lệch ngày.

### THER-02 — Thực hiện buổi

Bắt buộc:

* Nhân viên thực hiện.
* Tên khách xác nhận.
* Tick đồng ý.

Chặn khi:

* Hết buổi.
* Hết hạn.
* Thiếu nguyên liệu.

Khi thành công:

* Giảm 1 buổi.
* Chuyển đúng giá trị 1 buổi sang doanh thu thực hiện.
* Trừ nguyên liệu theo định mức.

### THER-03 — Hoàn tác

* Cộng lại 1 buổi.
* Cộng lại nguyên liệu.
* Đảo doanh thu.
* Đảo hoa hồng.
* Không hoàn tác quá tổng số buổi đã thực hiện.

### THER-04 — Hết hạn

Theo cấu hình:

* Giữ số dư; hoặc
* Ghi nhận doanh thu phần còn lại.

Phải chạy đúng một lần, không lặp.

### COMM-01

```text
Hoa hồng bán hàng
= Doanh thu dòng sau giảm giá × tỷ lệ
```

Chỉ tính khi:

* Có quy tắc.
* Có nhân viên.

Gói liệu trình không tính hoa hồng lúc bán.

### COMM-02

Hoa hồng thực hiện buổi tính trên:

```text
Giá trị 1 buổi × tỷ lệ
```

Không tính trên giá cả gói.

### COMM-03

Nhân viên trong:

* Hóa đơn
* Liệu trình
* Lịch hẹn
* Chấm công
* Hoa hồng

phải thuộc cùng một danh mục nhân viên.

---

# 4.6 Sổ quỹ — CASH

### CASH-01

Phiếu thu/chi thủ công:

* Đối tượng bắt buộc.
* Số tiền > 0.
* Ghi chú.
* Phương thức.
* Mã `PT/PC` duy nhất.
* Chi vượt số dư → chặn.

### CASH-02 — Chuyển quỹ

* Quỹ nguồn ≠ quỹ đích.
* Nguồn đủ tiền.
* Sinh 1 phiếu chi + 1 phiếu thu cùng mã chuyển.
* Không tính vào doanh thu/chi phí.

### CASH-03 — Đảo phiếu

* Có quyền.
* Có phê duyệt.
* Có lý do.
* Mỗi phiếu chỉ đảo tối đa một lần.
* Không đảo phiếu đảo.

### CASH-04 — Khóa kỳ

Kỳ bị khóa:

* Không thêm giao dịch.
* Không sửa giao dịch.
* Không hủy giao dịch.

Mở lại:

* Cần lý do.
* Cần PIN.

Khóa tới ngày tương lai:

* Có cảnh báo.
* Không được gây lỗi/mất dữ liệu khi bán hàng.

### CASH-05 — Số dư

```text
Số dư
= Đầu kỳ + Thu − Chi
```

Theo từng quỹ.

```text
Tổng quỹ
= Tổng các quỹ
```

Khớp với báo cáo Sổ quỹ.

### CASH-06

Báo cáo Sổ quỹ:

* Số liệu khớp màn hình.
* Xuất Excel/PDF.
* Bản in có đủ chữ ký.
* Có nhãn DEMO.

> Lưu ý: Ca không thuộc CASH.

---

# 4.7 Hóa đơn điện tử mô phỏng — EINV

### EINV-01

Chỉ xuất HĐĐT khi:

* Hóa đơn đã thanh toán.
* Chưa xuất HĐĐT.
* Có hồ sơ đơn vị bán.

Số hóa đơn:

* Tăng dần.
* Theo ký hiệu.
* Không xuất lần hai.

### EINV-02

Hủy/thay thế/điều chỉnh:

* Có lý do.
* Có phê duyệt.
* Dùng cơ chế PIN thống nhất.
* Có chuỗi liên kết gốc → liên quan.

### EINV-03

Mã số thuế:

* 10 số hoặc
* 13 số.

Bắt buộc có hồ sơ đơn vị bán trước khi xuất.

---

# 4.8 Khách hàng — CUST

### CUST-01

Tên bắt buộc.

SĐT:

* Đúng 10 chữ số tự nhiên.
* Không trùng.

MST:

* 10 hoặc 13 số.

### CUST-02

Không cho xóa khách đã có giao dịch.

Khách lẻ:

`KH000001`

* Không được xóa.
* Không được đổi mã.

### CUST-03

Lịch sử mua:

* Phân biệt hóa đơn đã hủy.
* Công nợ trừ phần đã hoàn.

---

# 4.9 Lịch hẹn — APPT

### APPT-01

Tạo lịch bắt buộc:

* Khách.
* Ngày.
* Giờ bắt đầu.
* Giờ kết thúc.
* Nhân viên.

Quy tắc:

```text
Giờ kết thúc > Giờ bắt đầu
```

Không cho phép trùng lịch cùng nhân viên.

### APPT-02

Có thể:

* Sửa lịch.
* Hủy lịch.
* Đổi trạng thái.

### APPT-03

Nhắc lịch:

* Nhắc trước giờ hẹn theo khoảng cấu hình.
* Đã đọc → không hiện lại.
* Lịch đã qua → không nhắc lại.

---

# 4.10 Chấm công — ATT

### ATT-01

* Tài khoản phải liên kết hồ sơ nhân viên.
* Có thể tạo/liên kết khi tạo tài khoản.
* Chấm công vào/ra đúng.
* Đúng giờ/đi muộn theo ca 08:00–17:30.
* Tính giờ công chính xác.

### ATT-02 — GPS

Phải thực sự kiểm tra vị trí.

Chỉ hiển thị trạng thái:

> `"Đang ở trong phạm vi: Văn phòng"`

khi kết quả GPS thực sự xác nhận thiết bị nằm trong vùng cho phép.

Không được coi là hợp lệ nếu:

* Không lấy được vị trí.
* Chưa kiểm tra vị trí.
* Chỉ dựa vào text cố định.

### ATT-03

Bảng công tháng:

* Tổng hợp từ bản ghi ngày.
* Số liệu phải khớp dữ liệu chấm công thực tế.

---

# 4.11 Báo cáo & Dashboard — RPT

### RPT-01

Dashboard theo kỳ:

* Hôm nay
* Tuần/tháng/quý/năm tùy cấu hình

Phải đúng:

* Doanh thu
* Số hóa đơn
* Khách mới/cũ
* Công nợ
* Tổng thu/chi

Ranh giới kỳ:

* 00:00
* 23:59
* Đầu tháng
* Đầu quý
* Đầu năm

theo giờ Việt Nam.

### RPT-02

Doanh thu dùng công thức duy nhất:

```text
Doanh thu thuần
= Σ (tiền hàng trước VAT − chiết khấu/giảm giá)
  của hóa đơn bán chưa hủy
− Σ (giá trị trả hàng trước VAT)
```

### RPT-03

Bộ báo cáo chuẩn:

* Excel thật `.xlsx/.xls`.
* Mở được không cảnh báo sai định dạng.
* PDF có nhãn DEMO.

Mỗi báo cáo có nút xuất riêng:

* Xuất Excel
* Xuất PDF

Không bắt buộc tải đồng loạt cả 7 báo cáo.

### RPT-04

Màn `"Kiểm tra dữ liệu"`:

* Không báo lỗi với dữ liệu hợp lệ do chính hệ thống tạo ra.

---

# 4.12 Kho / Nguyên liệu / Danh mục — STOCK

## STOCK-01 — Nhập hàng

Nhập hàng phải:

* Gắn nhà cung cấp.
* Ghi số lượng.
* Ghi giá nhập.
* Xác định kho.
* Tạo `stockMovements`.

## STOCK-02 — Trả hàng nhập

Trả nhà cung cấp:

* Giảm tồn đúng số lượng.
* Tạo `stockMovements`.
* Không làm tồn âm.

## STOCK-03 — Xuất hủy

Xuất hủy phải:

* Có số lượng.
* Có lý do.
* Xác định kho.
* Tạo `stockMovement`.

## STOCK-04 — Chuyển kho

Quỹ đạo:

```text
Kho nguồn
→ Xuất
→ Kho đích
→ Nhập
```

Kho nguồn và kho đích phải khác nhau.

Số lượng nguồn phải đủ.

## STOCK-05 — Kiểm kho

Kiểm kho phải có:

* Tồn hệ thống.
* Tồn thực tế.
* Chênh lệch.

Chênh lệch phải tạo giao dịch điều chỉnh kho.

## STOCK-06 — Nguyên liệu

Kho nguyên liệu phải được quản lý như tồn kho.

Khi thực hiện dịch vụ có định mức:

```text
Thực hiện dịch vụ
→ Đọc định mức
→ Trừ nguyên liệu
→ Ghi stockMovement
```

## STOCK-07 — Định mức

Định mức phải xác định được:

* Dịch vụ.
* Nguyên liệu.
* Số lượng tiêu hao.

## STOCK-08 — Tồn kho không âm

Không được tạo giao dịch khiến tồn kho < 0.

## STOCK-09 — Nguồn dữ liệu tồn kho

```text
Tồn hiện tại
= Tổng các stockMovements hợp lệ
```

Mọi biến động tồn kho phải có dấu vết trong `stockMovements`.

## STOCK-10 — Danh mục

Phạm vi danh mục:

* Sản phẩm.
* Dịch vụ.
* Nguyên liệu.
* Nhà cung cấp.
* Bảng giá.
* Kho.

---

# 4.13 Dữ liệu & lưu trữ — DATA

### DATA-01

F5 hoặc đóng/mở trình duyệt:

Các dữ liệu phải còn:

* Hóa đơn.
* Khách hàng.
* Sản phẩm.
* Sổ quỹ.
* Dữ liệu ca/chấm công.
* Liệu trình.

### DATA-02

Lần chạy đầu:

* Có Khách lẻ `KH000001`.
* Có danh mục sản phẩm mẫu.

### DATA-03

Nạp dữ liệu mẫu:

* Chạy không lỗi.
* Không phụ thuộc trạng thái trước đó.
* Kiểm tra dữ liệu không báo lệch.
* Logic dữ liệu mẫu phải giống logic hệ thống thật.
* Đặc biệt kiểm tra doanh thu gói và hoa hồng buổi.

### DATA-04

Reset:

* Chỉ chạy khi người dùng chủ động bấm.
* Có xác nhận.
* Không tự reset khi tải lại trang.

---

# 5. Yêu cầu phi chức năng — NFR

### NFR-01

Tương thích:

* Chrome
* Edge
* Safari
* Firefox

Responsive:

* ≥ 360px
* Desktop
* Mobile

Menu mobile hoạt động.

### NFR-02

Tiền:

`1.234.567 ₫`

Ngày:

`dd/mm/yyyy`

Timezone:

UTC+7.

### NFR-03

Dữ liệu người dùng nhập phải được escape khi hiển thị/in.

Test:

```text
<b>
"
'
<script>
```

Không được thực thi HTML/JavaScript.

### NFR-04

1.000 hóa đơn:

* Lọc/phân trang < 1 giây.

### NFR-05

localStorage:

* Cảnh báo khi gần đầy.
* Lỗi lưu phải được thông báo.
* Không được im lặng khi lưu thất bại.

### NFR-06

Các thao tác yêu cầu:

* Lý do.
* PIN.

không được tiếp tục nếu:

* Blank.
* Chỉ có khoảng trắng.
* Người dùng bấm Hủy.

### NFR-07

Login có thể thao tác bằng bàn phím.

* Tab.
* Shift + Tab.
* Enter.

Lỗi phải gắn đúng trường.

### NFR-08

Production:

* Authentication server-side.
* Authorization server-side.
* PIN server-side.
* Password hashing.
* Không có password/PIN mặc định.
* Không lưu thông tin nhạy cảm ở client.

### NFR-09 — Transaction consistency

Các thao tác quan trọng phải đảm bảo:

> Hoặc hoàn thành đầy đủ, hoặc không làm thay đổi dữ liệu liên quan.

Áp dụng đặc biệt cho:

* Bán hàng.
* Thanh toán.
* Hủy hóa đơn.
* Trả hàng.
* Thực hiện liệu trình.
* Hoàn tác.
* Sổ quỹ.

### NFR-10 — Auditability

Các thao tác nhạy cảm phải truy vết được:

* Người thực hiện.
* Thời gian.
* Đối tượng/giao dịch.
* Hành động.
* Lý do.
* Phê duyệt nếu có.

---

# 6. Môi trường & điều kiện kiểm thử

## Environment

* Xóa `localStorage` trước mỗi chu kỳ kiểm thử.
* Chuẩn bị dữ liệu theo Section 8.
* Mở DevTools → Console.
* Ghi nhận mọi JS error trong luồng nghiệp vụ.
* JS error ảnh hưởng luồng nghiệp vụ → P1.

## Demo credentials

```text
Username: admin
Password: 1111

Approval PIN: 1234
```

Chỉ dùng cho môi trường demo.

## Roles

Kiểm thử tối thiểu:

* Admin
* Quản lý
* Nhân viên

## Entry Criteria

Luồng bán hàng phải tạo được hóa đơn.

`DEF-01` phải được xử lý trước khi thực hiện regression đầy đủ.

## Exit Criteria

* 0 P1 mở.
* Số liệu đối soát Section 8 khớp.
* Không còn JS error chưa được đánh giá trong các luồng đã thực thi.

---

# 7. Ma trận quyền

| Thao tác                       | Admin | Quản lý | Nhân viên |
| ------------------------------ | ----: | ------: | --------: |
| Thu ngân / tạo hóa đơn         |     ✔ |       ✔ |         ✔ |
| Thu nợ                         |     ✔ |       ✔ |         ✘ |
| Hủy hóa đơn / Trả hàng         |     ✔ |       ✔ |         ✘ |
| Đảo phiếu                      |     ✔ |       ✔ |         ✘ |
| Khóa kỳ                        |     ✔ |       ✔ |         ✘ |
| Chuyển quỹ                     |     ✔ |       ✔ |         ✘ |
| Quản lý tài khoản / Phân quyền |     ✔ |       ✘ |         ✘ |

Quyền phải được kiểm tra ở action/UI flow, không chỉ bằng cách ẩn button.

---

# 8. Bộ dữ liệu đối soát

## T-01

1 dòng:

`110.000 ₫`, VAT 10%.

Expected:

* Trước VAT: 100.000
* VAT: 10.000

## T-02

2 dòng × 110.000 ₫, VAT 10%.

Expected:

* Trước VAT: 200.000
* VAT: 20.000
* Tổng: 220.000

## T-03

3 dòng:

* Có giảm giá dòng.
* Có giảm giá toàn đơn.

VAT và doanh thu từng dòng phải cộng đúng tổng đơn.

Sai số làm tròn ≤ 1 ₫.

## T-04

Bán gói:

* 11 buổi.
* 6.500.000 ₫.
* VAT 10%.
* Dùng 3 buổi.
* Sau đó trả gói.

Expected:

* Hoàn giá trị 8 buổi chưa dùng + VAT.
* Hoa hồng 3 buổi đã dùng bị đảo.

## T-05

Thanh toán:

* 1.000.000 tiền mặt.
* 1.200.000 chuyển khoản.

Sau đó hủy.

Expected:

* Hoàn 1.000.000 tiền mặt.
* Hoàn 1.200.000 chuyển khoản.

## T-06

Hóa đơn nợ:

* Thu nợ lần 1.
* Thu nợ lần 2.
* Sau đó hủy.

Expected:

* Hoàn đúng phương thức/số tiền từng lần thu.

## T-07

Mua 5 → trả 2 → hủy.

Expected:

* Tồn kho tăng tổng cộng đúng 5.
* Không tăng 7.
* Hoàn tiền theo số tiền thực thu/còn đủ điều kiện.

## T-08

Khóa kỳ đến hôm nay → bán.

Expected:

* Bị chặn.
* Tồn kho không đổi.
* Không tạo giao dịch bán thành công.

## T-09

Quỹ tiền mặt = 0 → trả hàng hoàn tiền mặt.

Expected:

* Bị chặn.
* Không thay đổi tồn kho.
* Không thay đổi thẻ.
* Không thay đổi hóa đơn.

## T-10

Ca 22:00 → bán lúc 00:30.

Phạm vi kiểm thử thuộc ATT/SHIFT vì ca không còn thuộc Sổ quỹ.

## T-11

Gói 6.500.000 ₫ / 11 buổi.

Commission 10%.

Expected:

```text
6.500.000 / 11 × 10%
≈ 59.091 ₫/buổi
```

Không được tính:

`650.000 ₫`.

## T-12

Sau T-01 → F5.

Expected:

* Hóa đơn còn.
* Tồn kho còn.
* Sổ quỹ còn.

---

# 9. Known Defects

## P1

| ID     | Defect                                                                                   |
| ------ | ---------------------------------------------------------------------------------------- |
| DEF-01 | `createInvoice` dùng `revenueFields` chưa khai báo; tạo hóa đơn lỗi và tồn kho đã bị trừ |
| DEF-02 | `spa_pos_demo_reset_v3` chưa được ghi; reload làm mất dữ liệu                            |
| DEF-03 | Nạp dữ liệu mẫu lỗi vì thiếu sản phẩm GDV033                                             |
| DEF-04 | VAT nhiều dòng tính sai                                                                  |
| DEF-05 | Hủy hóa đơn hoàn kho/hoàn tiền sai                                                       |
| DEF-06 | Trả hàng thay đổi dữ liệu trước khi chắc chắn hoàn tiền                                  |
| DEF-07 | Hoa hồng buổi tính trên giá cả gói                                                       |
| DEF-08 | Giảm giá dòng không kiểm soát hạn mức                                                    |
| DEF-09 | Nhân viên được phép Thu nợ                                                               |
| DEF-10 | Dashboard revenue khác báo cáo                                                           |
| DEF-12 | Ca xuyên đêm biến mất — thuộc ATT/SHIFT                                                  |
| DEF-13 | Session/mật khẩu lưu localStorage                                                        |

## P2

| ID     | Defect                                                               |
| ------ | -------------------------------------------------------------------- |
| DEF-11 | Thẻ liệu trình thiếu `vatRate`; dữ liệu mẫu doanh thu gói sai logic  |
| DEF-14 | PIN cố định; HĐĐT dùng PIN riêng                                     |
| DEF-15 | `accounts` và `employees` là hai danh mục khác nhau                  |
| DEF-16 | Nhắc lịch sai; trạng thái đã đọc mất; trước đây chưa có sửa/hủy lịch |

## P3

| ID     | Defect                                                             |
| ------ | ------------------------------------------------------------------ |
| DEF-17 | Excel thực chất là HTML đổi đuôi `.xls`                            |
| DEF-18 | Location trước đây là text cố định — baseline mới yêu cầu GPS thật |

---

# 10. Nguyên tắc kiểm thử sau khi Baseline được chốt

Sau khi Baseline v1.0 được phê duyệt:

1. Không tự ý thay đổi expected result trong Test Case.
2. Requirement mới phải được cập nhật version.
3. Defect không được tự động thay đổi requirement.
4. Test Case phải trace được về Requirement ID.
5. Test Scenario/Test Case phải sử dụng bộ dữ liệu T-01 trở đi khi phù hợp.
6. Các module liên quan phải được regression sau khi sửa P1.
7. Số liệu cuối cùng phải đối soát theo cùng định nghĩa doanh thu và tồn kho.

---

# 11. Trạng thái Baseline

**BASELINE V1.0 — CHỜ CHỦ DỰ ÁN PHÊ DUYỆT**

Sau khi được phê duyệt, tài liệu này là **Requirement Source of Truth** cho hoạt động QA của Spa POS.

Các thay đổi sau đó phải tạo version mới, ví dụ:

`Baseline v1.1`, `Baseline v1.2`...
