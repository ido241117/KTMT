.data
board:   .space 64
newline: .asciiz "\n"
prompt_black: .asciiz "Den luot Den. Nhap o xuat phat (1-32, 0 de thoat): "
prompt_red: .asciiz "Den luot Do. Nhap o xuat phat (1-32, 0 de thoat): "
dest_prompt: .asciiz "Nhap o den (1-32): "
continue_prompt: .asciiz "Co the an tiep. Nhap o den tiep theo (1-32): "
invalid: .asciiz "O xuat phat khong hop le hoac khong phai quan cua ban. Hay thu lai.\n"
invalid_move: .asciiz "Nuoc di khong hop le. Hay chon o den khac.\n"
capture_message: .asciiz "Da an quan doi phuong.\n"
promotion_message: .asciiz "Quan tot duoc phong vua.\n"
black_wins: .asciiz "Den thang!\n"
red_wins: .asciiz "Do thang!\n"
quit_message: .asciiz "Ket thuc van choi.\n"

.text
.globl main
main:
    la    $s0, board
    li    $t0, 0

initialize_board:
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
    bne   $t3, $zero, initialize_board

    li    $s4, 1
    move  $s7, $zero
display_board:
    li    $t0, 0
print_row:
    addiu $a0, $t0, 1
    li    $v0, 1
    syscall
    li    $a0, 32
    li    $v0, 11
    syscall
    li    $t1, 0
print_column:
    addu  $t2, $t0, $t1
    andi  $t2, $t2, 1
    beq   $t2, $zero, print_light
    sll   $t2, $t0, 3
    addu  $t2, $t2, $t1
    addu  $t2, $s0, $t2
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
    li    $a0, 48
    j     print_square
print_light:
    li    $a0, 32
print_square:
    li    $v0, 11
    syscall
    li    $a0, 32
    li    $v0, 11
    syscall
    addiu $t1, $t1, 1
    slti  $t2, $t1, 8
    bne   $t2, $zero, print_column
    la    $a0, newline
    li    $v0, 4
    syscall
    addiu $t0, $t0, 1
    slti  $t2, $t0, 8
    bne   $t2, $zero, print_row
source_prompt:
    bgtz  $s4, source_prompt_black
    la    $a0, prompt_red
    j     source_prompt_print
source_prompt_black:
    la    $a0, prompt_black
source_prompt_print:
    li    $v0, 4
    syscall
source_input:
    li    $v0, 5
    syscall
    move  $t0, $v0
    beq   $t0, $zero, game_exit
    blt   $t0, 1, invalid_source
    bgt   $t0, 32, invalid_source
    addiu $t0, $t0, -1
    srl   $t1, $t0, 2
    andi  $t2, $t0, 3
    sll   $t2, $t2, 1
    andi  $t3, $t1, 1
    bne   $t3, $zero, source_column_ready
    addiu $t2, $t2, 1
source_column_ready:
    sll   $s1, $t1, 3
    addu  $s1, $s1, $t2
    addu  $t4, $s0, $s1
    lb    $t3, 0($t4)
    beq   $t3, $zero, invalid_source
    slt   $t5, $zero, $t3
    slt   $t6, $zero, $s4
    bne   $t5, $t6, invalid_source
    move  $s3, $t3
destination_prompt:
    bne   $s7, $zero, continue_destination_prompt
    la    $a0, dest_prompt
    j     print_destination_prompt
continue_destination_prompt:
    la    $a0, continue_prompt
print_destination_prompt:
    li    $v0, 4
    syscall
destination_input:
    li    $v0, 5
    syscall
    move  $t0, $v0
    blt   $t0, 1, invalid_destination
    bgt   $t0, 32, invalid_destination
    addiu $t0, $t0, -1
    srl   $t1, $t0, 2
    andi  $t2, $t0, 3
    sll   $t2, $t2, 1
    andi  $t3, $t1, 1
    bne   $t3, $zero, destination_column_ready
    addiu $t2, $t2, 1
destination_column_ready:
    sll   $s2, $t1, 3
    addu  $s2, $s2, $t2
    addu  $t4, $s0, $s2
    lb    $t5, 0($t4)
    bne   $t5, $zero, invalid_destination

    move  $s6, $zero
    srl   $t0, $s1, 3
    srl   $t1, $s2, 3
    subu  $t2, $t1, $t0
    li    $t3, 2
    beq   $s3, $t3, measure_row_distance
    li    $t3, -2
    beq   $s3, $t3, measure_row_distance
    bgtz  $s4, validate_black_direction
    blez  $t2, invalid_destination
    j     measure_row_distance
validate_black_direction:
    bgez  $t2, invalid_destination
measure_row_distance:
    bltz  $t2, absolute_row_distance
    j     row_distance_ready
absolute_row_distance:
    subu  $t2, $zero, $t2
row_distance_ready:
    move  $t6, $t2
    li    $t3, 1
    beq   $t2, $t3, validate_normal_distance
    li    $t3, 2
    bne   $t2, $t3, invalid_destination
    li    $s6, 1
    j     validate_column
validate_normal_distance:
    bne   $s7, $zero, invalid_destination
validate_column:
    andi  $t0, $s1, 7
    andi  $t1, $s2, 7
    subu  $t2, $t1, $t0
    bltz  $t2, absolute_column_distance
    j     column_distance_ready
absolute_column_distance:
    subu  $t2, $zero, $t2
column_distance_ready:
    bne   $t2, $t6, invalid_destination
    beq   $s6, $zero, apply_move
    addu  $t0, $s1, $s2
    srl   $t0, $t0, 1
    addu  $t1, $s0, $t0
    lb    $t2, 0($t1)
    beq   $t2, $zero, invalid_destination
    slt   $t3, $zero, $t2
    slt   $t4, $zero, $s4
    beq   $t3, $t4, invalid_destination
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
    beq   $s6, $zero, finish_move
    move  $a0, $s2
    move  $a1, $s3
    jal   has_capture
    beq   $v0, $zero, finish_turn
    li    $s7, 1
    move  $s1, $s2
    j     destination_prompt
finish_move:
finish_turn:
    move  $s7, $zero
    li    $t0, 0
    li    $t1, 0
count_opponent_pieces:
    addu  $t2, $s0, $t1
    lb    $t3, 0($t2)
    beq   $t3, $zero, count_next_square
    slt   $t4, $zero, $t3
    slt   $t5, $zero, $s4
    beq   $t4, $t5, count_next_square
    addiu $t0, $t0, 1
count_next_square:
    addiu $t1, $t1, 1
    slti  $t2, $t1, 64
    bne   $t2, $zero, count_opponent_pieces
    bne   $t0, $zero, switch_turn
    bgtz  $s4, black_wins_game
    la    $a0, red_wins
    j     print_winner
black_wins_game:
    la    $a0, black_wins
print_winner:
    li    $v0, 4
    syscall
    li    $v0, 10
    syscall
switch_turn:
    subu  $s4, $zero, $s4
    j     display_board

invalid_destination:
    la    $a0, invalid_move
    li    $v0, 4
    syscall
    j     destination_prompt

game_exit:
    la    $a0, quit_message
    li    $v0, 4
    syscall
    li    $v0, 10
    syscall

invalid_source:
    la    $a0, invalid
    li    $v0, 4
    syscall
    j     source_prompt

has_capture:
    srl   $t0, $a0, 3
    andi  $t1, $a0, 7
    move  $t8, $zero
    bgtz  $s4, capture_black_direction
    li    $t2, 1
    j     capture_direction_ready
capture_black_direction:
    li    $t2, -1
capture_direction_ready:
    li    $t3, -1
capture_dx_loop:
    sll   $t4, $t2, 1
    addu  $t5, $t0, $t4
    bltz  $t5, capture_next_dx
    slti  $t6, $t5, 8
    beq   $t6, $zero, capture_next_dx
    sll   $t4, $t3, 1
    addu  $t6, $t1, $t4
    bltz  $t6, capture_next_dx
    slti  $t7, $t6, 8
    beq   $t7, $zero, capture_next_dx
    sll   $t4, $t5, 3
    addu  $t4, $t4, $t6
    addu  $t4, $s0, $t4
    lb    $t4, 0($t4)
    bne   $t4, $zero, capture_next_dx
    addu  $t5, $t0, $t2
    addu  $t6, $t1, $t3
    sll   $t5, $t5, 3
    addu  $t5, $t5, $t6
    addu  $t5, $s0, $t5
    lb    $t5, 0($t5)
    beq   $t5, $zero, capture_next_dx
    slt   $t6, $zero, $t5
    slt   $t7, $zero, $s4
    bne   $t6, $t7, capture_found
capture_next_dx:
    addiu $t3, $t3, 2
    slti  $t4, $t3, 2
    bne   $t4, $zero, capture_dx_loop
    bne   $t8, $zero, capture_not_found
    li    $t4, 2
    beq   $a1, $t4, capture_reverse_direction
    li    $t4, -2
    bne   $a1, $t4, capture_not_found
capture_reverse_direction:
    li    $t8, 1
    subu  $t2, $zero, $t2
    li    $t3, -1
    j     capture_dx_loop
capture_not_found:
    move  $v0, $zero
    jr    $ra
capture_found:
    li    $v0, 1
    jr    $ra