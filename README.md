# Cờ đam MIPS

Trò chơi cờ đam hai người chơi viết bằng hợp ngữ MIPS cho MARS. Bàn cờ có kích thước 8 × 8; chỉ 32 ô tối được sử dụng.

## Chạy chương trình

Mở MARS và nạp `checkers.asm`, hoặc chạy MARS từ PowerShell:

```powershell
java -jar "C:\Users\ADMIN\Downloads\Mars4_5.jar" checkers.asm
```

Đen đi trước. Mỗi lượt nhập số ô xuất phát rồi số ô đến. Khi chương trình yêu cầu ăn tiếp, chỉ nhập ô đến tiếp theo; quân vừa ăn sẽ tiếp tục di chuyển. Nhập `0` tại lời nhắc ô xuất phát để thoát. Nếu nước đi không hợp lệ, chương trình yêu cầu nhập lại cả ô xuất phát và ô đến (trong chuỗi ăn bắt buộc chỉ nhập lại ô đến).

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
| `read_number` | Đọc một dòng bằng `syscall 8` rồi tự chuyển sang số; trả về `-1` nếu dòng trống hoặc không phải số. |
| `square_to_index` | Đổi số ô 1–32 sang chỉ số 0–63 trong `board`. |
| `validate_move` | Kiểm tra ô đến trống, đúng hướng, đúng đường chéo; trả về 0 (sai), 1 (đi thường) hoặc 2 (ăn quân). |
| `piece_has_move` | Thử 8 ô đích quanh một quân bằng `validate_move`; dùng để tìm nước ăn tiếp. |
| `has_any_move` | Kiểm tra bên đang đến lượt còn nước đi hợp lệ hay không. |

1. `source_prompt` và `destination_prompt` nhận lượt đi qua `read_number` và `square_to_index`, sau đó gọi `validate_move`.
2. `apply_move` cập nhật quân; nếu ăn thì xóa quân đối phương ở ô giữa. Nếu tốt đến hàng cuối, chương trình phong vua.
3. Sau nước ăn, `piece_has_move` tìm nước ăn tiếp cho cùng quân; nếu có thì bắt buộc ăn tiếp.
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