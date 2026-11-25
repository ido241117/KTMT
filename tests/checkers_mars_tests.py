import argparse
import re
import subprocess
import sys
import tempfile
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
ASSEMBLY_PATH = PROJECT_ROOT / "checkers.asm"


def load_mars_jar_from_env() -> Path:
    env_path = PROJECT_ROOT / ".env"
    if not env_path.is_file():
        raise ValueError(f"Configuration file not found: {env_path}")

    for line in env_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue

        key, separator, value = line.partition("=")
        if separator and key.strip() == "MARS_JAR":
            value = value.strip()
            if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
                value = value[1:-1]
            if not value:
                raise ValueError("MARS_JAR is empty in .env")
            return Path(value)
    raise ValueError(f"MARS_JAR is not set in {env_path}")
    raise ValueError(f"MARS_JAR is not set in {env_path}")


def run_mars(
    input_text: str, mars_jar: Path, assembly_path: Path = ASSEMBLY_PATH
) -> str:
    result = subprocess.run(
        ["java", "-jar", str(mars_jar), "nc", "se1", str(assembly_path)],
        input=input_text,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
        timeout=60,
    )
    output = result.stdout + result.stderr
    if result.returncode:
        raise AssertionError(f"MARS exited with {result.returncode}:\n{output}")
    return output


# Chạy chương trình với bàn cờ thử: chèn đoạn mã xóa bàn cờ và đặt quân
# (chỉ số 0-63 -> giá trị quân) ngay sau khi khởi tạo, trước lượt đầu tiên.
def run_mars_with_board(pieces: dict[int, int], input_text: str, mars_jar: Path) -> str:
    source = ASSEMBLY_PATH.read_text(encoding="utf-8")
    marker = "    li    $s4, 1\n    move  $s7, $zero\n"
    setup = """\
    li    $t0, 0
test_clear_board:
    addu  $t1, $s0, $t0
    sb    $zero, 0($t1)
    addiu $t0, $t0, 1
    slti  $t2, $t0, 64
    bne   $t2, $zero, test_clear_board
"""
    for index, value in pieces.items():
        setup += f"    li    $t2, {value}\n    sb    $t2, {index}($s0)\n"
    assert source.count(marker) == 1
    fixture_source = source.replace(marker, setup + marker, 1)

    with tempfile.TemporaryDirectory() as temp_dir:
        fixture_path = Path(temp_dir) / "checkers_fixture.asm"
        fixture_path.write_text(fixture_source, encoding="utf-8")
        return run_mars(input_text, mars_jar, fixture_path)


RED_HEADER = "Ban co theo goc nhin ben Do:"
BLACK_HEADER = "Ban co theo goc nhin ben Den:"


# Bàn cờ được in dạng lưới, mỗi ô tối có ký hiệu quân và số ô, ví dụ hàng 1:
#   |      | r  1 |      | r  2 |      | r  3 |      | r  4 |
# Hàm này trả về các bàn cờ đã in, mỗi bàn là 8 chuỗi, mỗi chuỗi là 4 ô tối
# của một hàng theo thứ tự in ('.' là ô trống), ví dụ hàng 1 là "rrrr".
# Bàn cờ in trong lượt Đỏ bị xoay 180 độ; mặc định hàm xoay ngược lại để mọi
# bàn cờ đều theo hướng chuẩn (Đỏ ở trên). Truyền raw=True để giữ nguyên.
def printed_boards(output: str, raw: bool = False) -> list[list[str]]:
    boards: list[list[str]] = []
    rows: list[str] = []
    rotated = False
    for line in output.splitlines():
        if line.startswith((RED_HEADER, BLACK_HEADER)):
            assert not rows, f"Board rows are incomplete:\n{output}"
            rotated = line.startswith(RED_HEADER)
        elif line.startswith("|"):
            rows.append("".join(re.findall(r"([.rbRB]) +\d+", line)))
            if len(rows) == 8:
                if rotated and not raw:
                    rows = [row[::-1] for row in reversed(rows)]
                boards.append(rows)
                rows = []
    assert boards and not rows, f"Board rows are incomplete:\n{output}"
    return boards


# Commit này code gì: Khởi tạo bàn cờ 8x8, đặt Tốt Đỏ ở ba hàng trên và Tốt
# Đen ở ba hàng dưới, sau đó in trạng thái bàn cờ.
# Input: Không nhập gì; chỉ chạy chương trình.
# Output mong đợi (4 ô tối mỗi hàng, từ hàng 1 đến 8):
#   rrrr rrrr rrrr .... .... bbbb bbbb bbbb
# Test kiểm tra có đúng 8 hàng và quân Đen/Đỏ nằm đúng ba hàng ban đầu.
def test_initial_board(mars_jar: Path) -> None:
    output = run_mars("", mars_jar)
    boards = printed_boards(output)
    assert len(boards) == 1, f"Expected 1 board, got {len(boards)}"
    assert boards[0] == ["rrrr"] * 3 + ["...."] * 2 + ["bbbb"] * 3
    assert "| r  1 |" in output and "| b 32 |" in output


# Cách nhập một lượt: số ô của quân muốn đi, rồi số thứ tự nước đi trong danh
# sách chương trình liệt kê (danh sách xếp theo số ô đích tăng dần).
def turn(source: int, choice: int) -> str:
    return f"{source}\n{choice}\n"


# Các test bên dưới ghi số ô theo cách đánh số chuẩn (góc nhìn Đen). Hàm này
# đổi số ô chuẩn sang số mà người chơi Đỏ thực sự nhập (33 - n).
def red(square: int) -> int:
    return 33 - square


# Commit này code gì: In bàn cờ theo góc nhìn người đang đi; lượt Đỏ thì xoay
# bàn cờ 180 độ để quân Đỏ cũng đi từ dưới lên.
# Input: Đen đi 21->17, sau đó dừng ở lượt Đỏ.
# Output mong đợi: Bàn cờ lượt Đỏ có tiêu đề góc nhìn Đỏ, hàng trên cùng là
# hàng quân Đen (hàng 8), hàng dưới cùng là quân Đỏ; hàng 5 của Đen (b...) in
# ngược thành ...b ở hàng thứ 4 tính từ trên xuống.
def test_board_rotates_for_red(mars_jar: Path) -> None:
    output = run_mars(turn(21, 1), mars_jar)
    assert BLACK_HEADER in output and RED_HEADER in output
    assert printed_boards(output, raw=True)[-1] == [
        "bbbb", "bbbb", "bbb.", "...b", "....", "rrrr", "rrrr", "rrrr"
    ]


# Commit này code gì: Đánh số ô theo góc nhìn người đang đi; với Đỏ, ô dưới
# cùng bên trái cũng là ô 29 (ô n của Đỏ là ô 33 - n theo cách đánh số chuẩn).
# Input: Đen đi 21->17; Đỏ chọn quân 22 theo cách đánh số của Đỏ (ô chuẩn 11)
# và đi đến ô 18 của Đỏ (ô chuẩn 15), là lựa chọn thứ 2 sau ô 17.
# Output mong đợi: Bàn cờ lượt Đỏ in ô 1-4 ở hàng trên cùng và ô 29 ở góc
# dưới bên trái; danh sách nước đi của Đỏ cũng dùng số ô của Đỏ; sau nước Đỏ,
# quân Đỏ rời ô chuẩn 11 và đến ô chuẩn 15.
def test_notation_follows_current_player(mars_jar: Path) -> None:
    output = run_mars(turn(21, 1) + turn(22, 2) + "0\n", mars_jar)
    red_lines = [
        line for line in output.split(RED_HEADER)[1].splitlines() if line.startswith("|")
    ]
    assert re.search(r"b  1 .*b  2 .*b  3 .*b  4 ", red_lines[0])
    assert red_lines[7].startswith("| r 29 |")
    assert "1) 22-17" in output and "2) 22-18" in output
    board = printed_boards(output)[-1]
    assert board[2:4] == ["rr.r", "..r."]


# Commit này code gì: Kiểm tra ô xuất phát nằm trong 1-32, có quân và quân
# thuộc về người đang lượt (Đen đi đầu tiên) hay không.
# Input: 1 (quân Đỏ), 33 (ngoài khoảng 1-32), rồi quân 21 và nước 21->17.
# Output mong đợi: Từ chối 1 và 33, sau đó chấp nhận 21 và hiện danh sách.
def test_source_square_validation(mars_jar: Path) -> None:
    output = run_mars("1\n33\n" + turn(21, 1), mars_jar)
    assert output.count("O xuat phat khong hop le") == 2
    assert "Chon nuoc di (1-1)" in output


# Commit này code gì: Chọn quân rồi chọn nước đi từ danh sách các nước hợp lệ
# của quân đó (thay cho việc gõ ô đến).
# Input: Quân 22 có hai nước 22-17 và 22-18; chọn lựa chọn 2.
# Output mong đợi: Danh sách đúng hai nước theo thứ tự ô đích, nước 22-18
# được áp dụng: hàng 5 có quân Đen ở ô 18, hàng 6 trống ô 22.
def test_move_menu_lists_legal_moves(mars_jar: Path) -> None:
    output = run_mars(turn(22, 2) + "0\n", mars_jar)
    assert "Cac nuoc di cua quan o 22:\n  1) 22-17\n  2) 22-18\n" in output
    assert "Chon nuoc di (1-2): " in output
    board = printed_boards(output)[-1]
    assert board[4] == ".b.."
    assert board[5] == "b.bb"


# Commit này code gì: Lựa chọn sai thì nhập lại cả ô xuất phát và nước đi.
# Input: Quân 21 chỉ có một nước; nhập 5 (ngoài danh sách), rồi "x" (không
# phải số), rồi chọn lại 21 và nước 1.
# Output mong đợi: Hai lần báo lựa chọn sai, mỗi lần đều hỏi lại ô xuất phát
# (lời nhắc lượt Đen hiện 3 lần). Nước 21->17 được áp dụng.
def test_basic_move_validation_and_application(mars_jar: Path) -> None:
    output = run_mars("21\n5\n21\nx\n" + turn(21, 1), mars_jar)
    assert output.count("Lua chon khong hop le") == 2
    assert output.count("Den luot Den.") == 3
    board = printed_boards(output)[-1]
    assert board[4] == "b..."
    assert board[5] == ".bbb"


# Chọn nhầm quân bị chặn không làm treo chương trình.
# Input: Đen chọn 29 (bị chặn, không có nước đi), rồi chọn lại 21->17.
# Output mong đợi: Báo quân không có nước đi và hỏi lại ô xuất phát; nước
# 21->17 được áp dụng và quân ở 29 vẫn nằm yên.
def test_blocked_piece_does_not_soft_lock(mars_jar: Path) -> None:
    output = run_mars("29\n" + turn(21, 1) + "0\n", mars_jar)
    assert output.count("Quan nay khong co nuoc di hop le") == 1
    assert output.count("Den luot Den.") == 2
    board = printed_boards(output)[-1]
    assert board[4] == "b..."
    assert board[5] == ".bbb"
    assert board[7] == "bbbb"


# Commit này code gì: Hoàn tất một nước của Đen rồi một nước của Đỏ, sau đó
# quay lại lượt Đen; cho phép nhập 0 tại ô xuất phát để kết thúc ván.
# Input: Đen đi 21->17, Đỏ đi 9->13 (lựa chọn 2 của quân Đỏ), Đen nhập 0.
# Output mong đợi: Hiện lời nhắc lượt Đỏ sau nước Đen, lời nhắc lượt Đen sau
# nước Đỏ và thông báo kết thúc ván chơi.
def test_turns_alternate(mars_jar: Path) -> None:
    output = run_mars(turn(21, 1) + turn(red(9), 2) + "0\n", mars_jar)
    assert "Den luot Do." in output
    assert "Den luot Den." in output
    assert "Ket thuc van choi." in output
    assert printed_boards(output)[-1][3] == "r..."


# Commit này code gì: Thêm luật nhảy qua một quân đối phương, rồi xóa quân bị
# ăn khỏi bàn cờ.
# Input: Đen đi 21->17; Đỏ đi 10->14; Đen ăn 17x10; sau đó nhập 0 để thoát.
# Bàn cờ ngay trước nước ăn (4 ô tối mỗi hàng, từ hàng 1 đến 8):
#   rrrr rrrr r.rr .r.. b... .bbb bbbb bbbb
# Quân Đen ở 17 nhảy qua quân Đỏ ở 14, đáp xuống ô trống 10. Danh sách của
# quân 17 là 17x10 (ăn, dùng ký hiệu x) rồi 17-13.
# Output mong đợi: Báo đã ăn quân; quân Đỏ ở 14 và quân Đen ở 17 biến mất,
# quân Đen xuất hiện ở 10. Hàng 3, 4, 5 sau nước ăn:
#   rbrr .... ....
def test_capture_removes_opponent_piece(mars_jar: Path) -> None:
    output = run_mars(turn(21, 1) + turn(red(10), 2) + turn(17, 1) + "0\n", mars_jar)
    assert "  1) 17x10\n  2) 17-13\n" in output
    assert "Da an quan doi phuong." in output
    assert "Den luot Do." in output
    board = printed_boards(output)[-1]
    assert board[2:5] == ["rbrr", "....", "...."]


# Commit này code gì: Phong Tốt Đen khi chạm hàng cuối, cho vua đi/ăn cả
# tiến lẫn lùi, và bắt buộc tiếp tục nếu vua còn nước ăn.
# Input (các nước đơn để tạo thế ăn, số ô chuẩn): Đen 21->17, 22->18,
# 23->19, 24->20, 25->21; Đỏ 10->14, 11->15, 7->11, 12->16, 3->7.
# Sau đó Đen ăn 17x10; danh sách ăn tiếp chỉ có 10x3 (phong vua), rồi chỉ có
# 3x12 (vua ăn lùi). Nhập 0 sau khi chuỗi ăn kết thúc.
# Output mong đợi: Báo 3 quân bị ăn, hiện lời nhắc ăn tiếp 2 lần, báo phong
# vua; vua Đen cuối cùng nằm ở hàng 3, cột cuối.
# Hàng 3 trên bàn cờ cuối (4 ô tối):
#   r.rB
def test_capture_chain_and_promotion(mars_jar: Path) -> None:
    input_text = (
        turn(21, 1) + turn(red(10), 2)
        + turn(22, 1) + turn(red(11), 2)
        + turn(23, 1) + turn(red(7), 1)
        + turn(24, 1) + turn(red(12), 1)
        + turn(25, 1) + turn(red(3), 1)
        + turn(17, 1) + "1\n1\n0\n"
    )
    output = run_mars(input_text, mars_jar)
    assert output.count("Da an quan doi phuong.") == 3
    assert output.count("Co the an tiep.") == 2
    assert "Cac nuoc di cua quan o 10:\n  1) 10x3\n" in output
    assert "Cac nuoc di cua quan o 3:\n  1) 3x12\n" in output
    assert "Quan tot duoc phong vua." in output
    assert printed_boards(output)[-1][2] == "r.rB"


# Commit này code gì: Sau lượt, nếu đối thủ không còn quân (nên cũng không
# còn nước đi) thì thông báo bên thắng và kết thúc chương trình.
# Để testcase ngắn gọn, nó tạo bàn cờ thử: xóa hết quân, đặt Đen ở 18 và Đỏ
# ở 14. Vị trí trước nước ăn:
#   4 0   r   0   0
#   5   0   b   0   0
# Input: Đen chọn 18 và lựa chọn 1 (18x9), ăn quân cuối cùng.
# Output mong đợi: Ô 14 và 18 trống, quân Đen ở 9; chương trình in
# "Đen thắng!" và dừng, không hỏi nhập lượt tiếp theo.
def test_win_when_opponent_has_no_pieces(mars_jar: Path) -> None:
    output = run_mars_with_board({35: 1, 26: -1}, turn(18, 1), mars_jar)
    assert "Den thang!" in output
    assert "Nhap o xuat phat" not in output.split("Da an quan doi phuong.")[-1]


# Commit này code gì: Phát hiện thắng khi đối phương còn quân nhưng mọi quân
# đều bị chặn, không còn nước đi thường hay nước ăn nào.
# Bàn cờ thử: Tốt Đỏ ở 25, Tốt Đen ở 29, Vua Đen ở 26. Vị trí:
#   7   r   B   0   0
#   8 b   0   0   0
# Input: Vua Đen đi 26->30 (lựa chọn 3 sau 22 và 23). Tốt Đỏ ở 25 chỉ đi
# xuống được ô 29 và 30, cả hai đã có quân; không ăn được vì phía sau là mép
# bàn cờ.
# Output mong đợi: Báo đối phương hết nước đi và in "Đen thắng!".
def test_win_when_opponent_is_blocked(mars_jar: Path) -> None:
    output = run_mars_with_board({49: -1, 56: 1, 51: 2}, turn(26, 3), mars_jar)
    assert "Doi phuong khong con nuoc di hop le." in output
    assert "Den thang!" in output
    assert printed_boards(output)[-1][5:] == ["....", "r...", "bB.."]


# Commit này code gì: Đọc input bằng syscall 8 và tự chuyển sang số, để chữ
# cái hoặc dòng trống không làm MARS dừng chương trình.
# Input: "abc" và dòng trống ở ô xuất phát, " 21 " (có khoảng trắng), "x" ở
# lựa chọn nước đi (bị bắt nhập lại từ ô xuất phát), rồi 21->17 và 0.
# Output mong đợi: Báo đầu vào không phải số 2 lần, báo lựa chọn sai 1 lần,
# nước 21->17 được áp dụng.
def test_non_numeric_input_is_rejected(mars_jar: Path) -> None:
    output = run_mars("abc\n\n 21 \nx\n" + turn(21, 1) + "0\n", mars_jar)
    assert output.count("Dau vao khong phai so nguyen") == 2
    assert output.count("Lua chon khong hop le") == 1
    assert output.count("Den luot Den.") == 4
    assert "Ket thuc van choi." in output
    board = printed_boards(output)[-1]
    assert board[4] == "b..."
    assert board[5] == ".bbb"


def main() -> int:
    parser = argparse.ArgumentParser(description="Run checkers MARS integration tests.")
    parser.add_argument(
        "--mars-jar",
        type=Path,
        help="path to MARS jar (overrides MARS_JAR in .env)",
    )
    args = parser.parse_args()

    try:
        mars_jar = args.mars_jar or load_mars_jar_from_env()
    except ValueError as error:
        parser.error(str(error))
    if not mars_jar.is_file():
        parser.error(f"MARS jar not found: {mars_jar}")
    if not ASSEMBLY_PATH.is_file():
        parser.error(f"MIPS assembly file not found: {ASSEMBLY_PATH}")

    tests = (
        test_initial_board,
        test_board_rotates_for_red,
        test_notation_follows_current_player,
        test_source_square_validation,
        test_move_menu_lists_legal_moves,
        test_basic_move_validation_and_application,
        test_blocked_piece_does_not_soft_lock,
        test_turns_alternate,
        test_capture_removes_opponent_piece,
        test_capture_chain_and_promotion,
        test_win_when_opponent_has_no_pieces,
        test_win_when_opponent_is_blocked,
        test_non_numeric_input_is_rejected,
    )
    try:
        for test in tests:
            test(mars_jar)
            print(f"PASS: {test.__name__}")
    except (AssertionError, OSError, RuntimeError, subprocess.TimeoutExpired) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1

    print(f"All {len(tests)} MARS integration tests passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
