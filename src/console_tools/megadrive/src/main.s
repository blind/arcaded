;---------------------------------------------------------
;
;
;
;

PLANE_A_ADDR	equ	$c000
PLANE_B_ADDR	equ	$e000
PLANE_W_ADDR	equ	$d000
SPR_ATTR_ADDR	equ	$b800
HSCROLL_ADDR	equ	$1400

INP_UP1_BIT		equ	(1<<0)
INP_DOWN1_BIT	equ (1<<1)
INP_LEFT1_BIT	equ (1<<2)
INP_RIGHT1_BIT	equ (1<<3)

INP_A1_BIT		equ (1<<6)
INP_B1_BIT		equ (1<<4)
INP_C1_BIT		equ (1<<5)
INP_START1_BIT	equ (1<<7)

INP_X1_BIT		equ (1<<8)
INP_Y1_BIT		equ (1<<9)
INP_Z1_BIT		equ (1<<10)
INP_MODE1_BIT	equ (1<<11)

FONT_START_TILE	equ	((font_set-tile_set)>>5)

;---------------------------------------------------------
;---------------------------------------------------------
main:
	bsr		dma_init

	move.w	#SPR_ATTR_ADDR,d0
	bsr		sprt_init
	bsr		setup_vdp
	bsr		controller_init


	lea		VDP_BASE,a0
	lea		tile_set,a1
	move.w	#$8f02,4(a0)
	move_vram_addr	0,4(a0)	; Load tileset at VRAM addr 0
.copy_tiles:
	move.w	(a1)+,(a0)
	cmpa.l	#tile_set_end,a1
	blt.s	.copy_tiles

	lea		font_set,a1
	move_vram_addr	FONT_START_TILE*32,4(a0)	; Load tileset at VRAM addr 0
.copy_font:
	move.w	(a1)+,(a0)
	cmpa.l	#font_end,a1
	blt.s	.copy_font


	; Fill plane B with background tile.
	moveq	#7,d1
	move_vram_addr	PLANE_B_ADDR,4(a0)	; Load tileset at VRAM addr 0
	move.w	#(32*32)-1,d0
.fill_plane_b:
	move.w	d1,(a0)
	dbra.w	d0,.fill_plane_b


	; Palette
	lea		VDP_BASE,a1
	move.w	#$8f02,4(a1)	; set auto-increment to 2.
	move.l	#$c0000000,4(a1)
	lea		palette_1,a0
	moveq	#31,d1			; actually copy 32 colors, palette 1 and 2
.copy_loop_palette
	move.w	(a0)+,(a1)
	dbra.w	d1,.copy_loop_palette


	bsr		setup_sprites



	; ----------


	move.l	#my_vbl_rout,d0
	bsr		install_vbi_handler

	move.w	#$2300,sr
; Initialize some

	move.w	#4,readback_delay

;---------------------------------------------------------

main_loop:
	;
	bsr		wait_vbl
	; directly after vbl, we need to start DMA
	bsr		dma_execute_queue
	; then we need to update the VDP registers.
	; --

	bsr		read_controller

	bsr		update_delay

	; ----------
	; Controller 1
	lea		sprite_ids,a2
	move.w	controller_1,d2
	bsr		update_controller_sprites

	; Controller 2
	lea		sprite_ids+24,a2
	move.w	controller_2,d2
	bsr		update_controller_sprites

	; ----------

	bsr		sprt_render
	bra.s	main_loop


;---------------------------------------------------------
;---------------------------------------------------------

; params:
; a0 - address to sprite attribute
; sr - zero bit should be set correctly before jumping here.
colorize_if_zero:
	bne.s	.no_down1
	move.w	SPRT_pandp(a0),d3
	ori.w	#(1<<13),d3
	bra.s	.draw_down1
.no_down1
	move.w	SPRT_pandp(a0),d3
	andi.w	#~(3<<13),d3
.draw_down1
	move.w	d3,SPRT_pandp(a0)
	rts



update_controller_sprites:
; input a2.l - address to first sprite of controller representation
;       d2.w - controller data.

	; up
	move.w	(a2)+,d0
	bsr		sprt_get_attribute_ptr

	move.w	d2,d1
	andi.w	#INP_UP1_BIT,d1
	bsr		colorize_if_zero
	bsr.w	sprt_add_to_render

	; Down
	move.w	(a2)+,d0
	bsr		sprt_get_attribute_ptr
	move.w	d2,d1
	andi.w	#INP_DOWN1_BIT,d1
	bsr		colorize_if_zero

	bsr.w	sprt_add_to_render


	; Left
	move.w	(a2)+,d0
	bsr		sprt_get_attribute_ptr
	move.w	d2,d1
	andi.w	#INP_LEFT1_BIT,d1
	bsr		colorize_if_zero

	bsr.w	sprt_add_to_render


	; Right
	move.w	(a2)+,d0
	bsr		sprt_get_attribute_ptr
	move.w	d2,d1
	andi.w	#INP_RIGHT1_BIT,d1
	bsr.s	colorize_if_zero

	bsr.w	sprt_add_to_render


	; A
	move.w	(a2)+,d0
	bsr		sprt_get_attribute_ptr
	move.w	d2,d1
	andi.w	#INP_A1_BIT,d1
	bsr.s	colorize_if_zero

	bsr.w	sprt_add_to_render

	; B
	move.w	(a2)+,d0
	bsr		sprt_get_attribute_ptr
	move.w	d2,d1
	andi.w	#INP_B1_BIT,d1
	bsr		colorize_if_zero

	bsr.w	sprt_add_to_render


	; C
	move.w	(a2)+,d0
	bsr		sprt_get_attribute_ptr
	move.w	d2,d1
	andi.w	#INP_C1_BIT,d1
	bsr		colorize_if_zero

	bsr.w	sprt_add_to_render


	; Start
	move.w	(a2)+,d0
	bsr		sprt_get_attribute_ptr
	move.w	d2,d1
	andi.w	#INP_START1_BIT,d1
	bsr		colorize_if_zero

	bsr.w	sprt_add_to_render

	; Z
	move.w	(a2)+,d0
	bsr		sprt_get_attribute_ptr
	move.w	d2,d1
	andi.w	#INP_Z1_BIT,d1
	bsr		colorize_if_zero

	bsr.w	sprt_add_to_render

	; Y
	move.w	(a2)+,d0
	bsr		sprt_get_attribute_ptr
	move.w	d2,d1
	andi.w	#INP_Y1_BIT,d1
	bsr		colorize_if_zero

	bsr.w	sprt_add_to_render

	; X
	move.w	(a2)+,d0
	bsr		sprt_get_attribute_ptr
	move.w	d2,d1
	andi.w	#INP_X1_BIT,d1
	bsr		colorize_if_zero

	bsr.w	sprt_add_to_render

	; mode
	move.w	(a2)+,d0
	bsr		sprt_get_attribute_ptr
	move.w	d2,d1
	andi.w	#INP_MODE1_BIT,d1
	bsr		colorize_if_zero

	bsr.w	sprt_add_to_render

	rts


;---------------------------------------------------------
;---------------------------------------------------------
wait_vbl:
	move.w	#1,vbl_flag
.wait
	tst.w	vbl_flag
	bne.s	.wait
	rts


;---------------------------------------------------------
;---------------------------------------------------------

setup_sprites:
	; ----------
	; Setup code

	; Since sprt_alloc is not implemented as planned,
	; we must allocate each sprite manually.
	moveq	#24-1,d4
	lea		sprite_ids,a0
.alloc_sprites
	bsr		sprt_alloc
	addq.w	#2,a0
	dbra.w	d4,.alloc_sprites

	lea	sprite_ids,a2

	; sprite positions controller 1

	lea controller_indicator_sprite_positions,a1
	moveq	#12-1,d4
.sprite_pos_setup
	move.w	(a2)+,d0
	bsr.w	sprt_get_attribute_ptr

	move.w	(a1)+,d0
	add.w	#128,d0
	move.w	d0,SPRT_x(a0)

	move.w	(a1)+,d0
	add.w	#128,d0
	move.w	d0,SPRT_y(a0)

	move.w	(a1)+,SPRT_pandp(a0)

	dbra.w	d4,.sprite_pos_setup


	; sprite positions controller 2

	lea controller_indicator_sprite_positions,a1
	moveq	#12-1,d4
.sprite_pos_setup2
	move.w	(a2)+,d0
	bsr.w	sprt_get_attribute_ptr

	move.w	(a1)+,d0
	add.w	#128+72,d0
	move.w	d0,SPRT_x(a0)

	move.w	(a1)+,d0
	add.w	#128,d0
	move.w	d0,SPRT_y(a0)

	move.w	(a1)+,SPRT_pandp(a0)

	dbra.w	d4,.sprite_pos_setup2
	rts


;----------------------------------------------------
;----------------------------------------------------
; Read controller

read_controller:
	; Controller 1

	movea.l	#$a10003,a0
	bsr.s	read_controller_port

	move.w	controller_1,d1
	move.w	d0,controller_1
	eor.w	d0,d1
	move.w	d1,controller_1_x

	; Controller 2
	movea.l	#$a10005,a0
	bsr.s	read_controller_port

	move.w	controller_2,d1
	move.w	d0,controller_2
	eor.w	d0,d1
	move.w	d1,controller_2_x

	rts


read_controller_port:
	; expects a0 to be setup to point to the correct controller port
	move.b	#0,(a0)			; TH to low...
	nop
	nop
	move.b	(a0),d0			; 00SA00DU
	lsl.w	#8,d0			; make room for BCRL

	move.b	#$40,(a0)		; TH to high -> x1CBRLDU
	nop
	nop
	move.b	(a0),d0			; read

	; read 6 button controller

	move.b	#0,(a0)			; TH to low...
	nop
	nop
	move.b	(a0),d1			; 00SA00DU
	; lsl.w	#8,d1			; make room for BCRL

	move.b	#$40,(a0)		; TH to high -> x1CBRLDU
	nop
	nop
	; move.b	(a0),d1			; read and mask

	; Third time will get the extra buttons
	move.b	#0,(a0)			; TH to low...
	nop
	nop
	move.b	(a0),d2			; 00SA0000
	lsl.w	#8,d1			; make room for BCRL

	move.b	#$40,(a0)		; TH to high -> x1CBmxyz
	nop
	nop
	move.b	(a0),d1			; read and mask

	; Last time, to check if bit 2 and 3 when TH is low is set
	; then we have a 6 button controller

	move.b	#0,(a0)			; TH to low...
	nop
	nop
	move.b	(a0),d2			; 00SA11xx
	lsl.w	#8,d2			; make room for BCRL

	move.b	#$40,(a0)		; TH to high -> x1CBmxyz
	nop
	nop
	move.b	(a0),d2			; read and mask

	andi.w	#$0c00,d2
	bne.s	.yes
	move.w	#-1,d1
.yes
	move.w	d0,d2
	and.w	#$3f,d0
	lsr.w	#6,d2
	andi.w	#$c0,d2
	or.w	d2,d0

	andi.w	#$0f,d1
	lsl.w	#8,d1
	or.w	d1,d0

	rts


controller_init:
	moveq	#$40,d0		; bit mask for controller init.
	; Init code from sgdk, converted to assembler by me.

	lea		$a10009,a0
	move.b	d0,(a0)
	move.b	d0,2(a0)
	move.b	d0,4(a0)

	lea		$a10003,a0
	move.b	d0,(a0)
	move.b	d0,2(a0)
	move.b	d0,4(a0)

    rts

;---------------------------

setup_vdp:
	lea		VDP_CTRL,a1
	lea		vdp_regs,a0
	move.w	#((vdp_regs_end-vdp_regs)/2)-1,d2
.copy_loop:
	move.w	(a0)+,(a1)
	dbra.w	d2,.copy_loop
	rts

; vbl_routine:
my_vbl_rout:
	clr.w	vbl_flag
	rte

;---------------------------------------------------------
;---------------------------------------------------------
update_delay:

	move.w	controller_1,d1

	andi.w	#INP_START1_BIT,d1
	bne.s	.draw_text

	move.w	controller_1_x,d0
	move.w	d0,d1
	andi.w	#INP_UP1_BIT,d1
	beq.s	.no_up_change
	move.w	controller_1,d1
	andi.w	#INP_UP1_BIT,d1
	bne.s	.no_up_change

	addi.w	#1,readback_delay

.no_up_change
	andi.w	#INP_DOWN1_BIT,d0
	beq.s	.draw_text			; no change in down
	moveq	#INP_DOWN1_BIT,d1
	and.w	controller_1,d1
	bne.s	.draw_text

	subi.w	#1,readback_delay

.draw_text
	; TODO: Update text on screen.

	lea		char_lut,a1
	lea		VDP_BASE,a0
	move.w	#$8f02,4(a0)
	move_vram_addr	PLANE_A_ADDR+(32*10+10)*2,4(a0)

	move.w	readback_delay,d0
	rol.w	#4,d0
	move.w	d0,d1
	andi.w	#$f,d1
	add.w	d1,d1
	move.w	(a1,d1.w),(a0)

	rol.w	#4,d0
	move.w	d0,d1
	andi.w	#$f,d1
	add.w	d1,d1
	move.w	(a1,d1.w),(a0)

	rol.w	#4,d0
	move.w	d0,d1
	andi.w	#$f,d1
	add.w	d1,d1
	move.w	(a1,d1.w),(a0)

	rol.w	#4,d0
	move.w	d0,d1
	andi.w	#$f,d1
	add.w	d1,d1
	move.w	(a1,d1.w),(a0)

	rts


char_lut:
	dc.w	'0'+FONT_START_TILE-' '
	dc.w	'1'+FONT_START_TILE-' '
	dc.w	'2'+FONT_START_TILE-' '
	dc.w	'3'+FONT_START_TILE-' '
	dc.w	'4'+FONT_START_TILE-' '
	dc.w	'5'+FONT_START_TILE-' '
	dc.w	'6'+FONT_START_TILE-' '
	dc.w	'7'+FONT_START_TILE-' '
	dc.w	'8'+FONT_START_TILE-' '
	dc.w	'9'+FONT_START_TILE-' '
	dc.w	'A'+FONT_START_TILE-' '
	dc.w	'B'+FONT_START_TILE-' '
	dc.w	'C'+FONT_START_TILE-' '
	dc.w	'D'+FONT_START_TILE-' '
	dc.w	'E'+FONT_START_TILE-' '
	dc.w	'F'+FONT_START_TILE-' '


;---------------------------------------------------------
;---------------------------------------------------------
;---------------------------------------------------------
; This would be section data on any other platform.
;---------------------------------------------------------

palette_1:
	dc.w	$000, $eee, $666, $ee0,$e00,$0e0,$0ee,$00e
	dc.w	$aa, $e8e, $20e, $660,$e66,$6e0,$0e6,$66e


palette_2:
	dc.w	$000, $e6e, $e0e, $ee0,$e00,$0e0,$0ee,$00e
	dc.w	$aa, $e8e, $20e, $660,$e66,$6e0,$0e6,$66e


tile_set:

	ds.l	8

	; 1
	dc.l	$00010000
	dc.l	$00110000
	dc.l	$01110000
	dc.l	$11111110
	dc.l	$01110000
	dc.l	$00110000
	dc.l	$00010000
	dc.l	$00000000

	dc.l	$00010000
	dc.l	$00111000
	dc.l	$01111100
	dc.l	$11111110
	dc.l	$00010000
	dc.l	$00010000
	dc.l	$00010000
	dc.l	$00000000

	dc.l	$00111000
	dc.l	$01101100
	dc.l	$11000110
	dc.l	$11111110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$00000000

	dc.l	$11111000
	dc.l	$11001100
	dc.l	$11000110
	dc.l	$11111100
	dc.l	$11000110
	dc.l	$11001110
	dc.l	$11111000
	dc.l	$00000000

	dc.l	$01111100
	dc.l	$11100110
	dc.l	$11000000
	dc.l	$11000000
	dc.l	$11000000
	dc.l	$11100110
	dc.l	$01111100
	dc.l	$00000000

	dc.l	$01111100
	dc.l	$11000110
	dc.l	$11000000
	dc.l	$01111100
	dc.l	$00000110
	dc.l	$11000110
	dc.l	$01111100
	dc.l	$00000000

	; 7 is background
	dc.l	$22220000
	dc.l	$22220000
	dc.l	$22220000
	dc.l	$22220000
	dc.l	$00002222
	dc.l	$00002222
	dc.l	$00002222
	dc.l	$00002222


	; 8,9,10 is XYZ, 11 is mode

	dc.l	$11000110
	dc.l	$11000110
	dc.l	$01101100
	dc.l	$00111000
	dc.l	$01101100
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$00000000

	dc.l	$11000110
	dc.l	$11000110
	dc.l	$11000110
	dc.l	$01101100
	dc.l	$00111000
	dc.l	$00111000
	dc.l	$00111000
	dc.l	$00000000

	dc.l	$11111110
	dc.l	$00001100
	dc.l	$00011000
	dc.l	$00110000
	dc.l	$01100000
	dc.l	$11000000
	dc.l	$11111110
	dc.l	$00000000

	dc.l	$00000000
	dc.l	$00000000
	dc.l	$00000000
	dc.l	$01101100
	dc.l	$10010010
	dc.l	$10010010
	dc.l	$10010010
	dc.l	$00000000



font_set:
	incbin	font.bin
font_end:

tile_set_end:

controller_indicator_sprite_positions:
	;        x   y   pattern
	dc.w	32,24,2	 		; Up
	dc.w	32,40,2|(1<<12)	; Down
	dc.w	24,32,1			; Left
	dc.w	40,32,1|(1<<11)	; Right

	dc.w	56,32,3			; A
	dc.w	64,32,4			; B
	dc.w	72,32,5			; C

	dc.w	56,16,6			; Start

	dc.w	56,42,8			; X
	dc.w	64,42,9			; Y
	dc.w	72,42,10		; Z

	dc.w	66,16,11		; Mode


; http://md.squee.co/wiki/VDP
vdp_regs:
	dc.w	$8004		; mode register 1 - DMA enabled
	dc.w	$8174		; mode register 2 - Display enable bit set ($40) + VBI ($20)
	dc.w	$8200+(PLANE_A_ADDR>>10)	; plane a table location
	dc.w	$830c						; window table location -  VRAM:$3000
	dc.w	$8400+(PLANE_B_ADDR>>13)	; plane b table location
	dc.w	$8500+(SPR_ATTR_ADDR>>9)	; sprite table location
	dc.w	$8600						; sprite pattern generator base addr.
						; (should be 0, only used on modified machines with more VRAM)
	dc.w	$8704		; backgroud colour,  (reg 7)
	dc.w	$8a00		; HBL IRQ controller
	dc.w	$8b02		; Mode register 3
	dc.w	$8c00		; mode register 4 (32 cells wide display)
	dc.w	$8d05		; HBL scroll data location (VRAM:$1400)
	dc.w	$8e00		; nametable pattern gen base addr.
	dc.w	$8f02		; auto-increment value
	dc.w	$9000		; plane size 00 -> 32*32 cells.
	dc.w	$9100		; window plane h-pos
	dc.w	$9200		; window place v-pos
vdp_regs_end:



;---------------------------------------------------------
; RAM  - only ds.? allowed here, like section bss
;---------------------------------------------------------
	offset
;---------------------------------------------------------

vbl_flag:		ds.w	1

controller_1	ds.w	1
controller_1_x	ds.w	1
controller_2	ds.w	1
controller_2_x	ds.w	1

readback_delay	ds.w	1

sprite_ids
	ds.w	24		; 12 buttons per 6-btn controller.



