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
	
start	call	LED_Setup	    ; Initialisation
	call	Game_setup
gameloop			    ; Infinite game loop
				    ; Writes racket states to registers, then
				    ; writes gamezone state.
	call	Calculate_state	    ; New ball position + racket and goal checks
	btfss	PORTJ, 1	    ; Check for user input
	BRA	P1_nopress	    
	call	leftracket_true	    ; Button 1 pressed
	BRA	output
P1_nopress			    ; Button 1 not pressed
	call	leftracket_false
	btfss	PORTJ, 2	    ; Test button 2
	bra	P2_nopress
	call	rightracket_true    ; Button 2 pressed
	bra	output
P2_nopress			    ; Button 2 not pressed
	call	rightracket_false
	bra	output
output				    
	call	Write_state	    ; Write gamezone state
	call	Output_GRB	    ; Push to LEDs
	call	frame_delay	    ; Wait for next fram - delay length depends
				    ; on variableDelay value
	goto	gameloop	    
	
reset_animation			    ; Called when a goal is scored, flashes 
				    ; central 60 LEDs green and blank.
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





