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
    )
    output = result.stdout + result.stderr
    if result.returncode:
        raise AssertionError(f"MARS exited with {result.returncode}:\n{output}")
    return output


# Commit này code gì: Khởi tạo bàn cờ 8x8, đặt Tốt Đỏ ở ba hàng trên và Tốt
# Đen ở ba hàng dưới, sau đó in trạng thái bàn cờ.
# Input: Không nhập gì; chỉ chạy chương trình.
# Output mong đợi:
#   1   r   r   r   r
#   2 r   r   r   r
#   3   r   r   r   r
#   4 0   0   0   0
#   5   0   0   0   0
#   6 b   b   b   b
#   7   b   b   b   b
#   8 b   b   b   b
# Test kiểm tra có đúng 8 hàng và quân Đen/Đỏ nằm đúng ba hàng ban đầu.
def test_initial_board(mars_jar: Path) -> None:
    output = run_mars("", mars_jar)
    rows = re.findall(r"(?m)^[1-8] .*$", output)
    assert len(rows) == 8, f"Expected 8 board rows, got {len(rows)}"
    assert re.search(r"(?m)^1\s+r\s+r\s+r\s+r\s*$", output)
    assert re.search(r"(?m)^8 b\s+b\s+b\s+b\s*$", output)


# Commit này code gì: Kiểm tra ô xuất phát nằm trong 1-32, có quân và quân
# thuộc về người đang lượt (Đen đi đầu tiên) hay không.
# Input: 1 (quân Đỏ), 33 (ngoài khoảng 1-32), 21 (quân Đen), 17 (ô đến).
# Output mong đợi: Từ chối 1 và 33, sau đó chấp nhận 21 và đi 21->17.
# Quân Đen rời ô 21; trên bàn cờ, hàng 5 có một quân Đen mới.
def test_source_square_validation(mars_jar: Path) -> None:
    output = run_mars("1\n33\n21\n17\n", mars_jar)
    assert output.count("O xuat phat khong hop le") == 2
    assert "Nhap o den" in output


# Commit này code gì: Kiểm tra ô đến trống, đúng hướng và đúng đường chéo;
# chỉ sau khi hợp lệ mới cập nhật vị trí quân.
# Input: Quân Đen ở 21 thử đi đến 13 (đi qua hai hàng, sai), 22 (có quân),
# rồi đến 17 (đường chéo một ô, hợp lệ).
# Output mong đợi: Hai nước đầu bị từ chối. Nước 21->17 được áp dụng:
# hàng 5 có quân Đen ở ô đầu tiên; hàng 6 ô đầu tiên trong bốn ô trống.
def test_basic_move_validation_and_application(mars_jar: Path) -> None:
    output = run_mars("21\n13\n22\n17\n", mars_jar)
    assert output.count("Nuoc di khong hop le") == 2
    assert re.search(r"(?m)^5\s+b\s+0\s+0\s+0\s*$", output)
    assert re.search(r"(?m)^6 0\s+b\s+b\s+b\s*$", output)


# Commit này code gì: Hoàn tất một nước của Đen rồi một nước của Đỏ, sau đó
# quay lại lượt Đen; cho phép nhập 0 tại ô xuất phát để kết thúc ván.
# Input: Đen đi 21->17, Đỏ đi 9->13, Đen nhập 0 để thoát.
# Output mong đợi: Hiện lời nhắc lượt Đỏ sau nước Đen, lời nhắc lượt Đen sau
# nước Đỏ và thông báo kết thúc ván chơi.
def test_turns_alternate(mars_jar: Path) -> None:
    output = run_mars("21\n17\n9\n13\n0\n", mars_jar)
    assert "Den luot Do." in output
    assert "Den luot Den." in output
    assert "Ket thuc van choi." in output


# Commit này code gì: Thêm luật nhảy qua một quân đối phương, rồi xóa quân bị
# ăn khỏi bàn cờ.
# Input: Đen đi 21->17; Đỏ đi 10->14; Đen ăn 17x10; sau đó nhập 0 để thoát.
# Bàn cờ ngay trước nước ăn:
#   1   r   r   r   r
#   2 r   r   r   r
#   3   r   0   r   r
#   4 0   r   0   0
#   5   b   0   0   0
#   6 0   b   b   b
#   7   b   b   b   b
#   8 b   b   b   b
# Quân Đen ở 17 nhảy qua quân Đỏ ở 14, đáp xuống ô trống 10.
# Output mong đợi: Báo đã ăn quân; quân Đỏ ở 14 và quân Đen ở 17 biến mất,
# quân Đen xuất hiện ở 10. Các hàng sau nước ăn:
#   3   r   b   r   r
#   4 0   0   0   0
#   5   0   0   0   0
def test_capture_removes_opponent_piece(mars_jar: Path) -> None:
    output = run_mars("21\n17\n10\n14\n17\n10\n0\n", mars_jar)
    assert "Da an quan doi phuong." in output
    assert "Den luot Do." in output
    assert re.search(r"(?m)^3\s+r\s+b\s+r\s+r\s*$", output)
    assert re.search(r"(?m)^4 0\s+0\s+0\s+0\s*$", output)
    assert re.search(r"(?m)^5\s+0\s+0\s+0\s+0\s*$", output)


# Commit này code gì: Phong Tốt Đen khi chạm hàng cuối, cho vua đi/ăn cả
# tiến lẫn lùi, và bắt buộc tiếp tục nếu vua còn nước ăn.
# Input (các nước đơn để tạo thế ăn): Đen 21->17, 22->18, 23->19, 24->20,
# 25->21; Đỏ 10->14, 11->15, 7->11, 12->16, 3->7.
# Sau đó Đen nhập 17->10, chỉ nhập ô đến 3 để ăn tiếp và phong vua, rồi
# nhập ô đến 12 để vua ăn lùi. Nhập 0 sau khi chuỗi ăn kết thúc.
# Output mong đợi: Báo 3 quân bị ăn, hiện lời nhắc ăn tiếp 2 lần, báo phong
# vua; vua Đen cuối cùng nằm ở hàng 3, cột cuối.
# Một dòng trên bàn cờ cuối:
#   3   r   0   r   B
def test_capture_chain_and_promotion(mars_jar: Path) -> None:
    input_text = (
        "21\n17\n10\n14\n22\n18\n11\n15\n23\n19\n7\n11\n24\n20\n"
        "12\n16\n25\n21\n3\n7\n17\n10\n3\n12\n0\n"
    )
    output = run_mars(input_text, mars_jar)
    assert output.count("Da an quan doi phuong.") == 3
    assert output.count("Co the an tiep.") == 2
    assert "Quan tot duoc phong vua." in output
    assert re.search(r"(?m)^3\s+r\s+0\s+r\s+B\s*$", output)


# Commit này code gì: Đếm số quân còn lại của đối thủ sau lượt; nếu không còn
# quân thì thông báo bên thắng và kết thúc chương trình.
# Để testcase ngắn gọn, nó tạo bàn cờ thử: xóa hết quân, đặt Đen ở 18 và Đỏ
# ở 14. Vị trí trước nước ăn:
#   4 0   r   0   0
#   5   0   b   0   0
# Input: Đen đi 18->9, nhảy qua quân Đỏ ở 14 và ăn quân cuối cùng.
# Output mong đợi: Ô 14 và 18 trống, quân Đen ở 9; chương trình in
# "Đen thắng!" và dừng, không hỏi nhập lượt tiếp theo.
def test_win_when_opponent_has_no_pieces(mars_jar: Path) -> None:
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
    li    $t0, 35
    addu  $t1, $s0, $t0
    li    $t2, 1
    sb    $t2, 0($t1)
    li    $t0, 26
    addu  $t1, $s0, $t0
    li    $t2, -1
    sb    $t2, 0($t1)
"""
    assert source.count(marker) == 1
    fixture_source = source.replace(marker, setup + marker, 1)

    with tempfile.TemporaryDirectory() as temp_dir:
        fixture_path = Path(temp_dir) / "checkers_win_test.asm"
        fixture_path.write_text(fixture_source, encoding="utf-8")
        output = run_mars("18\n9\n", mars_jar, fixture_path)

    assert "Den thang!" in output


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
        test_source_square_validation,
        test_basic_move_validation_and_application,
        test_turns_alternate,
        test_capture_removes_opponent_piece,
        test_capture_chain_and_promotion,
        test_win_when_opponent_has_no_pieces,
    )
    try:
        for test in tests:
            test(mars_jar)
            print(f"PASS: {test.__name__}")
    except (AssertionError, OSError, RuntimeError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        return 1

    print(f"All {len(tests)} MARS integration tests passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
