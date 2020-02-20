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
loopcount	res 1
	
	
LEDs	code
    
LED_Setup
	clrf	TRISE ;// +1
	clrf	PORTE ;// +1
	clrf	TRISH ;// +1
	clrf	PORTH ;// +1
	bcf	PORTE, 0  ;//+1 ; READY PIN E0 FOR OUTPUT
	call	CLEAR_pixeldata
	call	write_states
	call	Output_GRB
	return
	
write_states
	LFSR	FSR0, 0x100
	movlw	.35
	movwf	loopcount
loop3	call	send_red
	call	send_blue
	;decfsz	numLEDs
	decfsz	loopcount
	goto	loop3
	return	
send_red
	movlw	0xF0 ;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	movlw	0xFF;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	movlw	0x00 ;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	return
send_blue
	movlw	0x00 ;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	movlw	0x00;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	movlw	0xFF ;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	return
	
	
CLEAR_pixeldata
	LFSR	FSR0, 0x100
	movlw	.70
	movwf	pixelcount
loop4	call	send_blank
	;decfsz	numLEDs
	decfsz	pixelcount
	goto	loop4
	return
send_blank
	movlw	0x00 ;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	movlw	0x00;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	movlw	0x00 ;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	return

Output_GRB
	LFSR	FSR0, 0x100
	movlw	.210 ;// RESET BYTE COUNT
	movwf	bytecount, 0
	bcf	INTCON,GIE ;// +1 ;disable interrupts 
loop1	
	movff	POSTINC0, _byte
	call	send_byte
	decfsz	bytecount, 1
	bra	loop1
	call	delay_rst  ;// +2 ; refresh flag
	bsf	INTCON,GIE ;// +1 ; (*) re-enable interrupts
	return
send_byte
	movlw	.8
	movwf	bitcount ;reset bit counter
loop5
	BTFSC	_byte, 7 ; check MSB of working byte
	bra	no_skip		; if 1 - send 1
	call	Send_0		; if 0 - send 0
	bra	skip
no_skip	call	Send_1
skip	RLNCF	_byte, 1	; then rotate the working byte (load next bit)
	movff	_byte, PORTH
	decfsz	bitcount, 1, 0	; decrement bit counter
	goto	loop5	; if bit counter is not zero then loop
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
	
	

;send_pixel
;	movlw	.24	   ;// +1 ; reset bit counter
;	movwf	bitcount   ;// +1
;loop2	btfsc	_PIXELDATA+0, 7 ; check MSB of working byte
;	bra	no_skip		; if 1 - send 1
;	call	Send_0		; if 0 - send 0
;	bra	skip
;no_skip	call	Send_1
;skip	; then rotate the working byte (load next bit)
;	bcf	STATUS, C
;	rlcf	_PIXELDATA+0 
;	rlcf	_PIXELDATA+1
;	rlcf	_PIXELDATA+2 
;	decfsz	bitcount	; decrement bit counter
;	goto	loop2	; if bit counter is not zero then loop
;	return   ;// + 2 ; send byte

		
;send_byte	
;	btfsc	_byte, 7 ; check MSB of working byte
;	bra	no_skip		; if 1 - send 1
;	call	Send_0		; if 0 - send 0
;	bra	skip
;no_skip	call	Send_1
;skip	rlncf	_byte, 1	; then rotate the working byte (load next bit)
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



