#include p18f87k22.inc
  
    extern LED_Setup,Output_GRB
	
rst	code	0x0000	; reset vector
	goto	start
	
acs0	udata_acs
numLEDs	    res 1
	
main	code
start	call	LED_Setup		; Sit in infinite loop
	;call	Output_GRB
	goto $
	movlw	.40
	movwf	numLEDs
	call	data_write
	call	Output_GRB
	goto $
	
data_write
	LFSR	FSR0, 0x100
loop1	movlw	b'11110000'
	movwf	POSTINC0 
	decfsz	numLEDs
	goto	loop1
	return
	
	end





