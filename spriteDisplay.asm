.INCLUDE "Header.inc"
.INCLUDE "InitSNES.asm"
.INCLUDE "LoadGraphics.asm"

.EQU PalNum $0000

.MACRO Stall
.REPT 3
WAI
.ENDR
.ENDM

.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

Start:
	InitSNES

	rep #$10
	sep #$20

	lda #%00000001
	sta $2105

	;blue background
	stz $2121
	lda #$40
	sta $2122
	sta $2122

	LoadPalette SprPal, 128, 16	;sprite palettes start at
					;color 128
	LoadBlockToVRAM Sprite, $0000, $0800

	jsr SpriteInit

	;lda #($80-16)
	;sta $0000	; sprite x-coordinate
	;lda #(224/2 - 16)
	;sta $0001	;sprite y-coordinate
	;stz $0002	;starting at tile 0 of tileset
	;lda #%01110000	;horizontal flip, top priority
	;sta $0003
	;stz $0000
	;stz $0001
	;stz $0002
	;stz $0003
	lda #8
	sta $0004
	;sta $0005
	lda #%00000010
	sta $0006
	stz $0007

	lda #%00000000	;clear x-msb
	sta $0200

	jsr SetupVideo

	lda #$80
	sta $4200	;Enable NMI

forever:
	Stall
	lda PalNum
	clc
	adc #$01
	and #$FF	;if > palette starting color > 24 (00011100)
	sta PalNum

	jmp forever
;initializes the sprite tables!
SpriteInit:
	php	;push processor status onto stack

	rep #$30	;16 bit A/X/Y

	ldx #$0000
	lda #$01	;prepare loop 1
;puts all sprites offscreen
_offscreen:
	sta $0000, X
	inx
	inx
	inx
	inx
	cpx #$0200	;200 is the size of the first OAM table
	bne _offscreen
	ldx #$0000
	lda #$5555
_clr:
	sta $0200, X	;increases 2 times bc 2 bits per sprite
	inx	;bit1 - enable or disable the x coordinate's 9th bit
		;(which places it off of the screen)
	inx	;bit2 - toggle sprite size: 0 - small, 1 - large
	cpx #$0020	;20 is the size of the OAM table
	bne _clr

	plp

	rts

SetupVideo:
	php
	rep #$10
	sep #$20	;8 bit A, 16 bit X/Y

	;DMA sprite data
	stz $2102
	stz $2103	;set OAM address to 0

;******Transfer sprite data now
	;stz $2102	;set OAM address to 0
	;stz $2103

	ldy #$0400	;writes $00 to $4300, #$04 to $4301
	sty $4300	;cpu->ppu, auto increment, $2104 (OAM write)
	stz $4302
	stz $4303
	ldy #$0220
	sty $4305	;220 bytes to transfer
	lda #$7E
	sta $4304	;CPU address 7E:0000 - work RAM
	lda #$01
	sta $420B

	;lda #%10100000	;32x32 and 64x64 size sprites
			; (We are using a 32x32)
	lda #%00000000	;changed it to 8x8 ;)
	sta $2101

	lda #%00010000	;enable sprites (objects in oam)
	sta $212C

	lda #$0F
	sta $2100	;turn on screen, full brightness

	plp
	rts

VBlank:
	rep #$30	;A/mem = 16 bits, X/Y = 16 bits

	phb
	pha
	phx
	phy
	phd

	sep #$20	;A/mem = 8 bit

	stz $2121
	lda PalNum
	sta $2122
	sta $2122

	lda $4210	;clear NMI flag
	rep #$30

	pld
	ply
	plx
	pla
	plb

	sep #$20
	rti

.ENDS

.BANK 1 SLOT 0
.ORG 0
.SECTION "CharacterData"
Sprite:
	.INCBIN "alphabet.pic"
SprPal:
	.INCBIN "alphabet.clr"
.ENDS
