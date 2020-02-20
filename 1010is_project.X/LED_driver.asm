#include p18f87k22.inc

    global  LED_Setup, Output_GRB

acs0	udata_acs

BRIGHTNESS	res 3
bitcount	res 1
bytecount	res 1
pixelcount	res 1
longdelaycount	res 1
current_address res 1
_GREEN		res 1
_RED		res 1
_BLUE		res 1
_byte		res 1
_PIXELDATA	res 3
	
	
LEDs	code
    
LED_Setup
	clrf	TRISE ;// +1
	clrf	PORTE ;// +1
	clrf	TRISH ;// +1
	clrf	PORTH ;// +1
	bcf	PORTE, 0  ;//+1 ; READY PIN E0 FOR OUTPUT
	;call	CLEAR_pixeldata
	;call	Output_GRB
	call	RESET_pixeldata
	call	Output_GRB
	return
	
	
	
RESET_pixeldata
	banksel	_PIXELDATA
	;movff	POSTINC0, _PIXELDATA+0
	;movff	POSTINC0, _PIXELDATA+1
	;movff	POSTINC0, _PIXELDATA+2
	movlw	.60 ;//+ 1 ;value of 50/255
	movwf	_PIXELDATA+0 ;//+1
	movlw	.220 ;//+ 1 ;value of 50/255
	movwf	_PIXELDATA+1 ;//+1
	movlw	.20 ;//+ 1 ;value of 50/255
	movwf	_PIXELDATA+2 ;//+1
	return
	
CLEAR_pixeldata
	banksel	_PIXELDATA
	movlw	b'00000000' ;//+ 1 ;value of 50/255
	movwf	_PIXELDATA+0 ;//+1
	movlw	b'00000000' ;//+ 1 ;value of 50/255
	movwf	_PIXELDATA+1 ;//+1
	movlw	b'00000000' ;//+ 1 ;value of 50/255
	movwf	_PIXELDATA+2 ;//+1
	return 

Output_GRB
	movlw	.70 ;// RESET PIXEL COUNT
	movwf	pixelcount
	bcf	INTCON,GIE ;// +1 ;disable interrupts 
loop1	
	call	send_pixel ;// +1 ; move to loop - send all data
	decfsz	pixelcount
	bra	loop1
	call	delay_rst  ;// +2 ; refresh flag
	bsf	INTCON,GIE ;// +1 ; (*) re-enable interrupts
	return	    



Send_1
	; 0.8us HI, 0.45us LO 
	; 20 instructions TOTAL (after bsf)
	bsf	PORTE, 0
	call	delay_.8    ; 12 instruction delay		    
	bcf	PORTE, 0    ; 12 instructions -> 13 instructions, lo pulse sent
	NOP
	NOP
	NOP
	NOP
	return
	
Send_0
	; 0.4us HI, 0.85us LO 
	; 20 instructions TOTAL (after bsf)
	bsf	PORTE, 0
	call	delay_.4		    
	bcf	PORTE, 0    ; 6 instruction delay -> 7 instruction delay, lo pulse sent
	call	delay_.85	    ; End hi
	return
	
	

send_pixel
	movlw	.24	   ;// +1 ; reset bit counter
	movwf	bitcount   ;// +1
loop2	btfsc	_PIXELDATA+0, 7 ; check MSB of working byte
	bra	no_skip		; if 1 - send 1
	call	Send_0		; if 0 - send 0
	bra	skip
no_skip	call	Send_1
skip	; then rotate the working byte (load next bit)
	bcf	STATUS, C
	rlcf	_PIXELDATA+0 
	rlcf	_PIXELDATA+1
	rlcf	_PIXELDATA+2 
	decfsz	bitcount	; decrement bit counter
	goto	loop2	; if bit counter is not zero then loop
	return   ;// + 2 ; send byte

		
;send_byte	
;	btfsc	_byte, 7 ; check MSB of working byte
;	bra	no_skip		; if 1 - send 1
;	call	Send_0		; if 0 - send 0
;	bra	skip
;no_skip	call	Send_1
;skip	rlncf	_byte, 1	; then rotate the working byte (load next bit)
;	;movff	_byte, PORTH
;	decfsz	bitcount	; decrement bit counter
;	goto	send_byte	; if bit counter is not zero then loop
;	return

	
	
	
;//DELAY ROUTINES
delay_.4
	NOP		; 6 instruction delay
	NOP		; req'd delay/time per instruction = 400ns/62.5ns 
	NOP		; = 6.4 (+/- 2) instructions.
	NOP
	return
	
delay_.8
	call	delay_.4    ; instructions 2-7
	NOP
	NOP
	NOP
	NOP
	return
	
delay_.85
	call	delay_.4    ; instructions 9 - 14
	call	delay_.4    ; instructions 14 - 20 
	return
	
delay_256
	movlw	0x00
	movwf	longdelaycount	
iter	decfsz	longdelaycount
	goto	iter
	return
	
delay_rst
	call	delay_256
	call	delay_256
	return
	
	
;//END
 end



