;---------------------------------------------------------
;
; Sprite system. Allocate sprite and stuff..
;
;---------------------------------------------------------
;---------------------------------------------------------
; Init sprite manager.
; params: d0.w	- address in VDP ram to sprite attribute table
;---------------------------------------------------------
sprt_init:
	; Setup sprite hardware and things like that.

	move.w	d0,_sprt_vdp_attrib_addr

	lea		_sprt_free_sprt_stack,a0
;	moveq	#1,d0
	move.w	#79-1,d1
.setup_free_list_loop
	move.w	d1,d0
	addq	#1,d0
	move.b	d0,(a0)+
	dbra.w	d1,.setup_free_list_loop

	moveq	#78,d0
	move.w	d0,_sprt_free_stack_idx

	move.l	#_sprt_render_list,_sprt_render_list_ptr

	rts


;---------------------------------------------------------
; Add a sprite to render this frame.
; params: d0.b - Sprite id to add.
;---------------------------------------------------------
sprt_add_to_render:
	move.l	a0,-(sp)
	move.l	_sprt_render_list_ptr,a0
	move.b	d0,(a0)+
	move.l	a0,_sprt_render_list_ptr
	move.l	(sp)+,a0
	rts


;---------------------------------------------------------
;---------------------------------------------------------
sprt_render:
	; Update the VPD sprite attribute table, or atleast
	; request a DMA to copy local sprite attributes to VDP ram.

	; Update link list in sprite attributes.
	lea		_sprt_render_list,a0
	lea		_sprt_attribute_data,a1	; a1 - address to sprite attributes.
	move.w	#0,d1					; offset to last sprite that is rendered.
	bra.s	.test
.loop
	moveq	#0,d0
	move.b	(a0)+,d0				; Get sprite index to draw
	move.b	d0,SPRT_link(a1,d1.w)	;
	move.w	d0,d1
	lsl.w	#3,d1					; New offset
.test
	cmpa.l	_sprt_render_list_ptr,a0
	bmi.s	.loop

	move.b	#0,SPRT_link(a1,d1.w)	; End render list by writing 0 to link reg.

	; Now that link list is updated, do DMA request.

	move.w	#80*4,d0					; number of WORDS to copy
	moveq	#2,d1						; byte skip after each word write.
	lea		_sprt_attribute_data,a0		; source prt,
	movea.w	_sprt_vdp_attrib_addr,a1	; VDP dest address.
	bsr		dma_ram2vram_req

	; Finally reset the _sprt_render_list_ptr
	move.l	#_sprt_render_list,_sprt_render_list_ptr

	rts


;---------------------------------------------------------
; Allocate sprite
; params: a0.l - Address where sprite id will be stored.
; return: d0.w - Id of allocated sprite
;---------------------------------------------------------
sprt_alloc:

	; Ignore parameter for now, just alloc one.
	move.w	_sprt_free_stack_idx,d1
	bpl.s	.not_empty
	move.w	#0,d0
	rts
.not_empty
	lea		_sprt_free_sprt_stack,a1
	moveq	#0,d0
	move.b	(a1,d1.w),d0
	subq.w	#1,d1
	move.w	d1,_sprt_free_stack_idx
	move.w	d0,(a0)

	rts

;---------------------------------------------------------
; Delloc sprite
; params: d0.w - Sprite to dealloc, no test are made to see
;                if the sprite was already released
;---------------------------------------------------------
sprt_release:
	move.w	_sprt_free_stack_idx,d1
	lea		_sprt_free_sprt_stack,a1
	addq.w	#1,d1
	move.b	d0,(a1,d1.w)
	move.w	d1,_sprt_free_stack_idx

	rts


;---------------------------------------------------------
; Dealloc many sprite
; params: d0.w - Number of sprites to dealloc, no test are
;                made to see if the sprite was already released
;         a0.l - poiner to first sprite to release.
;---------------------------------------------------------
sprt_release_bulk
	movem.l	d0-2/a0,-(sp)
	move.w	_sprt_free_stack_idx,d1
	lea		_sprt_free_sprt_stack,a1
	bra.s	.next
.dealloc:

	addq.w	#1,d1
	move.w	(a0)+,d2
	move.b	d2,(a1,d1.w)
	move.w	d1,_sprt_free_stack_idx
.next:
	subq.w	#1,d0
	bpl.s	.dealloc
	movem.l	(sp)+,d0-2/a0

	rts


;---------------------------------------------------------
; Return address to sprite attribute data in a0
; Params: d0.w	- Sprite id
; Return: a0.l  - Address to sprite attribute data
;---------------------------------------------------------
sprt_get_attribute_ptr:
	move.w	d0,-(sp)
	lsl.w	#3,d0
	lea		_sprt_attribute_data,a0
	lea		(a0,d0),a0
	move.w	(sp)+,d0
	rts

;---------------------------------------------------------
; Structs for sprites:
	rsreset
SPRT_y		rs.w	1		; Low 10 bits used. 128 = first visible col
SPRT_size	rs.b	1		; 0-1 vertical size, 2-3 horizontal size
SPRT_link	rs.b	1		; 0-6 link, 8-9 vertical size, 10-11 horizontal size
SPRT_pandp	rs.w	1		; 0-10 pattern, 11 h-flip, 12 v-flip, 13-14 palt, 15 prio
SPRT_x		rs.w	1		; Low 9 bits used. 128 0 first visible line.
;---------------------------------------------------------
	offset
;---------------------------------------------------------
; Data needed for sprite sub system.

_sprt_vdp_attrib_addr:
	ds.w	1

; stack of free sprite indices-
_sprt_free_stack_idx
	ds.w	1	; free stack index

_sprt_free_sprt_stack:
	ds.b	80
	even


; every frame, the sprites to be rendered is added to this list
; the sprites added first will be rendered on top the the ones
; added later
_sprt_render_list_ptr:
	ds.l	1
_sprt_render_list:
	ds.b	80
	even

; There are 80 hardware sprites, 8 bytes per sprite
_sprt_attribute_data:
	ds.b	80*8
	even
