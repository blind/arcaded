

;----------------------------------------------------
;----------------------------------------------------
; DMA code.
;----------------------------------------------------
dma_init:
	lea		_dma_count,a0
	move.w	#0,(a0)
	rts

dma_execute_queue:
	lea		_dma_count,a0
	move.w	(a0),d0			; Get number of DMAs into d0
	beq.s	.done			; If zero, just exit.
	clr.w	(a0)+			; Clear DMA count for next frame
	lea		VDP_CTRL,a1		; 
	subq.w	#1,d0
.loop

	move.l	(a0)+,(a1)		; Since we know there are 16 bytes to
	move.l	(a0)+,(a1)		; be written for every dma, just
	move.l	(a0)+,(a1)		; write them.
	move.l	(a0)+,(a1)
	dbra.w	d0,.loop
.done
	rts


;----------------------------------------------------
; Add a DMA transfer to the DMA queue
; Parameters:
; d0.w - number of words to copy
; d1.b - byte skip each write
; a0 - source address
; a1 - desitnation address in VRAM
; Scraps registers d0-d2/a0-2
dma_ram2vram_req:

	lea		_dma_count,a2			; 	
	move.w	(a2)+,d2				; current requests in queue.
	cmp.w	#32,d2					; queue is full (TODO: don't hard code)
	beq		.skip

	move.w	d2,d3

	add.w	#1,d2					; Increase count and write back.
	move.w	d2,-2(a2)				; Write back value to _dma_count
	lsl.w	#4,d3
	lea		(a2,d3.w),a2

	; Setup skip count
	move.w	#$8f00,d2				; Skip values register
	move.b	d1,d2
	move.w	d2,(a2)+

	; Setup register write for word count
	move.w	#$9300,d2
	move.b	d0,d2					; Low byte of word count
	swap	d2
	move.w	d0,d2
	lsr.w	#8,d2					; high byte of word count
	ori.w	#$9400,d2

	; swap	d2						; might be needed, test!

	move.l	d2,(a2)+				; write to queue

	; set source address...
	move.l	a0,d0			
	lsr.l	#1,d0					; since we copy words, low bit in address is not used.
	move.w	#$9500,d1				; register $15 write
	move.b	d0,d1

	swap	d1
	move.w	#$9600,d1				; register $16 write
	lsr.w	#8,d0
	move.b	d0,d1

	; might have to swap here to..

	move.l	d1,(a2)+				; write source (low+mid) to queue
	swap	d0
	move.w	#$9700,d1
	move.b	d0,d1
	move.w	d1,(a2)+


	; Setup destination address.
	move.l	a1,d0					; 

	move.w	d0,d1
	rol.w	#2,d1
	swap.w	d0
	move.w	d1,d0
	and.l	#$3fff0003,d0
	ori.l	#$40000080,d0			; VRAM write DMA start command

	move.l	d0,(a2)+				; Destination address.
.skip

	rts



;----------------------------------------------------
	offset
;----------------------------------------------------

_dma_count:
	ds.w	1

_dma_event_buffer:
	ds.b	16*32		; buffer for 32 DMA events every frame.
