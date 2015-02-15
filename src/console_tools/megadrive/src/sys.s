; MD HEADER

;STACK	equ		$00fffe00
STACK	equ		$01000000

; Initial stack pointer
	dc.l	STACK
; Initial program counter
	dc.l	start
; $08 - Bus error  
	dc.l	bus_or_addr_exeption_handler
; $0C - Address error 
	dc.l	bus_or_addr_exeption_handler
; $10 - Illegal instruction 
	dc.l	exception_handler
; $14 - Divistion by zero
	dc.l	exception_handler
; $18 - CHK exception
	dc.l	exception_handler
; $1C - TRAPV exception 
	dc.l	exception_handler
; $20 - Privilege violation 
	dc.l	priv_viol_exception_handler
; $24 - TRACE exeption  
	dc.l	exception_handler
; $28 - LINE 1010 EMULATOR  
	dc.l	exception_handler
; $2C - LINE 1111 EMULATOR  
	dc.l	exception_handler
; $30-$5F - Reserved by Motorola  
	ds.b	48 ; reserved bytes.
	
; $60 - Spurious exception 
	dc.l	irq_handler
; $64 - Interrupt request level 1  
	dc.l	irq_handler
; $68 - Interrupt request level 2  
	dc.l	irq_handler
; $6C - Interrupt request level 3  
	dc.l	irq_handler
; $70 - Interrupt request level 4 (VDP interrupt / Horizontal blank)  
	dc.l	hbi_handler
; $74 - Interrupt request level 5  
	dc.l	irq_handler
; $78 - Interrupt request level 6 (Vertical blank)  
	dc.l	vbi_handler
; $7C - Interrupt request level 7  
	dc.l	irq_handler

; $80 - TRAP #0-15 exception handler
	REPT 16
	dc.l	trap_handler
	ENDR

; $C0-$FF - Reserved by Motorola
	ds.b	64		; 64 bytes reserved


; $100-$10F - Console name (usually 'SEGA MEGA DRIVE ' or 'SEGA GENESIS    ')
	dc.b	'SEGA MEGA DRIVE '

; $110-$11F - Release date (usually '(C)XXXX YYYY.MMM' 
;            where XXXX is the company code, YYYY is the year and MMM - month)
	dc.b	'(C)DEMI 2014.DEC'
; $120-$14F - Domestic name  (48 bytes)
	dc.b	'Hero woduru, Mega Drive                         '

; $150-$17F - International name (48 bytes)
	dc.b	'Hello world, Mega Drive                         '

; $180-$18D - Version ('XX YYYYYYYYYYYY' where XX is the game type and YY the game code)
	dc.b	'GM 01234567891'
; $18E-$18F - Checksum (for info how to calculate checksum go HERE)
	dc.w	$0000	; <- put checksum here in post build process.

; $190-$19F - I/O support
	ds.b	 16	; Unused bytes?

; $1A0-$1A3 - ROM start 
	dc.l	0
; $1A4-$1A7 - ROM end
	dc.l	end_of_rom-1		; 128K rom size

; $1A8-$1AB - RAM start (usually $00FF0000)
	dc.l	$00FF0000
; $1AC-$1AF - RAM end (usually $00FFFFFF)
	dc.l	$00FFFFFF

; $1B0-$1B2 - 'RA' and $F8 enables SRAM.
	dc.b	'AR',$f8
; $1B3      - unused ($20)
	dc.b	$20
; $1B4-$1B7 - SRAM start (default $00200000)
	dc.l	$00200000
; $1B8-$1BB - SRAM end (default $0020FFFF)
	dc.l	$0020FFFF
; $1BC-$1FF - Notes (unused)
	ds.b	52
	dc.b	'JUE             '



	; Try to set background color or something...

VDP_BASE	equ	$c00000
VDP_DATA	equ	VDP_BASE
VDP_CTRL	equ	VDP_BASE+4

;	section text
;-------------------------------
start:

	move.w	#$2700,sr
	move.l	$a10008,d0	; Reset test.
	or.w	$a1000c,d0
	bne.s	.softreset

	move.b	$a10001,d0		; Version 
	andi.b	#$0f,d0			; is low byte zero?
	beq.s	.softreset		; yes, skip unlocking of VDP
	move.l  #'SEGA',$a14000
.softreset

	lea		VDP_BASE,a0
	moveq	#0,d0
	move.w	#$8f02,4(a0)		; update VDP addres by two each write 
	moveq	#$3f,d7				; counter = 64
	move.l	#$c0000000,4(a0)	; write to CRAM
.clear_cram
	move.w	d0,(a0)
	dbra.w	d7,.clear_cram

	move.w	#$3fff,d7
	move.l	#$40000000,4(a0)	; write to VRAM addr 0.
	move.l	#$ff0000,a1
.clear_vram_and_mem:
	move.l	d0,(a0)
	move.l	d0,(a1)+
	dbra.w	d7,.clear_vram_and_mem

	lea		dummy_handler,a0
	move.w	#$4ef9,d0			; JMP.l instruction
	move.w	d0,vbl_handler-2
	move.l	a0,vbl_handler

	move.w	d0,hbl_handler-2
	move.l	a0,hbl_handler

	jsr		main



_exit:
	bra.s	_exit


;---------------------------
install_hbi_handler:
	move.l	d0,hbl_handler
	rts


;---------------------------
install_vbi_handler:
	move.l	d0,vbl_handler
	rts

;---------------------------
vbi_handler:
	jmp		vbl_handler-2

;---------------------------
hbi_handler:
	jmp		hbl_handler-2

priv_viol_exception_handler:
	bra.s	exception_handler
;---------------------------
trap_handler:
	move.l	a0,-(sp)
	andi.w	#~$2000,4(sp)
	move.l	#$ffff00,a0
	move.l	a0,usp
	move.l	(sp)+,a0
	rte

;---------------------------
irq_handler:
	rte

;---------------------------
bus_or_addr_exeption_handler
	move.w	(sp)+,d0	; 	function code
	move.l	(sp)+,d1	; access address
	move.w	(sp)+,d2	; instruction register

exception_handler:
	stop	#$2700
	bra.s	exception_handler



;---------------------------
dummy_handler:
	rte
;---------------------------

;---------------------------------------------------------
;---------------------------------------------------------
; RAM  - only ds.? allowed here.
; This is the only instance of offset where a value 
; should be used.
;---------------------------------------------------------
	offset $ff0000
;---------------------------------------------------------
; Start with some interrupt function pointers.
; Since the vectors are in ROM, we need these
; to be able the change handlers in runtime.
; For speed and stuff, the handler must contain the 
; full jmp instruction (for simplicity)

; $4e79 followed by (address)

	ds.w	1		; $4e79
vbl_handler:	ds.l	1
	ds.w	1		; $4e79
hbl_handler:	ds.l	1



