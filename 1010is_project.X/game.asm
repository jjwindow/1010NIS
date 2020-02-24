#include p18f87k22.inc

    global  Write_state, CLEAR_pixeldata, Game_setup, Calculate_state
    

acs2	udata_acs 0x20

ball_VEL    res 1
workingVEL  res 1
ball_POS    res 1
ball_DIR    res 1
poscount    res 1
pixelcount  res 1
bytecount   res 1
loopcount   res 1
movecount   res 1
P1_score    res 1
P2_score    res 1

   
GAME code

; -------------------------------SET UP -------------------------------------
Game_setup
	CLRF	P1_score
	CLRF	P2_score
	call	CLEAR_pixeldata
	call	DrawLeftGoal
	call	DrawRightGoal
reset_state
	movlw	.65
	movwf	ball_POS
	movlw	b'10000000'
	movwf	ball_VEL
	BCF	ball_DIR, 7 ;NEG INITIAL
	return
	
;------------------------------DRAW GOALS---------------------------------------
DrawLeftGoal
	LFSR	FSR0, 0x0F4 ; point to initial address
	call	writeGOAL
	return
DrawRightGoal
	LFSR	FSR0, 0x1BA
	call	writeGOAL
	return
writeGOAL ; this writes a sequence of 4 yellow pixels for the endzone
	call	send_yellow
	call	send_yellow
	call	send_yellow
	call	send_yellow
	movlw	.4 ;then decrements the pixelcount and positioncount by 4
	subwf	pixelcount
	subwf	poscount
	return
	
;------------------------------CALCULATE GAME STATE-----------------------------
Calculate_state
	movlw	.0
	movwf	movecount   ;initially set the movecount to zero
	movff	ball_VEL, workingVEL
Check_Magnitude
	incf	movecount	    ;increment movecount
	BTFSC	workingVEL, 7	    ;check current bit of velocity
	bra	Check_Direction	    ;if NOT CLEAR (i.e. the 1 has been found) - then Update Position based on movecount
	rlcf	workingVEL, 1	    ;load next bit
	goto	Check_Magnitude	    ;loop again, check next bit
Check_Direction
	BTFSC	ball_DIR, 7
	bra	Positive	    ; MSB = 1 - direction is POSITIVE
	bra	Negative	    ; MSB = 0 - direction is NEGATIVE
Positive ;add movecount to POS
	movff	movecount, WREG
	addwf	ball_POS
	bra	check_G1
Negative ;subtract movecount from POS
	movff	movecount, WREG
	subwf	ball_POS
	bra	check_G1
check_G1 ; here we need to check if the new position is in the first foal
	movlw	.0
	CPFSLT	ball_POS    ; check if ball_position is in GOAL1
	bra	check_G2   ; if not in goal 1 - check goal 2
	bra	GOAL1	    ; if is in goal 1 - then process goal
check_G2 ; here we need to check if the new position is in the second goal
	movlw	.70
	CPFSGT	ball_POS ; check if ball_position is in GOAL2
	bra	end_state
	bra	GOAL2
GOAL1	; ball in goal 1 - so Player 2 has scored
	incf	P2_score 
	bra	resetgame
GOAL2	; ball in goal 2 - so Player 1 has scored
	incf	P1_score
	bra	resetgame
resetgame ; resets the game state if a goal has been scored
	call	reset_state
end_state ; returns
	return
	
	
;----------------------------------PUSH GAME STATE -------------------------------------	
Write_state
	LFSR	FSR0, 0x100 ; point to initial address
	movlw	.60
	movwf	pixelcount  ;60 internal pixels total
	movff	ball_POS, poscount
loop3	
	movlw	.0
	CPFSGT	poscount    ; check if we are at the ball pixel
	bra	BALL	    ; if ball is here - go to service routine
	call	send_blank  ; if ball is not here - send blank
	bra	checks_END
BALL	
	call	send_red   ; send red pixel for the ball pixel
checks_END
	decf	poscount
	decfsz	pixelcount
	goto	loop3
	return		    ; entire state has been written	


	
	
;------------------------------COLOUR CODES -------------------------------	
send_red
	movlw	0x00 ;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	movlw	0xBC;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	movlw	0x00 ;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	return
send_blue
	movlw	0xFF ;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	movlw	0x00;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	movlw	0xFB ;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	return
send_green
	movlw	0xA1 ;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	movlw	0x00;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	movlw	0x11 ;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	return
send_yellow
	movlw	0xF0 ;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	movlw	0xFF;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	movlw	0x00 ;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	return
send_pink
	movlw	0x00 ;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	movlw	0xFF;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	movlw	0xDC ;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	return
send_blank
	movlw	0x00 ;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	movlw	0x00;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	movlw	0x00 ;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	return	
send_white
	movlw	0xFF ;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	movlw	0xFF;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	movlw	0xFF ;//+ 1 ;value of 50/255
	movwf	POSTINC0 ;//+1
	return	
	

;--------------------CLEAR PIXEL DATA------------------------------------
CLEAR_pixeldata
	LFSR	FSR0, 0x0F4
	movlw	.70
	movwf	pixelcount
loop4	call	send_blank
	;decfsz	numLEDs
	decfsz	pixelcount
	goto	loop4
	return
    end