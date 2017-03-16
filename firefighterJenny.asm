; firefigther jenny

.include "..\C64Libs\CodeMacros.asm"

kVectors .block
	Screen = $3000
	Screen2 = $2000
	SpritePointer1 = Screen + $3f8
	SpritePointer2 = Screen + $3f9
	SpritePointer3 = Screen + $3fa
	SpritePointer4 = Screen + $3fb
	SpritePointer5 = Screen + $3fc
	SpritePointer6 = Screen + $3fd
	SpritePointer7 = Screen + $3fe
	SpritePointer8 = Screen + $3ff 
	SpritePointer1_2 = Screen2 + $3f8
	SpritePointer2_2 = Screen2 + $3f9
	SpritePointer3_2 = Screen2 + $3fa
	SpritePointer4_2 = Screen2 + $3fb
	SpritePointer5_2 = Screen2 + $3fc
	SpritePointer6_2 = Screen2 + $3fd
	SpritePointer7_2 = Screen2 + $3fe
	SpritePointer8_2 = Screen2 + $3ff 
	CustomChar = $3800
	Sprites = $3A00
.bend

kSprites .block
	PlayerL = kVectors.Sprites/64
	PlayerM = PlayerL + 1
	PlayerR = PlayerM + 1
	BirdDiveL = PlayerR + 1
	BirdLa = BirdDiveL +1
	BirdLb = BirdLa + 1
	BirdRa = BirdLb + 1
	BirdRb = BirdRa + 1
	BirdDiveR = BirdRb + 1
	Score = BirdDiveR+1
	Death = Score+1
.bend

kCollisionOffsets .block
	aboveMiddle = 0
	middle = 1
	left = 2
	right = 3
	belowMiddle = 4
.bend	

kDeathMode .block
	none = 0
	window = 1
	buildingBurntDown = 2
	bird = 3
.bend

sSpriteData .struct 
	x .byte ?
	y .byte ?
.ends

kEntityState .block
	free = 255
	movingLeft = 0
	movingRight = 1
	waitingLeft = 2
	waitingRight = 3
	divingLeft = 4
	divingRight = 5
.bend

kNumEntities = 5
kFireValue = 10

*= $02
;; dont cares
ZPTemp1 .byte ?
ZPTemp2 .byte ?
ZPTemp3 .byte ?
ZPTemp4 .byte ?
ZPTemp5 .byte ?
ZPTemp6 .byte ?
ZPTemp7 .byte ?
ZPTemp8 .byte ?
ZPTemp9 .byte ?
ZPTemp10 .byte ?
NMIZPtemp1 .byte ?
NMIZPtemp2 .byte ?
NMIZPtemp3 .byte ?
NMIZPtemp4 .byte ?
NMIZPtemp5 .byte ?
NMIZPtemp6 .byte ?
NMIZPtemp7 .byte ?
Pointer1 .word ?
Pointer2 .word ?
Pointer3 .word ?
Pointer4 .word ?
Pointer5 .word ?
Pointer6 .word ?
Pointer7 .word ?
CurrFunction .word ?
joyFire	 .byte ?
joyRight .byte ?
joyLeft	 .byte ?
joyDown	 .byte ?
joyUp	 .byte ?
Random   .word ?
RasterValue .byte ?
; Game Data
AirConSpawn .word ?
FireSpawn .word ?
HBirdSpawn .word ?
VBirdSpawn .word ?
SpawnTimer .word ?
Score .byte ?,?,?
Lives .byte ?
; Level Data
LEVELDATA = *
LevelLinePtr .word ?
ScrollY	.byte ?
PlayerPtr .byte ?
PlayerPtrDelta .byte ?
PlayerAnimCounter .byte ?
PlayerX .byte ?
EntityX .byte ?,?,?,?,?
PlayerXMoveTimer .byte ?
PlayerYCounter .byte ?,?,?
PlayerYPointer .word ?
PlayerYPointerMiddle .word ?
PlayerYPointerBottom .word ?
PlayerCollisionResults .byte ?,?
FireTimer .byte ?
FireIndex .byte ?
FireActiveIndex .byte ?
FireCount .byte ?
LevelOver .byte ?
DeathMode .byte ?
LineConterForScore .byte ?
PlayerSprite .dstruct sSpriteData
Entity1Sprite .dstruct sSpriteData
Entity2Sprite .dstruct sSpriteData
Entity3Sprite .dstruct sSpriteData
Entity4Sprite .dstruct sSpriteData
Entity5Sprite .dstruct sSpriteData
SpritePointers .byte ?,?,?,?,?,?
EntState .byte ?,?,?,?,?
EntAnimeTimer .byte ?,?,?,?,?

ActiveScreen  .byte ?
FireSFXTimer  .byte ?
FlipD018	  .byte ?

LEVELDATAEND = *
.if * >= $100
.warn "ZP Page Overflow"
.endif


*= $200 ; variables
Variables
UpOne .byte ?

*= $300 ; buffer
PageBuffer .byte ?

*= $400 ; line buffer
FourLineBuffer .fill 160

*=$500 ; level highlevel map
LevelMap .byte ?

;*=$7000 
*=$8600
ScreenDump .byte ?

*= $801
.word (+), 10
.null $9e, "2061"
+ .word 0
* = 2061
	#ClearInterupts
	#IOandKernal
	lda #0
	ldx #1
	jsr fillArea	
	ldx #2
	lda #0
-	sta $00,x
	inx
	bne -
	jsr MakeCramScreenScrollDown
;	jsr copyPETSCIIToCharset
	jmp SetupTitleScreen

displayDeathMsgAndWaitForFire
	jsr disableInGameNMIIRQ
	jsr KillSFX
	lda #%00001000
	sta $d011
	lda #0
-	cmp $d012	
	bne -	
	bit $d011	
	bmi -	
	#STAB #%11000110,$d018
	#STAB #0,$d015 ; turn off the sprites
	lda #32
	ldx #kFillIndexs.Screen ; empty the screen
	jsr fillArea
	lda Lives
	bmi _gameover
	ldx DeathMode
	lda DeathStringIndex,x
	bne _plot
_gameOver
	ldx #kStringIndex.gameOver
	lda #16
_plot
	ldy #10
	jsr plotStringAAtIndexX
	#STAB #%00010000,$d011 ; turn the screen off
	lda #0
-	cmp $d012	
	bne -	
	bit $d011	
	bmi -	
-	jsr ScanJoystick
	lda joyFire
	beq -
-	jsr ScanJoystick
	lda joyFire
	bne -
	lda Lives
	bpl +
	jmp SetupTitleScreen
+	jmp setUpLevelFunc
	
disableInGameNMIIRQ	
	#STAB #$04,$DD0D ; disable NMI
	lda $DD0D
	sei
	#STAB #$00,$d01A
	#STAB #$FF,$d019
	#STAPW EmptyNMI,$318 ; set NMI register
	#STAPW emptyIRQ,$314 ; set IRQ register
	cli
	rts
	
levelOverFunc	
	jsr disableInGameNMIIRQ
	jsr KillSFX
	#STAB #%00000000,$d011 ; turn the screen off
;	lda #0	; loaded above
-	cmp $d012	
	bne -	
	bit $d011	
	bmi -
	#STAB #%11000110,$d018
	#STAB #0,$d015 ; turn off the sprites
	lda #32
	ldx #kFillIndexs.Screen ; empty the screen
	jsr fillArea
	ldx #0
	lda #11
	ldy #10
	jsr plotStringAAtIndexX
	lda Random
	and #7
	clc
	adc #kStringIndex.save0
	tax
	lda #11+11
	ldy #10
	jsr plotStringAAtIndexX
	#STAB #%00010000,$d011 ; turn the screen off
	lda #0	
-	cmp $d012	
	bne -	
	bit $d011	
	bmi -
-	jsr ScanJoystick
	lda joyFire
	beq -
	jsr AdvanceLevelVars	
	jmp setUpLevelFunc	
	
deathFunc
	#STAB #kSprites.Death,SpritePointers
;-	ldx #3
-	bit $d011
	bmi -
	lda #50
 	cmp $d012
 	bcc -
- 	lda #200
 	cmp $d012
 	bcs -
; 	dex	
 ;	bpl --	
 	inc PlayerSprite.y	
 	lda PlayerSprite.y 
  	cmp #250
  	bne --
  	dec Lives
  	jsr plotLives
  	jmp displayDeathMsgAndWaitForFire
; ----- @MAIN LOOP@ -----
	
MAINLOOP	
	jmp (CurrFunction)

; ----- @Main Game Functions@ -----
MainLevel
	lda #100
-	cmp $d012	
	bcc -
 	lda #168
 	jsr waitD012
 	lda LevelOver
 	beq + 
 	jmp levelOverFunc
+	lda DeathMode
 	bne deathFunc
 	ldx #kCollisionOffsets.middle
	jsr checkPlayerCollision
	lda PlayerCollisionResults
	cmp #kFireValue
	bne +
	#STAB #kDeathMode.window,DeathMode
	bne deathFunc
+	lda $d01e
	and #1
	beq +
	#STAB #kDeathMode.bird,DeathMode
	bne deathFunc	
+	jsr animateFire
	jsr animateEntities
	jsr ScanJoystick
	jsr makeNextRandom
	jsr updateFire
	lda joyUp
	ora UpOne
	bne movePlayerUp
	lda joyDown
	beq +
	jmp movePlayerDown
+	#DecToHoldFF PlayerXMoveTimer
	bpl MAINLOOP
	lda #1
	sta PlayerXMoveTimer
	lda joyRight
	beq +
	gne movePlayerRight
+	lda joyLeft
	beq MAINLOOP
	jmp movePlayerLeft	
	
movePlayerUp
	#STAB #0,UpOne
;	ldx #kCollisionOffsets.aboveMiddle
	tax ; this should be the same as above
	jsr checkPlayerCollision
	lda PlayerCollisionResults
	beq MAINLOOP
	jsr animatePlayer
	lda PlayerSprite.y
	cmp #151
	bcc _moveScreen
	dec PlayerSprite.y
	dec PlayerSprite.y
	jsr decYCounters
	jmp MAINLOOP
_moveScreen
	jsr shiftAndDisableEntities
	inc ScrollY
	inc ScrollY
	lda ScrollY
	cmp #8
	bne _checkShift
	#ANDB ScrollY,#7
;	inc $d020
	inc FlipD018
;	lda $d018
;	eor #64
;	sta $d018
;	dec $d020
	jsr ScrollScreenDownOne
;	jsr copyCurrentLineToScreenAndAdvancePointer

	ldy #39
	lda ActiveScreen
	beq _2
-	lda (LevelLinePtr),y
	sta kVectors.Screen2,y
	and #63
	tax
	lda Char_Colours,x
	sta $d800,y
	dey
	bpl -
	bmi _donePlot
_2	
-	lda (LevelLinePtr),y
	sta kVectors.Screen,y
	and #63
	tax
	lda Char_Colours,x
	sta $d800,y
	dey
	bpl -
_donePlot
	lda ActiveScreen
	eor #1
	sta ActiveScreen
	#ADCBW LevelLinePtr,#40
	
	dec LineConterForScore
	bpl _exit
	lda #4
	sta LineConterForScore	
	sed
	lda Score
	clc
	adc #$10
	sta Score
	lda Score+1
	adc #0
	sta Score+1
	lda Score+2
	adc #0
	sta Score+2
	cld
	bcc _exit
	inc Lives
	bne _exit
_checkShift
	cmp #3
	beq _shiftScreen
	cmp #4
	bne _exit
_shiftScreen
	lda ActiveScreen
	bne _2c
	jsr CopyScreen2To1
	jmp _exit
_2c	jsr CopyScreen1To2
_exit
+	#ANDB ScrollY,#7
;	beq ++
;+	lda #250
;	jsr waitD012
;+;	dec $d020
;	#ANDORB $d011,#%11111000,ScrollY
;	inc $d020

-	lda $d012
	cmp #70
	bcc -
	jsr plotScoreToSprite
_updateCounter
	jsr decYCounters
	jmp MAINLOOP

ScoreTable .byte 10,0,0

movePlayerDown
	ldx #kCollisionOffsets.belowMiddle
	jsr checkPlayerCollision
	beq _exit
	lda PlayerSprite.y
	cmp #250-25
	bcc +
	jmp MAINLOOP
+	jsr animatePlayer
	inc PlayerSprite.y
	jsr incYCounters	
_exit	
	jmp MAINLOOP
	
movePlayerRight		
	ldx #kCollisionOffsets.right
	jsr checkPlayerCollision
	beq +
	lda PlayerCollisionResults
	beq +
	lda #128-12
	cmp PlayerX
	bcc +
	jsr animatePlayer		
	inc PlayerX				
	ldx #0			
	ldy #0			
	jsr setPlayerX				
+	jmp MAINLOOP	

movePlayerLeft		
	ldx #kCollisionOffsets.left
	jsr checkPlayerCollision
	beq +
	lda PlayerX	
	beq +	
	jsr animatePlayer		
	dec PlayerX		
	ldx #0
	ldy #0
	jsr setPlayerX		
+	jmp MAINLOOP		
	
decYCounters	
.comment
	dec PlayerYCounter
	dec PlayerYCounter
	bpl +
	#ANDB PlayerYCounter,#31
	#ADCIW PlayerYPointer,8
	cmp #$08
	bne +
	inc LevelOver
+	dec PlayerYCounter+1
	dec PlayerYCounter+1
	bpl +
	#ANDB PlayerYCounter+1,#31
	#ADCIW PlayerYPointerMiddle,8
+	dec PlayerYCounter+2
	dec PlayerYCounter+2
	bpl +
	#ANDB PlayerYCounter+2,#31
	#ADCIW PlayerYPointerBottom,8
+	rts
.endc
;.comment
	ldx #0
	ldy #0
	dec PlayerYCounter,x
	dec PlayerYCounter,x
	bpl +
	lda PlayerYCounter,x
	and #31
	sta PlayerYCounter,x
	clc
	lda PlayerYPointer,y
	adc #8
	sta PlayerYPointer,y	
	lda PlayerYPointer+1,y
	adc #0
	sta PlayerYPointer+1,y
	cmp #$08
	bne +
	inc LevelOver
+	inx
	iny
	iny
	dec PlayerYCounter,x
	dec PlayerYCounter,x
	bpl +
	lda PlayerYCounter,x
	and #31
	sta PlayerYCounter,x
	clc
	lda PlayerYPointer,y ; middle
	adc #8
	sta PlayerYPointer,y
	lda PlayerYPointer+1,y
	adc #0
	sta PlayerYPointer+1,y
+	inx
	iny
	iny
	dec PlayerYCounter,x
	dec PlayerYCounter,x
	bpl +
	lda PlayerYCounter,x
	and #31
	sta PlayerYCounter,x
	clc
	lda PlayerYPointer,y ; bottom
	adc #8
	sta PlayerYPointer,y ; Bottom
	lda PlayerYPointer+1,y
	adc #0
	sta PlayerYPointer+1,y
+	rts
;.endc

incYCounters
.comment
	inc PlayerYCounter
	lda PlayerYCounter
	cmp #32
	bcc +
	#STAB #0,PlayerYCounter
	#SUBBW PlayerYPointer,#8
+	inc PlayerYCounter+1
	lda PlayerYCounter+1
	cmp #32
	bcc +
	#STAB #0,PlayerYCounter+1
	#SUBBW PlayerYPointerMiddle,#8
+	inc PlayerYCounter+2
	lda PlayerYCounter+2
	cmp #32
	bcc +
	#STAB #0,PlayerYCounter+2
	#SUBBW PlayerYPointerBottom,#8
+	rts
.endc
;.comment
	ldx #0
	ldy #0
	inc PlayerYCounter,x
	lda PlayerYCounter,x
	cmp #32
	bcc +
	lda #0
	sta PlayerYCounter,x
	lda PlayerYPointer,y
	;sec
	sbc #8
	sta PlayerYPointer,y
	lda (PlayerYPointer)+1,y
	sbc #00
	sta (PlayerYPointer)+1,y
+	inx
	iny
	iny
	inc PlayerYCounter,x
	lda PlayerYCounter,x
	cmp #32
	bcc +
	lda #0
	sta PlayerYCounter,x
	lda PlayerYPointer,y ;Middle
	;sec
	sbc #8
	sta PlayerYPointer,y ;Middle
	lda (PlayerYPointer)+1,y
	sbc #00
	sta (PlayerYPointer)+1,y
+	inx
	iny
	iny
	inc PlayerYCounter,x
	lda PlayerYCounter,x
	cmp #32
	bcc +
	lda #0
	sta PlayerYCounter,x
	lda PlayerYPointer,y ;Bottom
	;sec
	sbc #8
	sta PlayerYPointer,y ;Bottom
	lda (PlayerYPointer)+1,y
	sbc #00
	sta (PlayerYPointer)+1,y
+	rts
;.endc

.comment
setupPlayer
	#STAB #55,$D00D ; SCORE
	sta $D00F
	sta $D00E ; Lives
	#STAB #24,$D00C	
	#STAB #kSprites.Score,kVectors.SpritePointer7
	#STAB #kSprites.Score+2,kVectors.SpritePointer8
	#STAB #250-25,PlayerSprite.y
	#STAB #kSprites.PlayerM,SpritePointers
	#STAB #kSprites.PlayerM,PlayerPtr
	#STAB #1,PlayerPtrDelta
	#STAB #8,PlayerAnimCounter
	sta PlayerYCounter
	#STAB #18,PlayerYCounter+1
	#STAB #28,PlayerYCounter+2
	#STAPW LevelMap,PlayerYPointer
	#STAPW LevelMap,PlayerYPointerMiddle
	#STAPW LevelMap,PlayerYPointerBottom
	#STAB #64,PlayerX
	ldx #0
	ldy #0
	jsr setPlayerX
	lda $d01e
	rts		
.endc	
			
setPlayerX
	lda PlayerX,x
	clc
	adc #(24+(4*8))/2
	asl a
	sta PlayerSprite.x,y
	lda #0
	bcc +
	lda D010Set,x
+	sta ZPTemp1
	lda $d010
	and D010Mask,x
	ora ZPTemp1
	sta $d010
	rts

D010Mask .byte %11111110
	 	 .byte %11111101
		 .byte %11111011
		 .byte %11110111
		 .byte %11101111
		 .byte %11011111
D010Set	 .byte %00000001
		 .byte %00000010
		 .byte %00000100
		 .byte %00001000
		 .byte %00010000
		 .byte %00100000
		
collisionXOffset .byte 6, 6, 0,12, 6	
collisionYOffset .byte 0, 2, 2, 2, 4	
	
checkPlayerCollision
	ldy collisionYOffset,x
	lda PlayerYPointer,y
	sta Pointer1
	lda PlayerYPointer+1,y
	sta Pointer1+1
	lda PlayerX
	clc
	adc collisionXOffset,x ; get the middle
	lsr a
	lsr a
	lsr a
	lsr a
	tay
	lda (Pointer1),y
;	sta $d020
	sta PlayerCollisionResults
	rts
	
waitD012	
	cmp $d012	
	bcs waitD012	
	bit $d011	
	bmi waitD012	
	rts	

;MCSSD_CRAM_CODE_DEST = $5000
MCSSD_SCREEN_CODE_DEST = $4000
MCSSD_SCREEN_SRC = $D800 ; $3400
MCSSD_NUM_LINES = 24
;MCSSD_CRAM_CODE_DEST - this is where the CRAM code is written to size $1680 
;MCSSD_SCREEN_CODE_DEST - this is where the SCREEN code is written to size $1680  
;MCSSD_SCREEN_SRC - this is where the SCREEN is in memory  
;MCSSD_NUM_LINES - this is the number of lines from the top to scroll 1-24  
MakeCramScreenScrollDown .proc
	ldx #11
-	lda ScreenCRAM,x
	sta $2,x
	dex
	bpl -
	jsr pairLoop
	ldx #11
-	lda ScreenCRAM2,x
	sta $2,x
	dex
	bpl -	
	jsr pairLoop
	ldx #11
-	lda Screen1To2,x
	sta $2,x
	dex
	bpl -
	jsr pairLoop
	ldx #11
-	lda Screen2To1,x
	sta $2,x
	dex
	bpl -
pairLoop
	ldy #5	
-	lda $2,y	 ; code template
	sta ($8),y	 ; code pointer
	dey	
	bpl -	
	lda $8		; code pointer
	clc	
	adc #6	
	sta $8		; code pointer
	bcc +	
	inc $9		; code pointer +1
+	lda $3
	bne +
	dec $4
+	dec $3	
	lda $6
	bne +
	dec $7
+	dec $6
	lda $4
	cmp 13
	bne pairLoop
	lda $3
	cmp 12
	bne pairLoop
	lda #$60
	iny 
	sta ($a),y
	rts
		
;tableCRAM
;	lda $D800+(MCSSD_NUM_LINES*40)-1
;	sta $D800+((MCSSD_NUM_LINES+1)*40)-1
;	.word MCSSD_CRAM_CODE_DEST
;	.word MCSSD_CRAM_CODE_DEST+((MCSSD_NUM_LINES*40)*6)
;	.byte $d7
ScreenCRAM	
	lda MCSSD_SCREEN_SRC+(12*40)-1	
	sta MCSSD_SCREEN_SRC+(13*40)-1	
	.word MCSSD_SCREEN_CODE_DEST ;start
	.word MCSSD_SCREEN_CODE_DEST +((12*40)*6) ;rts
	.word MCSSD_SCREEN_SRC-1 ; end
ScreenCRAM2	
	lda MCSSD_SCREEN_SRC+(MCSSD_NUM_LINES*40)-1	
	sta MCSSD_SCREEN_SRC+((MCSSD_NUM_LINES+1)*40)-1	
	.word MCSSD_SCREEN_CODE_DEST + ((12*40)*6)+1
	.word MCSSD_SCREEN_CODE_DEST +(((MCSSD_NUM_LINES-1)*40)*6)+1
	.word MCSSD_SCREEN_SRC+(40*13)-1
Screen1To2
	lda kVectors.Screen+(MCSSD_NUM_LINES*40)-1
	sta kVectors.Screen2+((MCSSD_NUM_LINES+1)*40)-1
	.word MCSSD_SCREEN_CODE_DEST + $1800
	.word MCSSD_SCREEN_CODE_DEST+ $1800 + ((MCSSD_NUM_LINES*40)*6)
	.word kVectors.Screen-1
Screen2To1
	lda kVectors.Screen2+(MCSSD_NUM_LINES*40)-1
	sta kVectors.Screen+((MCSSD_NUM_LINES+1)*40)-1
	.word MCSSD_SCREEN_CODE_DEST + $1800 + ((MCSSD_NUM_LINES*40)*6) +1
	.word MCSSD_SCREEN_CODE_DEST+ $1800 + ((MCSSD_NUM_LINES*40)*6) + ((MCSSD_NUM_LINES*40)*6) +1
	.word kVectors.Screen2-1
.pend	
	
.include "..\C64Libs\ScanJoystick.asm"
CRAMPart1 = $4000 ; -4b40
CRAMPart2 = $4b41 ; -5591
CopyScreen1To2 = $5800 ; -6e80
CopyScreen2To1 = $6e81 ; -8501

scrollScreenDownOne
;	inc $d020
;	inc $d020
	ldx #39
-	lda MCSSD_SCREEN_SRC+$1e0,x
	sta FourLineBuffer,x
	dex
	bpl -
	jsr MCSSD_SCREEN_CODE_DEST
	;dec $d020
	jsr MCSSD_SCREEN_CODE_DEST + ((12*40)*6)+1
	ldx #39
-	lda FourLineBuffer,x
	sta MCSSD_SCREEN_SRC+$0208,x
	dex
	bpl -
;	dec $d020
	rts

.comment	
resetScroll
	#STAPW ScreenDump,LevelLinePtr
	#STAB #0,ScrollY
	rts
.endc

animatePlayer	
	#DECToHoldFF PlayerAnimCounter
	bpl _exit
	#STAB #8,PlayerAnimCounter
	#ADCB PlayerPtr,PlayerPtrDelta	
	cmp #kSprites.PlayerL	
	beq _flip
	cmp #kSprites.PlayerR	
	beq _flip	
_store	
	sta SpritePointers	
_exit	
	rts	
_flip
	lda PlayerPtrDelta
	eor #%11111110
	sta PlayerPtrDelta
	jsr startJenny
	lda PlayerPtr
	bne _store

; ----- @Set Up level@ -----
; D00C > D02D
;                 c  d  e  f  10 11 12 3 4  5  6 7 8   9   a b c  d  e f 2 1 2 3  4 5 6 7
VicDataLUT .byte 24,55,55,55,128,64,50,0,0,255,8,0,206,255,1,0,63,64,0,0,6,6,15,1,2,9,7,10,1,1,1,1,1,1,1
setUpLevelFunc
	sei
	#STAB #%01000000,$d011 ; turn the screen off
	lda #0	
-	cmp $d012	
	bne -	
	bit $d011	
	bmi -	
		
	ldx #LEVELDATAEND - LEVELDATA
	lda #0
-	sta LEVELDATA,x
	dex
	bpl -
	
;	#STAB #24,$D00C	
;	#STAB #55,$D00D ; SCORE
;	sta $D00E ; Lives
;	sta $D00F
;	#STAB #%10000000,$d010
;	#STAB #50,$D012 ; set the intial latch
;	#STAB #%11111111,$d015
;	#STAB #%00001000,$d016
;	#STAB #%11011110,$d018
;	#STAB #1,$D01A ; enable d012 raster
;	#STAB #%00111111,$d01C
;	#STAB #%01000000,$d01D
;	#STAB #7,$D020 ;0 - light blue -> red for timer
;	sta $d021
;	#STAB #0,$D022 ;1 - black for windows
;	#STAB #15,$D023 ;2 - other builing colour
;	#STAB #2,$D024 ;3 - fire in windows
;	#STAB #7,$D025
;	#STAB #9,$D026
;	#STAB #1,$D027
	ldx #size(VicDataLUT)-1
-	lda VicDataLUT,x
	sta $D00C,x
	dex
	bpl -
	lda #1
	sta $D02D
	sta $D02E
	
	#STAPW MainLevel,CurrFunction
	#STAPW animateFireIRQ,$0314 ; set raster function
	;jsr setupPlayer
	
	
	#STAB #kSprites.Score,kVectors.SpritePointer7
	sta kVectors.SpritePointer7_2
	#STAB #kSprites.Score+2,kVectors.SpritePointer8
	sta kVectors.SpritePointer8_2
	#STAB #250-25,PlayerSprite.y
	#STAB #kSprites.PlayerM,SpritePointers
;	#STAB #kSprites.PlayerM,PlayerPtr
	sta PlayerPtr
	#STAB #1,PlayerPtrDelta
	#STAB #8,PlayerAnimCounter
	sta PlayerYCounter
	#STAB #18,PlayerYCounter+1
	#STAB #28,PlayerYCounter+2
	#STAPW LevelMap,PlayerYPointer
	#STAPW LevelMap,PlayerYPointerMiddle
	#STAPW LevelMap,PlayerYPointerBottom
	#STAB #64,PlayerX
	ldx #0
	ldy #0
	jsr setPlayerX
	lda $d01e
	
	jsr setSpriteData
	jsr makeLevel
	jsr convertLevelMapToScreens
	#STAPW ScreenDump,LevelLinePtr
	;#STAB #0,ScrollY
	sta ScrollY
;	jsr removeAllEntity
	lda #255
	ldx #(kNumEntities-1)*2
	ldy #kNumEntities-1
-	sta Entity1Sprite.y,x
	sta EntState,y
	dey
	dex
	dex
	bpl -
	
	ldx #0
	txa ;lda #0
	jsr fillArea
	#STAB #22,ZPTemp1
appear
	jsr scrollScreenDownOne
;	jsr copyCurrentLineToScreenAndAdvancePointer
	ldy #39
-	lda (LevelLinePtr),y
	sta kVectors.Screen,y
	and #63
	tax
	lda Char_Colours,x
	sta $d800,y
	dey
	bpl -
	#ADCBW LevelLinePtr,#40
	jsr CopyScreen1To2
	dec ZPTemp1
	jsr scrollScreenDownOne
;	jsr copyCurrentLineToScreenAndAdvancePointer
	ldy #39
-	lda (LevelLinePtr),y
	sta kVectors.Screen2,y
	and #63
	tax
	lda Char_Colours,x
	sta $d800,y
	dey
	bpl -
	#ADCBW LevelLinePtr,#40
	jsr CopyScreen2To1
	dec ZPTemp1
	bpl appear
	
	ldy #39
-	lda (LevelLinePtr),y
	sta kVectors.Screen,y
	and #63
	tax
	lda Char_Colours,x
	sta $d800,y
	dey
	bpl -
	#ADCBW LevelLinePtr,#40
	jsr scrollScreenDownOne
	
	jsr setUp5SecondTimer
	inc ActiveScreen
	#STAB #%01010000,$d011
	cli ; enable irqs
	jmp MAINLOOP
	
SetLevelVarsToInitial
.comment
	#STAPW $0100,SpawnTimer
	#STAPW $0200,AirConSpawn
	#STAPW $8400,HBirdSpawn
	#STAPW $6000,FireSpawn
	#STAB #$00,Score
.endc
	lda #$01
	sta SpawnTimer+1
	lda #$02
	sta AirConSpawn+1
	lda #$84
	sta HBirdSpawn+1
	lda #$60
	sta FireSpawn+1
	lda #$00
	sta SpawnTimer
	sta AirConSpawn
	sta HBirdSpawn
	sta FireSpawn
	sta Score
	;#STAB #$00,Score+1
	;#STAB #$00,Score+2
	sta Score+1
	sta Score+2
	#STAB #3,Lives
	jmp plotLives
	;rts

AdvanceLevelVars
;	#SUBBW FireSpawn,250
;	bne _exit
;	#STAPW $6000,FireSpawn
	#ADCIW HBirdSpawn,$420
	#ADCIW AirConSpawn,$420
	cmp #$30 ; max aircon
	bcc _exit
	lda #$10
	sta AirConSpawn+1
	dec SpawnTimer
	bpl _exit
	#STAB #9,SpawnTimer
	dec SpawnTimer+1
_exit
	rts
.comment	
copyPETSCIIToCharset
	#RAMCharROM
	ldx #0	
	stx ZPTemp2
loop	
	ldy #0
	sty Pointer1+1
	lda CharTable,x
	asl a
	rol Pointer1+1
	asl a
	rol Pointer1+1
	asl a
	rol Pointer1+1
	sta Pointer1
	#ADCIW Pointer1,$d800
	stx ZPTemp1
	ldx ZPTemp2
-	lda (Pointer1),y
	sta kVectors.CustomChar,x
	inx
	iny
	cpy #8
	bne -
	stx ZPTemp2
	inc ZPTemp1
	ldx ZpTemp1
	cpx #size(CharTable)
	bne loop
	#IOandKernal
	rts
.endc

setRandomSeed	
	lda $d41b ;#%10111011;lda $d41b 	
	sta Random	
	lda $d41b; #%00110101;$d41b	
	sta Random+1	
	rts	
		
makeNextRandom
	; we want C to equal 1 Xor X16,X14,X13,X11
	; X0XX 0X00 0000 X000
	lda #$80
	sta ZPTemp10
	lda Random+1
	eor ZPTemp10 ; X16
	sta ZPTemp10
	asl a
	asl a
	eor ZPTemp10 ; X14
	sta ZPTemp10
	asl a
	eor ZPTemp10 ; X13
	sta ZPTemp10
	asl a
	asl a
	eor ZPTemp10
	sta ZPTemp10
	;lda Random
	;asl a
	;asl a
	;asl a
	;asl a
	;eor ZPTemp1
	;sta ZPTemp1
	asl ZPTemp10
	rol Random
	rol Random+1
	rts

makeLevel	
	#STAPW LevelMap,Pointer1	
;	lda #0	
	sta ZPTemp4
	sta ZPTemp2
	tay
	sty ZPTemp3
-	jsr makeNextRandom	
	lda Random	
	cmp AirConSpawn+1 ; set carry
	lda #0
	ldx ZPTemp2 ; have we done 3 in a row
	beq +
	sec ; force window
+	rol a ; move carry into A
	sta (Pointer1),y	
	eor #1 ; invert it
	adc ZPTemp4	; if it is 1 add it
	sta ZPTemp4	; save it
	lda ZPTemp4 ; load it
	cmp #3	; have we done 3 in a row
	bcc +
	inc ZPTemp2 ; mark it
+	dec ZPTemp3 ; dec line counter
	bpl + ; still same line
	lda #7 ; restore the line counter
	sta ZPTemp3 
	lda #0  ; clear 
	sta ZPTemp4 ; counter
	sta ZPTemp2 ; trip flag
+	dey	
	bne -	
	inc Pointer1+1	
	lda Pointer1+1	
	cmp #$08	
	bne -	
	lda #2	
	ldx #7
-	sta LevelMap,x
	dex
	bpl -
	ldx #3
	stx LevelMap+3
	inx
	stx LevelMap+4
	rts	
		
convertLevelMapToScreens	
	lda #0	
	ldx #160	
-	sta FourLineBuffer-1,x	
	dex	
	bne -	
	#STAPW ScreenDump-1,Pointer1	
	#STAPW LevelMap,Pointer2
	; for all rows - 25
	#STAB #95,ZPTemp1
	; build the line
	;#STAB #0,ZPTemp3
	stx ZPTemp3
_startLoop
	#STAB #0,ZPTemp4
_lineLoop
	; load 	byte
	#STAB #3,ZPTemp2
	ldy ZPTemp3
	lda (Pointer2),y
	asl a
	asl a
	tax
	; write line
	ldy ZPTemp4
	lda #45
	sta FourLineBuffer+3
	sta FourLineBuffer+43
	sta FourLineBuffer+83
	sta FourLineBuffer+123
	lda #46
	sta FourLineBuffer+36
	sta FourLineBuffer+36+40
	sta FourLineBuffer+36+80
	sta FourLineBuffer+36+120	
_blockLoop
	lda BlockMaps.line1,x
	sta FourLineBuffer+4,y
	lda BlockMaps.line2,x
	sta FourLineBuffer+44,y
	lda BlockMaps.line3,x
	sta FourLineBuffer+84,y
	lda BlockMaps.line4,x
	sta FourLineBuffer+124,y
	inx
	iny
	dec ZPTemp2
	bpl _blockLoop
	sty ZPTemp4
	inc ZPTemp3
	bne +
	inc Pointer2+1
+	cpy #32
	bne _lineLoop
	; copy to the final screen area
	ldy #160
-	lda FourLineBuffer-1,y
	sta (Pointer1),y
	dey
	bne -
	#ADCIW Pointer1,160
	dec ZPTemp1
	bpl _startLoop
	; c1fc is the end of the normal map
	; plot the top of the building
	ldx #0
	txa ; empty the sky
-	sta $c1fd,x
	sta $c2fc,x
	inx
	bne -
	ldx #33
	lda #31
-	sta $c203,x
	dex
	bpl -
	rts

.comment	
copyCurrentLineToScreenAndAdvancePointer
	ldy #39
-	lda (LevelLinePtr),y
	sta kVectors.Screen,y
	dey
	bpl -
	#ADCBW LevelLinePtr,#40
	rts
.endc

fillArea	
	ldy #00
	sty Pointer1
	ldy FillAreaDestHiLUT,x
	sty Pointer1+1
	ldy FillAreaDestCountLUT,x
	sty ZPTemp1
	ldy #0
-	sta (Pointer1),y
	iny
	bne -
	inc Pointer1+1
	dec ZPTemp1
	bne -
PrevRTS
	rts
	
AddFire
	lda #0
	sta NMIZPTemp2
	lda Random+1
	;and #$7F
	bpl +
	cmp HBirdSpawn+1
	bcs PrevRTS
	jmp addEntity
+	cmp #96
	bcs PrevRTS
	asl a
	asl a
	rol NMIZPtemp2 ; x4 to expand to rows
	; now times by 40 to get screen rows
	asl a
	rol NMIZPTemp2 ; 2x
	sta NMIZPTemp6 ; actally 8x
	ldx NMIZPTemp2
	stx NMIZPTemp7 
	asl a
	rol NMIZPTemp2 ; 4x
	asl a
	rol NMIZPTemp2 ; 8x
	sta NMIZPTemp1 ; ZPTemp1+2 = 8x
	ldx NMIZPTemp2
	stx NMIZPTemp4
	asl a		; 16x
	rol NMIZPTemp4
	asl a
	rol NMIZPTemp4 ; 32x
	clc
	adc NMIZPTemp1 ; 8x low
	sta Pointer1 ; store it
	lda NMIZPTemp4 ; 32 hi
	adc NMIZPTemp2 ; add 8x hi
	adc #>ScreenDump
	sta Pointer1+1 ; store 32 lo
AddFireEndOf32BitMul
	jsr startFire
	lda Pointer1
	sec
	sbc LevelLinePtr
	sta Pointer2
	lda Pointer1+1
	sbc LevelLinePtr+1
	sta Pointer2+1
	bmi _below ; it is below us
_adjustMap
	; ahead of us, so we just edit the map
	lda Random
	and #7
	tay
	#ADCB NMIZPTemp7,#>LevelMap
	lda #kFireValue
	sta (NMIZPTemp6),y
	tya
	asl a
	asl a
	sta NMIZPTemp5
;	clc
	adc Pointer1
	sta Pointer1
	lda Pointer1+1
	adc #0
	sta Pointer1+1
	jmp SetPointer1ToBeFireWindow
;	rts
	
_below
	; check to see if it in $400 range i.e pointer2 > -4
	cmp #256-4
	bcc _exit ; its below the screen
	jsr _adjustMap
	; now we also need to adjust the screen
	lda #<kVectors.Screen
	sec
	sbc Pointer2
	sta Pointer1
	ldx ActiveScreen
	lda ScreenPointers,x
	sbc Pointer2+1
	sta Pointer1+1
	lda Pointer1
	sec
	sbc #160
	sta Pointer1
	lda Pointer1+1
	sbc #0
	sta Pointer1+1
	lda Pointer1
	clc
	adc NMIZPTemp5
	sta Pointer1
	sta Pointer2
	lda Pointer1+1
	adc #0
	sta Pointer1+1
	and #%00000011
	ora #$d8
	sta Pointer2+1
	and #$0f
	cmp #$04
	bcs _exit
	jsr SetPointer1ToBeFireWindowOnScreen
	; if we are above 4 pixels in the scroll
	; we also need plot down 1 rom on the 
	; other screen
	; make sure we are not right down the bottom where it will go off the screen
;	lda Pointer1+1
;	and #7
;	cmp #4
;	bcs _Exit
;	cmp #3
;	bne _safe
;	lda Pointer1
;	cmp #$70
;	bcs _Exit
;_safe	
	lda Pointer1
	clc
	adc #40
	sta Pointer1
	lda Pointer1+1
	eor #$10
	adc #0
	sta Pointer1+1
	jsr SetPointer1ToBeFireWindowOnScreen
_exit
	rts
ScreenPointers
	.byte >kVectors.Screen2,>kVectors.Screen
animateFire
	lda FireTimer
	clc
	adc #1
	and #3
	sta FireTimer
	beq +
	rts
+	lda FireIndex
	clc
	adc #1
	and #7
	sta FireIndex
;	tax
;	lda FireColourTable,x
;	sta $D024
	rts
	
SetPointer1ToBeFireWindow	
	ldx #size(WindowIndex)-1
-	ldy WindowIndex,x	
;	lda (Pointer1),y	
;	ora #$80 ; convert to fire	
	lda WindowTiles,x
	sta (Pointer1),y	
	dex	
	bpl -	
	rts

SetPointer1ToBeFireWindowOnScreen	
	ldx #size(WindowIndex)-1
-	ldy WindowIndex,x	
;	lda (Pointer1),y	
;	ora #$80 ; convert to fire	
	lda WindowTilesOnscreen,x
	sta (Pointer1),y	
	lda #2
	sta (Pointer2),y
	dex	
	bpl -	
	rts
; ----- @NMI@ -----

setUp5SecondTimer
;&&trashes a			
	#STAPW TODNMINextThing,$318 ; set NMI register
	#STAB #$80,$DD0F				
NMIInternal	
;&&trashes a
	lda #0			
	sta $DD0B 		
	sta $DD0A
	;sta $DD08
	#STAB SpawnTimer+1,$DD09		
	#STAB SpawnTimer,$DD08
	lda #0
	sta $DD0F
	; clear current time
	sta $DD0B
	sta $DD0A
	sta $DD09
	sta $DD08
	#STAB #$84,$DD0D ; enable timer alarm
	lda $DD0D
	rts

TODNMINextThing	
	#SaveAllRegisters
	cld
	jsr AddFire
	jsr setUp5SecondTimer
	inc FireCount
	lda FireCount
	cmp #128
	bne +
	lda #kDeathMode.buildingBurntDown
	sta DeathMode
	lda #127
+	lsr a
	lsr a
	lsr a
	lsr a
	tax
	lda BackgroundColourTable,x
	sta $d021
	sta $d020
	pla
	tay
	pla
	tax
	pla
EmptyNMI
	cli
	rti
	
; ----- @score@ -----
.comment
awardRowScore
	dec LineConterForScore
	bpl _exit
	lda #4
	sta LineConterForScore	
	sed
	lda Score
	clc
	adc #$10
	sta Score
	lda Score+1
	adc #0
	sta Score+1
	lda Score+2
	adc #0
	sta Score+2
	cld
	bcc _exit
	inc Lives
_exit
	rts 	
.endc		
		
plotScoreToSprite	
;	inc $D020
	ldx #(8*3)-1	
	lda #0	
	sta ZPTemp3 ; sprite offset
-	sta ScoreSprite,x	
	dex	
	bpl -	
	ldx #2	
	stx ZPTemp1	; num bytes	
-	lda #$f0
	sta ZPTemp2 ; char mask	
	lda Score,x	
	pha	
	and #$f0	
	lsr a	
	tay	
	jsr plotYToSpriteIndex
	lda #$0f
	sta ZPTemp2
	pla
	and #$0f
	asl a
	asl a
	asl a
	tay
	jsr plotYToSpriteIndex
	inc ZPTemp3
	dec ZPTemp1
	ldx ZPTemp1
	bpl -
;	dec $d020
	rts
		
plotYToSpriteIndex
	ldx ZPTemp3
	txa
	clc
	adc #8*3
	sta _comp
-	lda Font,y
	and ZPTemp2
	ora ScoreSprite,x
	sta ScoreSprite,x
	inx
	inx
	inx
	iny
_comp = *+1	
	cpx #00	
	bne -	
	rts	
	
plotLives
	ldx #62	
	lda #0	
	sta ZPTemp3 ; sprite offset
-	sta LivesSprite,x	
	dex	
	bpl -	
	lda #$ff	
	sta ZPTemp2 ; dont mask	
	lda Lives	
	cmp #6
	bcc +
	lda #5
+	sta ZPTemp4	
-	ldx ZPTemp4
	lda LivesIndexLUT,x
	tax
	ldy #0	
-	lda LivesChar,y
	and ZPTemp2
	ora LivesSprite,x
	sta LivesSprite,x
	inx
	inx
	inx
	iny
	cpy #7	
	bne -	
	dec ZPTemp4	
	bpl --	
	rts	
		
LivesIndexLUT .byte 0,1,2,24,25,26	
		
; ----- @IRQ@ -----
animateFireIRQ
;inc $d020
	cld
	lda $d012
	cmp #250
	bcc + ; are we done with this frame
	lda FireIndex	
	sta FireActiveIndex	; reset the index
	lda #35	; set us to start at the top again
	sta RasterValue
	; set sprite data
	jsr setSpriteData
	lda FlipD018
	beq _justD011
	dec FlipD018
	;inc $d020
	lda $d018
	eor #64
	sta $d018
	;dec $d020
_justD011
	; set scroll
	;dec $d020
	#ANDORB $d011,#%01110000,ScrollY
	;inc $d020
+	lda RasterValue
	adc #14
	cmp #241
	bcc +
	lda #251
+	sta $d012
	sta RasterValue
	lda FireActiveIndex
	clc
	adc #1
	and #7
	sta FireActiveIndex
	tax
	lda FireColourTable,x
	sta $D024
;dec $d020
emptyIRQ
	#STAB #$FF,$d019
	jmp $EA81

setSpriteData
	ldx #11
-	lda PlayerSprite,x
	sta $d000,x
	dex
	bpl -
	ldx #5
-	lda SpritePointers,x
	sta kVectors.SpritePointer1,x
	sta kVectors.SpritePointer1_2,x
	dex
	bpl -
	rts
	
; ----- @String printing@ -----
; a = x pos	
; y = y pos	
; x = string	
plotStringAAtIndexX			
;&&trashes a,x,y,Pointer1,Pointer1+1,Pointer2,Pointer2+1,Pointer3,Pointer3+1		
	clc		
	adc screenRowLUTLO,y		
	sta Pointer2		
	sta Pointer3		
	lda screenRowLUTHi,y
	adc #0
	sta Pointer2+1
	eor # (>kVectors.Screen) ^ $d8
	sta Pointer3+1
	lda StringTableLUT.lo,x			
	sta Pointer1			
	lda StringTableLUT.hi,x			
	sta Pointer1+1			
	ldy #0			
_l	lda (Pointer1),y			
	beq _done		
	sta (Pointer2),y			
	lda #1			
	sta (Pointer3),y			
_next			
	iny			
	bne _l			
_done			
	rts		

; ----- @Entity code@ -----
addEntity
	; find empty slot
	ldx #kNumEntities-1
-	lda EntState,x
	bmi _foundOne
	dex
	bpl -
	rts ; all full
_foundOne
	; mark as taken but setting slot
	lda Random+1
	and #3 ; make me a variable
	sta EntState,x
	tay ; convert entity type into index Y
	; set X,Y,pointer for entity
	lda EntityStartPointerLUT,y
	sta SpritePointers+1,x
	lda #4
	sta EntAnimeTimer,x
	lda EntityStartXLUT,y
	sta EntityX,x
	tay
	txa
	asl a
	tax
	tya
	lda #30
	sta Entity1Sprite.y,x
	; return
	rts

.comment	
removeAllEntity
	lda #255
	ldx #(kNumEntities-1)*2
	ldy #kNumEntities-1
-	sta Entity1Sprite.y,x
	sta EntState,y
	dey
	dex
	dex
	bpl -
	rts
.endc
	
shiftAndDisableEntities
	ldx #(kNumEntities-1)*2
	ldy #kNumEntities-1
-	lda Entity1Sprite.y,x
	cmp #1
	adc #0 ; inc twice and hold 0
	cmp #1
	adc #0
	sta Entity1Sprite.y,x
	bne +
	lda #kEntityState.free
	sta EntState,y
+	dey
	dex
	dex
	bpl -
	rts
	
animateEntities
	ldy #kNumEntities-1
_entLoop
	lda EntState,y
	tax
	bpl _found
_endLoopRenter
	dey
	bpl _entLoop
_exit
	rts
_found
	sty ZPTemp2
	stx ZPTemp3
	lda EntityFuncTable._lo,x
	sta _jmpP
	lda EntityFuncTable._hi,x
	sta _jmpP+1
_jmpP = *+1
	jmp $0000
_endAnim
	ldy ZPTemp2
	ldx ZPTemp3
	lda EntAnimeTimer,y
	cmp #$FF
	sbc #0
	sta EntAnimeTimer,y
	bpl _endLoopRenter
	cpx #kEntityState.movingLeft
	beq _eorFrame
	cpx #kEntityState.movingRight
	bne _endLoopRenter
_eorFrame
	lda SpritePointers+1,y
	eor #1
	sta SpritePointers+1,y
	lda #16
	sta EntAnimeTimer,y
	bne _endLoopRenter

EntityFuncTable		
_lo .byte <birdLeft,<birdRight,<BirdDiveWaitL,<BirdDiveWaitR,<BirdDiveL,<BirdDiveR		
_hi .byte >birdLeft,>birdRight,>BirdDiveWaitL,>BirdDiveWaitr,>BirdDiveL,>BirdDiveR		

birdLeft		
	lda EntityX,y
	clc
	adc #1
	sta EntityX,y
	bpl +
	lda EntState,y
	eor #1 ; make it go the other way
	sta EntState,y 
	lda SpritePointers+1,y
	eor #2
	sta SpritePointers+1,y
+	iny ; inc the sprite num by one to account for player relative
	tya
	tax
	asl a
	tay
	jsr setPlayerX	
	jmp animateEntities._endAnim		
birdRight		
	lda EntityX,y
	sec
	sbc #1
	sta EntityX,y
	bpl +
	lda EntState,y
	eor #1 ; make it go the other way
	sta EntState,y 
	lda SpritePointers+1,y
	eor #2
	sta SpritePointers+1,y
+	iny ; inc the sprite num by one to account for player relative
	tya
	tax
	asl a
	tay
	jsr setPlayerX	
	jmp animateEntities._endAnim		

BirdDiveWaitL
	lda EntAnimeTimer,y
	cmp #$FF
	sbc #0
	sta EntAnimeTimer,y
	bmi _switch
	jmp animateEntities._endLoopRenter
_switch	
	lda #kEntityState.divingLeft
	sta EntState,y	
	jmp animateEntities._endLoopRenter	
.comment
	tya
	tax
	asl a
	tay
	; get the players Pos X, subtract Mine
	lda PlayerX
	sec
	sbc EntityX,x
	sta ZPTemp4
	; get the mine Pos Y, subtract Players
	lda PlayerSprite.y
	sec
	sbc Entity1Sprite.y,y
	; if negative just go
	bmi _go
	; if delta<DeltaX go
	cmp ZPTemp4
	bcc _go
	bcs _end
_go
	lda #kEntityState.divingLeft
	sta EntState,x
_end
	iny ; inc the sprite num by one to account for player relative
	iny
	inx
.endc
_endNoAdjust
;	jsr setPlayerX	
	ldy ZPTemp2
	jmp animateEntities._endLoopRenter	
	
	
BirdDiveL	
	lda EntityX,y
	clc
	adc #1
	sta EntityX,y
	iny
	tya
	tax
	asl a
	tay
	jsr setPlayerX
	lda PlayerSprite.y,y ; y has been inc so it now references entity sprites
	clc
	adc #2
	sta PlayerSprite.y,y
	bcc BirdDiveWaitL._endNoAdjust
	lda #$ff
	sta PlayerSprite.y,y
	ldx ZPTemp3
	sta EntState,x
	bne BirdDiveWaitL._endNoAdjust
	
BirdDiveWaitR
	lda EntAnimeTimer,y
	cmp #$FF
	sbc #0
	sta EntAnimeTimer,y
	bmi _switch
	jmp animateEntities._endLoopRenter
_switch	
	lda #kEntityState.divingRight
	sta EntState,y	
	jmp animateEntities._endLoopRenter	
.comment
	tya
	tax
	asl a
	tay
	; get the players Pos X, subtract Mine
	lda EntityX,x
	sec
	sbc PlayerX
	sta ZPTemp4	
		; get the mine Pos Y, subtract Players
	lda PlayerSprite.y
	sec
	sbc Entity1Sprite.y,y
	; if negative just go
	bmi _go
	; if delta<DeltaX go
	cmp ZPTemp4
	bcc _go
	bcs _end
_go
	lda #kEntityState.divingRight
	sta EntState,x
_end
	iny
	iny
	inx
_endNoAdjust
	jsr setPlayerX	
	ldy ZPTemp2
	jmp animateEntities._endLoopRenter		
.endc

BirdDiveR	
	lda EntityX,y
	sec
	sbc #1
	sta EntityX,y
	iny
	tya
	tax
	asl a
	tay
	jsr setPlayerX
	lda PlayerSprite.y,y ; y has been inc so it now references entity sprites
	clc
	adc #2
	sta PlayerSprite.y,y
	bcc BirdDiveWaitL._endNoAdjust
	lda #$ff
	sta PlayerSprite.y,y
	ldx ZPTemp3
	sta EntState,x
	bne BirdDiveWaitL._endNoAdjust		
			
; ----- @Title Screen@ -----
SetupTitleScreen
	lda #%00001000
	sta $d011
	lda #0
-	cmp $d012	
	bne -	
	bit $d011	
	bmi -	
	;#STAB #%00000000,$d016
;	#STAB #0,$d015 ; turn off the sprites
	sta $d016
	sta $d015
	#STAB #%11000100,$d018
	lda #96
	ldx #kFillIndexs.Screen ; empty the screen
	jsr fillArea	
	ldx #0
	stx $d020
	stx $d021
-	lda TS_Logo,x
	sta kVectors.Screen,x
	tay
	lda TS_Colours,y
	sta $d800,x
	lda TS_Logo+$100,x
	sta kVectors.Screen+$100,x
	tay
	lda TS_Colours,y
	sta $d900,x
	dex
	bne -
	ldx #8
-	lda TS_Logo+$200,x
	sta kVectors.Screen+$200,x
	lda #7
	sta $da00,x
	dex
	bpl -
	#STAPW $D800+13*40,Pointer1
	ldx #11 
-	ldy #39
-	lda TS_Colours,y
	sta (Pointer1),y
	dey
	bpl -
	#ADCBW Pointer1,#40
	dex
	bpl --
	lda #%00011011
	sta $d011
	lda #0
-	cmp $d012	
	bne -	
	bit $d011	
	bmi -	
SetInitialVectors	
.comment	
	#STAPW kVectors.Screen+(13*40)+9,Pointer1	
	#STAPW kVectors.Screen+(13*40)+10,Pointer4	
	#STAPW kVectors.Screen+(14*40)-1 ,Pointer2	
	#STAPW kVectors.Screen+(14*40)+1,Pointer5	
	#STAPW kVectors.Screen+(14*40)  ,Pointer6	
;	#STAPW kVectors.Screen+(14*40)  ,Pointer7	
	#STAPW TitleText,Pointer3	
.endc	
	ldx #11
-	lda PointerScreenLUT,x
	sta Pointer1,x	
	dex	
	bpl -			

	#STAB #0,ZPTemp4 ;char index	
	sta ZPTemp5	; mode, new char/empty
	sta ZPTemp6 ; scroll start index
	lda #5
	sta ZPTemp7
TitleLoop
	ldx #2
	stx ZPTemp1
-	lda #0
	cmp $d012	
	bne -	
	bit $d011	
	bmi -	
	jsr ScanJoystick
	lda joyFire
	beq +
	jmp justWaitForFire
+	dec ZPTemp1	
	bpl -	
	lda ZPTemp5 ; mode
	bne _empty
	ldy ZPTemp4 ;char index
	cpy #22
	beq _empty
	lda (Pointer3),y
	inc ZPTemp4
	jmp _store
_empty
	lda #96
_store
	ldy #0
	sta (Pointer2),y
	ldy ZPTemp6
	lda (Pointer1),y
	cmp #96
	beq _copy
	inc ZPTemp6
	ldx ZPTemp6
	cpx #22
	beq _advanceAndSwap
	iny
_copy
	lda (Pointer4),y
	sta (Pointer1),y
	iny
	cpy #30
	bne _copy
	lda ZPtemp5
	eor #1
	sta ZPTemp5
	jmp TitleLoop
_advanceAndSwap 
	#ADCBW Pointer3,#22
	;#STAB #0,ZPTemp4 ;char index	
	dec ZPTemp4
	lda #0
	sta ZPTemp5	; mode, new char/empty
	lda #29
	sta ZPTemp6 ; scroll start index
	
TitleLoopR
	ldx #2
	stx ZPTemp1
-	lda #0
	cmp $d012	
	bne -	
	bit $d011	
	bmi -	
	jsr ScanJoystick
	lda joyFire
	beq +
	jmp justWaitForFire
+	dec ZPTemp1	
	bpl -	
	lda ZPTemp5 ; mode
	bne _empty
	ldy ZPTemp4 ;char index
	;cpy #22
	bmi _empty
	lda (Pointer3),y
	dec ZPTemp4
	jmp _store
_empty
	lda #96
_store
	ldy #0
	sta (Pointer6),y
	ldy ZPTemp6
	lda (Pointer5),y
	cmp #96
	beq _copy
	dec ZPTemp6
	ldx ZPTemp6
	cpx #7
	beq _advanceAndSwap
	dey
_copy
	lda (Pointer6),y
	sta (Pointer5),y
	dey
	bpl _copy
	lda ZPtemp5
	eor #1
	sta ZPTemp5
	jmp TitleLoopR 
_advanceAndSwap 
	#ADCBW Pointer3,#22
	inc ZPTemp4 ;char index	
	lda #0
	sta ZPTemp5	; mode, new char/empty
	sta ZPTemp6 ; scroll start index
	
	#ADCBW Pointer1,#80
	#ADCBW Pointer2,#80
	#ADCBW Pointer4,#80
	#ADCBW Pointer5,#80
	#ADCBW Pointer6,#80
	dec ZPTemp7
	bmi justWaitForFire
	jmp TitleLoop
justWaitForFire
-	jsr ScanJoystick
	lda joyFire
	beq -
	jsr setRandomSeed
	jsr SetLevelVarsToInitial
	jsr plotScoreToSprite
	jmp setUpLevelFunc
	
; ----- @SFX@ -----
startFire
	lda #$ec
	sta $d405
	lda #$6c
	sta $d406
	lda #%10000001
	sta $d404
	;ldx #$00
	;lda FireLUT,x
	;sta $d404,x
	;inx
	;lda FireLUT,x
	;sta $d404,x
	;inx
	;lda FireLUT,x
	;sta $d404,x
	lda #%00011111
	sta $d418
	sta FireSFXTimer
	lda #$80
	sta $d400
	rts
FireLUT	
.byte %10000001,$ec,$6c
	
startJenny
	lda #$03
	sta $d40c
	sta $d40d
;	lda #$a0
;	sta $d408
	lda Random
	sta $d407
	lda Random+1
	ora #$80
	sta $D408
	ldx #$80
	stx $d40b
	inx
	stx $d40b
	rts
	
updateFire
	#DecToHoldFF FireSFXTimer
	beq _turnOff
	and #1
	beq _exit
	lda Random
	sta $d400
_exit
	rts
_turnOff
	lda #$80
	sta $d404
	rts

KillSFX
	lda #$80
	sta $d404
	sta $d40b
	rts
		
; ----- @Dutch Breeze text appear@ -----
.comment
a73C2 .byte ?
a73C3 .byte ?
a111F .byte ?

ShiftRightAndPlot 
		LDX _currIndex
        LDA kVectors.Screen,X
        CMP #$20 ; space
        BEQ _scroll ; no, skip
        INX  ; decrease number to copy 
        STX _currIndex
_currIndex   =*+$01
_scroll	LDX #$22
_loop	LDA kVectors.Screen+1,X
		STA kVectors.Screen+0,X
		LDA kVectors.Screen+81,X
		STA kVectors.Screen+80,X
		LDA kVectors.Screen+161,X
		STA kVectors.Screen+160,X
        LDA kVectors.Screen+241,X
        STA kVectors.Screen+240,X
        INX 
		CPX #$28
        BNE _loop
        LDX a73C2
        BEQ _plotNext
        LDA #$20
        STA kVectors.Screen+39
        STA kVectors.Screen+119
        STA kVectors.Screen+199
        STA kVectors.Screen+279
        RTS 

_plotNext   
		LDY #$00
		LDA (Pointer1),Y
		STA kVectors.Screen+39
		LDY #$50
		LDA (Pointer1),Y
		STA kVectors.Screen+119
		LDY #$A0
		LDA (Pointer1),Y
		STA kVectors.Screen+199
        LDY #$F0
        LDA (Pointer1),Y
        STA kVectors.Screen+279
        INC Pointer1
        BNE _exit
        INC Pointer1+1
_exit	RTS 

PlotAndShiftLeft 
		LDX _index
        LDA kVectors.Screen+40,X
        CMP #$20
        BEQ _emptyChar
        DEX 
        BNE _nextChar
		LDY #$00
        LDA (Pointer2),Y
        STA kVectors.Screen+40,X
        LDY #$50
        LDA (Pointer2),Y
        STA kVectors.Screen+120,X
        LDY #$A0
        LDA (Pointer2),Y
		STA kVectors.Screen+200,X
        LDY #$F0
        LDA (Pointer2),Y
        STA kVectors.Screen+280,X
        LDY #$00
        LDA (Pointer1),Y
        STA kVectors.Screen+39
        LDY #$50
        LDA (Pointer1),Y
        STA kVectors.Screen+119
        LDY #$A0
        LDA (Pointer1),Y
        STA kVectors.Screen+199
        LDY #$F0
        LDA (Pointer1),Y
        STA kVectors.Screen+279
        LDA #$00
        STA a111F
        LDA a73C3
        STA a73C2
        RTS 

_nextChar   STX _index
_index   =*+$01
_emptyChar   LDX #$05
_loop	LDA kVectors.Screen+39,X
        STA kVectors.Screen+40,X
		LDA kVectors.Screen+119,X
        STA kVectors.Screen+120,X
        LDA kVectors.Screen+199,X
        STA kVectors.Screen+200,X
        LDA kVectors.Screen+279,X
        STA kVectors.Screen+280,X
        DEX 
        BNE _loop
        LDX a73C2
        BNE b1E8A
        JMP j72AE

b1E8A   DEC a73C2
        LDA #$20
        STA kVectors.Screen+40
        STA kVectors.Screen+120
        STA kVectors.Screen+200
        STA kVectors.Screen+280
        RTS 
        
j72AE   LDA a73C3
        STA a73C2
        LDY #$00
        LDA (Pointer2),Y
        STA kVectors.Screen+40
        LDY #$50
        LDA (Pointer2),Y
        STA kVectors.Screen+120
        LDY #$A0
        LDA (Pointer2),Y
        STA kVectors.Screen+200
        LDY #$F0
        LDA (Pointer2),Y
        STA kVectors.Screen+280
        LDX Pointer2
        DEX 
        CPX #$FF
        BNE _8bit
        DEC Pointer3
_8bit   STX Pointer2
        RTS 
.endc		
EntityStartXLUT	.byte 80,80,0,127
EntityStartPointerLUT .byte kSprites.BirdRa,kSprites.BirdLa,kSprites.BirdDiveR,kSprites.BirdDiveL

WindowIndex .byte 45,46,85,86
WindowTiles .byte 192+43,192+44,192+41,192+42
WindowTilesOnscreen .byte 192+41,192+42,192+43,192+44
kFillIndexs .block
	CRAM = 0
	Variables = 1
	Screen = 2
.bend

FillAreaDestHiLUT .byte $D8,$02,$30	
FillAreaDestCountLUT .byte $04,$06,$08	

FireColourTable .byte 2,8,10,7,7,10,8,2	
BackgroundColourTable .byte 6,14,15,12,11,2,10,7,7
CharTable .byte 32,32+128,127,102

BlockMaps .block
	line1 .byte $4a,$4b,$4b,$4c, $4a,$4b,$4b,$4c ,$40,$40,$40,$40 ,$40,$40,$5b,$5c ,$5d,$5e,$40,$40
	line2 .byte $44,$4d,$4e,$47, $44,$45,$46,$47 ,$62,$66,$67,$40 ,$40,$40,$57,$58 ,$59,$5a,$40,$40
	line3 .byte $44,$45,$46,$47, $44,$45,$46,$47 ,$62,$63,$64,$65 ,$40,$40,$53,$54 ,$55,$56,$40,$40
	line4 .byte $41,$42,$42,$43, $41,$42,$42,$43 ,$40,$40,$40,$40 ,$40,$40,$4f,$50 ,$51,$52,$40,$40
.bend

screenRowLUTLO		
.for ue = kVectors.Screen, ue < kVectors.Screen + $400, ue = ue + 40
.byte <ue
.next
screenRowLUTHi	
.for ue = kVectors.Screen, ue < kVectors.Screen + $400, ue = ue + 40
.byte >ue
.next

PointerScreenLUT .word (kVectors.Screen+(13*40)+9),(kVectors.Screen+(14*40)-1),(TitleText),(kVectors.Screen+(13*40)+10),(kVectors.Screen+(14*40)+1),(kVectors.Screen+(14*40))	

Font
;0
.dfont '.#...#..'
.dfont '#.#.#.#.'
.dfont '#.#.#.#.'
.dfont '#.#.#.#.'
.dfont '#.#.#.#.'
.dfont '#.#.#.#.'
.dfont '#.#.#.#.'
.dfont '.#...#..'
;1
.dfont '.#...#..'
.dfont '##..##..'
.dfont '.#...#..'
.dfont '.#...#..'
.dfont '.#...#..'
.dfont '.#...#..'
.dfont '.#...#..'
.dfont '###.###.'
;2
.dfont '.#...#..'
.dfont '#.#.#.#.'
.dfont '..#...#.'
.dfont '.#...#..'
.dfont '.#...#..'
.dfont '#...#...'
.dfont '#...#...'
.dfont '###.###.'
;3
.dfont '##..##..'
.dfont '#.#.#.#.'
.dfont '..#...#.'
.dfont '.#...#..'
.dfont '..#...#.'
.dfont '..#...#.'
.dfont '#.#.#.#.'
.dfont '##..##..'
;4
.dfont '#.#.#.#.'
.dfont '#.#.#.#.'
.dfont '#.#.#.#.'
.dfont '#.#.#.#.'
.dfont '###.###.'
.dfont '..#...#.'
.dfont '..#...#.'
.dfont '..#...#.'
;5
.dfont '###.###.'
.dfont '#...#...'
.dfont '#...#...'
.dfont '.#...#..'
.dfont '.#...#..'
.dfont '..#...#.'
.dfont '..#...#.'
.dfont '##..##..'
;6
.dfont '.#...#..'
.dfont '#...#...'
.dfont '#...#...'
.dfont '##..##..'
.dfont '#.#.#.#.'
.dfont '#.#.#.#.'
.dfont '#.#.#.#.'
.dfont '.#...#..'
;7
.dfont '###.###.'
.dfont '..#...#.'
.dfont '..#...#.'
.dfont '..#...#.'
.dfont '.#...#..'
.dfont '.#...#..'
.dfont '#...#...'
.dfont '#...#...'
;8
.dfont '.#...#..'
.dfont '#.#.#.#.'
.dfont '#.#.#.#.'
.dfont '.#...#..'
.dfont '#.#.#.#.'
.dfont '#.#.#.#.'
.dfont '#.#.#.#.'
.dfont '.#...#..'
;9
.dfont '.##..##.'
.dfont '#.#.#.#.'
.dfont '#.#.#.#.'
.dfont '.##..##.'
.dfont '..#...#.'
.dfont '..#...#.'
.dfont '.#...#..'
.dfont '#...#...'
LivesChar
.dfont '...##...'
.dfont '...##...'
.dfont '.######.'
.dfont '...##...'
.dfont '...##...'
.dfont '..####..'
.dfont '.##..##.'
.dfont '........'

kStringIndex .block
	rescue = 0
	diedFlame = 1
	caughtInFlames = 2
	byBird = 3
	save0 = 4
	save7 = 11
	gameOver = 12
.bend

StringTableLUT .mMakeTable strRescue,strDiedFlame,strDiedCaughtFlames,strHitByBird,Save0,Save1,Save2,Save3,Save4,Save5,Save6,Save7,GameOver	
DeathStringIndex .byte 0,9,4,6
.enc screen			
strRescue .text "Rescue the ",0	
strDiedFlame .text "You got burnt and fell",0
strDiedCaughtFlames .text "The flames got too intense and               the building colapsed",0
strHitByBird .text "A bird hit you and you fell",0
Save0 .text "Cat",0
Save1 .text "Dog",0
Save2 .text "Motor Bike",0
Save3 .text "B128",0
Save4 .text "HL3",0
Save5 .text "Prince",0
Save6 .text "Cheese",0
Save7 .text "Dragon",0
GameOver .text "Game Over",0
;.enc title
;.cdef "az", 1
;.cdef "09", 48
;.cdef "  ", 32
;.cdef "!!", 33
;.cdef "&&", 38
;.cdef "()", 41
;.cdef "::", 58
;.cdef "~~", 96

TitleText .text "you are the best fire "
		  .text "rescuer in town.climb "
		  .text "to the top and rescue "
		  .text " the thing.don't take "
		  .text " long or the building "
		  .text "will colpase.the birds"
		  .text "  are angry and will  "
		  .text "attack.some even dive "
		  .text "at you.1up each 10,000"		
		  .text "   code : oziphantom  "		
		  .text "    art : saul c      "		
		  .text "- press fire to play -"		
				
TS_Logo .include "Logo-map.asm"
TS_Colours .include "Logo-colors.asm"
Char_Colours .binary "attribs.raw",0,45
.byte 0,0

*= $3800
.binary "chars.raw",0,360
.dfont '.......#'
.dfont '.......#'
.dfont '.......#'
.dfont '.......#'
.dfont '.......#'
.dfont '.......#'
.dfont '.......#'
.dfont '.......#'
.dfont '#.......'
.dfont '#.......'
.dfont '#.......'
.dfont '#.......'
.dfont '#.......'
.dfont '#.......'
.dfont '#.......'
.dfont '#.......'

*= $3A00
.binary "sprites.prg",2
ScoreSprite = $3A00 + (9*64)
LivesSprite = $3A00 + (11*64)