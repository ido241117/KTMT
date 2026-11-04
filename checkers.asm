.data
board:   .space 64
newline: .asciiz "\n"
prompt_black: .asciiz "Black: choose a source square (1-32, 0 to quit): "
prompt_red: .asciiz "Red: choose a source square (1-32, 0 to quit): "
dest_prompt: .asciiz "Choose a destination square (1-32): "
invalid: .asciiz "Invalid source square or not your piece. Try again.\n"
invalid_move: .asciiz "Invalid move. Try another destination.\n"
quit_message: .asciiz "Game ended.\n"

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
    bltz  $t3, print_red
    li    $a0, 98
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
    la    $a0, dest_prompt
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

    srl   $t0, $s1, 3
    srl   $t1, $s2, 3
    subu  $t2, $t1, $t0
    bgtz  $s4, validate_black_direction
    li    $t3, 1
    bne   $t2, $t3, invalid_destination
    j     validate_column
validate_black_direction:
    li    $t3, -1
    bne   $t2, $t3, invalid_destination
validate_column:
    andi  $t0, $s1, 7
    andi  $t1, $s2, 7
    subu  $t2, $t1, $t0
    beq   $t2, $zero, invalid_destination
    li    $t3, 1
    beq   $t2, $t3, apply_move
    li    $t3, -1
    bne   $t2, $t3, invalid_destination
apply_move:
    addu  $t0, $s0, $s1
    sb    $zero, 0($t0)
    addu  $t0, $s0, $s2
    sb    $s3, 0($t0)
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