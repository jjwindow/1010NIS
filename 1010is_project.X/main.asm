#include p18f87k22.inc
  
    extern  LED_Setup,Output_GRB, Write_state, Game_setup, Calculate_state
    extern  delay_256, frame_delay, GREEN_pixeldata, CLEAR_pixeldata
    extern  leftracket_true, leftracket_false, rightracket_true, rightracket_false
    global  reset_animation
    
rst	code	0x0000	; reset vector
	goto	start
	
acs0	udata_acs 0x0
loopcount res 1
 
 
main	code
;--------------------MAIN------------------------	
	
start	call	LED_Setup		; Sit in infinite loop
	call	Game_setup
gameloop
	call	Calculate_state
	btfss	PORTJ, 1
	BRA	P1_nopress
	call	leftracket_true
	BRA	output
P1_nopress
	call	leftracket_false
	btfss	PORTJ, 2
	bra	P2_nopress
	call	rightracket_true
	bra	output
P2_nopress
	call	rightracket_false
	bra	output
output
	call	Write_state
	call	Output_GRB
	call	frame_delay
	goto	gameloop
	
reset_animation
	movlw	.6
	movwf	loopcount
loop1	call	CLEAR_pixeldata ; OUTPUT CLEAN
	call	Output_GRB
	call	frame_delay
	call	GREEN_pixeldata	; OUTPUT GREEN
	call	Output_GRB
	call	frame_delay
	decfsz	loopcount
	goto	loop1		; and LOOP
	return			 ;once looped enough times, return
    end





