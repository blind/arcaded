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
.copy_loop:
	move.w	(a1)+,(a0)
	cmpa.l	#tile_set_end,a1
	blt.s	.copy_loop


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

;---------------------------------------------------------

main_loop:
	; 
	bsr		wait_vbl
	; directly after vbl, we need to start DMA
	bsr		dma_execute_queue
	; then we need to update the VDP registers.
	; --

	bsr		read_controller

	; ----------
	; Controller 1 
	lea		sprite_ids,a2
	move.w	controller_1,d2
	bsr		update_controller_sprites

	; Controller 2
	lea		sprite_ids+20,a2
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

	; Since sprt_alloc is not implemented correctly, 
	; we must allocate each sprite manually.
	moveq	#24-1,d4
	lea		sprite_ids,a0
.alloc_sprites
	move.w	#12*2,d0
	bsr		sprt_alloc
	addq.w	#2,a0
	dbra.w	d4,.alloc_sprites


	lea	sprite_ids,a2

	; sprite positions controller 1

	lea controller_indicator_sprite_positions,a1
	moveq	#10-1,d4
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
	moveq	#10-1,d4
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
; Code copied from interwebs, haven't read up on 
; _how_ it works, it just does.
read_controller:
	; Controller 1

	movea.l	#$a10003,a0
	move.b	#0,(a0)			; TH to low...
	move.w	#$0030,d1		; mask all but Start and A
	nop
	nop
	and.b	(a0),d1			; 00SA00DU 
	lsl.w	#2,d1			; make room for BCRL

	move.b	#$40,(a0)		; TH to high -> x1CBRLDU
	move.w	#$003f,d0		; mask	
	nop
	nop
	and.b	(a0),d0			; read and mask
	or.w	d1,d0

	move.w	d0,controller_1

	; Controller 2

	movea.l	#$a10005,a0
	move.b	#0,(a0)			; TH to low...
	move.w	#$0030,d1		; mask all but Start and A
	nop
	nop
	and.b	(a0),d1			; 00SA00DU 

	move.b	#$40,(a0)		; TH to high -> x1CBRLDU
	move.w	#$003f,d0		; mask	
	lsl.w	#2,d1			; make room for BCRL
	nop
	and.b	(a0),d0			; read and mask
	or.w	d1,d0

	move.w	d0,controller_2


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

	dc.l	$22220000
	dc.l	$22220000
	dc.l	$22220000
	dc.l	$22220000
	dc.l	$00002222
	dc.l	$00002222
	dc.l	$00002222
	dc.l	$00002222

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



tile_set_end:

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
	dc.w	$8c00		; mode register 4 (320 wide display)
	dc.w	$8d05		; HBL scroll data location (VRAM:$1400)
	dc.w	$8e00		; nametable pattern gen base addr.
	dc.w	$8f02		; auto-increment value
	dc.w	$9001		; plane size
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
controller_2	ds.w	1

sprite_ids
	ds.w	24		; 12 buttons per 6-btn controller.



