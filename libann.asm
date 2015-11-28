
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	This is the main file of the library
;
;	Author: Alexey Lyashko 
;	Site:	syprog.blogspot.com
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




	format ELF64

	include 'types.asm'
	include 'externs.asm'
	include 'publics.asm'
	

section '.text' executable align 16

	include 'neuron.asm'
	include 'synaps.asm'
	include 'net.asm'



section '.data'

	errno	dd	0
