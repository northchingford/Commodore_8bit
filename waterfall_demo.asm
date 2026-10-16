; REU-assisted waterfall scene for a C64 with a 512 KiB 1750 REU.
; Build assets with make_waterfall_assets.py, then assemble with ACME.

* = $0801
!byte $0c,$08,$0a,$00,$9e,$32,$30,$36,$31,$00,$00,$00 ; 10 SYS 2061

start:
	sei
	lda #$00
	sta $d01a
	lda $dc0d
	lda $dd0d
	lda $dd00
	and #$fc
	ora #$03                    ; VIC bank 0: $0000-$3fff
	sta $dd00

	lda #$00
	sta $d020
	lda #$0e
	sta $d021                    ; sky blue backdrop
	lda #$3b
	sta $d011                    ; multicolor bitmap, display enabled
	lda #$18
	sta $d016
	sta $d018                    ; screen $0400, bitmap $2000
	lda #$00
	sta $d015
	jsr copy_screen_data
	lda $01
	and #$fe                    ; hide BASIC ROM so DMA can read frames at $a000-$bfff
	sta $01
	jsr init_reu
	jsr init_water_sound
	cli

demo_loop:
	jsr wait_frame
	jsr show_next_frame
	jsr update_water_sound
	jmp demo_loop

copy_screen_data:
	ldx #$00
copy_full_pages:
	lda $4000,x
	sta $0400,x
	lda $4100,x
	sta $0500,x
	lda $4200,x
	sta $0600,x
	lda $4400,x
	sta $d800,x
	lda $4500,x
	sta $d900,x
	lda $4600,x
	sta $da00,x
	inx
	bne copy_full_pages
	ldx #$00
copy_last_page:
	cpx #$e8
	beq screen_data_done
	lda $4300,x
	sta $0700,x
	lda $4700,x
	sta $db00,x
	inx
	jmp copy_last_page
screen_data_done:
	rts

init_reu:
	lda #$00
	sta $df02                    ; C64 frame data begins at $4800
	lda #$48
	sta $df03
	lda #$00
	sta $df04
	sta $df05
	sta $df06                    ; REU destination $00000
	sta $df07
	lda #$78                    ; six frames, 6 * $1400 = $7800 bytes
	sta $df08
	lda #$1f
	sta $df09                    ; no REU interrupts
	lda #$00
	sta $df0a                    ; increment both addresses
	lda #$90                    ; C64 -> REU, execute DMA
	sta $df01
	lda #$00
	sta frame_index
	rts

show_next_frame:
	ldx frame_index
	lda reu_frame_low,x
	sta $df04
	lda reu_frame_mid,x
	sta $df05
	lda #$00
	sta $df06
	lda #$40                    ; bitmap destination $2b40 (y=72)
	sta $df02
	lda #$2b
	sta $df03
	lda #$00
	sta $df07
	lda #$14                    ; 128 bitmap rows = $1400 bytes
	sta $df08
	lda #$91                    ; REU -> C64, execute DMA
	sta $df01
	inc frame_index
	lda frame_index
	cmp #$06
	bne frame_index_ready
	lda #$00
	sta frame_index
frame_index_ready:
	rts

wait_frame:
	lda $d012
	cmp #$ff
	bne wait_frame
wait_next_frame:
	lda $d012
	cmp #$ff
	beq wait_next_frame
	rts

init_water_sound:
	lda #$00
	sta $d40e
	lda #$18
	sta $d40f
	lda #$00
	sta $d413                    ; immediate noise attack
	lda #$f2
	sta $d414                    ; sustained, softly released noise
	lda #$81
	sta $d412                    ; voice 3 noise waveform + gate
	lda #$0c
	sta $d418                    ; water noise, leave headroom
	lda #$5d
	sta noise_phase
	rts

update_water_sound:
	lda noise_phase
	asl
	bcc noise_no_xor
	eor #$1d
noise_no_xor:
	sta noise_phase
	and #$1f
	clc
	adc #$0c
	sta $d40e
	lda noise_phase
	and #$0f
	adc #$10
	sta $d40f
	rts

reu_frame_low:
!byte $00,$00,$00,$00,$00,$00
reu_frame_mid:
!byte $00,$14,$28,$3c,$50,$64
frame_index: !byte $00
noise_phase: !byte $5d

* = $2000
!binary "waterfall_bitmap.bin"

* = $4000
!binary "waterfall_screen.bin"

* = $4400
!binary "waterfall_colors.bin"

* = $4800
!binary "waterfall_reu_frames.bin"