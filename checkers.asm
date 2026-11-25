.data
    # last_path = [0] * 16       (cac o da di qua cua nuoc vua di, chi so 0-63)
    # last_path_len = 0          (0 = chua co nuoc nao trong van)
    # last_player = 0            (ben vua di: 1 Den, -1 Do)
    # last_capture = 0           (1 neu nuoc vua di la nuoc an)
last_path_len: .word 0
last_player: .word 0
last_capture: .word 0
last_path: .space 16
    # board = [0] * 64           (8 hang x 8 cot; 0 trong, 1/-1 tot Den/Do,
    #                             2/-2 vua Den/Do)
board:   .space 64
    # input_buffer = [0] * 16    (dong vua nhap tu ban phim)
input_buffer: .space 16
    # move_list = [0] * 8        (o dich cac nuoc hop le cua quan dang chon)
move_list: .space 8

    # Cac chuoi dung de in ban co
newline: .asciiz "\n"
header_black: .asciiz "Ban co theo goc nhin ben Den:\n"
header_red: .asciiz "Ban co theo goc nhin ben Do:\n"
board_border: .asciiz "+------+------+------+------+------+------+------+------+\n"
cell_left: .asciiz "| "
light_cell: .asciiz "     "
row_end: .asciiz "|\n"
    # Cac loi nhac va thong bao
prompt_black: .asciiz "Den luot Den. Nhap o xuat phat (1-32, H de nghi hoa, M choi lai, 0 de thoat): "
prompt_red: .asciiz "Den luot Do. Nhap o xuat phat (1-32, H de nghi hoa, M choi lai, 0 de thoat): "
restart_message: .asciiz "Bat dau van moi.\n"
play_again_prompt: .asciiz "Van co da ket thuc. Nhap M de choi van moi, phim khac de thoat: "
draw_offer_black: .asciiz "Den de nghi hoa. Do co dong y khong? Nhap H de dong y, phim khac de tu choi: "
draw_offer_red: .asciiz "Do de nghi hoa. Den co dong y khong? Nhap H de dong y, phim khac de tu choi: "
draw_declined: .asciiz "De nghi hoa bi tu choi. Van co tiep tuc.\n"
draw_message: .asciiz "Hai ben dong y hoa. Van co hoa!\n"
moves_header: .asciiz "Cac nuoc di cua quan o "
moves_header_end: .asciiz ":\n"
move_item_indent: .asciiz "  "
move_item_separator: .asciiz ") "
choice_prompt: .asciiz "Chon nuoc di (1-"
choice_prompt_end: .asciiz "): "
continue_message: .asciiz "Co the an tiep.\n"
    # Cac thong bao loi (phan dau + so vua nhap + phan duoi)
error_square_not_number: .asciiz "Loi: dau vao khong hop le. Hay nhap so o tu 1 den 32 (H de nghi hoa, M choi lai, 0 de thoat).\n"
error_square_prefix: .asciiz "Loi: o "
error_out_of_range_suffix: .asciiz " nam ngoai khoang 1-32.\n"
error_empty_suffix: .asciiz " dang trong, khong co quan de di.\n"
error_opponent_suffix: .asciiz " la quan cua doi phuong. Hay chon quan cua ban.\n"
error_blocked_suffix: .asciiz " bi chan, khong co nuoc di hop le. Hay chon quan khac.\n"
error_choice_not_number: .asciiz "Loi: dau vao khong phai so nguyen. Hay nhap so thu tu tu 1 den "
error_choice_prefix: .asciiz "Loi: lua chon "
error_choice_suffix: .asciiz " khong co trong danh sach.\n"
period_newline: .asciiz ".\n"
    # Cac thong bao trong van
capture_message: .asciiz "Da an quan doi phuong.\n"
promotion_message: .asciiz "Quan tot duoc phong vua.\n"
no_move_message: .asciiz "Doi phuong khong con nuoc di hop le.\n"
black_wins: .asciiz "Den thang!\n"
red_wins: .asciiz "Do thang!\n"
quit_message: .asciiz "Ket thuc van choi.\n"
status_count_black: .asciiz "So quan: Den "
status_count_red: .asciiz ", Do "
status_last_black: .asciiz "Nuoc vua di cua Den: "
status_last_red: .asciiz "Nuoc vua di cua Do: "

# Quy uoc thanh ghi dung xuyen suot chuong trinh chinh:
#   $s0 = dia chi board        $s4 = luot hien tai (1 Den, -1 Do)
#   $s1 = o xuat phat (0-63)   $s6 = 1 neu nuoc vua di la nuoc an
#   $s2 = o den (0-63); luc chon quan, tam giu so o vua nhap de in loi
#                              $s7 = 1 khi dang trong chuoi an bat buoc
#   $s3 = gia tri quan dang di (1/-1 tot, 2/-2 vua)
#   $s5 = so nuoc di trong move_list cua quan dang chon
.text
.globl main

# ===========================================================================
# def main():
#     while True:                         # moi vong lap la mot van
#         new_game()
#         while van chua ket thuc:
#             display_board(); print_game_status()
#             chon quan -> chon nuoc -> apply_move -> an tiep neu bat buoc
#             doi luot; neu ben sap di het nuoc thi ben vua di thang
# ===========================================================================
main:
    # board_addr = &board
    la    $s0, board

    # ---------- BUOC 1: BAT DAU VAN MOI ----------
    # initialize_board() ; last_path_len = 0 ; turn = DEN ; chaining = False
new_game:
    jal   initialize_board
    sw    $zero, last_path_len
    li    $s4, 1
    move  $s7, $zero

    # ---------- BUOC 2: IN BAN CO VA HOI O XUAT PHAT ----------
turn_start:
    # display_board() ; print_game_status()
    jal   display_board
    jal   print_game_status
source_prompt:
    # print(prompt_black if turn == DEN else prompt_red, end="")
    bgtz  $s4, source_prompt_black
    la    $a0, prompt_red
    j     source_prompt_print
source_prompt_black:
    la    $a0, prompt_black
source_prompt_print:
    li    $v0, 4                  # syscall 4 = print string
    syscall

    # n = read_number()
    jal   read_number
    # if n == LENH: source_command()      (H = hoa, M = choi lai)
    li    $t0, -2
    beq   $v0, $t0, source_command
    # if n == SAI_DINH_DANG: bao loi, hoi lai
    bltz  $v0, invalid_source_input
    # if n == 0: thoat
    beq   $v0, $zero, game_exit

    # typed = n  (giu lai de in loi) ; src = square_to_index(n)
    move  $s2, $v0
    move  $a0, $v0
    jal   square_to_index
    # if src == -1: loi "o ngoai khoang 1-32"
    bltz  $v0, source_out_of_range
    move  $s1, $v0

    # piece = board[src]
    addu  $t0, $s0, $s1
    lb    $s3, 0($t0)
    # if piece == 0: loi "o dang trong"
    beq   $s3, $zero, source_empty
    # if (piece > 0) != (turn > 0): loi "quan cua doi phuong"
    slt   $t0, $zero, $s3
    slt   $t1, $zero, $s4
    bne   $t0, $t1, source_opponent

    # ---------- BUOC 3: LIET KE NUOC DI VA CHO CHON ----------
    # (trong chuoi an, danh sach chi gom nuoc an tiep)
move_menu:
    # count = build_move_list(src, piece)
    move  $a0, $s1
    move  $a1, $s3
    jal   build_move_list
    # if count == 0: loi "quan bi chan"
    beq   $v0, $zero, piece_has_no_moves
    move  $s5, $v0

    # if chaining: print("Co the an tiep.")
    beq   $s7, $zero, print_move_menu
    la    $a0, continue_message
    li    $v0, 4
    syscall
print_move_menu:
    # print_move_list(src, count)
    move  $a0, $s1
    move  $a1, $s5
    jal   print_move_list
    # print("Chon nuoc di (1-", count, "): ", end="")
    la    $a0, choice_prompt
    li    $v0, 4
    syscall
    move  $a0, $s5
    li    $v0, 1                  # syscall 1 = print integer
    syscall
    la    $a0, choice_prompt_end
    li    $v0, 4
    syscall

    # k = read_number()
    jal   read_number
    # if k khong phai so: loi ; if not 1 <= k <= count: loi
    bltz  $v0, choice_not_number
    blt   $v0, 1, choice_out_of_range
    bgt   $v0, $s5, choice_out_of_range

    # dst = move_list[k - 1]
    la    $t0, move_list
    addu  $t0, $t0, $v0
    lbu   $s2, -1($t0)
    # is_capture = abs(dst // 8 - src // 8) // 2    (cach 2 hang la nuoc an)
    srl   $t0, $s1, 3
    srl   $t1, $s2, 3
    subu  $t0, $t1, $t0
    abs   $t0, $t0
    srl   $s6, $t0, 1

    # ---------- BUOC 4: AP DUNG NUOC DI ----------
apply_move:
    # record_move()                 (ghi lai de in "Nuoc vua di")
    jal   record_move
    # board[src] = 0 ; board[dst] = piece
    addu  $t0, $s0, $s1
    sb    $zero, 0($t0)
    addu  $t0, $s0, $s2
    sb    $s3, 0($t0)
    # if is_capture: board[(src + dst) // 2] = 0 ; print("Da an quan doi phuong.")
    beq   $s6, $zero, check_promotion
    addu  $t0, $s1, $s2
    srl   $t0, $t0, 1
    addu  $t0, $s0, $t0
    sb    $zero, 0($t0)
    la    $a0, capture_message
    li    $v0, 4
    syscall

check_promotion:
    # row = dst // 8
    srl   $t0, $s2, 3
    # if piece == 1 and row == 0: piece = 2      (tot Den len hang tren cung)
    # if piece == -1 and row == 7: piece = -2    (tot Do xuong hang duoi cung)
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
    # board[dst] = piece ; print("Quan tot duoc phong vua.")
    addu  $t0, $s0, $s2
    sb    $s3, 0($t0)
    la    $a0, promotion_message
    li    $v0, 4
    syscall

    # ---------- BUOC 5: BAT BUOC AN TIEP NEU CON NUOC AN ----------
check_next_capture:
    # if not is_capture: ket thuc luot
    beq   $s6, $zero, finish_turn
    # chaining = True   (build_move_list chi con tinh nuoc an)
    li    $s7, 1
    # if build_move_list(dst, piece) == 0: ket thuc luot
    move  $a0, $s2
    move  $a1, $s3
    jal   build_move_list
    beq   $v0, $zero, finish_turn
    # src = dst
    move  $s1, $s2
    # display_board() ; print_game_status()   (cho thay vi tri sau buoc an)
    jal   display_board
    jal   print_game_status
    # quay lai BUOC 3 voi cung quan
    j     move_menu

    # ---------- BUOC 6: DOI LUOT VA KIEM TRA THANG ----------
finish_turn:
    # chaining = False ; turn = -turn
    move  $s7, $zero
    subu  $s4, $zero, $s4
    # if has_any_move(): sang luot moi (het quan cung la het nuoc di)
    jal   has_any_move
    bne   $v0, $zero, turn_start
    # display_board() ; print_game_status() ; print("Doi phuong khong con ...")
    jal   display_board
    jal   print_game_status
    la    $a0, no_move_message
    li    $v0, 4
    syscall
    # print("Den thang!" if turn == DO else "Do thang!")   (ben vua di thang)
    bltz  $s4, black_wins_game
    la    $a0, red_wins
    j     print_winner
black_wins_game:
    la    $a0, black_wins
print_winner:
    li    $v0, 4
    syscall

    # ---------- BUOC 7: HET VAN (THANG HOAC HOA) ----------
game_over:
    # print("Van co da ket thuc. Nhap M de choi van moi, ...", end="")
    la    $a0, play_again_prompt
    li    $v0, 4
    syscall
    # if read_number() la lenh 'M': restart_game() else: game_exit()
    jal   read_number
    li    $t0, -2
    bne   $v0, $t0, game_exit
    li    $t0, 77                 # 77 = 'M'
    bne   $v1, $t0, game_exit
    j     restart_game

    # ---------- LENH MOT CHU CAI TAI LOI NHAC O XUAT PHAT ----------
source_command:
    # if letter == 'H': offer_draw()
    li    $t0, 72                 # 72 = 'H'
    beq   $v1, $t0, offer_draw
    # elif letter == 'M': restart_game()
    li    $t0, 77
    beq   $v1, $t0, restart_game
    # else: bao loi dau vao
    j     invalid_source_input

restart_game:
    # print("Bat dau van moi.") ; quay lai BUOC 1
    la    $a0, restart_message
    li    $v0, 4
    syscall
    j     new_game

    # ---------- DE NGHI HOA ----------
    # ben kia cung nhap H thi hoa; nhap khac thi ben de nghi di tiep
offer_draw:
    # print(draw_offer_black if turn == DEN else draw_offer_red, end="")
    bgtz  $s4, offer_draw_black
    la    $a0, draw_offer_red
    j     offer_draw_print
offer_draw_black:
    la    $a0, draw_offer_black
offer_draw_print:
    li    $v0, 4
    syscall
    # if read_number() khong phai lenh 'H': tu choi
    jal   read_number
    li    $t0, -2
    bne   $v0, $t0, draw_rejected
    li    $t0, 72
    bne   $v1, $t0, draw_rejected
    # print("Hai ben dong y hoa. Van co hoa!") ; het van
    la    $a0, draw_message
    li    $v0, 4
    syscall
    j     game_over
draw_rejected:
    # print("De nghi hoa bi tu choi. Van co tiep tuc.") ; hoi lai o xuat phat
    la    $a0, draw_declined
    li    $v0, 4
    syscall
    j     source_prompt

    # ---------- LOI KHI CHON O XUAT PHAT ----------
    # moi loi neu ro nguyen nhan, kem so o nguoi choi vua nhap (typed)
invalid_source_input:
    # print("Loi: dau vao khong hop le. ...") ; hoi lai
    la    $a0, error_square_not_number
    li    $v0, 4
    syscall
    j     source_prompt
source_out_of_range:
    # suffix = " nam ngoai khoang 1-32."
    la    $a2, error_out_of_range_suffix
    j     report_square_error
source_empty:
    # suffix = " dang trong, khong co quan de di."
    la    $a2, error_empty_suffix
    j     report_square_error
source_opponent:
    # suffix = " la quan cua doi phuong. ..."
    la    $a2, error_opponent_suffix
    j     report_square_error
piece_has_no_moves:
    # suffix = " bi chan, khong co nuoc di hop le. ..."
    la    $a2, error_blocked_suffix
report_square_error:
    # print_with_number("Loi: o ", typed, suffix) ; hoi lai o xuat phat
    la    $a0, error_square_prefix
    move  $a1, $s2
    jal   print_with_number
    j     source_prompt

    # ---------- LOI KHI CHON NUOC DI ----------
choice_not_number:
    # print_with_number("Loi: ... tu 1 den ", count, ".")
    la    $a0, error_choice_not_number
    move  $a1, $s5
    la    $a2, period_newline
    j     report_choice_error
choice_out_of_range:
    # print_with_number("Loi: lua chon ", k, " khong co trong danh sach.")
    la    $a0, error_choice_prefix
    move  $a1, $v0
    la    $a2, error_choice_suffix
report_choice_error:
    jal   print_with_number
    # if not chaining: chon lai tu o xuat phat (khop req.md)
    # else: quan dang an phai giu nguyen, chi in lai danh sach nuoc an
    beq   $s7, $zero, source_prompt
    j     move_menu

game_exit:
    # print("Ket thuc van choi.") ; exit()
    la    $a0, quit_message
    li    $v0, 4
    syscall
    li    $v0, 10                 # syscall 10 = exit
    syscall

# ===========================================================================
# def initialize_board():
#     """Do o ba hang tren, Den o ba hang duoi, chi dat quan tren o toi."""
# ===========================================================================
initialize_board:
    # for i in range(64):
    li    $t0, 0
initialize_loop:
    #   row = i // 8 ; col = i % 8
    srl   $t1, $t0, 3
    andi  $t2, $t0, 7
    #   if (row + col) % 2 == 0: value = 0          (o sang)
    addu  $t3, $t1, $t2
    andi  $t3, $t3, 1
    beq   $t3, $zero, initialize_empty
    #   elif row < 3: value = -1                    (tot Do)
    slti  $t3, $t1, 3
    bne   $t3, $zero, initialize_red
    #   elif row < 5: value = 0                     (hai hang giua trong)
    slti  $t3, $t1, 5
    bne   $t3, $zero, initialize_empty
    #   else: value = 1                             (tot Den)
    li    $t3, 1
    j     initialize_store
initialize_red:
    li    $t3, -1
    j     initialize_store
initialize_empty:
    move  $t3, $zero
initialize_store:
    #   board[i] = value
    addu  $t4, $s0, $t0
    sb    $t3, 0($t4)
    addiu $t0, $t0, 1
    slti  $t3, $t0, 64
    bne   $t3, $zero, initialize_loop
    # return
    jr    $ra

# ===========================================================================
# def display_board():
#     """In ban co theo goc nhin ben dang di. Luot Do thi xoay 180 do (o hien
#     thi thu i lay tu board[63 - i]) va so o in theo cach dem cua Do
#     (o n chuan in thanh 33 - n), de quan Do cung di tu duoi len."""
# ===========================================================================
display_board:
    # print() ; print(header_black if turn == DEN else header_red)
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
    # print(board_border)
    la    $a0, board_border
    syscall

    # for r in range(8):
    li    $t0, 0
print_row:
    #   for c in range(8):
    li    $t1, 0
print_column:
    #     print("| ", end="")
    la    $a0, cell_left
    li    $v0, 4
    syscall
    #     if (r + c) % 2 == 0: in o sang
    addu  $t2, $t0, $t1
    andi  $t2, $t2, 1
    beq   $t2, $zero, print_light

    #     i = r * 8 + c ; if turn == DO: i = 63 - i
    sll   $t7, $t0, 3
    addu  $t7, $t7, $t1
    bgtz  $s4, print_cell_index_ready
    li    $t2, 63
    subu  $t7, $t2, $t7
print_cell_index_ready:
    #     piece = board[i]
    addu  $t2, $s0, $t7
    lb    $t3, 0($t2)
    #     symbol = {0: '.', 1: 'b', -1: 'r', 2: 'B', -2: 'R'}[piece]
    beq   $t3, $zero, print_empty
    li    $t6, 2
    beq   $t3, $t6, print_black_king
    li    $t6, -2
    beq   $t3, $t6, print_red_king
    bltz  $t3, print_red
    li    $a0, 98                 # 'b'
    j     print_square
print_black_king:
    li    $a0, 66                 # 'B'
    j     print_square
print_red_king:
    li    $a0, 82                 # 'R'
    j     print_square
print_red:
    li    $a0, 114                # 'r'
    j     print_square
print_empty:
    li    $a0, 46                 # '.'
print_square:
    #     print(symbol, " ", end="")
    li    $v0, 11                 # syscall 11 = print character
    syscall
    li    $a0, 32
    syscall

    #     number = (i // 8) * 4 + (i % 8) // 2 + 1
    srl   $t2, $t7, 3
    sll   $t2, $t2, 2
    andi  $t3, $t7, 7
    srl   $t3, $t3, 1
    addu  $t2, $t2, $t3
    addiu $t2, $t2, 1
    #     if turn == DO: number = 33 - number
    bgtz  $s4, print_number_ready
    li    $t3, 33
    subu  $t2, $t3, $t2
print_number_ready:
    #     print(f"{number:2} ", end="")     (so 1 chu so them mot dau cach)
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
    #     print("     ", end="")               (o sang de trong)
    la    $a0, light_cell
    li    $v0, 4
    syscall
next_column:
    addiu $t1, $t1, 1
    slti  $t2, $t1, 8
    bne   $t2, $zero, print_column
    #   print("|") ; print(board_border)
    la    $a0, row_end
    li    $v0, 4
    syscall
    la    $a0, board_border
    syscall
    addiu $t0, $t0, 1
    slti  $t2, $t0, 8
    bne   $t2, $zero, print_row
    # return
    jr    $ra

# ===========================================================================
# def read_number() -> int:
#     """Doc mot dong bang syscall 8 roi tu doi sang so (syscall 5 lam MARS
#     dung chuong trinh khi gap chu). Bo qua khoang trang hai dau.
#     Tra ve: so >= 0 (toi da 3 chu so), -1 neu dong trong / sai dinh dang,
#             -2 neu dong chi co mot chu cai (lenh); khi do $v1 = chu viet hoa."""
# ===========================================================================
read_number:
    # line = input()                 (toi da 15 ky tu)
    la    $a0, input_buffer
    li    $a1, 16
    li    $v0, 8                  # syscall 8 = read string
    syscall
    # p = 0 ; value = 0 ; digits = 0 ; letter = 0
    la    $t0, input_buffer
    move  $v0, $zero
    move  $t1, $zero
    move  $t6, $zero
read_skip_leading:
    # while line[p] == ' ': p += 1
    lb    $t2, 0($t0)
    li    $t3, 32
    bne   $t2, $t3, read_check_letter
    addiu $t0, $t0, 1
    j     read_skip_leading
read_check_letter:
    # lower = ord(line[p]) | 0x20     (OR 0x20 doi chu hoa thanh chu thuong)
    ori   $t3, $t2, 32
    # if 'a' <= lower <= 'z': letter = lower - 32 ; p += 1 ; kiem tra phan duoi
    slti  $t4, $t3, 97
    bne   $t4, $zero, read_digits
    slti  $t4, $t3, 123
    beq   $t4, $zero, read_digits
    addiu $t6, $t3, -32
    addiu $t0, $t0, 1
    j     read_trailing
read_digits:
    # while line[p].isdigit():
    lb    $t2, 0($t0)
    slti  $t3, $t2, 48
    bne   $t3, $zero, read_trailing
    slti  $t3, $t2, 58
    beq   $t3, $zero, read_trailing
    #   value = value * 10 + int(line[p]) ; digits += 1
    li    $t3, 10
    mul   $v0, $v0, $t3
    addiu $t2, $t2, -48
    addu  $v0, $v0, $t2
    addiu $t1, $t1, 1
    #   if digits > 3: return -1
    slti  $t3, $t1, 4
    beq   $t3, $zero, read_invalid
    addiu $t0, $t0, 1
    j     read_digits
read_trailing:
    # phan con lai chi duoc la ' ', '\r' roi '\n' hoac het chuoi
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
    # if letter: return -2, letter
    bne   $t6, $zero, read_command
    # if digits == 0: return -1      (dong trong)
    beq   $t1, $zero, read_invalid
    # return value
    jr    $ra
read_command:
    li    $v0, -2
    move  $v1, $t6
    jr    $ra
read_invalid:
    li    $v0, -1
    jr    $ra

# ===========================================================================
# def square_to_index(n: int) -> int:
#     """Doi so o 1-32 (theo goc nhin ben dang di) sang chi so 0-63 trong
#     board. Moi hang co 4 o toi; hang chan bat dau o cot 1, hang le o cot 0.
#     Tra ve -1 neu n ngoai khoang 1-32."""
# ===========================================================================
square_to_index:
    # if not 1 <= n <= 32: return -1
    blt   $a0, 1, square_invalid
    bgt   $a0, 32, square_invalid
    # if turn == DO: n = 33 - n      (ban co cua Do xoay 180 do)
    move  $t0, $a0
    bgtz  $s4, square_perspective_ready
    li    $t0, 33
    subu  $t0, $t0, $a0
square_perspective_ready:
    # row = (n - 1) // 4 ; col = (n - 1) % 4 * 2
    addiu $t0, $t0, -1
    srl   $t1, $t0, 2
    andi  $t2, $t0, 3
    sll   $t2, $t2, 1
    # if row % 2 == 0: col += 1
    andi  $t3, $t1, 1
    bne   $t3, $zero, square_column_ready
    addiu $t2, $t2, 1
square_column_ready:
    # return row * 8 + col
    sll   $v0, $t1, 3
    addu  $v0, $v0, $t2
    jr    $ra
square_invalid:
    li    $v0, -1
    jr    $ra

# ===========================================================================
# def validate_move(src: int, dst: int, piece: int) -> int:
#     """Kiem tra quan piece di tu o src den o dst (chi so 0-63).
#     Tra ve 0 neu khong hop le, 1 neu la nuoc di thuong, 2 neu la nuoc an.
#     Trong chuoi an (chaining) chi chap nhan nuoc an."""
# ===========================================================================
validate_move:
    # if board[dst] != 0: return 0
    addu  $t0, $s0, $a1
    lb    $t0, 0($t0)
    bne   $t0, $zero, validate_invalid
    # dr = dst // 8 - src // 8
    srl   $t0, $a0, 3
    srl   $t1, $a1, 3
    subu  $t2, $t1, $t0
    # if piece la vua (2 / -2): bo qua kiem tra huong
    li    $t3, 2
    beq   $a2, $t3, validate_distance
    li    $t3, -2
    beq   $a2, $t3, validate_distance
    # if piece == -1 and dr <= 0: return 0     (tot Do chi di xuong)
    bgtz  $a2, validate_black_direction
    blez  $t2, validate_invalid
    j     validate_distance
validate_black_direction:
    # if piece == 1 and dr >= 0: return 0      (tot Den chi di len)
    bgez  $t2, validate_invalid
validate_distance:
    # if abs(dr) != abs(dc): return 0          (phai di cheo)
    abs   $t4, $t2
    andi  $t0, $a0, 7
    andi  $t1, $a1, 7
    subu  $t5, $t1, $t0
    abs   $t5, $t5
    bne   $t4, $t5, validate_invalid
    # if abs(dr) == 1: nuoc di thuong
    li    $t3, 1
    beq   $t4, $t3, validate_step
    # if abs(dr) != 2: return 0
    li    $t3, 2
    bne   $t4, $t3, validate_invalid
    # mid = board[(src + dst) // 2]
    addu  $t0, $a0, $a1
    srl   $t0, $t0, 1
    addu  $t0, $s0, $t0
    lb    $t0, 0($t0)
    # if mid == 0 or cung phe voi piece: return 0
    beq   $t0, $zero, validate_invalid
    slt   $t1, $zero, $t0
    slt   $t3, $zero, $a2
    beq   $t1, $t3, validate_invalid
    # return 2
    li    $v0, 2
    jr    $ra
validate_step:
    # if chaining: return 0 ; return 1
    bne   $s7, $zero, validate_invalid
    li    $v0, 1
    jr    $ra
validate_invalid:
    move  $v0, $zero
    jr    $ra

# ===========================================================================
# def record_move():
#     """Ghi buoc src -> dst vao last_path. Buoc dau cua luot bat dau duong di
#     moi; moi buoc an tiep chi noi them o dich."""
# ===========================================================================
record_move:
    # if not chaining:
    la    $t0, last_path
    bne   $s7, $zero, record_append
    #   last_path[0] = src ; last_path_len = 1
    sb    $s1, 0($t0)
    li    $t1, 1
    sw    $t1, last_path_len
    #   last_player = turn ; last_capture = is_capture
    sw    $s4, last_player
    sw    $s6, last_capture
record_append:
    # last_path[last_path_len] = dst ; last_path_len += 1
    lw    $t1, last_path_len
    addu  $t2, $t0, $t1
    sb    $s2, 0($t2)
    addiu $t1, $t1, 1
    sw    $t1, last_path_len
    jr    $ra

# ===========================================================================
# def print_game_status():
#     """In so quan moi ben va nuoc vua di, vi du
#          So quan: Den 12, Do 11
#          Nuoc vua di cua Den: 16x23
#     So o in theo goc nhin ben dang di, giong so o tren ban co vua in."""
# ===========================================================================
print_game_status:
    # luu $ra, $s1, $s2 len stack
    addiu $sp, $sp, -12
    sw    $ra, 8($sp)
    sw    $s1, 4($sp)
    sw    $s2, 0($sp)
    # black = red = 0 ; for i in range(64):
    move  $s1, $zero
    move  $s2, $zero
    move  $t0, $zero
status_count_loop:
    #   if board[i] > 0: black += 1 ; elif board[i] < 0: red += 1
    addu  $t1, $s0, $t0
    lb    $t1, 0($t1)
    beq   $t1, $zero, status_count_next
    bltz  $t1, status_count_is_red
    addiu $s1, $s1, 1
    j     status_count_next
status_count_is_red:
    addiu $s2, $s2, 1
status_count_next:
    addiu $t0, $t0, 1
    slti  $t1, $t0, 64
    bne   $t1, $zero, status_count_loop
    # print("So quan: Den", black, ", Do", red)
    la    $a0, status_count_black
    move  $a1, $s1
    la    $a2, status_count_red
    jal   print_with_number
    move  $a0, $s2
    li    $v0, 1
    syscall
    la    $a0, newline
    li    $v0, 4
    syscall

    # if last_path_len == 0: return            (chua co nuoc nao)
    lw    $t0, last_path_len
    beq   $t0, $zero, status_done
    # print("Nuoc vua di cua Den: " if last_player == DEN else "... Do: ", end="")
    lw    $t0, last_player
    la    $a0, status_last_red
    bltz  $t0, status_print_player
    la    $a0, status_last_black
status_print_player:
    li    $v0, 4
    syscall
    # for j in range(last_path_len):
    move  $s1, $zero
status_path_loop:
    #   if j > 0: print('x' if last_capture else '-', end="")
    beq   $s1, $zero, status_print_square
    li    $a0, 45                 # '-'
    lw    $t0, last_capture
    beq   $t0, $zero, status_print_separator
    li    $a0, 120                # 'x'
status_print_separator:
    li    $v0, 11
    syscall
status_print_square:
    #   print(index_to_square(last_path[j]), end="")
    la    $t0, last_path
    addu  $t0, $t0, $s1
    lbu   $a0, 0($t0)
    jal   index_to_square
    move  $a0, $v0
    li    $v0, 1
    syscall
    addiu $s1, $s1, 1
    lw    $t0, last_path_len
    bne   $s1, $t0, status_path_loop
    # print()
    la    $a0, newline
    li    $v0, 4
    syscall
status_done:
    # khoi phuc $ra, $s1, $s2 ; return
    lw    $s2, 0($sp)
    lw    $s1, 4($sp)
    lw    $ra, 8($sp)
    addiu $sp, $sp, 12
    jr    $ra

# ===========================================================================
# def print_with_number(prefix: str, number: int, suffix: str):
#     """print(prefix, number, suffix, sep="", end="") - dung ghep thong bao
#     loi co kem con so nguoi choi vua nhap."""
# ===========================================================================
print_with_number:
    # print(prefix, end="")
    li    $v0, 4
    syscall
    # print(number, end="")
    move  $a0, $a1
    li    $v0, 1
    syscall
    # print(suffix, end="")
    move  $a0, $a2
    li    $v0, 4
    syscall
    jr    $ra

# ===========================================================================
# def index_to_square(i: int) -> int:
#     """Doi chi so 0-63 sang so o 1-32 theo goc nhin ben dang di (nguoc voi
#     square_to_index). Chi dung $t0, $t1 va $v0."""
# ===========================================================================
index_to_square:
    # n = (i // 8) * 4 + (i % 8) // 2 + 1
    srl   $t0, $a0, 3
    sll   $t0, $t0, 2
    andi  $t1, $a0, 7
    srl   $t1, $t1, 1
    addu  $v0, $t0, $t1
    addiu $v0, $v0, 1
    # if turn == DO: n = 33 - n
    bgtz  $s4, index_to_square_done
    li    $t0, 33
    subu  $v0, $t0, $v0
index_to_square_done:
    # return n
    jr    $ra

# ===========================================================================
# def build_move_list(src: int, piece: int) -> int:
#     """Tim moi nuoc hop le cua quan piece o o src, ghi o dich vao move_list.
#     Thu lan luot o dich 1-32 theo goc nhin ben dang di nen danh sach tu sap
#     xep theo so o tang dan. Tra ve so nuoc tim duoc."""
# ===========================================================================
build_move_list:
    # luu $ra, $s1, $s2, $s3, $s5 len stack
    addiu $sp, $sp, -20
    sw    $ra, 16($sp)
    sw    $s1, 12($sp)
    sw    $s2, 8($sp)
    sw    $s3, 4($sp)
    sw    $s5, 0($sp)
    # count = 0 ; for n in range(1, 33):
    move  $s1, $a0
    move  $s2, $a1
    li    $s3, 1
    move  $s5, $zero
build_move_loop:
    #   dst = square_to_index(n)
    move  $a0, $s3
    jal   square_to_index
    #   if validate_move(src, dst, piece) != 0:
    move  $a0, $s1
    move  $a1, $v0
    move  $a2, $s2
    jal   validate_move
    beq   $v0, $zero, build_move_next
    #     move_list[count] = dst ; count += 1
    la    $t0, move_list
    addu  $t0, $t0, $s5
    sb    $a1, 0($t0)
    addiu $s5, $s5, 1
build_move_next:
    addiu $s3, $s3, 1
    slti  $t0, $s3, 33
    bne   $t0, $zero, build_move_loop
    # khoi phuc thanh ghi ; return count
    move  $v0, $s5
    lw    $s5, 0($sp)
    lw    $s3, 4($sp)
    lw    $s2, 8($sp)
    lw    $s1, 12($sp)
    lw    $ra, 16($sp)
    addiu $sp, $sp, 20
    jr    $ra

# ===========================================================================
# def print_move_list(src: int, count: int):
#     """In danh sach nuoc di da danh so, vi du
#          Cac nuoc di cua quan o 21:
#            1) 21-17
#     Dung '-' cho nuoc di thuong va 'x' cho nuoc an (ky hieu co dam chuan)."""
# ===========================================================================
print_move_list:
    # luu $ra, $s1, $s2, $s3 len stack
    addiu $sp, $sp, -16
    sw    $ra, 12($sp)
    sw    $s1, 8($sp)
    sw    $s2, 4($sp)
    sw    $s3, 0($sp)
    move  $s1, $a0
    move  $s2, $a1
    move  $s3, $zero
    # print("Cac nuoc di cua quan o", index_to_square(src), ":")
    la    $a0, moves_header
    li    $v0, 4
    syscall
    move  $a0, $s1
    jal   index_to_square
    move  $a0, $v0
    li    $v0, 1
    syscall
    la    $a0, moves_header_end
    li    $v0, 4
    syscall
    # for k in range(count):
print_move_loop:
    #   print(f"  {k + 1}) ", end="")
    la    $a0, move_item_indent
    li    $v0, 4
    syscall
    addiu $a0, $s3, 1
    li    $v0, 1
    syscall
    la    $a0, move_item_separator
    li    $v0, 4
    syscall
    #   print(index_to_square(src), end="")
    move  $a0, $s1
    jal   index_to_square
    move  $a0, $v0
    li    $v0, 1
    syscall
    #   dst = move_list[k]
    #   print('x' if abs(dst // 8 - src // 8) == 2 else '-', end="")
    la    $t0, move_list
    addu  $t0, $t0, $s3
    lbu   $t1, 0($t0)
    srl   $t2, $s1, 3
    srl   $t3, $t1, 3
    subu  $t2, $t3, $t2
    abs   $t2, $t2
    li    $a0, 45                 # '-'
    li    $t3, 2
    bne   $t2, $t3, print_move_separator
    li    $a0, 120                # 'x'
print_move_separator:
    li    $v0, 11
    syscall
    #   print(index_to_square(dst))
    la    $t0, move_list
    addu  $t0, $t0, $s3
    lbu   $a0, 0($t0)
    jal   index_to_square
    move  $a0, $v0
    li    $v0, 1
    syscall
    la    $a0, newline
    li    $v0, 4
    syscall
    addiu $s3, $s3, 1
    bne   $s3, $s2, print_move_loop
    # khoi phuc thanh ghi ; return
    lw    $s3, 0($sp)
    lw    $s2, 4($sp)
    lw    $s1, 8($sp)
    lw    $ra, 12($sp)
    addiu $sp, $sp, 16
    jr    $ra

# ===========================================================================
# def has_any_move() -> bool:
#     """Ben dang den luot con it nhat mot nuoc di thuong hoac nuoc an khong?
#     Tra ve False neu het quan hoac moi quan deu bi chan."""
# ===========================================================================
has_any_move:
    # luu $ra, $s1 len stack
    addiu $sp, $sp, -8
    sw    $ra, 4($sp)
    sw    $s1, 0($sp)
    # for i in range(64):
    move  $s1, $zero
any_move_loop:
    #   piece = board[i]
    addu  $t0, $s0, $s1
    lb    $a1, 0($t0)
    #   if piece == 0 or khac phe voi turn: continue
    beq   $a1, $zero, any_move_next
    slt   $t1, $zero, $a1
    slt   $t2, $zero, $s4
    bne   $t1, $t2, any_move_next
    #   if build_move_list(i, piece) > 0: return True
    move  $a0, $s1
    jal   build_move_list
    beq   $v0, $zero, any_move_next
    li    $v0, 1
    j     any_move_return
any_move_next:
    addiu $s1, $s1, 1
    slti  $t0, $s1, 64
    bne   $t0, $zero, any_move_loop
    # return False
    move  $v0, $zero
any_move_return:
    # khoi phuc $ra, $s1 ; return
    lw    $s1, 0($sp)
    lw    $ra, 4($sp)
    addiu $sp, $sp, 8
    jr    $ra
