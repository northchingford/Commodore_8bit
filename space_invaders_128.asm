; Space Invaders for the Commodore 128 80-column VDC display.
; Build: acme -f cbm -o space_invaders_128.prg space_invaders_128.asm
; Load and RUN from C128 BASIC 7.0; this is not a C64-mode program.

* = $0801
!byte $11,$08,$0a,$00,$de,$20,$35,$2c,$31,$3a,$9e,$32,$30,$36,$37,$00,$00,$00 ; 10 GRAPHIC 5,1:SYS 2067

* = $0813

VDC_STATUS = $d600
VDC_DATA   = $d601
SID        = $d400
GETIN      = $ffe4

start:
	jsr init_vdc
	jsr init_sid
	jsr clear_vdc
	jsr load_glyphs
	jsr init_game
	jsr draw_interface
	jsr draw_fleet
	jsr draw_ship
	lda $a2
	sta last_tick

main_loop:
	jsr wait_tick
	jsr read_keys
	lda game_over
	beq game_running
	lda key_value
	cmp #$20
	bne main_loop
	jsr clear_vdc
	jsr init_game
	jsr draw_interface
	jsr draw_fleet
	jsr draw_ship
	jmp main_loop

game_running:
	jsr update_player_bullet
	jsr update_enemy_bullet
	jsr update_fleet
	jsr update_sound
	jmp main_loop

wait_tick:
	lda $a2
	cmp last_tick
	beq wait_tick
	sta last_tick
	rts

read_keys:
	lda #$00
	sta key_value
	jsr GETIN
	beq keys_done
	sta key_value
	cmp #$41                    ; A or left cursor
	beq move_left
	cmp #$61
	beq move_left
	cmp #$9d
	beq move_left
	cmp #$44                    ; D or right cursor
	beq move_right
	cmp #$64
	beq move_right
	cmp #$1d
	beq move_right
	cmp #$20                    ; fire
	beq fire_player
	jmp keys_done

move_left:
	lda ship_x
	cmp #$04
	bcc keys_done
	jsr erase_ship
	dec ship_x
	jsr draw_ship
	jmp keys_done

move_right:
	lda ship_x
	cmp #$4c
	bcs keys_done
	jsr erase_ship
	inc ship_x
	jsr draw_ship
	jmp keys_done

fire_player:
	lda player_bullet_active
	bne keys_done
	lda ship_x
	clc
	adc #$01
	sta player_bullet_x
	lda #$14
	sta player_bullet_y
	lda #$01
	sta player_bullet_active
	lda #$02
	sta player_bullet_clock
	jsr play_shot
keys_done:
	rts

update_fleet:
	dec fleet_clock
	bne fleet_done
	lda #$07
	sta fleet_clock
	jsr erase_fleet
	lda fleet_dir
	bmi fleet_move_left
	lda fleet_x
	cmp #$30
	bcc fleet_move_right
	lda #$ff
	sta fleet_dir
	inc fleet_y
	jmp fleet_move_left
fleet_move_right:
	inc fleet_x
	jmp fleet_moved
fleet_move_left:
	lda fleet_x
	cmp #$08
	bne fleet_decrement_x
	lda #$01
	sta fleet_dir
	inc fleet_y
	jmp fleet_move_right
fleet_decrement_x:
	dec fleet_x
fleet_moved:
	lda fleet_anim
	eor #$01
	sta fleet_anim
	jsr draw_fleet
	jsr maybe_enemy_shot
	lda fleet_y
	cmp #$0f
	bcc fleet_done
	jsr lose_life
fleet_done:
	rts

update_player_bullet:
	lda player_bullet_active
	beq player_bullet_done
	dec player_bullet_clock
	bne player_bullet_done
	lda #$02
	sta player_bullet_clock
	ldx player_bullet_x
	ldy player_bullet_y
	lda #$20
	sta cell_color
	jsr write_cell
	dec player_bullet_y
	lda player_bullet_y
	cmp #$03
	bcs player_bullet_collision
	lda #$00
	sta player_bullet_active
	jmp player_bullet_done

player_bullet_collision:
	jsr test_alien_hit
	lda player_bullet_active
	beq player_bullet_done
	ldx player_bullet_x
	ldy player_bullet_y
	lda #$8c
	lda #$0e
	sta cell_color
	lda #$8c
	jsr write_cell
player_bullet_done:
	rts

test_alien_hit:
	lda player_bullet_y
	sec
	sbc fleet_y
	bcc no_alien_hit
	cmp #$06
	bcs no_alien_hit
	lsr
	tay
	lda alien_row_base,y
	sta alien_index
	ldx #$00
alien_hit_column:
	lda fleet_x
	clc
	adc alien_x_offset,x
	sta compare_x
	lda player_bullet_x
	cmp compare_x
	bcc alien_hit_next
	sec
	sbc compare_x
	cmp #$02
	bcs alien_hit_next
	lda alien_index
	clc
	adc alien_index_column,x
	tay
	lda alien_alive,y
	beq alien_hit_next
	lda #$00
	sta alien_alive,y
	dec aliens_remaining
	lda #$00
	sta player_bullet_active
	jsr add_score
	jsr play_explosion
	jsr erase_fleet
	jsr draw_fleet
	lda aliens_remaining
	bne alien_hit_done
	lda #$01
	sta game_over
	jsr draw_victory
alien_hit_done:
	rts
alien_hit_next:
	inx
	cpx #$0a
	bne alien_hit_column
no_alien_hit:
	rts

update_enemy_bullet:
	lda enemy_bullet_active
	beq enemy_bullet_done
	dec enemy_bullet_clock
	bne enemy_bullet_done
	lda #$03
	sta enemy_bullet_clock
	ldx enemy_bullet_x
	ldy enemy_bullet_y
	lda #$20
	sta cell_color
	jsr write_cell
	inc enemy_bullet_y
	lda enemy_bullet_y
	cmp #$16
	bcc draw_enemy_bullet
	lda enemy_bullet_x
	cmp ship_x
	bcc enemy_missed
	sec
	sbc ship_x
	cmp #$02
	bcs enemy_missed
	lda #$00
	sta enemy_bullet_active
	jsr play_explosion
	jsr lose_life
	jmp enemy_bullet_done
enemy_missed:
	lda #$00
	sta enemy_bullet_active
	jmp enemy_bullet_done
draw_enemy_bullet:
	ldx enemy_bullet_x
	ldy enemy_bullet_y
	lda #$0a
	sta cell_color
	lda #$8d
	jsr write_cell
enemy_bullet_done:
	rts

maybe_enemy_shot:
	lda enemy_bullet_active
	bne enemy_shot_done
	dec enemy_shot_timer
	bne enemy_shot_done
	lda #$0a
	sta enemy_shot_timer
	ldx alien_cursor
	lda fleet_x
	clc
	adc alien_x_offset,x
	clc
	adc #$01
	sta enemy_bullet_x
	lda fleet_y
	clc
	adc #$05
	sta enemy_bullet_y
	lda #$01
	sta enemy_bullet_active
	lda #$03
	sta enemy_bullet_clock
	inc alien_cursor
	lda alien_cursor
	cmp #$0a
	bcc enemy_shot_done
	lda #$00
	sta alien_cursor
enemy_shot_done:
	rts

update_sound:
	lda shot_timer
	beq sound_explosion
	dec shot_timer
	bne sound_explosion
	lda #$20
	sta $d404
sound_explosion:
	lda explosion_timer
	beq sound_done
	dec explosion_timer
	bne sound_done
	lda #$80
	sta $d412
sound_done:
	rts

play_shot:
	lda #$50
	sta $d400
	lda #$18
	sta $d401
	lda #$21
	sta $d404
	lda #$04
	sta shot_timer
	rts

play_explosion:
	lda #$a0
	sta $d40e
	lda #$08
	sta $d40f
	lda #$81
	sta $d412
	lda #$10
	sta explosion_timer
	rts

lose_life:
	lda lives
	beq life_lost_done
	dec lives
	jsr update_lives
	jsr play_explosion
	lda lives
	bne life_reset
	lda #$01
	sta game_over
	jsr draw_game_over
	jmp life_lost_done
life_reset:
	lda #$00
	sta player_bullet_active
	sta enemy_bullet_active
	jsr erase_fleet
	lda #$04
	sta fleet_y
	lda #$27
	sta ship_x
	jsr draw_fleet
	jsr draw_ship
life_lost_done:
	rts

add_score:
	sed
	clc
	lda score_bcd
	adc #$01
	sta score_bcd
	cld
	jsr update_score
	rts

update_score:
	lda score_bcd
	and #$f0
	lsr
	lsr
	lsr
	lsr
	clc
	adc #$30
	sta char_value
	lda #$01
	sta cell_color
	ldx #$07
	ldy #$01
	lda char_value
	jsr write_cell
	lda score_bcd
	and #$0f
	clc
	adc #$30
	ldx #$08
	ldy #$01
	jsr write_cell
	rts

update_lives:
	ldx #$07
	ldy #$03
	lda #$01
	sta cell_color
	lda lives
	clc
	adc #$30
	jsr write_cell
	rts

init_game:
	lda #$00
	sta score_bcd
	sta fleet_anim
	sta alien_cursor
	sta player_bullet_active
	sta enemy_bullet_active
	sta game_over
	lda #$1e
	sta aliens_remaining
	lda #$00
	sta fleet_clear
	lda #$03
	sta lives
	lda #$27
	sta ship_x
	lda #$18
	sta fleet_x
	lda #$04
	sta fleet_y
	lda #$01
	sta fleet_dir
	lda #$07
	sta fleet_clock
	lda #$0a
	sta enemy_shot_timer
	ldx #$00
init_aliens:
	lda #$01
	sta alien_alive,x
	inx
	cpx #$1e
	bne init_aliens
	jsr update_score
	jsr update_lives
	rts

draw_interface:
	lda #$00
	sta addr_lo
	sta addr_hi
	lda #<title_text
	sta $fb
	lda #>title_text
	sta $fc
	jsr write_text
	lda #$51
	sta addr_lo
	lda #$00
	sta addr_hi
	lda #<score_text
	sta $fb
	lda #>score_text
	sta $fc
	jsr write_text
	lda #$91
	sta addr_lo
	lda #$00
	sta addr_hi
	lda #<lives_text
	sta $fb
	lda #>lives_text
	sta $fc
	jsr write_text
	lda #$9c
	sta addr_lo
	lda #$07
	sta addr_hi
	lda #<controls_text
	sta $fb
	lda #>controls_text
	sta $fc
	jsr write_text
	jsr update_score
	jsr update_lives
	rts

draw_game_over:
	lda #$04
	sta addr_lo
	lda #$07
	sta addr_hi
	lda #<game_over_text
	sta $fb
	lda #>game_over_text
	sta $fc
	jsr write_text
	rts

draw_victory:
	lda #$84
	sta addr_lo
	lda #$03
	sta addr_hi
	lda #<victory_text
	sta $fb
	lda #>victory_text
	sta $fc
	jsr write_text
	rts

write_text:
	jsr set_vdc_addr
	ldx #$1f
	jsr vdc_select
	ldy #$00
write_text_loop:
	lda ($fb),y
	beq write_text_done
	cmp #$41                    ; Convert ASCII uppercase to VDC screen codes.
	bcc write_text_store
	cmp #$5b
	bcs write_text_store
	sec
	sbc #$40
write_text_store:
	jsr vdc_store
	iny
	bne write_text_loop
write_text_done:
	rts

draw_ship:
	lda #$0b
	sta cell_color
	lda #$88
	ldx ship_x
	ldy #$15
	jsr write_cell
	lda #$89
	ldx ship_x
	inx
	ldy #$15
	jsr write_cell
	lda #$8a
	ldx ship_x
	ldy #$16
	jsr write_cell
	lda #$8b
	ldx ship_x
	inx
	ldy #$16
	jsr write_cell
	rts

erase_ship:
	lda #$01
	sta cell_color
	lda #$20
	ldx ship_x
	ldy #$15
	jsr write_cell
	lda #$20
	ldx ship_x
	inx
	ldy #$15
	jsr write_cell
	lda #$20
	ldx ship_x
	ldy #$16
	jsr write_cell
	lda #$20
	ldx ship_x
	inx
	ldy #$16
	jsr write_cell
	rts

erase_fleet:
	lda #$01
	sta fleet_clear
	jsr render_fleet
	rts

draw_fleet:
	lda #$00
	sta fleet_clear
	jsr render_fleet
	rts

render_fleet:
	lda #$00
	sta line_index
render_line:
	ldx #$00
clear_row_buffer:
	lda #$20
	sta row_buffer,x
	inx
	cpx #$1e
	bne clear_row_buffer
	lda line_index
	lsr
	tay
	lda alien_row_base,y
	sta alien_index
	lda line_index
	and #$01
	sta alien_part
	lda #$00
	sta alien_column
	sta buffer_offset
render_alien_column:
	lda fleet_clear
	bne alien_column_next
	ldx alien_index
	lda alien_alive,x
	beq alien_column_next
	lda alien_part
	beq alien_top_glyph
	lda fleet_anim
	beq alien_bottom_frame_zero
	lda #$86
	bne set_alien_glyph
alien_bottom_frame_zero:
	lda #$82
	bne set_alien_glyph
alien_top_glyph:
	lda fleet_anim
	beq alien_top_frame_zero
	lda #$84
	bne set_alien_glyph
alien_top_frame_zero:
	lda #$80
set_alien_glyph:
	ldx buffer_offset
	sta row_buffer,x
	clc
	adc #$01
	inx
	sta row_buffer,x
alien_column_next:
	inc alien_index
	inc alien_column
	lda buffer_offset
	clc
	adc #$03
	sta buffer_offset
	lda alien_column
	cmp #$0a
	bne render_alien_column
	lda fleet_y
	clc
	adc line_index
	sta screen_y
	jsr point_to_fleet_row
	ldx #$1f
	jsr vdc_select
	ldx #$00
write_fleet_chars:
	lda row_buffer,x
	jsr vdc_store
	inx
	cpx #$1e
	bne write_fleet_chars
	jsr point_to_fleet_row
	lda addr_hi
	clc
	adc #$08
	sta addr_hi
	jsr set_vdc_addr
	ldx #$1f
	jsr vdc_select
	lda fleet_clear
	beq fleet_color_green
	lda #$01
	bne fleet_color_ready
fleet_color_green:
	lda #$0d
fleet_color_ready:
	sta fill_value
	ldx #$1e
write_fleet_attrs:
	lda fill_value
	jsr vdc_store
	dex
	bne write_fleet_attrs
	inc line_index
	lda line_index
	cmp #$06
	beq render_fleet_done
	jmp render_line
render_fleet_done:
	rts

point_to_fleet_row:
	ldy screen_y
	lda row_addr_lo,y
	clc
	adc fleet_x
	sta addr_lo
	lda row_addr_hi,y
	adc #$00
	sta addr_hi
	jsr set_vdc_addr
	rts

write_cell:
	sta char_value
	stx cell_x
	sty cell_y
	ldy cell_y
	lda row_addr_lo,y
	clc
	adc cell_x
	sta addr_lo
	lda row_addr_hi,y
	adc #$00
	sta addr_hi
	jsr set_vdc_addr
	ldx #$1f
	jsr vdc_select
	lda char_value
	jsr vdc_store
	lda addr_hi
	clc
	adc #$08
	sta addr_hi
	jsr set_vdc_addr
	ldx #$1f
	jsr vdc_select
	lda cell_color
	jsr vdc_store
	rts

clear_vdc:
	lda #$00
	sta addr_lo
	sta addr_hi
	lda #$20
	sta fill_value
	lda #$d0
	sta count_lo
	lda #$07
	sta count_hi
	jsr vdc_fill
	lda #$00
	sta addr_lo
	lda #$08
	sta addr_hi
	lda #$01
	sta fill_value
	lda #$d0
	sta count_lo
	lda #$07
	sta count_hi
	jsr vdc_fill
	rts

vdc_fill:
	jsr set_vdc_addr
	ldx #$1f
	jsr vdc_select
vdc_fill_loop:
	lda count_lo
	ora count_hi
	beq vdc_fill_done
	lda fill_value
	jsr vdc_store
	lda count_lo
	bne vdc_fill_low
	dec count_hi
vdc_fill_low:
	dec count_lo
	jmp vdc_fill_loop
vdc_fill_done:
	rts

load_glyphs:
	lda #$00
	sta addr_lo
	lda #$24
	sta addr_hi
	jsr set_vdc_addr
	ldx #$1f
	jsr vdc_select
	ldx #$00
load_glyph_loop:
	lda glyph_data,x
	jsr vdc_store
	inx
	cpx #$90
	bne load_glyph_loop
	rts

init_vdc:
	lda #$00
	ldx #$0c                    ; Screen RAM base: $0000.
	jsr vdc_write_reg
	lda #$00
	ldx #$0d
	jsr vdc_write_reg
	lda #$00
	ldx #$0e                    ; Hide cursor at the first screen cell.
	jsr vdc_write_reg
	lda #$00
	ldx #$0f
	jsr vdc_write_reg
	lda #$08                    ; Attribute RAM at $0800.
	ldx #$14
	jsr vdc_write_reg
	lda #$00
	ldx #$15
	jsr vdc_write_reg
	lda #$40                    ; Text mode with per-character attributes.
	ldx #$19
	jsr vdc_write_reg
	lda #$f0                    ; Black background, white default foreground.
	ldx #$1a
	jsr vdc_write_reg
	lda #$20                    ; 16 KB VDC: character generator starts at $2000.
	ldx #$1c
	jsr vdc_write_reg
	rts

init_sid:
	ldx #$00
	lda #$00
clear_sid:
	sta SID,x
	inx
	cpx #$19
	bne clear_sid
	lda #$08
	sta $d405
	sta $d40c
	lda #$a8
	sta $d406
	sta $d40d
	sta $d413
	lda #$0f
	sta $d418
	rts

set_vdc_addr:
	lda addr_hi
	ldx #$12
	jsr vdc_write_reg
	lda addr_lo
	ldx #$13
	jsr vdc_write_reg
	rts

vdc_write_reg:
	sta vdc_value
	stx vdc_register
	jsr vdc_wait
	ldx vdc_register
	stx VDC_STATUS
	jsr vdc_wait
	lda vdc_value
	sta VDC_DATA
	rts

vdc_select:
	jsr vdc_wait
	stx VDC_STATUS
	rts

vdc_store:
	jsr vdc_wait
	sta VDC_DATA
	rts

vdc_wait:
	bit VDC_STATUS
	bpl vdc_wait
	rts

glyph_data:
; Alien frame 0, 2x2 cells.
!byte $01,$07,$1f,$3d,$7f,$cf,$c3,$0c
!byte $80,$e0,$f8,$bc,$fe,$f3,$33,$30
!byte $0c,$0c,$1e,$3c,$60,$c0,$00,$00
!byte $30,$30,$78,$3c,$06,$03,$00,$00
; Alien frame 1.
!byte $01,$07,$1f,$3d,$7f,$cf,$c3,$1e
!byte $80,$e0,$f8,$bc,$fe,$f3,$33,$78
!byte $0c,$18,$3c,$66,$c0,$00,$00,$00
!byte $30,$18,$3c,$66,$03,$00,$00,$00
; Player ship, 2x2 cells.
!byte $00,$00,$01,$03,$07,$0f,$1f,$3f
!byte $00,$00,$80,$c0,$e0,$f0,$f8,$fc
!byte $7f,$ff,$ff,$ef,$cf,$0f,$0f,$00
!byte $fe,$ff,$ff,$f7,$f3,$f0,$f0,$00
; Player and enemy projectiles.
!byte $18,$18,$18,$18,$18,$18,$18,$18
!byte $00,$18,$3c,$7e,$7e,$3c,$18,$00
; Explosion, 2x2 cells.
!byte $18,$81,$42,$24,$18,$24,$42,$81
!byte $18,$81,$42,$24,$18,$24,$42,$81
!byte $00,$18,$42,$24,$18,$24,$42,$18
!byte $00,$18,$42,$24,$18,$24,$42,$18

title_text:      !text "          SPACE INVADERS 128          ",0
score_text:      !text "SCORE 00",0
lives_text:      !text "LIVES 3",0
controls_text:   !text "      A/D OR CURSORS: MOVE     SPACE: FIRE",0
game_over_text:  !text "  GAME OVER - PRESS SPACE TO RESTART  ",0
victory_text:    !text "       INVADERS DESTROYED - YOU WIN!       ",0

alien_row_base: !byte 0,10,20
alien_x_offset: !byte 0,3,6,9,12,15,18,21,24,27
alien_index_column: !byte 0,1,2,3,4,5,6,7,8,9
row_addr_lo:
!byte $00,$50,$a0,$f0,$40,$90,$e0,$30,$80,$d0
!byte $20,$70,$c0,$10,$60,$b0,$00,$50,$a0,$f0
!byte $40,$90,$e0,$30,$80
row_addr_hi:
!byte $00,$00,$00,$00,$01,$01,$01,$02,$02,$02
!byte $03,$03,$03,$04,$04,$04,$05,$05,$05,$06
!byte $06,$06,$07,$07,$07

last_tick:              !byte 0
key_value:              !byte 0
game_over:              !byte 0
score_bcd:              !byte 0
lives:                  !byte 3
aliens_remaining:       !byte 30
ship_x:                 !byte $27
fleet_x:                !byte $18
fleet_y:                !byte $04
fleet_dir:              !byte 1
fleet_clock:            !byte 7
fleet_anim:             !byte 0
fleet_clear:            !byte 0
line_index:             !byte 0
screen_y:               !byte 0
alien_part:             !byte 0
alien_column:           !byte 0
alien_index:            !byte 0
buffer_offset:          !byte 0
compare_x:              !byte 0
player_bullet_active:   !byte 0
player_bullet_x:        !byte 0
player_bullet_y:        !byte 0
player_bullet_clock:    !byte 0
enemy_bullet_active:    !byte 0
enemy_bullet_x:         !byte 0
enemy_bullet_y:         !byte 0
enemy_bullet_clock:     !byte 0
enemy_shot_timer:       !byte 0
alien_cursor:           !byte 0
shot_timer:             !byte 0
explosion_timer:        !byte 0
cell_color:             !byte 1
cell_x:                 !byte 0
cell_y:                 !byte 0
char_value:             !byte 0
addr_lo:                !byte 0
addr_hi:                !byte 0
fill_value:             !byte 0
count_lo:               !byte 0
count_hi:               !byte 0
vdc_value:              !byte 0
vdc_register:           !byte 0
row_buffer:             !fill 30, $20
alien_alive:            !fill 30, 0