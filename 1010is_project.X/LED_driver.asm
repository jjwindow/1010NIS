#include p18f87k22.inc

    global  LED_Setup, Output_GRB
    extern  CLEAR_pixeldata

acs1	udata_acs 0x10

BRIGHTNESS	res 3
bitcount	res 1
bytecount	res 1
pixelcount	res 1
longdelaycount	res 1
Wbyte		res 1
_PIXELDATA	res 3
loopcount	res 1
	
	
LEDs	code
   
;-------------------------------SETUP-------------------------------------------
LED_Setup
	clrf	TRISE 
	bcf	PORTE, 0  ; READY PIN E0 FOR OUTPUT
	call	CLEAR_pixeldata
	call	Output_GRB
	return
	
;---------------------------WRITE STATES TO LEDs--------------------------------

Output_GRB
	LFSR	FSR0, 0x100
	movlw	.210		; RESET BYTE COUNT (70px * 3 bytes)
	movwf	bytecount
	bcf	INTCON,GIE	;disable interrupts for continuous transmission 
loop1	
	movff	POSTINC0, Wbyte
	call	send_byte
	decfsz	bytecount, 1
	bra	loop1
	call	delay_rst	; refresh signal (50 microsec delay)
	bsf	INTCON,GIE	; re-enable interrupts
	return
send_byte
	movlw	.8
	movwf	bitcount	; reset bit counter
loop5
	banksel Wbyte
	BTFSC	Wbyte, 7	; check MSB of working byte
	bra	no_skip		; if 1 - send 1
	call	Send_0		; if 0 - send 0
	bra	skip
no_skip	call	Send_1
skip	RLNCF	Wbyte, F	; then rotate the working byte (load next bit)
	movff	Wbyte, PORTH
	decfsz	bitcount, 1, 0	; decrement bit counter
	goto	loop5		; if bit counter is not zero then loop
	return
Send_1
	; 0.8us HI, 0.45us LO 
	; 20 instructions TOTAL (after bsf)
	; TESTED WITH OSCILLOSCOPE - TIMINGS NOT ACCURATE
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
	

;-----------------------------------DELAYS--------------------------------------
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
	
	
;---------------------------------END-------------------------------------------
 end



