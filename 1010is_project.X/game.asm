#include p18f87k22.inc

    global  Write_state, CLEAR_pixeldata, Game_setup, Calculate_state
    global  frame_delay, GREEN_pixeldata
    global  leftracket_true, leftracket_false, rightracket_true, rightracket_false
    extern  delay_256, reset_animation

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
delay1	    res 1
delay2	    res 1
VariableDelay	res 1
racketcount res 1
sitecheck  res 1
   
GAME code

; -------------------------------SET UP -------------------------------------
Game_setup
	CLRF	P1_score
	CLRF	P2_score
	SETF	TRISJ		; configure PORT J for input  -  
				; J1 = Button 1 FLAG, J2 = Button 2 FLAG
	call	slowDelay
	call	CLEAR_pixeldata
	call	resetstate1
	return
resetstate1
	call	slowDelay
	call	reset_animation
	call	DrawLeftGoal
	call	DrawRightGoal
	
	call	defaultDelay
	
	movlw	.0		; Ball starts at near end of gamezone
	movwf	ball_POS
	movlw	b'10000000'	; Fixed position chnge between frames
	movwf	ball_VEL
	BSF	ball_DIR, 7	; Inital velocity left to right
	return
resetstate2
	call	slowDelay
	call	reset_animation
	call	DrawLeftGoal
	call	DrawRightGoal
	
	call	defaultDelay
	
	movlw	.59		; Ball starts at far end of gamezone
	movwf	ball_POS
	movlw	b'10000000'	; Fixed position chnge between frames
	movwf	ball_VEL
	BCF	ball_DIR, 7	; Inital velocity right to left
	return
defaultDelay
	movlw	.4
	movwf	VariableDelay		;set default delay count
	return
slowDelay
	movlw	.20
	movwf	VariableDelay		; set slow delay count
	return

;------------------------------CALCULATE GAME STATE-----------------------------
Calculate_state
	movlw	.0
	movwf	movecount	    ; initially set the movecount to zero
	movff	ball_VEL, workingVEL
Check_Magnitude
	; Used when ball_VEL was altered instead of frame delay
	; Still used in calculation but bal_VEL is always the 'lowest' it can be
	; (b'10000000' in our encoding).
	incf	movecount	    ; increment movecount
	BTFSC	workingVEL, 7	    ; check current bit of velocity
	bra	Check_Direction	    ; if NOT CLEAR (i.e. the 1 has been found) - 
				    ; then Update Position based on movecount
	rlcf	workingVEL, 1	    ; load next bit
	goto	Check_Magnitude	    ; loop again, check next bit
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
check_B1 ;CHECK IF B1 IS PRESSED
	BTFSC	PORTJ, 1
	bra	B1_pressed	; BUTTON 1 PRESSED
	bra	check_G1	; BUTTON 1 NOT PRESSED
check_B2 ;CHECK IF B2 IS PRESSED
	BTFSC	PORTJ, 2
	bra	B2_pressed	; BUTTON 2 PRESSED
	bra	check_G2	; BUTTON 2 NOT PRESSED
B1_pressed
	call	DrawLeftRacket
	movlw	.6
	CPFSGT	ball_POS	; check if ball is Inside Racket1
	bra	ReflectRight	; *HIT* - POS < 6 (1, 2, 3, 4 or 5)-(inside racket)
	bra	check_G1	; *NO HIT* (outside racket) - proceed to check goal
B2_pressed
	call	DrawRightRacket
	movlw	.54
	CPFSLT	ball_POS	; check if ball is inside Racket2
	bra	ReflectLeft	; *HIT* - POS > 54 (55, 56, 57, 58 or 59) - (inside racket)
	bra	check_G2	; *NO HIT* (outside racket) - proceed to check goal
ReflectRight
	BSF	ball_DIR, 7	; set the direction to POSITIVE (MSB = 1)
	movlw	.4
	CPFSLT	ball_POS	; CHECK BALL POSITION
	bra	decVEL_2	; POS = 4 - decrease velocity by 2 units
	movlw	.3		
	CPFSLT	ball_POS
	bra	decVEL_1	; POS = 3 - decrease velocity by 1 unit
	movlw	.2		
	CPFSLT	ball_POS
	bra	end_state	; POS = 2 - do not change velocity (-> END)
	movlw	.1		
	CPFSLT	ball_POS	
	bra	incVEL_1	; POS = 1 - increase velocity by 1 unit
	bra	incVEL_2	; POS = 0 - increase velocity by 2 units
ReflectLeft
	BCF	ball_DIR, 7	; set the direction to NEGATIVE (MSB = 0)
	movlw	.55
	CPFSGT	ball_POS	; CHECK BALL POSITION
	bra	decVEL_2	; POS = 55 - decrease velocity by 2 units
	movlw	.56
	CPFSGT	ball_POS
	bra	decVEL_1	; POS = 56 - decrease velocity by 1 unit
	movlw	.57
	CPFSGT	ball_POS
	bra	end_state	; POS = 57 - do not change velocity (-> END)
	movlw	.58
	CPFSGT	ball_POS	
	bra	incVEL_1	; POS = 58 - increase velocity by 1 unit
	bra	incVEL_2	; POS = 59 - increase velocity by 2 units
check_G1 ; here we need to check if the new position is in the first foal
	BTFSS	STATUS, N	; check if ball_position is in GOAL1 
				; (result of subtraction is negative)
	bra	end_state
	bra	GOAL1		; Result is negative: if is in goal 1 - then process goal
check_G2 ; here we need to check if the new position is in the second goal
	movlw	.59
	CPFSGT	ball_POS	; check if ball_position is in GOAL2
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

;------------------------------DRAW RACKET--------------------------------------
DrawLeftRacket
	LFSR	FSR0, 0x100	; Registers for left of gamezone 
	call	writeRACKET_l
	return
DrawRightRacket
	LFSR	FSR0, 0x1A5	; Registers for right of gamezone 
	call	writeRACKET_r
	return
;------------------------------RACKET STATES------------------------------------	
;---------------RIGHT RACKET
writeRACKET_r
	movlw	.50		; At the right, racket starts at site 50
	movwf	sitecheck
racketloop_r
	movlw	.55		; Racket finishes at site 55
	cpfseq	sitecheck	
	bra	in_racket_r	; if counter not reached, continue checking racket sites
	return			; if counter reached, exit
in_racket_r		
	movff	sitecheck, W
	cpfseq	ball_POS	; check racket sites for ball position
	bra	no_ball_r
	call	send_purple	; if ball at this site in racket, display purple 
	incf	sitecheck
	bra	racketloop_r
no_ball_r
	call	send_blue	; if ball not at that site, pixel is blue
	incf	sitecheck
	bra	racketloop_r
;----------------LEFT RACKET	
writeRACKET_l
	movlw	.0		; on left, racket starts at site 0
	movwf	sitecheck
racketloop_l
	movlw	.5
	cpfseq	sitecheck
	bra	in_racket_l	; if counter not reached, continue checking racket sites
	return			; if counter reached, exit
in_racket_l
	movff	sitecheck, W
	cpfseq	ball_POS
	bra	no_ball_l
	call	send_purple	; if ball at this site in racket, display purple
	incf	sitecheck
	bra	racketloop_l
no_ball_l
	call	send_blue	; if ball not at that site, pixel is blue
	incf	sitecheck
	bra	racketloop_l

;----------------------------------CONDITION CASES FOR RACKET -------------------------------------	
;-------------------------DRAW RACKET (BUTTON PRESSED)
rightracket_true
	LFSR	FSR0, 0x1A5	; Starting register for racket
	movlw	.5		; length of racket
	movwf	racketcount
	movff	ball_POS, poscount
	movlw	.55
	subwf	poscount, 1
rr_loop1
	movlw	.0
	cpfsgt	poscount	; check if we are at ball pixel
	bra	ball_true_r_t	; send ball
	call	send_blue
	bra	check_fin_r_t
ball_true_r_t			; racket pressed AND ball at this site
	call	send_purple	
check_fin_r_t			; check if we have done all racket pixels
	decf	poscount
	decfsz	racketcount
	goto	lr_loop1
	return
		
	
leftracket_true
	LFSR	FSR0, 0x100	; Starting register for racket
	movlw	.5		; length of racket
	movwf	racketcount
	movff	ball_POS, poscount
lr_loop1
	movlw	.0
	cpfsgt	poscount	; check if we are at ball pixel
	bra	ball_true_l_t	; send ball
	call	send_blue
	bra	check_fin_l_t
ball_true_l_t			; racket pressed AND ball at this site
	call	send_purple	
check_fin_l_t			; check if we have done all racket pixels
	decf	poscount
	decfsz	racketcount
	goto	lr_loop1
	return

;-------------------------DRAW RACKET (NO BUTTON)
leftracket_false
	LFSR	FSR0, 0x100
	movlw	.5
	movwf	racketcount
	movff	ball_POS, poscount
lr_loop2
	movlw	.0
	cpfsgt	poscount	; check if we are at ball pixel
	bra	ball_true_l_f	; send ball
	call	send_blank
	bra	check_fin_l_f
ball_true_l_f
	call	send_red	
check_fin_l_f			; check if we have done all racket pixels
	decf	poscount
	decfsz	racketcount
	goto	lr_loop2
	return
	
rightracket_false
	LFSR	FSR0, 0x1A5
	movlw	.5
	movwf	racketcount
	movff	ball_POS, poscount
	movlw	.55
	subwf	poscount, 1
rr_loop2
	movlw	.0
	cpfsgt	poscount	; check if we are at ball pixel
	bra	ball_true_r	; send ball
	call	send_blank
	bra	check_fin_r
ball_true_r
	call	send_red	
check_fin_r   ; check if we have done all racket pixels
	decf	poscount
	decfsz	racketcount
	goto	lr_loop2
	return
	
;------------------------------DRAW GOALS---------------------------------------
	
DrawLeftGoal
	LFSR	FSR0, 0x0F1	; Point to initial address
	call	writeGOAL
	return
DrawRightGoal
	LFSR	FSR0, 0x1B4
	call	writeGOAL
	return
writeGOAL ; this writes a sequence of 5 yellow pixels for the endzone
	call	send_yellow
	call	send_yellow
	call	send_yellow
	call	send_yellow
	call	send_yellow
	return
	
;-------------------INCREASE/DECREASE VELOCITY FUNCTIONS--------------------	
decVEL_2
	incf	VariableDelay
	incf	VariableDelay
	bra	end_state
decVEL_1
	incf	VariableDelay
	bra	end_state
incVEL_1
	decfsz	VariableDelay
	bra	end_state	; delay not zero - so fine, return
	call	set_MIN		; delay is zero but must be at least 1
incVEL_2
	decfsz	VariableDelay
	bra	decAgain	; delay not min yet, so decrement again
	bra	set_MIN		; delay is min - set to minimum value of 1 (MAX VELOCITY) 
decAgain
	decfsz	VariableDelay
	bra	end_state
	bra	set_MIN		; delay is min - set to minimum value of 1 (MAX VELOCITY)
set_MIN	
	movlw	.1
	movwf	VariableDelay
	bra	end_state

;----------------------------------PUSH GAME STATE -------------------------------------	
Write_state
	LFSR	FSR0, 0x10F ; point to initial address
	movlw	.50 ; non-racket pixels
	movwf	pixelcount  
	movff	ball_POS, poscount
	movlw	.5
	subwf	poscount, 1
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
send_red		    ; Used for ball
	movlw	0x00 
	movwf	POSTINC0 
	movlw	0xBC
	movwf	POSTINC0 
	movlw	0x00 
	movwf	POSTINC0 
	return
send_blue		    ; Used for racket
	movlw	0xFF 
	movwf	POSTINC0 
	movlw	0x00
	movwf	POSTINC0 
	movlw	0xFB 
	movwf	POSTINC0
	return
send_green		    ; Used for reset animation
	movlw	0xA1 
	movwf	POSTINC0 
	movlw	0x00
	movwf	POSTINC0 
	movlw	0x11 
	movwf	POSTINC0 
	return
send_yellow		    ; Used for goals
	movlw	0xF0 
	movwf	POSTINC0
	movlw	0xFF
	movwf	POSTINC0
	movlw	0x00 
	movwf	POSTINC0
	return
send_purple		    ; Used for ball when inside racket
	movlw	0x00 
	movwf	POSTINC0 
	movlw	0xB7
	movwf	POSTINC0 
	movlw	0xFF 
	movwf	POSTINC0 
	return
send_blank		    ; Erase pixel
	movlw	0x00 
	movwf	POSTINC0 
	movlw	0x00
	movwf	POSTINC0 
	movlw	0x00 
	movwf	POSTINC0 
	return	
send_null
	movlw	.0
	addwf	POSTINC0    ; Skip three FSR addresses (move to next pixel)
	addwf	POSTINC0
	addwf	POSTINC0
	return
send_white
	movlw	0xFF 
	movwf	POSTINC0 
	movlw	0xFF
	movwf	POSTINC0 
	movlw	0xFF 
	movwf	POSTINC0 
	return	
	

;---------------------------CLEAR PIXEL DATA------------------------------------
CLEAR_pixeldata
	LFSR	FSR0, 0x100
	movlw	.60
	movwf	pixelcount
loop4	call	send_blank
	decfsz	pixelcount
	goto	loop4
	return
    
GREEN_pixeldata
	LFSR	FSR0, 0x100
	movlw	.60
	movwf	pixelcount
loop5	call	send_green
	decfsz	pixelcount
	goto	loop5
	return
	
;------------------------FRAME DELAY ROUTINES-----------------------------------	

frame_delay
	movff	VariableDelay, delay2
iter2	decfsz	delay2
	goto	cont2
	return
cont2	call	sub_delay
	goto	iter2

sub_delay
	movlw	0x0
	movwf	delay1
iter1	decfsz	delay1
	goto	cont1
	return
cont1	call	delay_256
	goto	iter1
	
;---------------------------------END-------------------------------------------

	end
