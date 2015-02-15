
	include "macros.i"
	section text
	include 'sys.s'

	section text
	include 'main.s'

	section text
	include 'sprt.s'

	section text
	include 'dma.s'

	org	$20000
; don't put anyting here!
end_of_rom:
