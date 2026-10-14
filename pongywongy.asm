; Two-player C64 Pong. Joystick port 2 controls the left bat;
; joystick port 1 controls the right bat.

* = $0801
!byte $0c,$08,$0a,$00,$9e,$32,$30,$36,$31,$00,$00,$00 ; 10 SYS 2061

start:
	sei
	lda #$04
	sta $d020
    lda #$00
	sta $d021
	lda #$0f
	sta $d418
	jsr reset_game
	cli

game_loop:
	jsr wait_frame
	lda game_over
	bne wait_for_fire
	jsr read_controls
	jsr move_ball
	jsr animate_ball
	jsr update_sound
	jsr update_sprites
	jmp game_loop

wait_for_fire:
	lda $dc00
	and #$10
	beq restart_game
	lda $dc01
	and #$10
	beq restart_game
	jmp game_loop

restart_game:
	jsr reset_game
	jmp game_loop

wait_frame:
	lda $d012
	cmp #$ff
	bne wait_frame
wait_next_frame:
	lda $d012
	cmp #$ff
	beq wait_next_frame
	rts

reset_game:
	ldx #$00
	lda #$20
clear_screen:
	sta $0400,x
	sta $0500,x
	sta $0600,x
	sta $0700,x
	lda #$01
	sta $d800,x
	sta $d900,x
	sta $da00,x
	sta $db00,x
	lda #$20
	inx
	bne clear_screen

	lda #$c0
	sta $07f8
	lda #$c4
	sta $07f9
	lda #$c5
	sta $07fa
	lda #$07
	sta $d015
	lda #$06
	sta $d017
	lda #$00
	sta $d01c
	sta $d01d
	lda #$01
	sta $d027
	lda #$02
	sta $d028
	lda #$06
	sta $d029

	lda #$00
	sta left_score
	sta right_score
	sta game_over
	sta sound_timer
	sta spin_frame
	sta spin_timer
	lda #$96
	sta ball_x
	lda #$78
	sta ball_y
	lda #$28
	sta left_y
	sta right_y
	lda #$01
	sta x_direction
	lda #$00
	sta y_direction
	jsr draw_title
	jsr draw_score
	jsr update_sprites
	rts

draw_title:
	ldx #$00
draw_banner:
	lda banner_text,x
	sta $040b,x
	inx
	cpx #$12
	bne draw_banner
	lda #$10
	sta $07ce
	lda #$31
	sta $07cf
	lda #$10
	sta $07d7
	lda #$32
	sta $07d8
	lda #$2d
	sta $07d3
	rts

draw_score:
	lda left_score
	clc
	adc #$30
	sta $07d1
	lda right_score
	clc
	adc #$30
	sta $07d5
	rts

read_controls:
	lda $dc00
	and #$01
	bne left_down_check
	lda left_y
	cmp #$34
	bcc left_down_check
	sec
	sbc #$02
	sta left_y
left_down_check:
	lda $dc00
	and #$02
	bne right_controls
	lda left_y
	cmp #$d0
	bcs right_controls
	clc
	adc #$02
	sta left_y

right_controls:
	lda $dc01
	and #$01
	bne right_down_check
	lda right_y
	cmp #$34
	bcc right_down_check
	sec
	sbc #$02
	sta right_y
right_down_check:
	lda $dc01
	and #$02
	bne controls_done
	lda right_y
	cmp #$d0
	bcs controls_done
	clc
	adc #$02
	sta right_y
controls_done:
	rts

move_ball:
	lda x_direction
	beq move_ball_left
	clc
	lda ball_x
	adc #$02
	sta ball_x
	cmp #$f8
	bcs check_right_bat
	jmp move_ball_y

move_ball_left:
	sec
	lda ball_x
	sbc #$02
	sta ball_x
	cmp #$32
	bcc check_left_bat
	jmp move_ball_y

check_right_bat:
	lda right_y
	sec
	sbc #$08
	cmp ball_y
	bcc right_bat_lower_edge
	beq right_bat_lower_edge
	jsr score_left
	jmp move_ball_y
right_bat_lower_edge:
	lda right_y
	clc
	adc #$32
	bcs right_bat_hit
	cmp ball_y
	bcc right_bat_miss
right_bat_hit:
	lda #$00
	sta x_direction
	lda #$f6
	sta ball_x
	jsr play_boing
	jmp move_ball_y
right_bat_miss:
	jsr score_left
	jmp move_ball_y

check_left_bat:
	lda left_y
	sec
	sbc #$08
	cmp ball_y
	bcc left_bat_lower_edge
	beq left_bat_lower_edge
	jsr score_right
	jmp move_ball_y
left_bat_lower_edge:
	lda left_y
	clc
	adc #$32
	bcs left_bat_hit
	cmp ball_y
	bcc left_bat_miss
left_bat_hit:
	lda #$01
	sta x_direction
	lda #$34
	sta ball_x
	jsr play_boing
	jmp move_ball_y
left_bat_miss:
	jsr score_right
	jmp move_ball_y

move_ball_y:
	lda y_direction
	bne move_ball_down
	sec
	lda ball_y
	sbc #$02
	sta ball_y
	cmp #$32
	bcs move_ball_done
	lda #$32
	sta ball_y
	lda #$01
	sta y_direction
	rts
move_ball_down:
	clc
	lda ball_y
	adc #$02
	sta ball_y
	cmp #$d2
	bcc move_ball_done
	lda #$d2
	sta ball_y
	lda #$00
	sta y_direction
move_ball_done:
	rts

score_left:
	inc left_score
	jsr draw_score
	lda left_score
	cmp #$05
	beq left_wins
	jsr serve_ball
	rts
left_wins:
	lda #$01
	sta game_over
	jsr display_left_win
	rts

score_right:
	inc right_score
	jsr draw_score
	lda right_score
	cmp #$05
	beq right_wins
	jsr serve_ball
	rts
right_wins:
	lda #$01
	sta game_over
	jsr display_right_win
	rts

serve_ball:
	lda #$96
	sta ball_x
	lda #$78
	sta ball_y
	lda $dc04
	and #$01
	sta x_direction
	lda $dc05
	and #$01
	sta y_direction
	rts

play_boing:
	lda #$80
	sta $d400
	lda #$22
	sta $d401
	lda #$09
	sta $d405
	lda #$00
	sta $d406
	lda #$21
	sta $d404
	lda #$08
	sta sound_timer
	rts

update_sound:
	lda sound_timer
	beq sound_done
	dec sound_timer
	bne sound_done
	lda #$20
	sta $d404
sound_done:
	rts

animate_ball:
	inc spin_timer
	lda spin_timer
	and #$03
	bne spin_done
	inc spin_frame
	lda spin_frame
	and #$03
	clc
	adc #$c0
	sta $07f8
spin_done:
	rts

update_sprites:
	lda ball_x
	sta $d000
	lda ball_y
	sta $d001
	lda #$28
	sta $d002
	lda left_y
	sta $d003
	lda #$00
	sta $d004
	lda right_y
	sta $d005
	lda #$04
	sta $d010
	rts

display_left_win:
	ldx #$00
left_win_text_loop:
	lda left_win_text,x
	sta $05c4,x
	inx
	cpx #$10
	bne left_win_text_loop
	jmp display_prompt

display_right_win:
	ldx #$00
right_win_text_loop:
	lda right_win_text,x
	sta $05c3,x
	inx
	cpx #$11
	bne right_win_text_loop

display_prompt:
	ldx #$00
prompt_text_loop:
	lda prompt_text,x
	sta $0612,x
	inx
	cpx #$13
	bne prompt_text_loop
	rts

left_score:  !byte $00
right_score: !byte $00
game_over:   !byte $00
ball_x:      !byte $00
ball_y:      !byte $00
left_y:      !byte $00
right_y:     !byte $00
x_direction: !byte $00
y_direction: !byte $00
sound_timer: !byte $00
spin_frame:  !byte $00
spin_timer:  !byte $00

left_win_text:
!byte 12,5,6,20,32,16,12,1,25,5,18,32,23,9,14,19
right_win_text:
!byte 18,9,7,8,20,32,16,12,1,25,5,18,32,23,9,14,19
prompt_text:
!byte 16,18,5,19,19,32,6,9,18,5,32,20,15,32,19,20,1,18,20
banner_text:
!byte 16,15,14,7,25,32,23,15,14,7,25,32,2,25,32,19,12,3

* = $3000
; Four changing 24x21 ball sprites create a rotating highlight.
!fill 18, $00
!byte $00,$18,$00,$00,$3c,$00,$00,$66,$00
!byte $00,$c3,$00,$00,$c3,$00,$00,$66,$00
!byte $00,$3c,$00,$00,$18,$00,$00,$00,$00
!fill 18, $00
!byte $00

* = $3040
!fill 18, $00
!byte $00,$18,$00,$00,$3c,$00,$00,$7e,$00
!byte $00,$db,$00,$00,$c3,$00,$00,$7e,$00
!byte $00,$3c,$00,$00,$18,$00,$00,$00,$00
!fill 18, $00
!byte $00

* = $3080
!fill 18, $00
!byte $00,$18,$00,$00,$3c,$00,$00,$66,$00
!byte $00,$ff,$00,$00,$ff,$00,$00,$66,$00
!byte $00,$3c,$00,$00,$18,$00,$00,$00,$00
!fill 18, $00
!byte $00

* = $30c0
!fill 18, $00
!byte $00,$18,$00,$00,$3c,$00,$00,$7e,$00
!byte $00,$c3,$00,$00,$db,$00,$00,$7e,$00
!byte $00,$3c,$00,$00,$18,$00,$00,$00,$00
!fill 18, $00
!byte $00

* = $3100
; Narrow white-independent red/blue paddle bitmap, doubled vertically.
!for .i, 0, 20 {
	!byte $00,$ff,$00
}
!byte $00

* = $3140
!for .i, 0, 20 {
	!byte $00,$ff,$00
}
!byte $00
