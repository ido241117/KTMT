import argparse
import re
import subprocess
from pathlib import Path


ASSEMBLY_PATH = Path(__file__).resolve().parents[1] / "checkers.asm"


def run_mars(input_text: str, mars_jar: Path) -> str:
    result = subprocess.run(
        ["java", "-jar", str(mars_jar), "nc", "se1", str(ASSEMBLY_PATH)],
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
# Input: 1 (quan Do), 0 (ngoai khoang 1-32), 21 (quan Den).
# Output mong doi: Tu choi hai input dau; chap nhan o 21 va in
# "Source square accepted.".
def test_source_square_validation(mars_jar: Path) -> None:
    output = run_mars("1\n0\n21\n", mars_jar)
    assert output.count("Invalid source square") == 2
    assert "Source square accepted." in output


def main() -> int:
    parser = argparse.ArgumentParser(description="Run checkers MARS tests.")
    parser.add_argument("--mars-jar", required=True, type=Path)
    args = parser.parse_args()
    if not args.mars_jar.is_file():
        parser.error(f"MARS jar not found: {args.mars_jar}")

    tests = (test_initial_board, test_source_square_validation)
    for test in tests:
        test(args.mars_jar)
        print(f"PASS: {test.__name__}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
