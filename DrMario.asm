################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Dr Mario.
#
# Jinbo Chang 1004821419
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       2
# - Unit height in pixels:      2
# - Display width in pixels:    64
# - Display height in pixels:   64
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. 
ADDR_DSPL: .word 0x10008000
# The address of the keyboard. 
ADDR_KBRD: .word 0xffff0000
pill_count:         .word 0
gravity_delay: .word 60
min_gravity_delay:  .word 20

colors: .word 0xff0000, 0x0000ff, 0xffff00

pill_x:         .word 16        # X coordinate
pill_y:         .word 4         # Y coordinate
pill_orientation: .word 0       # 0=horizontal, 1=vertical
pill_color1:    .word 0xff0000  # first block colour red
pill_color2:    .word 0x0000ff  # second block colour blu

next_pill_orientation: .word 0         # 0: horizontal, 1: vertical
next_pill_color1:      .word 0xff0000    # red
next_pill_color2:      .word 0x0000ff    # blue
next_capsules:  .space 60
prev_pill_x: .word 16
prev_pill_y: .word 4
prev_pill_orientation: .word 0

theme_notes:      .word 69, 71, 73, 71    # 4 notes
theme_durations:  .word 200,200,400,200     # how long takes
theme_length:     .word 4                 # notes number in theme
music_index:      .word 0                 # index
music_timer:      .word 200               # time left

BLACK: .word 0x000000    # 검은색 정의
LIGHT_GRAY: .word 0xCCCCCC  # 밝은 회색 정의

##############################################################################
# Mutable Data
##############################################################################

##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    # Initialize the game
    la $s0, ADDR_DSPL # Store display address into $s0
    jal generate_random_colors 
    jal generate_random_next
    jal draw_pill
    jal draw_bottle           

game_loop:
    # 키 입력 플래그 확인 (키보드 주소의 첫 번째 워드)
    lw   $t0, ADDR_KBRD         # $t0에 키보드 컨트롤러 주소 로드
    lw   $t1, 0($t0)            # $t1에 입력 플래그 로드 (키 눌렸으면 1, 아니면 0)
    beq  $t1, 1, keyboard_input # 만약 $t1 == 1이면, 키가 눌린 것이므로 입력 처리로 분기
    j    update_position        # 그렇지 않으면(즉, 0이면) 그냥 위치 업데이트(중력 등) 진행

keyboard_input:
    # 두 번째 워드에서 실제 ASCII 코드를 읽는다.
    lw   $t2, 4($t0)            # $t2에 ASCII 코드 저장
    # 여기서 $t2의 값에 따라 적절한 키 처리 함수를 호출한다.
    beq  $t2, 0x70, handle_pause  # p키이면 handle_pause로 분기
    beq  $t2, 0x71, game_end     # 'q' (0x71)면 game_end로 점프하여 종료
    beq  $t2, 0x61, move_left   # 'a' (0x61)면 왼쪽 이동
    beq  $t2, 0x64, move_right  # 'd' (0x64)면 오른쪽 이동
    beq  $t2, 0x77, rotate      # 'w' (0x77)면 회전
    beq  $t2, 0x73, move_down   # 's' (0x73)면 아래로 이동
    j    update_position        # 처리 후, update_position으로 돌아감
    

update_position:
    # Clear screen, redraw, and so forth
    jal clear_screen
    jal draw_outline
    jal draw_pill       # 드롭 시 최종 위치의 outline을 그려줌
    jal draw_bottle
    jal draw_next_capsule
    # delay ~16ms
    li $v0, 32
    li $a0, 16
    syscall
    # --- 배경음악 타이머 업데이트 ---
    lw   $t0, music_timer    # 현재 music_timer (밀리초)
    addi $t0, $t0, -16       # 16ms만큼 감소 (한 프레임당 16ms)
    blez $t0, play_next_note # 타이머가 0 이하이면 다음 노트를 재생
    sw   $t0, music_timer    # 그렇지 않으면 업데이트된 타이머 저장
    
    # Gravity: 매 60 프레임(약 1초)마다 캡슐을 아래로 이동
    addi $s2, $s2, 1         # s2: 프레임 카운터
    lw   $t1, gravity_delay     # gravity_delay 값을 로드
    bne  $s2, $t1, continue_loop
    li   $s2, 0
    jal  move_down         # 캡슐을 아래로 이동

continue_loop:
    j game_loop


# Function: Draw a bottle
# Draws a bottle on the screen by calling line-drawing functions for each part.
draw_bottle:

    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Draw the bottom of the bottle
    addi $a0, $zero, 6    # X starting position
    addi $a1, $zero, 30    # Y position
    addi $a2, $zero, 21    # Length (horizontal)
    jal draw_line          # Call draw_line to draw bottom

    # Draw the left wall of the bottle
    addi $a0, $zero, 6    # X position
    addi $a1, $zero, 10    # Y starting position
    addi $a2, $zero, 20    # Length (vertical)
    jal draw_vertical_line # Call draw_vertical_line

    # Draw the right wall of the bottle
    addi $a0, $zero, 26    # X position
    addi $a1, $zero, 10    # Y starting position
    addi $a2, $zero, 20    # Length (vertical)
    jal draw_vertical_line # Call draw_vertical_line

    # Draw the left neck connector
    addi $a0, $zero, 6     # X starting position
    addi $a1, $zero, 10    # Y position
    addi $a2, $zero, 6     # Length (horizontal) 
    jal draw_line          # Call draw_line to draw left neck connector

    # Draw the right neck connector
    addi $a0, $zero, 21    # X starting position
    addi $a1, $zero, 10    # Y position
    addi $a2, $zero, 6     # Length (horizontal) 
    jal draw_line          # Call draw_line to draw right neck connector

    # Draw the left neck wall
    addi $a0, $zero, 11    # X position
    addi $a1, $zero, 4     # Y starting position
    addi $a2, $zero, 6     # Length (vertical)
    jal draw_vertical_line # Call draw_vertical_line

    # Draw the right neck wall
    addi $a0, $zero, 21    # X position
    addi $a1, $zero, 4     # Y starting position
    addi $a2, $zero, 6     # Length (vertical)
    jal draw_vertical_line # Call draw_vertical_line
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra                 # Return to caller

# Function: Draw a horizontal line
# Arguments: 
# $a0 = X starting position, $a1 = Y position, $a2 = Length
draw_line:
    li $t1, 0xffffff       # Set the color (white)
    lw $t0, ADDR_DSPL      # Load display base address into $t0

line_loop:
    sll $t2, $a1, 7        # Y Offset = Y * 128
    add $t3, $t0, $t2      # Base address + Y Offset
    sll $t4, $a0, 2        # X Offset = X * 4
    add $t3, $t3, $t4      # Base + Y Offset + X Offset
    sw $t1, 0($t3)         # Draw pixel at calculated address
    addi $a0, $a0, 1       # Move to the next X position
    subi $a2, $a2, 1       # Decrease remaining length
    bgtz $a2, line_loop    # Continue until length is 0
    jr $ra                 # Return to caller

# Function: Draw a vertical line
# Arguments: 
# $a0 = X position, $a1 = Y starting position, $a2 = Length
draw_vertical_line:
    li $t1, 0xffffff       # Set the color (white)
    lw $t0, ADDR_DSPL      # Load display base address into $t0

vertical_loop:
    sll $t2, $a1, 7        # Y Offset = Y * 128
    add $t3, $t0, $t2      # Base address + Y Offset
    sll $t4, $a0, 2        # X Offset = X * 4
    add $t3, $t3, $t4      # Base + Y Offset + X Offset
    sw $t1, 0($t3)         # Draw pixel at calculated address
    addi $a1, $a1, 1       # Move to the next Y position
    subi $a2, $a2, 1       # Decrease remaining length
    bgtz $a2, vertical_loop # Continue until length is 0
    jr $ra                 # Return to caller
    
    
# Function: draw_pill
# 캡슐의 현재 위치와 방향에 따라 두 블록을 그림
draw_pill:
    # $ra 백업
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    # 디스플레이 기본 주소 로드
    lw   $t0, ADDR_DSPL

    # 현재 캡슐 좌표와 상태 읽기
    lw   $t1, pill_x            # pill_x (현재 X)
    lw   $t2, pill_y            # pill_y (현재 Y)
    lw   $t3, pill_orientation  # pill_orientation (0=가로, 1=세로)
    lw   $t4, pill_color1       # 첫 번째 블록 색상
    lw   $t5, pill_color2       # 두 번째 블록 색상

    # --- 여기서는 이전 위치 클리어 코드를 완전히 제거합니다 ---
    # update_position에서 clear_screen이 호출되므로 이전 그림은 모두 지워집니다.

    # (원래의 pill_x, pill_y 값을 보존)
    move $t7, $t1       # $t7 = 원본 pill_x
    move $t8, $t2       # $t8 = 원본 pill_y

    # 첫 번째 블록 그리기 (좌표: (pill_x, pill_y))
    sll  $t6, $t2, 5    # Y offset = pill_y * 32
    add  $t6, $t6, $t1  # offset += pill_x
    sll  $t6, $t6, 2    # *4 (바이트 오프셋)
    add  $t6, $t0, $t6  # 최종 주소 = 디스플레이 기본 주소 + offset
    sw   $t4, 0($t6)    # 첫 번째 블록 그리기

    # 두 번째 블록 좌표 계산 (원본 좌표에서만 계산, 수정하지 않음)
    move $t9, $t7       # $t9 = pill_x 복사
    move $s1, $t8       # $s1 = pill_y 복사
    beq  $t3, $zero, draw_horizontal_current
    addi $s1, $s1, 1  # 세로 모드이면 두 번째 블록은 (pill_x, pill_y+1)
    j    draw_second_current
draw_horizontal_current:
    addi $t9, $t9, 1  # 가로 모드이면 두 번째 블록은 (pill_x+1, pill_y)
draw_second_current:
    sll  $t6, $s1, 5
    add  $t6, $t6, $t9
    sll  $t6, $t6, 2
    add  $t6, $t0, $t6
    sw   $t5, 0($t6)    # 두 번째 블록 그리기

    # 이전 좌표(prev_pill_*) 업데이트는 원본 좌표로 (즉, 수정하지 않은 값)
    sw   $t7, prev_pill_x
    sw   $t8, prev_pill_y
    sw   $t3, prev_pill_orientation

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

    
    # Function: generate_random_colors
# pill_color1과 pill_color2에 랜덤 색상 할당
generate_random_colors:
    # orientation은 항상 0 (가로)
    li   $t0, 0
    sw   $t0, pill_orientation

    # 랜덤 색상 1 생성 (0 ~ 2)
    li   $v0, 42
    li   $a0, 0
    li   $a1, 3
    syscall
    la   $t0, colors    # 색상 배열 시작 주소
    sll  $a0, $a0, 2    # 인덱스 * 4 (워드 단위)
    add  $t0, $t0, $a0
    lw   $t1, 0($t0)
    sw   $t1, pill_color1

    # 랜덤 색상 2 생성 (0 ~ 2)
    li   $v0, 42
    li   $a0, 0
    li   $a1, 3
    syscall
    la   $t0, colors
    sll  $a0, $a0, 2
    add  $t0, $t0, $a0
    lw   $t1, 0($t0)
    sw   $t1, pill_color2

    jr   $ra
    
# Function: clear_screen
# 검정색으로 전체 화면 덮기
clear_screen:
    lw $t0, ADDR_DSPL       # 디스플레이 주소
    li $t1, 0x000000        # 검정색
    li $t2, 0               # 카운터
    li $t3, 4096            # 64x64 = 4096 픽셀

clear_loop:
    sw $t1, 0($t0)          # 픽셀을 검정색으로
    addi $t0, $t0, 4        # 다음 픽셀 주소
    addi $t2, $t2, 1        # 카운터 증가
    blt $t2, $t3, clear_loop # 4096번 반복
    jr $ra
    
move_left:
    lw $t0, pill_x          # 현재 X 좌표 로드
    lw $t1, pill_y
    
    li $t2, 11
    blt $t1, $t2, neck_left # pill_y < 10
    
    li   $t3, 7              # 최소 pill_x 값 (내부 최소)
    beq  $t0, $t3, left_blocked   # 만약 pill_x가 7이면 더 왼쪽으로 못 감
    
    subi $t0, $t0, 1        # X 좌표 1 감소
    sw $t0, pill_x          # 새 X 좌표 저장
    j update_position
    
neck_left:
    # -- 목 영역 --
    li   $t3, 12             # 목 영역 내부 최소 pill_x 값
    ble  $t0, $t3, left_blocked  # 만약 pill_x가 12 이하라면 이동 불가
    subi $t0, $t0, 1
    sw   $t0, pill_x
    j    update_position
    
left_blocked:
    j    update_position     # 이동 불가하면 그대로 update_position으로

move_right:
    lw $t0, pill_x
    lw   $t1, pill_orientation  # 현재 orientation (0: 가로, 1: 세로)
    lw   $t2, pill_y         # 현재 pill_y 읽기
    li   $t3, 11             # 기준 Y = 10 (목 영역 구분)
    blt  $t2, $t3, neck_right   # pill_y < 10이면 목 영역로 분기

    # -- 메인 병 영역 --
    # orientation에 따라 최대 pill_x 결정
    beq  $t1, $zero, right_horizontal_check  # 가로 모드
    li   $t4, 25             # vertical: 최대 pill_x = 25
    beq  $t0, $t4, right_blocked
    j    right_done

right_horizontal_check:
    li   $t4, 24             # horizontal: 최대 pill_x = 24
    beq  $t0, $t4, right_blocked

right_done:
    addi $t0, $t0, 1         # pill_x 증가
    sw   $t0, pill_x
    j    update_position

neck_right:
    # -- 목 영역 --
    # orientation에 따라 최대 pill_x 결정
    beq  $t1, $zero, neck_right_horizontal  # horizontal 모드
    li   $t4, 20             # vertical: 최대 pill_x = 20
    beq  $t0, $t4, right_blocked
    j    neck_right_done

neck_right_horizontal:
    li   $t4, 19             # horizontal: 최대 pill_x = 19
    beq  $t0, $t4, right_blocked

neck_right_done:
    addi $t0, $t0, 1         # pill_x 증가
    sw   $t0, pill_x
    j    update_position

right_blocked:
    j    update_position

move_down:
    # 현재 좌표와 상태 로드
    lw   $t0, pill_x           # $t0 = pill_x
    lw   $t1, pill_y           # $t1 = pill_y
    lw   $t2, pill_orientation # $t2 = pill_orientation (0: horizontal, 1: vertical)
    lw   $t3, ADDR_DSPL        # $t3 = 디스플레이 기본 주소

    # --- 후보 셀 계산 ---
    # 후보1: 기본적으로 (pill_x, pill_y+1)
    addi $t4, $t1, 1           # $t4 = pill_y + 1
    sll  $t5, $t4, 5           # $t5 = (pill_y+1) * 32
    add  $t5, $t5, $t0         # $t5 = (pill_y+1)*32 + pill_x
    sll  $t5, $t5, 2           # 바이트 오프셋
    add  $t5, $t3, $t5         # $t5 = 주소 of 후보1 셀
    lw   $t6, 0($t5)           # $t6 = 후보1 셀의 색상

    # 만약 orientation이 vertical이면, 후보1은 자기 자신의 셀이므로 검사에서 무시
    lw   $t8, BLACK           # $t8 = BLACK
    bne  $t2, $zero, skip_first_candidate
    # horizontal인 경우엔 검사 실시:
    bne  $t6, $t8, pill_lock   # 만약 후보1 셀이 비어있지 않으면 잠금
skip_first_candidate:
    # 후보2: orientation에 따라 다르게 계산
    beq  $t2, $zero, horizontal_candidate   # if horizontal
    # vertical case:
    addi $t4, $t1, 2           # vertical: 후보2 행 = pill_y + 2
    move $t7, $t0              # vertical: 후보2 X = pill_x
    j candidate_done
horizontal_candidate:
    addi $t4, $t1, 1           # horizontal: 후보2 행 = pill_y + 1
    addi $t7, $t0, 1           # horizontal: 후보2 X = pill_x + 1
candidate_done:
    sll  $t5, $t4, 5           # $t5 = (후보2 행)*32
    add  $t5, $t5, $t7         # $t5 = (후보2 행)*32 + 후보2 X
    sll  $t5, $t5, 2           # 바이트 오프셋
    add  $t5, $t3, $t5         # 최종 주소 for 후보2 셀
    lw   $t7, 0($t5)           # $t7 = 후보2 셀의 색상

    # 후보2 셀 검사
    bne  $t7, $t8, pill_lock   # 만약 후보2 셀이 비어있지 않으면 잠금

    # --- 병 바닥 도달 검사 ---
    lw   $t4, pill_y          # $t4 = pill_y
    # horizontal: 아래 후보 셀은 pill_y+1, vertical: 아래 후보 셀은 pill_y+2
    beq  $t2, $zero, bottom_horiz_horz
    addi $t4, $t4, 2          # vertical: $t4 = pill_y + 2
    j    bottom_horiz
bottom_horiz_horz:
    addi $t4, $t4, 1          # horizontal: $t4 = pill_y + 1
bottom_horiz:
    li   $t5, 30              # $t5 = 병 바닥 grid 행 (30)
    beq  $t4, $t5, pill_lock   # 만약 아래 셀이 병 바닥이면 잠금

    # --- 이동 가능: 캡슐을 아래로 이동 ---
    addi $t1, $t1, 1          # pill_y = pill_y + 1
    sw   $t1, pill_y
    j    update_position

pill_lock:
    # 1. 현재 캡슐을 초기 위치 및 상태로 재설정 (orientation은 항상 0: 가로)
    li   $t0, 16             # 새로운 pill_x = 16
    li   $t1, 4              # 새로운 pill_y = 4
    li   $t2, 0              # 새로운 pill_orientation = 0 (가로)
    sw   $t0, pill_x
    sw   $t1, pill_y
    sw   $t2, pill_orientation

    # 2. 다음 캡슐 값(next_pill_color1/next_pill_color2)을 현재 pill에 복사
    lw   $t3, next_pill_color1
    lw   $t4, next_pill_color2
    sw   $t3, pill_color1
    sw   $t4, pill_color2

    # 3. 새 다음 캡슐 값 갱신 (generate_random_next는 다음 캡슐의 값을 랜덤하게 생성)
    jal  generate_random_next

    # 4. 플레이된 pill 수 증가 (pill_count++)
    lw   $t0, pill_count
    addi $t0, $t0, 1
    sw   $t0, pill_count

    # 5. 중력 딜레이(gravity_delay) 조정: 매 pill마다 2프레임씩 감소,
    #    단, 최소 값(min_gravity_delay) 이하로 내려가지 않음.
    lw   $t1, gravity_delay     # 현재 중력 딜레이
    addi $t1, $t1, -2           # 2프레임 감소
    lw   $t2, min_gravity_delay # 최소 중력 딜레이 값
    blt  $t1, $t2, set_min_delay  # 만약 새 딜레이($t1)가 최소보다 작으면
    sw   $t1, gravity_delay     # 그대로 저장하고
    j    update_position       # update_position로 복귀

set_min_delay:
    sw   $t2, gravity_delay     # 최소값으로 설정
    j    update_position

    
rotate:
    lw $t0, pill_orientation  # 현재 방향 (0=가로, 1=세로)
    xori $t0, $t0, 1          # 0 ↔ 1 토글
    sw $t0, pill_orientation  # 새 방향 저장
    j update_position
    
game_end:
    li $v0, 10         # 종료 시스템 콜 번호
    syscall            # 프로그램 종료

handle_pause:
    # 필요한 레지스터 백업 ($ra, $s0, $s1 등)
    addi $sp, $sp, -12
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)
    sw   $s1, 8($sp)

pause_loop:
    # "Paused" 메시지를 화면에 그린다.
    jal draw_pause_message
    # 150ms 정도 지연 (syscall 32)
    li   $v0, 32
    li   $a0, 150
    syscall

    # 키보드 컨트롤러에서 입력 여부를 확인
    lw   $t0, ADDR_KBRD       # 키보드 컨트롤러 주소
    lw   $t1, 0($t0)          # 입력 플래그 (키 눌림: 1, 아니면 0)
    beq  $t1, 0, pause_loop   # 입력 없으면 계속 루프
    lw   $t1, 4($t0)          # 실제 입력된 키
    beq  $t1, 0x70, pause_exit  # 만약 p키(0x70)가 입력되면 루프 종료
    j    pause_loop

pause_exit:
    # "Paused" 메시지를 삭제
    jal delete_pause_message

    # 백업한 레지스터 복원
    lw   $ra, 0($sp)
    lw   $s0, 4($sp)
    lw   $s1, 8($sp)
    addi $sp, $sp, 12
    jr   $ra
    
draw_pause_message:
    lw   $t0, ADDR_DSPL       # 디스플레이 기본 주소
    li   $t1, 0x00FFFF        # 메시지 색상 (예: 시안)
    # 예: 화면의 한 영역에 색상을 채워 "Paused" 효과를 준다.
    # 실제 텍스트 출력은 복잡하므로, 간단히 몇 개의 픽셀을 색칠하는 방식.
    # (여기서는 임의 주소 3000번 근처에 색상을 쓴다고 가정)
    addi $t2, $t0, 0       # 메시지 시작 주소
    sw   $t1, 0($t2)
    sw   $t1, 8($t2)
    sw   $t1, 128($t2)
    sw   $t1, 136($t2)
    sw   $t1, 256($t2)
    sw   $t1, 264($t2)
    sw   $t1, 384($t2)
    sw   $t1, 392($t2)
    sw   $t1, 512($t2)
    sw   $t1, 520($t2)
    
    jr   $ra

# delete_pause_message:
# draw_pause_message로 그린 "Paused" 메시지를 지웁니다.
delete_pause_message:
    lw   $t0, ADDR_DSPL
    li   $t1, 0x000000        # BLACK
    addi $t2, $t0, 3000
    sw   $t1, 0($t2)
    sw   $t1, 4($t2)
    sw   $t1, 8($t2)
    jr   $ra
    
play_next_note:
    # (1) 현재 노트 재생: 테마 배열에서 현재 노트 정보를 로드
    lw   $t1, music_index      # 현재 노트 인덱스
    la   $t2, theme_notes
    sll  $t1, $t1, 2           # 인덱스 * 4 (word 단위)
    add  $t2, $t2, $t1         # 테마 노트 배열에서 현재 노트의 주소
    lw   $a0, 0($t2)           # $a0에 현재 노트의 피치

    la   $t3, theme_durations
    add  $t3, $t3, $t1         # 테마 노트 배열과 같은 인덱스로 접근
    lw   $a1, 0($t3)           # $a1에 현재 노트의 지속시간 (밀리초)

    # (2) 음색과 볼륨 설정 (예시)
    li   $a2, 56               # 인스트루먼트 (예: 56번)
    li   $a3, 150              # 볼륨 (예: 150)

    # (3) MIDI 사운드 시스템 콜을 호출하여 노트 재생
    li   $v0, 31               # MIDI 사운드 재생 시스템 콜
    syscall                    # 현재 노트를 재생
    # ※ 여기서 PLAY_SOUND 매크로와 달리 sleep을 호출하지 않습니다.
    #     (게임 루프의 딜레이로 이미 16ms가 적용되므로, 별도의 sleep 없이 진행)

    # (4) music_timer를 현재 노트의 지속시간으로 재설정
    sw   $a1, music_timer

    # (5) music_index를 증가시키고 테마 길이만큼 wrap-around 처리
    lw   $t4, music_index
    addi $t4, $t4, 1           # 다음 노트 인덱스
    la   $t5, theme_length
    lw   $t5, 0($t5)           # 테마 노트 개수
    # 만약 t4 >= t5이면 t4=0 (wrap-around)
    blt  $t4, $t5, no_wrap
    li   $t4, 0
no_wrap:
    sw   $t4, music_index

    j game_loop
    
##############################################################################
# Function: draw_outline
# 목적: 현재 캡슐이 떨어졌을 때 최종 착지 위치의 바로 위 행에 outline(ghost)를 그린다.
#       단, outline은 병의 바닥(grid row = 30)보다 위여야 한다.
##############################################################################
draw_outline:
    # 백업: $ra와 $s0 (필요한 경우 $s1도)
    addi $sp, $sp, -8
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)
    # (필요하다면 $s1도 백업할 수 있음; 여기서는 바로 사용)

    # 디스플레이 기본 주소
    lw   $t0, ADDR_DSPL

    # 현재 캡슐 grid 좌표와 orientation 읽기
    lw   $t1, pill_x            # $t1 = pill_x
    lw   $t2, pill_y            # $t2 = pill_y
    lw   $t3, pill_orientation  # $t3 = pill_orientation (0: horizontal, 1: vertical)

    # 병 바닥 grid 행 = 30 (outline은 이보다 위여야 함)
    li   $t7, 30                # $t7 = 30

    # drop_y: 캡슐이 현재 위치(pill_y)부터 아래로 떨어뜨려볼 변수
    move $t4, $t2               # $t4 = drop_y 초기값 = pill_y

outline_loop:
    # 만약 drop_y가 병 바닥(30)와 같다면 반복 종료
    beq  $t4, $t7, drop_done

    # 후보 행 = drop_y + 1 (첫 번째 블록 후보 위치의 행)
    addi $t5, $t4, 1            # $t5 = drop_y + 1

    # --- 첫 번째 블록 후보 검사 ---
    # 첫 번째 블록은 (pill_x, drop_y+1)
    sll  $s0, $t5, 5            # $s0 = (drop_y+1) * 32
    add  $s0, $s0, $t1          # $s0 = (drop_y+1)*32 + pill_x
    sll  $s0, $s0, 2            # *4 (바이트 오프셋)
    add  $s0, $t0, $s0          # 최종 주소 for 첫 번째 후보
    lw   $t8, 0($s0)            # $t8 = 색상 at 첫 번째 후보 cell

    # --- 두 번째 블록 후보 검사 ---
    # 두 번째 블록의 후보 행은 orientation에 따라:
    #   horizontal (t3 == 0): (pill_x+1, drop_y+1)
    #   vertical   (t3 == 1): (pill_x, drop_y+2)
    beq  $t3, $zero, second_horizontal  # if horizontal, branch
    addi $t5, $t4, 2            # vertical: candidate row = drop_y + 2
    j    second_calc_done
second_horizontal:
    addi $t5, $t4, 1            # horizontal: candidate row = drop_y + 1
second_calc_done:
    # 두 번째 블록 후보 X 좌표 = pill_x + (1 - pill_orientation)
    li   $t6, 1                # $t6 = 1
    sub  $t6, $t6, $t3          # $t6 = 1 - pill_orientation
    add  $t6, $t1, $t6          # $t6 = pill_x + (1 - pill_orientation)
    # 후보 위치 = (second_x, candidate row) = ($t6, $t5)
    sll  $s0, $t5, 5            # $s0 = candidate row * 32
    add  $s0, $s0, $t6          # $s0 = candidate row*32 + second_x
    sll  $s0, $s0, 2            # *4 (바이트 오프셋)
    add  $s0, $t0, $s0          # 최종 주소 for 두 번째 후보
    lw   $t9, 0($s0)            # $t9 = 색상 at 두 번째 후보 cell

    # 이제 BLACK 상수를 로드하여 후보 cell과 비교.
    # ($t6은 이제 사용 완료되었으므로 재사용 가능)
    lw   $t6, BLACK            # $t6 = BLACK

    # 만약 첫 번째 후보나 두 번째 후보의 색상이 BLACK이 아니면 충돌로 판단하고 루프 종료
    bne  $t8, $t6, drop_done
    bne  $t9, $t6, drop_done

    # 두 후보 모두 BLACK이면, drop_y를 1 증가시키고 반복
    addi $t4, $t4, 1
    j    outline_loop

drop_done:
    # outline_y = drop_y - 1 (충돌 발생 후보 바로 위)
    addi $t4, $t4, -1

    # 이제 outline을 그릴 색상은 LIGHT_GRAY.
    # $t6를 재사용하여 LIGHT_GRAY를 로드합니다.
    lw   $t6, LIGHT_GRAY       # $t6 = LIGHT_GRAY

    # --- 첫 번째 블록 outline 그리기 ---
    # 위치: (pill_x, outline_y)
    sll  $s0, $t4, 5            # $s0 = outline_y * 32
    add  $s0, $s0, $t1          # $s0 = outline_y*32 + pill_x
    sll  $s0, $s0, 2            # *4 (바이트 오프셋)
    add  $s0, $t0, $s0          # 최종 주소
    sw   $t6, 0($s0)            # 첫 번째 블록 outline 그리기

    # --- second block outline ---
    # orientation에 따라:
    #   vertical (t3 == 1): outline 위치 = (pill_x, outline_y+1)
    #   horizontal (t3 == 0): outline 위치 = (pill_x+1, outline_y)
    beq  $t3, $zero, outline_horizontal
    # vertical case:
    subi $t4, $t4, 1            # 
    sll  $s0, $t4, 5            # $s0 = (outline_y+1)*32
    add  $s0, $s0, $t1          # $s0 = (outline_y+1)*32 + pill_x
    sll  $s0, $s0, 2
    add  $s0, $t0, $s0
    sw   $t6, 0($s0)
    j    outline_end

outline_horizontal:
    # horizontal case: outline position = (pill_x+1, outline_y)
    # : X = pill_x+1, Y = outline_y
    # $s0 reuse:
    li   $s0, 0                # clear $s0
    sll  $s0, $t4, 5           # $s0 = outline_y * 32
    # X 좌표: pill_x+1
    move $s1, $t1             # $s1 = pill_x
    addi $s1, $s1, 1          # $s1 = pill_x + 1
    add  $s0, $s0, $s1        # $s0 = outline_y * 32 + (pill_x+1)
    sll  $s0, $s0, 2
    add  $s0, $t0, $s0
    sw   $t6, 0($s0)

outline_end:
    lw   $ra, 0($sp)
    addi $sp, $sp, 8
    jr   $ra


# Function: draw_next_capsule
# 목적: 전역 변수 next_pill_orientation, next_pill_color1, next_pill_color2에 저장된  
#       다음 캡슐의 정보를 이용하여, 화면의 (28,4)를 기준으로 미리보기 패널에 그림.
# 사용 가능한 레지스터: $t0 ~ $t9
draw_next_capsule:
    addi $sp, $sp, -4        # $ra 백업
    sw   $ra, 0($sp)

    lw   $t0, ADDR_DSPL      # $t0 = 디스플레이 기본 주소

    li   $t1, 28             # preview_x = 28 (0~31 범위 내)
    li   $t2, 4              # preview_y = 4

    # 다음 캡슐 정보 로드
    lw   $t3, next_pill_orientation  # $t3 = 다음 캡슐 orientation (0: horizontal, 1: vertical)
    lw   $t4, next_pill_color1       # $t4 = 첫 번째 블록 색상
    lw   $t5, next_pill_color2       # $t5 = 두 번째 블록 색상

    # --- 첫 번째 블록 그리기 ---
    # 계산: offset = ((preview_y * 32) + preview_x) * 4
    move $t6, $t2           # $t6 = preview_y
    sll  $t6, $t6, 5         # $t6 = preview_y * 32
    add  $t6, $t6, $t1       # $t6 = preview_y*32 + preview_x
    sll  $t6, $t6, 2         # byte offset (*4)
    add  $t6, $t0, $t6       # 최종 주소 = 디스플레이 기본 주소 + offset
    sw   $t4, 0($t6)         # 첫 번째 블록을 next_pill_color1으로 그림

    # --- 두 번째 블록 좌표 결정 ---
    move $t7, $t1           # $t7 = preview_x (복사)
    move $t8, $t2           # $t8 = preview_y (복사)
    beq  $t3, $zero, next_horiz_preview
    # orientation이 1 (vertical)인 경우: 두 번째 블록은 바로 아래에 위치
    addi $t8, $t8, 1        # y 좌표 +1
    j    next_draw_preview
next_horiz_preview:
    # orientation이 0 (horizontal)인 경우: 두 번째 블록은 오른쪽에 위치
    addi $t7, $t7, 1        # x 좌표 +1
next_draw_preview:
    # --- 두 번째 블록 그리기 ---
    move $t9, $t8           # $t9 = preview_y (복사)a
    sll  $t9, $t9, 5         # $t9 = preview_y * 32
    add  $t9, $t9, $t7       # $t9 = preview_y*32 + (preview_x 혹은 preview_x+1)
    sll  $t9, $t9, 2         # byte offset
    add  $t9, $t0, $t9       # 최종 주소 계산
    sw   $t5, 0($t9)         # 두 번째 블록을 next_pill_color2로 그림

    lw   $ra, 0($sp)         # $ra 복원
    addi $sp, $sp, 4
    jr   $ra
    
generate_random_next:
    # orientation은 항상 0 (가로)
    li   $t0, 0
    sw   $t0, next_pill_orientation

    # 랜덤 색상 1 생성 (0 ~ 2)
    li   $v0, 42
    li   $a0, 0
    li   $a1, 3
    syscall
    la   $t0, colors
    sll  $a0, $a0, 2
    add  $t0, $t0, $a0
    lw   $t1, 0($t0)
    sw   $t1, next_pill_color1

    # 랜덤 색상 2 생성 (0 ~ 2)
    li   $v0, 42
    li   $a0, 0
    li   $a1, 3
    syscall
    la   $t0, colors
    sll  $a0, $a0, 2
    add  $t0, $t0, $a0
    lw   $t1, 0($t0)
    sw   $t1, next_pill_color2

    jr   $ra
