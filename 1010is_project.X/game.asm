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
P1_button   res	1
P2_button   res 1

   
GAME code

; -------------------------------SET UP -------------------------------------
Game_setup
	CLRF	P1_score
	CLRF	P2_score
	SETF	TRISJ		;configure PORT J for input  -  J1 = Button 1 FLAG, J2 = Button 2 FLAG
	;CLRF	PORTH
	call	CLEAR_pixeldata
	call	DrawLeftGoal
	call	DrawRightGoal
	call	resetstate1
	return
resetstate1
	movlw	.30
	movwf	ball_POS
	movlw	b'10000000'
	movwf	ball_VEL
	BSF	ball_DIR, 7 ;POS INITIAL
	return
resetstate2
	movlw	.30
	movwf	ball_POS
	movlw	b'10000000'
	movwf	ball_VEL
	BCF	ball_DIR, 7 ;NEG INITIAL
	return

;------------------------------DRAW RACKET--------------------------------------
DrawLeftRacket
	LFSR	FSR0, 0x100
	call	writeRACKET
	return
DrawRightRacket
	LFSR	FSR0, 0x1A5
	call	writeRACKET
	return
writeRACKET
	call	send_blue
	call	send_blue
	call	send_blue
	call	send_blue
	call	send_blue
	return
;------------------------------DRAW GOALS---------------------------------------
DrawLeftGoal
	LFSR	FSR0, 0x0F1 ; point to initial address
	call	writeGOAL
	return
DrawRightGoal
	LFSR	FSR0, 0x1B4
	call	writeGOAL
	return
writeGOAL ; this writes a sequence of 4 yellow pixels for the endzone
	call	send_yellow
	call	send_yellow
	call	send_yellow
	call	send_yellow
	call	send_yellow
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
	bra	check_B2
	bra	check_G2
Negative ;subtract movecount from POS
	movff	movecount, WREG
	subwf	ball_POS
	bra	check_B1
check_B1    ;CHECK IF B1 IS PRESSED
	BTFSC	PORTJ, 1
	bra	B1_pressed	; BUTTON 1 PRESSED
	bra	check_G1	; BUTTON 1 NOT PRESSED
check_B2    ;CHECK IF B2 IS PRESSED
	BTFSC	PORTJ, 2
	bra	B2_pressed	; BUTTON 2 PRESSED
	bra	check_G2	; BUTTON 2 NOT PRESSED
B1_pressed
	movlw	.6
	CPFSGT	ball_POS	; check if ball is Inside Racket1
	bra	ReflectRight	; *HIT* - POS < 6 (1, 2, 3, 4 or 5)-(inside racket)
	bra	check_G1	; *NO HIT* (outside racket) - proceed to check goal
B2_pressed
	movlw	.54
	CPFSLT	ball_POS	; check if ball is inside Racket2
	bra	ReflectLeft	; *HIT* - POS > 54 (55, 56, 57, 58 or 59) - (inside racket)
	bra	check_G2	; *NO HIT* (outside racket) - proceed to check goal
ReflectRight
	BSF	ball_DIR, 7	; set the direction to POSITIVE (MSB = 1)
	bra	end_state
ReflectLeft
	BCF	ball_DIR, 7	; set the direction to NEGATIVEE (MSB = 0)
	bra	end_state
check_G1 ; here we need to check if the new position is in the first foal
	BTFSS	STATUS, N    ; check if ball_position is in GOAL1 (result of subtraction is negative)
	bra	end_state
	bra	GOAL1	    ; Result is negative: if is in goal 1 - then process goal
check_G2 ; here we need to check if the new position is in the second goal
	movlw	.60
	CPFSGT	ball_POS ; check if ball_position is in GOAL2
	bra	end_state
	bra	GOAL2
GOAL1	; ball in goal 1 - so Player 2 has scored
	incf	P2_score 
	call	resetstate1
	bra	end_state
GOAL2	; ball in goal 2 - so Player 1 has scored
	incf	P1_score
	call	resetstate2
	bra	end_state
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
	LFSR	FSR0, 0x0F1
	movlw	.70
	movwf	pixelcount
loop4	call	send_blank
	;decfsz	numLEDs
	decfsz	pixelcount
	goto	loop4
	return
    end