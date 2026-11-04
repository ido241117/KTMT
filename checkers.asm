.data
board:   .space 64
newline: .asciiz "\n"

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

    li    $v0, 10
    syscall