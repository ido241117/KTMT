import argparse
import re
import subprocess
import tempfile
from pathlib import Path


ASSEMBLY_PATH = Path(__file__).resolve().parents[1] / "checkers.asm"


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


# Commit nay code gi: Khoi tao ban co 8x8, dat Tot Do o ba hang tren va Tot
# Den o ba hang duoi, sau do in trang thai ban co.
# Input: Khong nhap gi; chi chay chuong trinh.
# Output mong doi:
#   1   r   r   r   r
#   2 r   r   r   r
#   3   r   r   r   r
#   4 0   0   0   0
#   5   0   0   0   0
#   6 b   b   b   b
#   7   b   b   b   b
#   8 b   b   b   b
# Test kiem tra co dung 8 hang va quan Den/Do nam dung ba hang ban dau.
def test_initial_board(mars_jar: Path) -> None:
    output = run_mars("", mars_jar)
    rows = re.findall(r"(?m)^[1-8] .*$", output)
    assert len(rows) == 8, f"Expected 8 board rows, got {len(rows)}"
    assert re.search(r"(?m)^1\s+r\s+r\s+r\s+r\s*$", output)
    assert re.search(r"(?m)^8 b\s+b\s+b\s+b\s*$", output)


# Commit nay code gi: Kiem tra o xuat phat co nam trong 1-32, co quan va
# quan do thuoc nguoi dang luot (Den di dau tien) hay khong.
# Input: 1 (quan Do), 0 (ngoai khoang 1-32), 21 (quan Den), 17 (o den).
# Output mong doi: Tu choi 1 va 0, sau do chap nhan 21 va di 21->17.
# Quan Den roi o 21; tren ban co, hang 5 co mot quan Den moi.
def test_source_square_validation(mars_jar: Path) -> None:
    output = run_mars("1\n33\n21\n17\n", mars_jar)
    assert output.count("O xuat phat khong hop le") == 2
    assert "Nhap o den" in output


# Commit nay code gi: Kiem tra o den trong, dung huong va dung duong cheo;
# chi sau khi hop le moi cap nhat vi tri quan.
# Input: Quan Den o 21 thu di den 13 (di qua hai hang, sai), 22 (co quan),
# roi den 17 (duong cheo mot o, hop le).
# Output mong doi: Hai nuoc dau bi tu choi. Nuoc 21->17 duoc ap dung:
# hang 5 co quan Den o o dau tien; hang 6 o dau tien trong bo bon o trong.
def test_basic_move_validation_and_application(mars_jar: Path) -> None:
    output = run_mars("21\n13\n22\n17\n", mars_jar)
    assert output.count("Nuoc di khong hop le") == 2
    assert re.search(r"(?m)^5\s+b\s+0\s+0\s+0\s*$", output)
    assert re.search(r"(?m)^6 0\s+b\s+b\s+b\s*$", output)


# Commit nay code gi: Hoan tat mot nuoc cua Den roi mot nuoc cua Do, sau do
# quay lai luot Den; cho phep nhap 0 tai o xuat phat de ket thuc van.
# Input: Den di 21->17, Do di 9->13, Den nhap 0 de thoat.
# Output mong doi: Hien prompt luot Do sau nuoc Den, prompt luot Den sau
# nuoc Do, va thong bao ket thuc van choi.
def test_turns_alternate(mars_jar: Path) -> None:
    output = run_mars("21\n17\n9\n13\n0\n", mars_jar)
    assert "Den luot Do." in output
    assert "Den luot Den." in output
    assert "Ket thuc van choi." in output


# Commit nay code gi: Them luat nhay qua mot quan doi phuong, roi xoa quan bi
# an khoi ban co.
# Input: Den di 21->17; Do di 10->14; Den an 17x10; sau do nhap 0 de thoat.
# Ban co ngay truoc nuoc an:
#   1   r   r   r   r
#   2 r   r   r   r
#   3   r   0   r   r
#   4 0   r   0   0
#   5   b   0   0   0
#   6 0   b   b   b
#   7   b   b   b   b
#   8 b   b   b   b
# Quan Den o 17 nhay qua quan Do o 14, dap xuong o trong 10.
# Output mong doi: Bao da an quan; quan Do o 14 va quan Den o 17 bien mat,
# quan Den xuat hien o 10. Cac hang sau nuoc an:
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


# Commit nay code gi: Phong Tot Den khi cham hang cuoi, cho vua di/an ca
# tien va lui, va bat buoc tiep tuc neu vua con nuoc an.
# Input (cac nuoc don de tao the an): Den 21->17, 22->18, 23->19, 24->20,
# 25->21; Do 10->14, 11->15, 7->11, 12->16, 3->7.
# Sau do Den nhap 17->10, chi nhap o den 3 de an tiep va phong vua, roi
# nhap o den 12 de vua an lui. Nhap 0 sau khi chuoi an ket thuc.
# Output mong doi: Bao 3 quan bi an, hien loi nhac an tiep 2 lan, bao phong
# vua; vua Den cuoi cung nam o hang 3, cot cuoi.
# Mot dong tren ban co cuoi:
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


# Commit nay code gi: Dem so quan con lai cua doi thu sau luot; neu khong con
# quan thi thong bao ben thang va ket thuc chuong trinh.
# De testcase ngan gon, no tao ban co thu: xoa het quan, dat Den o 18 va Do
# o 14. Vi tri truoc nuoc an:
#   4 0   r   0   0
#   5   0   b   0   0
# Input: Den di 18->9, nhay qua quan Do o 14 va an quan cuoi cung.
# Output mong doi: O 14 va 18 trong, quan Den o 9; chuong trinh in
# "Black wins!" va dung, khong hoi nhap luot tiep theo.
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
    parser = argparse.ArgumentParser(description="Run checkers MARS tests.")
    parser.add_argument("--mars-jar", required=True, type=Path)
    args = parser.parse_args()
    if not args.mars_jar.is_file():
        parser.error(f"MARS jar not found: {args.mars_jar}")

    tests = (
        test_initial_board,
        test_source_square_validation,
        test_basic_move_validation_and_application,
        test_turns_alternate,
        test_capture_removes_opponent_piece,
        test_capture_chain_and_promotion,
        test_win_when_opponent_has_no_pieces,
    )
    for test in tests:
        test(args.mars_jar)
        print(f"PASS: {test.__name__}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
