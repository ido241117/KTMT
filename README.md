# Cờ đam MIPS

Trò chơi cờ đam hai người chơi viết bằng hợp ngữ MIPS cho MARS. Bàn cờ có kích thước 8 × 8; chỉ 32 ô tối được sử dụng.

## Chạy chương trình

Mở MARS và nạp `checkers.asm`, hoặc chạy MARS từ PowerShell:

```powershell
java -jar "C:\Users\ADMIN\Downloads\Mars4_5.jar" checkers.asm
```

Đen đi trước. Mỗi lượt nhập số ô xuất phát rồi số ô đến. Khi chương trình yêu cầu ăn tiếp, chỉ nhập ô đến tiếp theo; quân vừa ăn sẽ tiếp tục di chuyển. Nhập `0` tại lời nhắc ô xuất phát để thoát.

## Chạy testcase

```powershell
python .\tests\checkers_mars_tests.py --mars-jar "C:\Users\ADMIN\Downloads\Mars4_5.jar"
```

Mỗi commit thêm tính năng đều bổ sung testcase Python cho tính năng đó. Bộ kiểm thử chạy MARS ở chế độ dòng lệnh, kiểm tra khởi tạo bàn cờ, nhập sai, đổi lượt, ăn quân, ăn liên tiếp, phong vua, ăn lùi bằng vua và điều kiện thắng. Thay đường dẫn MARS trong lệnh trên nếu cần.

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

1. `initialize_board` đặt quân Đỏ ở ba hàng trên và quân Đen ở ba hàng dưới.
2. `display_board` in trạng thái bàn cờ; `source_prompt` và `destination_prompt` nhận lượt đi.
3. Chương trình kiểm tra ô xuất phát thuộc người chơi hiện tại, ô đến trống và nước đi đúng hướng, khoảng cách.
4. `apply_move` cập nhật quân; nếu ăn thì xóa quân đối phương ở ô giữa.
5. Sau nước ăn, `has_capture` tìm nước ăn tiếp cho cùng quân. Nếu tốt đến hàng cuối, chương trình phong vua trước khi kiểm tra ăn tiếp.
6. `count_opponent_pieces` kiểm tra điều kiện thắng do đối phương hết quân; nếu chưa kết thúc, chương trình đổi lượt.

## Phạm vi

- Ăn quân ở đầu lượt chưa bắt buộc; nếu đã ăn mà còn nước ăn tiếp thì phải tiếp tục.
- Vua di chuyển và ăn chéo theo cả hai hướng.
- Chương trình phát hiện thắng khi đối phương hết quân; chưa phát hiện trường hợp đối phương còn quân nhưng không còn nước đi hợp lệ.
- Đầu vào là số nguyên. Ô xuất phát nhận `0` để thoát; các ô đi hợp lệ nằm trong khoảng 1–32.