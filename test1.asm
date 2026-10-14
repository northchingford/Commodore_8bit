; Commodore 64 / 6510 assembly (ACME syntax)
; Assemble to a PRG and load/run it. The ball uses hardware sprite 0.

* = $0801
!byte $0c,$08,$0a,$00,$9e,$32,$30,$36,$31,$00,$00,$00 ; 10 SYS 2061

start:
	lda #$00    				; Black
    sta $d020   				; Border
    sta $d021   				; Background
	sei
	lda #$c0                    ; sprite data at $3000 in VIC bank 0
	sta $07f8
	lda #$01
	sta $d015                   ; enable sprite 0
	lda #$06                    ; blue
	sta $d027
	lda #160
	sta xpos
	lda #0
	sta xposhi
	lda #100
	sta ypos
	lda #1
	sta xdir                    ; 0=left, 1=right
	sta ydir                    ; 0=up, 1=down
	lda #2
	sta xspeed
	sta yspeed
	cli

frame:
	lda $d012
	cmp #$ff
	bne frame                   ; synchronize to raster
waitline:
	lda $d012
	cmp #$ff
	beq waitline

	jsr move_x
	jsr move_y
	lda xpos
	sta $d000
	lda xposhi
	and #1
	sta $d010
	lda ypos
	sta $d001
	jmp frame

move_x:
	lda xdir
	beq x_left
	clc
	lda xpos
	adc xspeed
	sta xpos
	lda xposhi
	adc #0
	sta xposhi
	jmp x_bounds
x_left:
	sec
	lda xpos
	sbc xspeed
	sta xpos
	lda xposhi
	sbc #0
	sta xposhi

x_bounds:
	lda xposhi
	beq x_check_left
	cmp #1
	beq x_check_right
	jmp hit_left               ; underflowed past the left edge
x_check_left:
	lda xpos
	cmp #24
	bcc hit_left
	rts
x_check_right:
	lda xpos
	cmp #39                    ; x=295 is the rightmost limit
	bcs hit_right
	rts

hit_left:
	lda #24
	sta xpos
	lda #0
	sta xposhi
	jsr random_angle
	lda #1                    ; head back into the screen
	sta xdir
	rts
hit_right:
	lda #39
	sta xpos
	lda #1
	sta xposhi
	jsr random_angle
	lda #0
	sta xdir
	rts

move_y:
	lda ydir
	beq y_up
	clc
	lda ypos
	adc yspeed
	sta ypos
	jmp y_bounds
y_up:
	sec
	lda ypos
	sbc yspeed
	sta ypos
y_bounds:
	lda ypos
	cmp #50
	bcc hit_top
	cmp #220
	bcs hit_bottom
	rts
hit_top:
	lda #50
	sta ypos
	jsr random_angle
	lda #1
	sta ydir
	rts
hit_bottom:
	lda #220
	sta ypos
	jsr random_angle
	lda #0
	sta ydir
	rts

; Pick new horizontal/vertical speeds and directions from timer noise.
random_angle:
	lda $dc04
	and #3
	clc
	adc #1
	sta xspeed
	lda $dc05
	and #3
	clc
	adc #1
	sta yspeed
	lda $dc04
	and #1
	sta xdir
	lda $dc05
	and #1
	sta ydir
	rts

xpos:   !byte 0
xposhi: !byte 0
ypos:   !byte 0
xspeed: !byte 0
yspeed: !byte 0
xdir:   !byte 0
ydir:   !byte 0

; 24x21 blue ball, 3 bytes per row (sprite data occupies 64 bytes).
* = $3000
!byte $00,$00,$00,$00,$00,$00,$00,$18,$00
!byte $00,$3c,$00,$00,$7e,$00,$00,$ff,$00
!byte $01,$ff,$80,$03,$ff,$c0,$03,$ff,$c0
!byte $07,$ff,$e0,$07,$ff,$e0,$07,$ff,$e0
!byte $07,$ff,$e0,$03,$ff,$c0,$03,$ff,$c0
!byte $01,$ff,$80,$00,$ff,$00,$00,$7e,$00
!byte $00,$3c,$00,$00,$18,$00,$00,$00,$00
