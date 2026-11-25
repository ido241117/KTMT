.data
board:   .space 64
input_buffer: .space 16
newline: .asciiz "\n"
header_black: .asciiz "Ban co theo goc nhin ben Den:\n"
header_red: .asciiz "Ban co theo goc nhin ben Do:\n"
board_border: .asciiz "+------+------+------+------+------+------+------+------+\n"
cell_left: .asciiz "| "
light_cell: .asciiz "     "
row_end: .asciiz "|\n"
prompt_black: .asciiz "Den luot Den. Nhap o xuat phat (1-32, 0 de thoat): "
prompt_red: .asciiz "Den luot Do. Nhap o xuat phat (1-32, 0 de thoat): "
dest_prompt: .asciiz "Nhap o den (1-32): "
continue_prompt: .asciiz "Co the an tiep. Nhap o den tiep theo (1-32): "
invalid_input: .asciiz "Dau vao khong phai so nguyen. Hay nhap lai.\n"
invalid: .asciiz "O xuat phat khong hop le hoac khong phai quan cua ban. Hay thu lai.\n"
invalid_move: .asciiz "Nuoc di khong hop le. Hay thu lai.\n"
capture_message: .asciiz "Da an quan doi phuong.\n"
promotion_message: .asciiz "Quan tot duoc phong vua.\n"
no_move_message: .asciiz "Doi phuong khong con nuoc di hop le.\n"
black_wins: .asciiz "Den thang!\n"
red_wins: .asciiz "Do thang!\n"
quit_message: .asciiz "Ket thuc van choi.\n"

# Quy uoc thanh ghi dung xuyen suot chuong trinh chinh:
#   $s0 = dia chi board        $s4 = luot hien tai (1 Den, -1 Do)
#   $s1 = o xuat phat (0-63)   $s6 = 1 neu nuoc vua di la nuoc an
#   $s2 = o den (0-63)         $s7 = 1 khi dang trong chuoi an bat buoc
#   $s3 = gia tri quan dang di (1/-1 tot, 2/-2 vua)
.text
.globl main
main:
    la    $s0, board
    jal   initialize_board
    li    $s4, 1
    move  $s7, $zero

turn_start:
    jal   display_board
source_prompt:
    bgtz  $s4, source_prompt_black
    la    $a0, prompt_red
    j     source_prompt_print
source_prompt_black:
    la    $a0, prompt_black
source_prompt_print:
    li    $v0, 4
    syscall
    jal   read_number
    bltz  $v0, invalid_source_input
    beq   $v0, $zero, game_exit
    move  $a0, $v0
    jal   square_to_index
    bltz  $v0, invalid_source
    move  $s1, $v0
    addu  $t0, $s0, $s1
    lb    $s3, 0($t0)
    beq   $s3, $zero, invalid_source
    slt   $t0, $zero, $s3
    slt   $t1, $zero, $s4
    bne   $t0, $t1, invalid_source

destination_prompt:
    bne   $s7, $zero, continue_destination_prompt
    la    $a0, dest_prompt
    j     print_destination_prompt
continue_destination_prompt:
    la    $a0, continue_prompt
print_destination_prompt:
    li    $v0, 4
    syscall
    jal   read_number
    bltz  $v0, invalid_destination_input
    move  $a0, $v0
    jal   square_to_index
    bltz  $v0, invalid_destination
    move  $s2, $v0
    move  $a0, $s1
    move  $a1, $s2
    move  $a2, $s3
    jal   validate_move
    beq   $v0, $zero, invalid_destination
    addiu $s6, $v0, -1

apply_move:
    addu  $t0, $s0, $s1
    sb    $zero, 0($t0)
    addu  $t0, $s0, $s2
    sb    $s3, 0($t0)
    beq   $s6, $zero, check_promotion
    addu  $t0, $s1, $s2
    srl   $t0, $t0, 1
    addu  $t0, $s0, $t0
    sb    $zero, 0($t0)
    la    $a0, capture_message
    li    $v0, 4
    syscall
check_promotion:
    srl   $t0, $s2, 3
    li    $t1, 1
    beq   $s3, $t1, promote_black
    li    $t1, -1
    beq   $s3, $t1, promote_red
    j     check_next_capture
promote_black:
    bne   $t0, $zero, check_next_capture
    li    $s3, 2
    j     store_promoted_piece
promote_red:
    li    $t1, 7
    bne   $t0, $t1, check_next_capture
    li    $s3, -2
store_promoted_piece:
    addu  $t0, $s0, $s2
    sb    $s3, 0($t0)
    la    $a0, promotion_message
    li    $v0, 4
    syscall
check_next_capture:
    beq   $s6, $zero, finish_turn
    move  $a0, $s2
    move  $a1, $s3
    li    $a2, 1
    jal   piece_has_move
    beq   $v0, $zero, finish_turn
    li    $s7, 1
    move  $s1, $s2
    j     destination_prompt

# Doi luot roi kiem tra ben sap di con nuoc hop le khong. Het quan cung la
# truong hop khong con nuoc di, nen mot phep kiem tra bao ca hai dieu kien.
finish_turn:
    move  $s7, $zero
    subu  $s4, $zero, $s4
    jal   has_any_move
    bne   $v0, $zero, turn_start
    jal   display_board
    la    $a0, no_move_message
    li    $v0, 4
    syscall
    bltz  $s4, black_wins_game
    la    $a0, red_wins
    j     print_winner
black_wins_game:
    la    $a0, black_wins
print_winner:
    li    $v0, 4
    syscall
    li    $v0, 10
    syscall

invalid_source_input:
    la    $a0, invalid_input
    j     report_source_error
invalid_source:
    la    $a0, invalid
report_source_error:
    li    $v0, 4
    syscall
    j     source_prompt

# Nuoc di sai ngoai chuoi an ($s7 == 0): nhap lai ca o xuat phat va o den
# (khop req.md), nen chon nham quan bi chan cung khong bi ket. Trong chuoi
# an bat buoc ($s7 != 0) quan an phai giu nguyen, chi nhap lai o den.
invalid_destination_input:
    la    $a0, invalid_input
    j     report_destination_error
invalid_destination:
    la    $a0, invalid_move
report_destination_error:
    li    $v0, 4
    syscall
    beq   $s7, $zero, source_prompt
    j     destination_prompt

game_exit:
    la    $a0, quit_message
    li    $v0, 4
    syscall
    li    $v0, 10
    syscall

# ---------------------------------------------------------------------------
# initialize_board: dat Do o ba hang tren, Den o ba hang duoi, con lai trong.
# ---------------------------------------------------------------------------
initialize_board:
    li    $t0, 0
initialize_loop:
    srl   $t1, $t0, 3
    andi  $t2, $t0, 7
    addu  $t3, $t1, $t2
    andi  $t3, $t3, 1
    beq   $t3, $zero, initialize_empty
    slti  $t3, $t1, 3
    bne   $t3, $zero, initialize_red
    slti  $t3, $t1, 5
    bne   $t3, $zero, initialize_empty
    li    $t3, 1
    j     initialize_store
initialize_red:
    li    $t3, -1
    j     initialize_store
initialize_empty:
    move  $t3, $zero
initialize_store:
    addu  $t4, $s0, $t0
    sb    $t3, 0($t4)
    addiu $t0, $t0, 1
    slti  $t3, $t0, 64
    bne   $t3, $zero, initialize_loop
    jr    $ra

# ---------------------------------------------------------------------------
# display_board: in ban co dang luoi; moi o toi hien ky hieu quan (r/b/R/B,
# '.' la o trong) kem so o 1-32 de nguoi choi biet can nhap so nao.
# Ban co duoc in theo goc nhin cua ben dang di ($s4): luot Do thi xoay 180
# do (o hien thi thu i la o 63 - i trong board) de quan Do cung di len, va
# so o in ra cung danh theo goc nhin Do (o n chuan in thanh 33 - n).
# ---------------------------------------------------------------------------
display_board:
    la    $a0, newline
    li    $v0, 4
    syscall
    bgtz  $s4, display_header_black
    la    $a0, header_red
    j     display_header_print
display_header_black:
    la    $a0, header_black
display_header_print:
    syscall
    la    $a0, board_border
    syscall
    li    $t0, 0
print_row:
    li    $t1, 0
print_column:
    la    $a0, cell_left
    li    $v0, 4
    syscall
    addu  $t2, $t0, $t1
    andi  $t2, $t2, 1
    beq   $t2, $zero, print_light
    sll   $t7, $t0, 3
    addu  $t7, $t7, $t1
    bgtz  $s4, print_cell_index_ready
    li    $t2, 63
    subu  $t7, $t2, $t7
print_cell_index_ready:
    addu  $t2, $s0, $t7
    lb    $t3, 0($t2)
    beq   $t3, $zero, print_empty
    li    $t6, 2
    beq   $t3, $t6, print_black_king
    li    $t6, -2
    beq   $t3, $t6, print_red_king
    bltz  $t3, print_red
    li    $a0, 98
    j     print_square
print_black_king:
    li    $a0, 66
    j     print_square
print_red_king:
    li    $a0, 82
    j     print_square
print_red:
    li    $a0, 114
    j     print_square
print_empty:
    li    $a0, 46
print_square:
    li    $v0, 11
    syscall
    li    $a0, 32
    syscall
    srl   $t2, $t7, 3
    sll   $t2, $t2, 2
    andi  $t3, $t7, 7
    srl   $t3, $t3, 1
    addu  $t2, $t2, $t3
    addiu $t2, $t2, 1
    bgtz  $s4, print_number_ready
    li    $t3, 33
    subu  $t2, $t3, $t2
print_number_ready:
    slti  $t3, $t2, 10
    beq   $t3, $zero, print_square_number
    li    $a0, 32
    syscall
print_square_number:
    move  $a0, $t2
    li    $v0, 1
    syscall
    li    $a0, 32
    li    $v0, 11
    syscall
    j     next_column
print_light:
    la    $a0, light_cell
    li    $v0, 4
    syscall
next_column:
    addiu $t1, $t1, 1
    slti  $t2, $t1, 8
    bne   $t2, $zero, print_column
    la    $a0, row_end
    li    $v0, 4
    syscall
    la    $a0, board_border
    syscall
    addiu $t0, $t0, 1
    slti  $t2, $t0, 8
    bne   $t2, $zero, print_row
    jr    $ra

# ---------------------------------------------------------------------------
# read_number: doc mot dong bang syscall 8 (khong dung syscall 5 vi MARS dung
# chuong trinh khi gap ky tu khong phai so). Chap nhan khoang trang hai dau
# va toi da 3 chu so.
# Tra ve: $v0 = so doc duoc (>= 0), hoac -1 neu dong trong / sai dinh dang.
# ---------------------------------------------------------------------------
read_number:
    la    $a0, input_buffer
    li    $a1, 16
    li    $v0, 8
    syscall
    la    $t0, input_buffer
    move  $v0, $zero
    move  $t1, $zero
read_skip_leading:
    lb    $t2, 0($t0)
    li    $t3, 32
    bne   $t2, $t3, read_digits
    addiu $t0, $t0, 1
    j     read_skip_leading
read_digits:
    lb    $t2, 0($t0)
    slti  $t3, $t2, 48
    bne   $t3, $zero, read_trailing
    slti  $t3, $t2, 58
    beq   $t3, $zero, read_trailing
    li    $t3, 10
    mul   $v0, $v0, $t3
    addiu $t2, $t2, -48
    addu  $v0, $v0, $t2
    addiu $t1, $t1, 1
    slti  $t3, $t1, 4
    beq   $t3, $zero, read_invalid
    addiu $t0, $t0, 1
    j     read_digits
read_trailing:
    lb    $t2, 0($t0)
    beq   $t2, $zero, read_end
    li    $t3, 10
    beq   $t2, $t3, read_end
    li    $t3, 13
    beq   $t2, $t3, read_skip_trailing
    li    $t3, 32
    bne   $t2, $t3, read_invalid
read_skip_trailing:
    addiu $t0, $t0, 1
    j     read_trailing
read_end:
    beq   $t1, $zero, read_invalid
    jr    $ra
read_invalid:
    li    $v0, -1
    jr    $ra

# ---------------------------------------------------------------------------
# square_to_index: doi so o 1-32 sang chi so 0-63 trong board.
# So o duoc danh theo goc nhin ben dang di: voi Do, ban co xoay 180 do nen
# o n cua Do la o 33 - n theo cach danh so chuan (goc nhin Den).
# Moi hang co 4 o toi; hang chan (0, 2, ...) bat dau o cot 1, hang le o cot 0.
# Vao: $a0 = so o. Tra ve: $v0 = chi so, hoac -1 neu ngoai khoang 1-32.
# ---------------------------------------------------------------------------
square_to_index:
    blt   $a0, 1, square_invalid
    bgt   $a0, 32, square_invalid
    move  $t0, $a0
    bgtz  $s4, square_perspective_ready
    li    $t0, 33
    subu  $t0, $t0, $a0
square_perspective_ready:
    addiu $t0, $t0, -1
    srl   $t1, $t0, 2
    andi  $t2, $t0, 3
    sll   $t2, $t2, 1
    andi  $t3, $t1, 1
    bne   $t3, $zero, square_column_ready
    addiu $t2, $t2, 1
square_column_ready:
    sll   $v0, $t1, 3
    addu  $v0, $v0, $t2
    jr    $ra
square_invalid:
    li    $v0, -1
    jr    $ra

# ---------------------------------------------------------------------------
# validate_move: kiem tra quan $a2 di tu o $a0 den o $a1 (chi so 0-63).
# - O den phai trong, di cheo dung 1 hoac 2 hang.
# - Tot chi di tien (Den len tren, Do xuong duoi); vua di ca hai huong.
# - Di 2 hang la nuoc an: o giua phai co quan doi phuong.
# - Trong chuoi an ($s7 != 0) chi chap nhan nuoc an.
# Tra ve: $v0 = 0 khong hop le, 1 nuoc di thuong, 2 nuoc an.
# ---------------------------------------------------------------------------
validate_move:
    addu  $t0, $s0, $a1
    lb    $t0, 0($t0)
    bne   $t0, $zero, validate_invalid
    srl   $t0, $a0, 3
    srl   $t1, $a1, 3
    subu  $t2, $t1, $t0
    li    $t3, 2
    beq   $a2, $t3, validate_distance
    li    $t3, -2
    beq   $a2, $t3, validate_distance
    bgtz  $a2, validate_black_direction
    blez  $t2, validate_invalid
    j     validate_distance
validate_black_direction:
    bgez  $t2, validate_invalid
validate_distance:
    abs   $t4, $t2
    andi  $t0, $a0, 7
    andi  $t1, $a1, 7
    subu  $t5, $t1, $t0
    abs   $t5, $t5
    bne   $t4, $t5, validate_invalid
    li    $t3, 1
    beq   $t4, $t3, validate_step
    li    $t3, 2
    bne   $t4, $t3, validate_invalid
    addu  $t0, $a0, $a1
    srl   $t0, $t0, 1
    addu  $t0, $s0, $t0
    lb    $t0, 0($t0)
    beq   $t0, $zero, validate_invalid
    slt   $t1, $zero, $t0
    slt   $t3, $zero, $a2
    beq   $t1, $t3, validate_invalid
    li    $v0, 2
    jr    $ra
validate_step:
    bne   $s7, $zero, validate_invalid
    li    $v0, 1
    jr    $ra
validate_invalid:
    move  $v0, $zero
    jr    $ra

# ---------------------------------------------------------------------------
# piece_has_move: thu 8 o dich quanh quan $a1 o o $a0 (4 huong cheo x khoang
# cach 1 hoac 2) bang validate_move.
# Vao: $a2 = 1 neu chi tinh nuoc an. Tra ve: $v0 = 1 neu co nuoc, 0 neu khong.
# Bit cua bien dem k (0-7): bit 0 = khoang cach 1/2, bit 1 = len/xuong,
# bit 2 = trai/phai.
# ---------------------------------------------------------------------------
piece_has_move:
    addiu $sp, $sp, -20
    sw    $ra, 16($sp)
    sw    $s1, 12($sp)
    sw    $s2, 8($sp)
    sw    $s3, 4($sp)
    sw    $s5, 0($sp)
    move  $s1, $a0
    move  $s2, $a1
    move  $s3, $a2
    move  $s5, $zero
piece_move_loop:
    andi  $t0, $s5, 1
    addiu $t0, $t0, 1
    andi  $t1, $s5, 2
    move  $t2, $t0
    bne   $t1, $zero, piece_row_step_ready
    subu  $t2, $zero, $t0
piece_row_step_ready:
    andi  $t1, $s5, 4
    move  $t3, $t0
    bne   $t1, $zero, piece_column_step_ready
    subu  $t3, $zero, $t0
piece_column_step_ready:
    srl   $t4, $s1, 3
    addu  $t4, $t4, $t2
    bltz  $t4, piece_next_target
    slti  $t5, $t4, 8
    beq   $t5, $zero, piece_next_target
    andi  $t5, $s1, 7
    addu  $t5, $t5, $t3
    bltz  $t5, piece_next_target
    slti  $t6, $t5, 8
    beq   $t6, $zero, piece_next_target
    sll   $a1, $t4, 3
    addu  $a1, $a1, $t5
    move  $a0, $s1
    move  $a2, $s2
    jal   validate_move
    beq   $v0, $zero, piece_next_target
    beq   $s3, $zero, piece_move_found
    li    $t0, 2
    beq   $v0, $t0, piece_move_found
piece_next_target:
    addiu $s5, $s5, 1
    slti  $t0, $s5, 8
    bne   $t0, $zero, piece_move_loop
    move  $v0, $zero
    j     piece_move_return
piece_move_found:
    li    $v0, 1
piece_move_return:
    lw    $s5, 0($sp)
    lw    $s3, 4($sp)
    lw    $s2, 8($sp)
    lw    $s1, 12($sp)
    lw    $ra, 16($sp)
    addiu $sp, $sp, 20
    jr    $ra

# ---------------------------------------------------------------------------
# has_any_move: ben $s4 con it nhat mot nuoc di thuong hoac nuoc an hop le?
# Tra ve: $v0 = 1 neu con, 0 neu het quan hoac moi quan deu bi chan.
# ---------------------------------------------------------------------------
has_any_move:
    addiu $sp, $sp, -8
    sw    $ra, 4($sp)
    sw    $s1, 0($sp)
    move  $s1, $zero
any_move_loop:
    addu  $t0, $s0, $s1
    lb    $a1, 0($t0)
    beq   $a1, $zero, any_move_next
    slt   $t1, $zero, $a1
    slt   $t2, $zero, $s4
    bne   $t1, $t2, any_move_next
    move  $a0, $s1
    move  $a2, $zero
    jal   piece_has_move
    bne   $v0, $zero, any_move_return
any_move_next:
    addiu $s1, $s1, 1
    slti  $t0, $s1, 64
    bne   $t0, $zero, any_move_loop
    move  $v0, $zero
any_move_return:
    lw    $s1, 0($sp)
    lw    $ra, 4($sp)
    addiu $sp, $sp, 8
    jr    $ra
