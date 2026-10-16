; Steven Croucher: single-screen C64 bitmap demo with a two-minute SID loop.
; Build the artwork first with: python3 make_steven_bitmap.py
; Then assemble with: acme -f cbm -o steven_demo.prg steven_demo.asm

* = $0801
!byte $0c,$08,$0a,$00,$9e,$32,$30,$36,$31,$00,$00,$00 ; 10 SYS 2061

start:
	sei
	lda #$00
	sta $d01a
	lda $dc0d
	lda $dd0d
	lda $dd00
	ora #$03                    ; VIC bank 0: $0000-$3fff
	sta $dd00

	lda #$00
	sta $d020
	sta $d021
	lda #$01
	sta $d022                    ; shared bitmap color 1: white
	lda #$02
	sta $d023                    ; shared bitmap color 2: red
	lda #$3b
	sta $d011                    ; bitmap mode, display enabled, 25 rows
	lda #$18
	sta $d016                    ; multicolor, 40 columns
	sta $d018                    ; screen $0400, bitmap $2000
	lda #$00
	sta $d015

	ldx #$00
	lda #$12
screen_colors:
	sta $0400,x
	sta $0500,x
	sta $0600,x
	sta $0700,x
	inx
	bne screen_colors

	ldx #$00
copy_cell_colors:
	lda cell_colors,x
	sta $d800,x
	lda cell_colors+$100,x
	sta $d900,x
	lda cell_colors+$200,x
	sta $da00,x
	inx
	bne copy_cell_colors
	ldx #$e8
copy_last_color_page:
	dex
	lda cell_colors+$300,x
	sta $db00,x
	bne copy_last_color_page

	jsr init_music

demo_loop:
	jsr wait_frame
	jsr music_tick
	jmp demo_loop

wait_frame:
	lda $d012
	cmp #$ff
	bne wait_frame
wait_next_frame:
	lda $d012
	cmp #$ff
	beq wait_next_frame
	rts

init_music:
	lda #$00
	sta frame_in_bar
	sta arp_clock
	sta arp_step
	sta beat_clock
	sta bar_index
	sta repeat_index
	sta chord_gate
	sta vibrato_phase
	sta lead_low
	sta lead_high
	ldx #$00
clear_sid:
	sta $d400,x
	inx
	cpx #$19
	bne clear_sid
	lda #$08
	sta $d405                    ; voice 1 attack/decay
	sta $d40c                    ; voice 2 attack/decay
	sta $d413                    ; voice 3 attack/decay
	lda #$82
	sta $d406                    ; voice 1 sustain/release
	sta $d40d                    ; voice 2 sustain/release
	sta $d414                    ; voice 3 sustain/release
	lda #$0f
	sta $d418                    ; maximum volume
	rts

music_tick:
	lda frame_in_bar
	bne music_not_bar_start
	jsr start_bar
music_not_bar_start:
	inc frame_in_bar
	inc arp_clock
	lda arp_clock
	cmp #$0c
	bcc music_arp_done
	lda #$00
	sta arp_clock
	inc arp_step
	lda arp_step
	and #$07
	sta arp_step
	lda bar_index
	asl
	asl
	asl
	clc
	adc arp_step
	tax
	lda arp_notes,x
	tax
	lda note_low,x
	sta lead_low
	lda note_high,x
	sta lead_high
	lda #$00
	sta $d404
	lda #$21                    ; triangle + gate
	sta $d404
music_arp_done:
	inc beat_clock
	lda beat_clock
	cmp #$19
	bcc music_bass_done
	lda #$00
	sta beat_clock
	jsr play_bass
music_bass_done:
	lda chord_gate
	beq music_gate_done
	dec chord_gate
	bne music_gate_done
	lda #$40                    ; release voice 2
	sta $d40b
music_gate_done:
	lda frame_in_bar
	cmp #$64
	bne music_done
	lda #$00
	sta frame_in_bar
	sta arp_clock
	sta arp_step
	inc bar_index
	lda bar_index
	cmp #$0c
	bne music_done
	lda #$00
	sta bar_index
	inc repeat_index
	lda repeat_index
	cmp #$05
	bne music_done
	lda #$00
	sta repeat_index
music_done:
	jsr update_lead_pitch
	rts

update_lead_pitch:
	inc vibrato_phase
	lda vibrato_phase
	and #$07
	tax
	clc
	lda lead_low
	adc vibrato_low,x
	sta $d400
	lda lead_high
	adc vibrato_high,x
	sta $d401
	rts

start_bar:
	lda #$08
	sta chord_gate
	lda bar_index
	tax
	lda bass_roots,x
	clc
	adc #$13                    ; root plus an octave and a fifth
	tax
	lda note_low,x
	sta $d407
	lda note_high,x
	sta $d408
	lda #$00
	sta $d40b
	lda #$41                    ; sawtooth + gate
	sta $d40b
	jsr play_bass
	lda #$00
	sta beat_clock
	rts

play_bass:
	ldx bar_index
	lda bass_roots,x
	tax
	lda note_low,x
	sta $d40e
	lda note_high,x
	sta $d40f
	lda #$00
	sta $d412
	lda #$41                    ; sawtooth + gate
	sta $d412
	rts

; C, C, F, F, G, G, F, F, D, F, G, D (12-bar progression)
bass_roots:
!byte 0,0,5,5,7,7,5,5,2,5,7,2
arp_notes:
!byte 12,16,19,24,19,16,19,24
!byte 12,16,19,24,19,16,19,24
!byte 17,21,24,29,24,21,24,29
!byte 17,21,24,29,24,21,24,29
!byte 19,23,26,31,26,23,26,31
!byte 19,23,26,31,26,23,26,31
!byte 17,21,24,29,24,21,24,29
!byte 17,21,24,29,24,21,24,29
!byte 14,18,21,26,21,18,21,26
!byte 17,21,24,29,24,21,24,29
!byte 19,23,26,31,26,23,26,31
!byte 14,18,21,26,21,18,21,26

; PAL SID note periods, C2 through B4, one semitone per entry.
note_low:
!byte $5a,$9c,$e2,$2d,$7b,$cf,$27,$85,$e8,$51,$c1,$37
!byte $b4,$38,$c4,$59,$f7,$9d,$4e,$0a,$d0,$a2,$81,$6d
!byte $67,$70,$89,$b2,$ed,$3b,$9c,$13,$a0,$45,$02,$da
note_high:
!byte $04,$04,$04,$05,$05,$05,$06,$06,$06,$07,$07,$08
!byte $08,$09,$09,$0a,$0a,$0b,$0c,$0d,$0d,$0e,$0f,$10
!byte $11,$12,$13,$14,$15,$17,$18,$1a,$1b,$1d,$1f,$20
vibrato_low:
!byte $00,$20,$40,$20,$00,$e0,$c0,$e0
vibrato_high:
!byte $00,$00,$00,$00,$00,$ff,$ff,$ff

frame_in_bar: !byte $00
arp_clock:    !byte $00
arp_step:     !byte $00
beat_clock:   !byte $00
bar_index:    !byte $00
repeat_index: !byte $00
chord_gate:   !byte $00
vibrato_phase: !byte $00
lead_low:      !byte $00
lead_high:     !byte $00

* = $2000
!binary "steven_bitmap.bin"

* = $4000
cell_colors:
!binary "steven_colors.bin"