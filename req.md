# Bài tập: Trò chơi cờ đam

**Môn học:** Thí nghiệm Kiến trúc Máy tính (CO2008)  
**Khoa:** Khoa học và Kỹ thuật Máy tính  
**Trường:** Trường Đại học Bách khoa - Đại học Quốc gia TP. Hồ Chí Minh  
**Yêu cầu:** Cài đặt cờ đam bằng hợp ngữ MIPS trên MARS  
**Thời điểm:** TP. Hồ Chí Minh, tháng 4 năm 2025  
**Năm học:** 2024–2025

## Mục lục

1. [Giới thiệu](#1-giới-thiệu)
   - [Lời mở đầu](#11-lời-mở-đầu)
   - [Luật cơ bản của cờ đam Anh](#12-luật-cơ-bản-của-cờ-đam-anh)
   - [Ký hiệu cờ đam](#13-ký-hiệu-cờ-đam)
2. [Yêu cầu](#2-yêu-cầu)
   - [Hiển thị trạng thái bàn cờ](#21-hiển-thị-trạng-thái-bàn-cờ)
   - [Thực hiện nước đi](#22-thực-hiện-nước-đi)
3. [Yêu cầu mở rộng](#3-yêu-cầu-mở-rộng)
   - [Cải thiện trải nghiệm sử dụng](#31-cải-thiện-trải-nghiệm-sử-dụng)
   - [Các bộ luật nâng cao](#32-các-bộ-luật-nâng-cao)
4. [Quy định chung](#4-quy-định-chung)
   - [Quy định cơ bản](#41-quy-định-cơ-bản)
   - [Tiêu chí đánh giá](#42-tiêu-chí-đánh-giá)

## 1. Giới thiệu

### 1.1. Lời mở đầu

Cờ đam (còn được gọi là *draughts* tại Vương quốc Anh) là một trong những trò chơi bàn cờ phổ biến nhất thế giới. Trò chơi thường diễn ra trên bàn cờ 8 × 8 hoặc 10 × 10. Mục tiêu chính là dùng các quân cờ của mình để khiến đối thủ không còn quân cờ nào.

Để đơn giản hóa bài tập, sinh viên cần cài đặt phiên bản **cờ đam Anh** bằng hợp ngữ MIPS trên MARS. Sinh viên có thể thử cài đặt một số biến thể khác để đạt điểm cộng.

### 1.2. Luật cơ bản của cờ đam Anh

#### 1.2.1. Bố trí ban đầu

Cờ đam Anh được chơi trên bàn cờ 8 × 8 giữa hai bên đối kháng. Bàn cờ có 64 ô, nhưng chỉ sử dụng 32 ô (như sẽ giải thích ở phần sau).

Một bên điều khiển các quân màu tối (thường là màu đen), bên còn lại điều khiển các quân màu sáng (thường là màu đỏ, đôi khi là màu trắng).

Mỗi quân cờ được gọi là *man* hoặc *pawn*; trong tài liệu này, quân cờ được gọi là **quân tốt**.

Các quân tốt được xếp trên bàn cờ như minh họa:

> **Hình 1.** Vị trí ban đầu của các quân tốt trên bàn cờ.

Bên đi quân tối đi trước. Sau đó, hai bên lần lượt thay phiên nhau đi.

#### 1.2.2. Di chuyển quân tốt

Trong mỗi lượt, người chơi phải di chuyển một quân tốt của mình tiến một ô theo đường chéo đến một ô trống. Vì vậy, các ô màu trắng không thể được sử dụng.

Ví dụ, các mũi tên màu cam trong hình dưới đây biểu thị những nước đi đầu tiên có thể có của bên đen:

> **Hình 2.** Các nước đi đầu tiên có thể có của bên đen.

#### 1.2.3. Ăn quân và ăn liên tiếp

Người chơi có thể ăn quân nếu ô chéo phía trước đang có quân đối phương và ô ngay phía sau quân đó còn trống.

> **Hình 3.** Bên đỏ có thể nhảy qua quân đen và đáp xuống ô trống ngay phía sau để ăn quân.

Quân ăn sẽ nhảy qua quân đối phương và đáp xuống ô trống nói trên. Quân đối phương bị ăn sẽ được loại khỏi bàn cờ.

> **Hình 4.** Trạng thái bàn cờ sau khi ăn quân.

Nếu ngay sau khi đáp xuống có thể ăn tiếp, người chơi được thực hiện nước ăn đó trước khi kết thúc lượt. Đây được gọi là **ăn liên tiếp**. Không giới hạn số quân có thể ăn trong một chuỗi.

> **Hình 5.** Bên đen có thể nhảy liên tiếp để ăn nhiều quân.

Theo luật cờ đam Anh:

1. Nếu có thể ăn quân ngay từ đầu lượt thì **bắt buộc phải ăn**, kể cả khi nước đi đó gây bất lợi cho người ăn.
2. Nếu sau nước ăn đầu tiên có thể tiếp tục ăn thì **bắt buộc phải ăn tiếp**.

Trong phạm vi yêu cầu tối thiểu của bài tập này, có thể bỏ qua quy tắc thứ nhất nhưng phải tuân theo quy tắc thứ hai.

#### 1.2.4. Phong cấp

Khi một quân tốt đi đến hàng cuối cùng của bàn cờ, quân đó được phong thành **quân vua**.

> **Hình 6.** Quân tốt đen được phong thành quân vua đen.

Khác với quân tốt, quân vua trong cờ đam Anh có thể di chuyển hoặc ăn quân theo cả hướng tiến lẫn hướng lùi. Tuy nhiên, mỗi nước đi vẫn chỉ đi trong phạm vi như quân tốt.

> **Hình 7.** Phạm vi di chuyển và ăn quân của quân vua đen so với quân tốt đen.

Nếu quân tốt đến hàng cuối cùng bằng một nước ăn, quân đó được phong vua ngay lập tức và có thể tiếp tục ăn ngược về phía sau trong cùng chuỗi ăn.

> **Hình 8.** Quân vua đỏ vừa được phong có thể lập tức nhảy lùi để tiếp tục chuỗi ăn.

#### 1.2.5. Điều kiện thắng

Người chơi thắng khi đối phương không còn nước đi hợp lệ. Trường hợp thường gặp là đối phương đã bị ăn hết quân. Chương trình tối thiểu cần kiểm tra trường hợp này, thông báo người thắng và kết thúc ván chơi.

Một trường hợp ít gặp hơn là tất cả quân của đối phương đều bị chặn, không thể di chuyển.

> **Hình 9.** Bên đen không còn nước đi hợp lệ nên bên đỏ thắng.

### 1.3. Ký hiệu cờ đam

Tương tự cờ vua, cờ đam có hệ thống ký hiệu tiêu chuẩn để ghi lại các ván đấu.

Trong hệ thống này, các ô có thể sử dụng được đánh số như sau:

> **Hình 10.** Cách đánh số ô, với bên đen ở phía dưới.

Ở vị trí ban đầu, ô dưới cùng bên trái (ô 29) có một quân tốt đen, còn ô trên cùng bên phải (ô 4) có một quân tốt đỏ.

Để tham khảo, hình dưới đây thể hiện cách đánh số theo góc nhìn của bên đỏ:

> **Hình 11.** Cách đánh số ô, với bên đỏ ở phía dưới.

Mỗi nước đi được ghi bằng hai số: số thứ nhất là ô xuất phát, số thứ hai là ô đến. Dấu gạch ngang (`-`) biểu thị nước đi thông thường; dấu `x` hoặc dấu nhân (`×`) biểu thị nước nhảy ăn quân.

Ví dụ:

- Ở Hình 6, nước đi được ghi là `5-1`.
- Ở Hình 8, chuỗi ăn được ghi là `15x24 24x31 31x22 22x13`.

## 2. Yêu cầu

### 2.1. Hiển thị trạng thái bàn cờ

Sau mỗi lượt, chương trình **phải** xuất trạng thái hiện tại của bàn cờ ra cửa sổ terminal của MARS. Có thể tham khảo cách biểu diễn sau:

```text
1  r r r r
2  r r r r
3  r r r r
4  0 0 0 0
5  0 0 0 0
6  b b b b
7  b b b b
8  b b b b
```

Trong đó:

- Khoảng trống (` `): ô không thể sử dụng.
- `r`, `b`: quân tốt của hai bên.
- `R`, `B`: quân vua của hai bên.
- `0`: ô trống có thể sử dụng.

### 2.2. Thực hiện nước đi

Chương trình yêu cầu người chơi hiện tại nhập ô xuất phát và ô đến, sau đó kiểm tra tính hợp lệ của nước đi.

Ví dụ về một lượt đi:

```text
1  r r r r
2  r r r r
3  r r r r
4  0 0 0 0
5  0 0 0 0
6  b b b b
7  b b b b
8  b b b b

Đến lượt Đen.
Nhập ô xuất phát: 21
Nhập ô đến: 17

1  r r r r
2  r r r r
3  r r r r
4  0 0 0 0
5  b 0 0 0
6  0 b b b
7  b b b b
8  b b b b

Đến lượt Đỏ.
Nhập ô xuất phát:
```

Các bước kiểm tra tính hợp lệ bao gồm:

- Ô xuất phát có quân cờ hay không?
- Quân ở ô xuất phát có thuộc về người chơi hiện tại hay không?
- Quân đó có được phép đi đến ô đích hay không (xét hướng đi và tình trạng có quân tại ô đích)?

Nếu một trong các kiểm tra thất bại, chương trình yêu cầu người chơi thử lại bằng một cặp ô khác.

Ví dụ:

```text
Đến lượt Đen.
Nhập ô xuất phát: 21
Nhập ô đến: 13
Nước đi không hợp lệ! Hãy thử lại.
Nhập ô xuất phát:
```

Nếu nước đi là nước ăn và có thể ăn liên tiếp, chương trình yêu cầu người chơi nhập ô đến cho lần ăn tiếp theo.

Ví dụ:

```text
1  0 0 0 0
2  0 0 0 0
3  r 0 0 0
4  0 B B 0
5  0 0 0 0
6  0 B B 0
7  0 0 0 0
8  0 0 0 0

Đến lượt Đỏ.
Nhập ô xuất phát: 9
Nhập ô đến: 18
Đã ăn quân Đen.

1  0 0 0 0
2  0 0 0 0
3  0 0 0 0
4  0 0 0 0
5  0 0 0 0
6  0 0 B 0
7  0 r 0 0
8  0 B B 0

Có thể ăn tiếp.
Nhập ô đến:
```

## 3. Yêu cầu mở rộng

Sản phẩm tối thiểu là chương trình cờ đam đáp ứng các yêu cầu tại Mục 1 và Mục 2. Sản phẩm tối thiểu chỉ có thể đạt tối đa 9/10 điểm (8/10 điểm đối với chương trình Honors).

Để đạt các điểm còn lại, sinh viên cần cài đặt thêm một số tính năng. Dưới đây là các gợi ý. Độ khó của tính năng và mức độ hoàn thiện là những yếu tố chính được cân nhắc khi cộng điểm.

### 3.1. Cải thiện trải nghiệm sử dụng

Có thể bổ sung các tính năng cải thiện trải nghiệm sử dụng (QoL) vào trò chơi cơ bản, chẳng hạn:

- Hiển thị bàn cờ đẹp mắt, dễ nhìn hơn.
- Điều chỉnh cách hiển thị trạng thái bàn cờ theo người chơi hiện tại. Ví dụ, xoay bàn cờ để trong lượt của bên đỏ, bên đỏ cũng có cảm giác đang đi lên.
- Mở rộng ý tưởng trên cho hệ thống ký hiệu: khi bên đỏ chơi, ô dưới cùng bên trái của bên đỏ cũng là ô 29.
- Thiết kế cách nhập liệu khác với cách được trình bày. Ví dụ, người chơi chọn một ô có quân của mình; chương trình liệt kê các nước đi có thể thực hiện bằng quân đó, rồi yêu cầu người chơi chọn một nước. Có thể áp dụng cách tương tự cho các lượt ăn liên tiếp.
- Hiển thị thông báo lỗi rõ ràng hơn, cho người chơi biết nguyên nhân nước đi không hợp lệ.
- Phát hiện điều kiện thắng khi đối phương bị chặn và không còn nước đi hợp lệ.
- Cho phép người chơi đề nghị hòa. Nếu cả hai bên cùng đồng ý, kết thúc ván đấu với kết quả hòa.
- Cho phép người chơi bắt đầu lại ván đấu mà không cần thoát chương trình.
- Đề xuất tính năng QoL khác; cần giải thích lý do tính năng đó hữu ích và cách cài đặt.

### 3.2. Các bộ luật nâng cao

Như đã nêu ở Mục 1, phiên bản cờ đam trong sản phẩm tối thiểu đã được giản lược. Nếu muốn thử thách hơn, sinh viên có thể:

- Bắt buộc người chơi ăn quân bất cứ khi nào có thể.
- Mở rộng bàn cờ thành 10 × 10 với 15 hoặc 20 quân tốt ban đầu cho mỗi bên.
- Cài đặt các biến thể khác của trò chơi, chẳng hạn biến thể có quân vua bay hoặc quân tốt có thể đi lùi ngay từ đầu.
- Đề xuất một quy tắc nâng cao khác có độ khó cao hơn.

## 4. Quy định chung

### 4.1. Quy định cơ bản

- Sinh viên làm việc theo nhóm, mỗi nhóm không quá 3 thành viên.
- Yêu cầu đối với bài nộp (báo cáo, mã nguồn, trình diễn trực tiếp, vấn đáp, v.v.) do giảng viên quyết định và sẽ được thông báo qua một kênh khác.
- Sinh viên có trách nhiệm bảo vệ bài làm của nhóm và không sao chép bài của nhóm khác. Nếu phát hiện đạo văn, điểm của cả hai bên sẽ bị ảnh hưởng.
- Không cấm sử dụng AI để lập trình, nhưng mục tiêu chính vẫn là hiểu và thiết kế được chương trình.
- Vì chỉ một số lớp được giao bài tập này nên đề thi cuối kỳ sẽ không có câu hỏi liên quan đến nội dung bài tập.

### 4.2. Tiêu chí đánh giá

Dưới đây là một số tiêu chí (không giới hạn) có thể được dùng để đánh giá sinh viên:

- Tính năng và mức độ hoạt động của phần mềm.
- Mức độ dễ đọc của mã nguồn.
- Cấu trúc tổng thể của phần mềm.
- Mức độ hiểu biết về cách hoạt động của hợp ngữ MIPS.
- Kỹ năng viết báo cáo và/hoặc trình bày kết quả dự án.
