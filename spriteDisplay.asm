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

	lda #%00001001
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

	lda #(80-16)
	sta $4200	;Enable NMI

forever:
	Stall
	lda PalNum
	clc
	adc #$01
	and #$FF	;if > palette starting color > 24 (00011100)
	sta PalNum

	jmp forever

SpriteInit:
	php	;push processor status onto stack

	rep #$30	;16 bit A/X/Y

	ldx #$0000
	lda #$01	;prepare loop 1

_offscreen:
	sta $0000, X
	inx
	inx
	inx
	inx
	cpx #$0200
	bne _offscreen
	ldx #$0000
	lda #$5555
_xmsb:
	sta $0000, X
	inx
	inx
	cpx #$0220
	bne _xmsb

	plp
	rts

;formula for displaying sprite in middle of screen:
;	(screen/2 - half_sprite)
	lda #(256/2 - 16)	;256 width screen resolution
	sta $0000		;sprite x-coordinate
	lda #(224/2 - 16)	;224 height screen resolution
	sta $0001		;sprite y-coordinate

	; $0002 and $0003 are already set to 0, which we want,
	; (use palette 0, no sprite flip, and no priority

	lda #%01010100		;clear X-MSB
	sta $0200

SetupVideo:
	rep #$10
	sep #$20	;8 bit A, 16 bit X/Y

	;DMA sprite data
	stz $2102
	stz $2103	;set OAM address to 0

	ldy #$0400	;writes $00 to $4300, #$04 to $4301
	sty $4300	;cpu->ppu, auto increment, $2104 (OAM write)
	stz $4302
	stz $4303
	lda #$7E
	sta $4304	;CPU address 7E:0000 - work RAM
	ldy #$0220
	sty $4305	; #$220 bytes to transfer
	lda #$01
	sta $420B

	lda #%10100000	;32x32 and 64x64 size sprites
			; (We are using a 32x32)
	sta $2101

	lda #%00010000	;enable sprites
	sta $212C

	lda #$0F
	sta $2100	;turn on screen, full brightness

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
	.INCBIN "biker.pic"
SprPal:
	.INCBIN "biker.clr"
.ENDS
