; REU-assisted waterfall scene. Load waterfall.reu into a 512 KiB REU first.
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
	sta reu_offset_low
	sta reu_offset_mid
	sta reu_offset_high
	sta $df04                    ; REU frame pointer starts at $00000
	sta $df05
	sta $df06
	sta $df07
	lda #$14                    ; 128 bitmap rows = $1400 bytes
	sta $df08
	lda #$1f
	sta $df09                    ; no REU interrupts
	lda #$00
	sta $df0a                    ; increment both addresses
	sta frame_index
	rts

show_next_frame:
	lda reu_offset_low
	sta $df04
	lda reu_offset_mid
	sta $df05
	lda reu_offset_high
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
	cmp #$66                    ; 102 frames use 510 KiB of the 512 KiB REU
	bne advance_reu_frame
	lda #$00
	sta frame_index
	sta reu_offset_low
	sta reu_offset_mid
	sta reu_offset_high
	rts
advance_reu_frame:
	clc
	lda reu_offset_mid
	adc #$14
	sta reu_offset_mid
	bcc reu_frame_ready
	inc reu_offset_high
reu_frame_ready:
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

frame_index: !byte $00
reu_offset_low: !byte $00
reu_offset_mid: !byte $00
reu_offset_high: !byte $00
noise_phase: !byte $5d

* = $2000
!binary "waterfall_bitmap.bin"

* = $4000
!binary "waterfall_screen.bin"

* = $4400
!binary "waterfall_colors.bin"