# Cờ đam MIPS

Trò chơi cờ đam hai người chơi viết bằng hợp ngữ MIPS cho MARS. Bàn cờ có kích thước 8 × 8; chỉ 32 ô tối được sử dụng.

## Chạy chương trình

Mở MARS và nạp `checkers.asm`, hoặc chạy MARS từ PowerShell:

```powershell
java -jar "C:\Users\ADMIN\Downloads\Mars4_5.jar" checkers.asm
```

Đen đi trước. Mỗi lượt nhập số ô của quân muốn đi; chương trình liệt kê các nước đi hợp lệ của quân đó (ví dụ `1) 22-17`, `2) 22-18`, dấu `x` là nước ăn) và người chơi nhập số thứ tự nước muốn đi. Khi có thể ăn tiếp, chương trình liệt kê các nước ăn tiếp của quân vừa ăn để chọn tiếp. Nhập `0` tại lời nhắc ô xuất phát để thoát, `H` để đề nghị hòa, `M` để chơi lại từ đầu. Nếu lựa chọn không hợp lệ, chương trình yêu cầu chọn lại từ ô xuất phát (trong chuỗi ăn bắt buộc chỉ chọn lại nước ăn).

## Chạy testcase

Tạo file `.env` từ mẫu `.env.example` và đặt đường dẫn đến MARS trong biến `MARS_JAR`.

```powershell
python .\tests\checkers_mars_tests.py
```

Mỗi commit thêm tính năng đều bổ sung testcase Python cho tính năng đó. Bộ kiểm thử chạy MARS ở chế độ dòng lệnh, kiểm tra khởi tạo bàn cờ, nhập sai, đổi lượt, ăn quân, ăn liên tiếp, phong vua, ăn lùi bằng vua và điều kiện thắng. Có thể truyền đường dẫn MARS khác để ghi đè giá trị trong `.env`:

```sh
python .\tests\checkers_mars_tests.py --mars-jar "C:\path\to\Mars4_5.jar"
```

## Cách biểu diễn bàn cờ

Bàn cờ được lưu trong mảng `board` gồm 64 byte, tương ứng 8 hàng × 8 cột. Các ô sáng không thể đi; ô tối chứa một trong các giá trị:

| Giá trị | Ý nghĩa |
|---:|---|
| `0` | Ô trống |
| `1` | Tốt Đen |
| `-1` | Tốt Đỏ |
| `2` | Vua Đen |
| `-2` | Vua Đỏ |

Người chơi nhập số ô từ **1 đến 32**. Số ô được đổi thành tọa độ hàng/cột; hàng được đánh số từ trên xuống. Khi hiển thị bàn cờ, `b`/`r` là tốt Đen/Đỏ, `B`/`R` là vua Đen/Đỏ, `0` là ô tối trống và khoảng trắng là ô sáng.

## Luồng xử lý

Chương trình chính (`main`) điều phối lượt đi; các bước tính toán được tách thành hàm con gọi bằng `jal`:

| Hàm | Việc làm |
|---|---|
| `initialize_board` | Đặt quân Đỏ ở ba hàng trên, quân Đen ở ba hàng dưới. |
| `display_board` | In trạng thái bàn cờ. |
| `read_number` | Đọc một dòng bằng `syscall 8` rồi tự chuyển sang số; trả về `-1` nếu dòng trống hoặc không phải số, `-2` (kèm chữ cái trong `$v1`) nếu là lệnh một chữ cái. |
| `square_to_index` | Đổi số ô 1–32 (theo góc nhìn bên đang đi) sang chỉ số 0–63 trong `board`. |
| `index_to_square` | Đổi ngược chỉ số 0–63 sang số ô 1–32 để in ra. |
| `validate_move` | Kiểm tra ô đến trống, đúng hướng, đúng đường chéo; trả về 0 (sai), 1 (đi thường) hoặc 2 (ăn quân). |
| `build_move_list` | Thử mọi ô đích 1–32 bằng `validate_move`, ghi các nước hợp lệ của một quân vào `move_list`. |
| `print_move_list` | In danh sách nước đi đã đánh số để người chơi chọn. |
| `record_move` | Ghi bước đi vừa áp dụng vào `last_path` (nối thêm khi ăn liên tiếp). |
| `print_game_status` | In số quân mỗi bên và nước vừa đi dưới bàn cờ. |
| `print_with_number` | In "chuỗi + số + chuỗi", dùng cho thông báo lỗi có kèm số đã nhập. |
| `has_any_move` | Kiểm tra bên đang đến lượt còn nước đi hợp lệ hay không. |

1. `source_prompt` nhận ô xuất phát; `move_menu` gọi `build_move_list` và `print_move_list`, rồi đọc số thứ tự nước đi.
2. `apply_move` cập nhật quân; nếu ăn thì xóa quân đối phương ở ô giữa. Nếu tốt đến hàng cuối, chương trình phong vua.
3. Sau nước ăn, `build_move_list` (chỉ tính nước ăn khi `$s7 = 1`) tìm nước ăn tiếp cho cùng quân; nếu có thì quay lại `move_menu` và bắt buộc ăn tiếp.
4. `finish_turn` đổi lượt rồi gọi `has_any_move`. Nếu bên sắp đi hết quân hoặc mọi quân đều bị chặn, bên vừa đi thắng.

## Phạm vi

- Ăn quân ở đầu lượt chưa bắt buộc; nếu đã ăn mà còn nước ăn tiếp thì phải tiếp tục.
- Vua di chuyển và ăn chéo theo cả hai hướng.
- Chương trình phát hiện thắng khi đối phương hết quân hoặc còn quân nhưng không còn nước đi hợp lệ.
- Ô xuất phát nhận `0` để thoát; các ô đi hợp lệ nằm trong khoảng 1–32. Nhập chữ, dòng trống hoặc ký tự lạ sẽ được báo lỗi và yêu cầu nhập lại thay vì làm MARS dừng chương trình.

## Tính năng mở rộng

### Xoay bàn cờ theo người đang đi

- **Lý do:** Bên Đỏ ngồi đối diện bên Đen; nếu bàn cờ luôn in với Đen ở dưới thì đến lượt Đỏ, người chơi phải tự hình dung ngược hướng đi. Xoay bàn cờ giúp cả hai bên luôn thấy quân mình ở dưới và đi lên.
- **Cách làm:** `display_board` in dòng tiêu đề cho biết góc nhìn, rồi duyệt các ô hiển thị như cũ. Khi `$s4 < 0` (lượt Đỏ), ô hiển thị thứ `i` lấy dữ liệu từ ô `63 - i` của `board`, tức xoay 180 độ. Mảng `board` không đổi nên phần kiểm tra nước đi giữ nguyên.

### Đánh số ô theo người đang đi

- **Lý do:** Khi bàn cờ đã xoay, nếu số ô vẫn theo góc nhìn Đen thì Đỏ thấy số chạy ngược (32 ở góc trên bên trái), rất dễ nhập nhầm. Với cách đánh số theo người chơi, ô dưới cùng bên trái của cả hai bên đều là ô 29 và quân mình luôn nằm ở các ô 21–32 khi bắt đầu ván.
- **Cách làm:** Xoay 180 độ biến ô số `n` thành ô số `33 - n`. Vì vậy `square_to_index` đổi `n` thành `33 - n` trước khi tính tọa độ khi `$s4 < 0`, còn `display_board` in số `33 - n` cho từng ô. Phần còn lại của chương trình vẫn làm việc với chỉ số 0–63 trong `board`.

### Chọn nước đi từ danh sách

- **Lý do:** Gõ ô đến dễ sai (nhầm hướng, nhầm ô có quân, quên luật ăn). Khi chương trình tự liệt kê các nước hợp lệ, người chơi chỉ cần chọn, không thể nhập một nước sai luật. Chọn nhầm một quân bị chặn cũng được báo ngay thay vì phải đoán ô đến. Trong chuỗi ăn, danh sách chỉ gồm các nước ăn tiếp nên người chơi thấy rõ mình bắt buộc phải đi đâu.
- **Cách làm:** `build_move_list` thử lần lượt ô đích 1–32 (theo góc nhìn bên đang đi) bằng `validate_move` và lưu các ô hợp lệ vào mảng `move_list`. Vì thử theo số ô tăng dần nên danh sách đã được sắp xếp sẵn. `print_move_list` in từng nước theo ký hiệu cờ đam (`-` đi thường, `x` ăn quân). Lựa chọn `k` lấy ô đích từ `move_list[k - 1]`; nước ăn được nhận ra khi hàng đích cách hàng xuất phát 2 hàng. Cùng hàm này cũng dùng để kiểm tra còn nước ăn tiếp (`$s7 = 1` khiến `validate_move` chỉ nhận nước ăn) và kiểm tra bên sắp đi còn nước hay không.

### Thông báo lỗi rõ ràng

- **Lý do:** Thông báo chung chung kiểu "không hợp lệ" buộc người chơi tự đoán mình sai ở đâu. Thông báo nêu đúng nguyên nhân và lặp lại con số vừa nhập giúp sửa ngay ở lần nhập tiếp theo.
- **Các lỗi được phân biệt:**

  | Tình huống | Thông báo |
  |---|---|
  | Ô xuất phát không phải số | `Loi: dau vao khong phai so nguyen. Hay nhap so o tu 1 den 32 (0 de thoat).` |
  | Ô ngoài khoảng | `Loi: o 33 nam ngoai khoang 1-32.` |
  | Ô trống | `Loi: o 15 dang trong, khong co quan de di.` |
  | Quân đối phương | `Loi: o 9 la quan cua doi phuong. Hay chon quan cua ban.` |
  | Quân bị chặn | `Loi: o 29 bi chan, khong co nuoc di hop le. Hay chon quan khac.` |
  | Lựa chọn không phải số | `Loi: dau vao khong phai so nguyen. Hay nhap so thu tu tu 1 den N.` |
  | Lựa chọn ngoài danh sách | `Loi: lua chon 7 khong co trong danh sach.` |

- **Cách làm:** Mỗi lần kiểm tra thất bại nhảy đến một nhãn riêng (`source_out_of_range`, `source_empty`, `source_opponent`, `piece_has_no_moves`, `choice_out_of_range`, ...). Các nhãn này chỉ chọn phần đuôi thông báo rồi dùng chung hàm `print_with_number` để in "phần đầu + số đã nhập + phần đuôi". Số ô vừa nhập được giữ trong `$s2` trong lúc chọn quân. Số in ra đúng là số người chơi đã gõ, nên với Đỏ vẫn là số theo góc nhìn Đỏ.

### Đề nghị hòa

- **Lý do:** Có những thế cờ không bên nào thắng được (ví dụ mỗi bên chỉ còn một vua). Nếu không có hòa, người chơi chỉ còn cách thoát chương trình và ván cờ không có kết quả.
- **Cách dùng:** Tại lời nhắc ô xuất phát, nhập `H` (hoặc `h`) để đề nghị hòa. Chương trình hỏi ngay bên kia; bên kia nhập `H` (cũng đề nghị hòa) thì ván kết thúc hòa, nhập bất kỳ thứ gì khác là từ chối và bên đề nghị tiếp tục lượt của mình.
- **Cách làm:** `read_number` nhận thêm lệnh một chữ cái: dòng chỉ gồm một chữ cái (bỏ qua khoảng trắng) trả về `$v0 = -2` và chữ cái viết hoa trong `$v1`. Chữ cái được đổi về chữ thường bằng `ori` với `0x20` để chỉ cần so sánh một khoảng `'a'`–`'z'`. `source_command` chuyển lệnh `H` đến `offer_draw`; các chữ cái khác bị báo lỗi như dữ liệu sai.

### Chơi lại không cần thoát chương trình

- **Lý do:** Trên MARS, chạy lại chương trình nghĩa là phải dừng, nạp lại (assemble) rồi chạy lại. Khi muốn chơi nhiều ván liên tiếp hoặc bắt đầu lại một ván đi hỏng, chơi lại ngay trong chương trình nhanh hơn nhiều.
- **Cách dùng:** Nhập `M` tại lời nhắc ô xuất phát để bỏ ván hiện tại và bắt đầu ván mới. Khi ván kết thúc (thắng hoặc hòa), chương trình hỏi `Nhap M de choi van moi`; nhập phím khác để thoát.
- **Cách làm:** Phần khởi tạo trong `main` được đặt nhãn `new_game` (gọi `initialize_board`, đặt `$s4 = 1`, `$s7 = 0`). `restart_game` in thông báo rồi nhảy về `new_game`. Mọi đường kết thúc ván (thắng hoặc hòa) đều đi qua `game_over`; nhãn này hỏi chơi lại thay vì gọi `syscall 10` ngay.

### Hiện nước vừa đi và số quân (tính năng tự đề xuất)

- **Lý do:** Bàn cờ xoay sau mỗi lượt nên rất khó so sánh hai bàn cờ liên tiếp để biết đối phương vừa đi gì, nhất là sau một chuỗi ăn nhiều quân. Dòng trạng thái cho biết ngay nước vừa đi (theo ký hiệu cờ đam, ví dụ `16x23x30x21`) và số quân còn lại, giúp người chơi nắm thế cờ mà không phải tự đếm.
- **Ví dụ:**

  ```text
  So quan: Den 12, Do 11
  Nuoc vua di cua Den: 16x23
  ```

- **Cách làm:** `record_move` được gọi mỗi khi áp dụng một bước đi. Bước đầu của lượt (`$s7 = 0`) bắt đầu đường đi mới trong mảng `last_path` và ghi lại bên đi cùng cờ "ăn quân"; mỗi bước ăn tiếp chỉ nối thêm ô đích. `print_game_status` đếm quân trên `board`, rồi in từng ô trong `last_path` bằng `index_to_square`, nên số ô theo góc nhìn người đang xem bàn cờ. `new_game` đặt `last_path_len = 0` để ván mới không hiện nước của ván cũ.