	;BIG TIME - Zooming logo
	;
	;By Jobbo 12/11/94

FALSE	Equ	     0
TRUE	Equ 	    -1

RAMPWIDTH	Equ	      1024/8
RAMPHEIGHT	Equ	         256
RAMPPLANES	Equ	           5

MINSIZE	Equ	           0
MAXSIZE	Equ	RAMPHEIGHT-1


	Incdir	Sources:Includes/
	Include	Hardware.i
	Include	HW_Macros.i
	Include	HW_Start.i
	Include	PT-Play.i
mt_data	Incbin	Modules:MOD.Livin'_Insanity

Main	;Switch on DMA for copper and bitplanes
	Move.w	#SETIT!DMAEN!BPLEN!COPEN,DMACON(a5)

	;Set address of Level 3 interrupt handler
	Move.l	#Level3,$6c

	;Switch on VBI interrupt
	Move.w	#SETIT!INTEN!VERTB,INTENA(a5)

	;Set up for first event in story board
	Bsr	NextEvent
	Jsr	mt_init

	;Set copper list
	Bsr	DoCopListDB

	;Strobe copper to start
	Move.w	#0,COPJMP1(a5)

MouseWait	;Repeat until mouse key
	Btst	#6,CIAAPRA
	Bne.s	MouseWait

	Jsr	mt_end

	;Exit
	Move.w	#INTEN,INTENA(a5)	;Stop Interrupts
	Rts


;======================================================================================================


Level3	Jsr	mt_music
	
	;Point copper list at bitmap
	Move.l	#Bitmap,d0		;d0 -> Start of bpl data
	Move.w	Size,d2		;Upper word = Unary part
	Mulu	#RAMPWIDTH*RAMPPLANES,d2	;Size * Byte per line
	Add.w	#(RAMPWIDTH-40)/2-2,d2	;Position at centre of bitmap
	Add.l	d2,d0		;d0 = d0 + Offset for scrolling

	Tst.l	WaitFrames
	Beq.s	.NoWait		;Do update if equal to zero
	Sub.l	#1,WaitFrames		;Decrement wait 
	Bsr	SetUpBplPtrs		;Update ptrs in copper list
	Bra.s	.Exit		;Skip frame update
.NoWait

	;Do X position offset
	Move.w	Size,d2		;Upper word = Unary part
	Move.l	XOffset,d1		;d1 = X position offset
	Muls	d2,d1		;d1 = (d1 * Size) / Max size	
	Divs	#MAXSIZE+1,d1
	
	Move.w	d1,d3		;Use a copy
	AndI.w	#$f,d3		;d3 = d3 mod 16
	Mulu	#$11,d3		;So as to affect odd and even planes
				;i.e. $08 * $11 = $88
	Move.l	CopSSPtr,a0
	Move.w	d3,(a0)		;Change value in copper list

	Ext.l	d1		;Extend sign for long word
	Asr.l	#4,d1		;d1 = (d1 / 16) * 2
	Add.l	d1,d1		;This gives the offset in bytes
	Sub.l	d1,d0		;BplPtr + X position offset


	Bsr	SetUpBplPtrs		;Update ptrs in copper list

	Bsr	AddColourMoves		;Add Palette changes in copper list
	
	
	;Change the size
	Move.l	Size,d2		;This is a long word because I'm using
				;it as a fixed point number
	Add.l	Speed,d2		;Add speed to size	
	CmpI.l	#MAXSIZE*$10000,d2	;Size is in range 0..MAXSIZE
	Ble.s	.OkaySize

	Move.l	#MINSIZE*$10000,d2	;Reset size
	Bsr	NextEvent

.OkaySize	Move.l	d2,Size		;Store size

	;Swap copper lists for double buffering
.Exit	Bsr	DoCopListDB

	;Exit back to user mode
	Move.w	#VERTB,INTREQ(a5)	;Clear interrupt request bit
	Rte


;------------------------------------------------------------------------------------------------------


	;Deals with double buffering of copper lists.
	;Points the copper at one list and my work pointers at the other list.
	;Which list is which depends on CopToggle.
	;
	;Uses None
	;---------------------------------------------------------------------

CopToggle	Dc.w	0

DoCopListDB	Tst.w	CopToggle
	Bne.s	.NonZero

	Move.w	#1,CopToggle
	Move.l	#CopperList1,CopListPtr	;Display list 1
	Move.l	#SmoothScroll2,CopSSPtr	;Work on list 2
	Move.l	#BplPtrs2,CopBPsPtr
	Move.l	#ColourMoves2,CopCMsPtr
	Bra	.View
.NonZero
	Move.w	#0,CopToggle
	Move.l	#CopperList2,CopListPtr	;Display list 2
	Move.l	#SmoothScroll1,CopSSPtr	;Work on list 1
	Move.l	#BplPtrs1,CopBPsPtr
	Move.l	#ColourMoves1,CopCMsPtr

	;Point copper at list to view
.View	Move.l	CopListPtr,COP1LCH(a5)
	
	Rts


;------------------------------------------------------------------------------------------------------


	;Change zoom variables for the next event in the 
	;story board.
	;
	;Uses d0,a0
	;-----------------------------------------------

NextEvent	Lea	StoryBoard,a0		;a0 -> Position in story board
	Move.l	StoryPosition,d0
	
	Mulu	#4+4+4+4+4,d0
	Add.l	d0,a0		;a0 = a0 + (Offset * Bytes per event)

	Move.l	(a0)+,WaitFrames
	Move.l	(a0)+,AnimOffset
	Move.l	(a0)+,Speed
	Move.l	(a0)+,XOffset
	Move.l	(a0)+,YOffset

	Move.l	StoryPosition,d0	;Increase the story position and
	AddI.l	#1,d0		;check for the end position.
	CmpI.l	#NOOFEVENTS-1,d0
	Ble.s	.OkayPosition		
	Move.l	#0,d0
.OkayPosition	Move.l	d0,StoryPosition

	Rts


;------------------------------------------------------------------------------------------------------


	;Alter copper list area so as to change the palette
	;several times down the screen.
	;
	;Uses d0-d7,a0,a1
	;--------------------------------------------------

AddColourMoves	Lea	Chunky,a0		;a0 -> $xRGB Chunky graphics data
	Add.l	AnimOffset,a0		;a0 = a0 + Offset for anim frame
	Move.l	CopCMsPtr,a1		;a1 -> Colour changes in copper list		
	
	Move.w	Size,d2		;d2 = Size
	Add.w	d2,d2		;d2 = d2 * 2
				;This is because the ramp increase by
				;2 pixels each line

	Move.w	d2,d3		;Copy size
	Lsr.w	#2,d3		;d3 = 15 - (d3 / 8)
	Move.w	#15,Brightness		
	Sub.w	d3,Brightness		;Store in Brightness variable


	Move.w	#128,d5		;d5 = Offset for centre
	Move.w	d2,d0		;d5 = 128 - Size
	Sub.w	d0,d5
	AddI.w	#44,d5		;For top of display


	;Do Y position offset
	Move.l	YOffset,d1		;d1 = Y position offset
	Muls	d2,d1		;d1 = (d1 * Size) / Max size	
	Divs	#(MAXSIZE+1)*2,d1
	Add.w	d1,d5		;Add Y position offset


	MoveQ.w	#0,d0		;d0 = Counter for lines
	MoveQ.w	#0,d1		;0 is a dummy last Y pos
	MoveQ.b	#FALSE,d6		;d6 = Flag for going past Pal/NTSC
				;copper list border

ForColourLines	Move.w	d1,d4		;d4 = Last Y pos
	Move.w	d0,d1		;d1 = Y pos
	Mulu	d2,d1		;d1 = d1 * Size
	Add.w	d1,d1		;d1 = d1 * 2
	Divu	#31,d1		;d1 = d1 / 31 
				;Could Lsr #5,d1 which is faster
	Add.w	d5,d1		;Plus offset for top	

	Ble	.SkipThisLine		;Compare to zero, skip if on screen
	Cmp.w	d4,d1
	Ble	.SkipThisLine		;Skip if NOT bigger than last Y pos

	CmpI.w	#255,d1		;Check if above the Pal/NTSC border
	Ble.s	.OkayNTSC		;Yes
	CmpI.b	#FALSE,d6		;No, check if we need to do an extra
				;wait for the Pal/NTSC border
	Bne.s	.DoneAlready		;If d6 = FALSE don't do
	Move.b	#TRUE,d6	
	Move.l	#$ffe1fffe,(a1)+	;Insert wait for last NTSC pos
.DoneAlready
	CmpI.w	#255+44,d1
	Bgt	CopperEnd		;End if larger than max Y

.OkayNTSC	Move.b	d1,(a1)+		;Insert Y wait position
	Move.b	#$01,(a1)+		;Insert X wait position
	Move.w	#$fffe,(a1)+		;Insert wait command

	MoveM	d0-d2,-(SP)		;Save before Scale Colour
	Move.w	Brightness,d1		;Used be Scale Colour

	Move.w	#COLOR01,d4		;d4 = Which colour register
	MoveQ.w	#30,d3		;d3 = Counter for colours
.ForColours	Move.w	d4,(a1)+		;Insert a move for colour register 
	Move.w	(a0)+,d7		;Get colour from chunky data

	;Begin Scale Colour

	;Given a colour value and a brightness value returns
	;the scaled colour with respect to the brightness.
	;
	;Uses d0-d2
	;---------------------------------------------------
	;PRE: d1 = Brightness value, d7 = $xRGB data     

	Tst.w	d1
	Ble.s	.Exit
	Tst.w	d7
	Beq.s	.Exit

	;Do Blue	
	Move.w	d7,d0
	AndI.w	#$00f,d0
	Sub.w	d1,d0
	Bgt.s	.NotToSmall
	MoveQ.w	#$0,d0
.NotToSmall	Move.w	d0,d2
	
	;Do Green	
	Move.w	d7,d0
	AndI.w	#$0f0,d0
	Lsr.w	#4,d0
	Sub.w	d1,d0
	Ble.s	.EndGreen
	Lsl.w	#4,d0
	Or.w	d0,d2
.EndGreen
	;Do Red	
	Move.w	d7,d0
	AndI.w	#$f00,d0
	Lsr.w	#8,d0
	Sub.w	d1,d0
	Ble.s	.EndRed
	Lsl.w	#8,d0
	Or.w	d0,d2
.EndRed
	Move.w	d2,d7		;Return scaled colour to d7
.Exit		
	;End   Scale Colour

	Move.w	d7,(a1)+		;Insert scaled colour
	AddI.w	#2,d4		;Increase colour register
	Dbf	d3,.ForColours

	MoveM	(SP)+,d0-d2		;Restore after Scale Colour

	Bra.s	.DontSkip

.SkipThisLine	Add.l	#31*2,a0		;Skip colour data for this line

.DontSkip	AddI.w	#1,d0		;Next line
	CmpI.w	#31,d0
	Blt	ForColourLines


	;This next bit is almost the same as above except it is performed no matter what 
	;the last Y pos was and also because it changes all the colours to black.

ForBlackLine	Move.w	d0,d1		;d1 = Y pos
	Mulu	d2,d1		;d1 = d1 * Size
	Add.w	d1,d1		;d1 = d1 * 2
	Divu	#31,d1		;d1 = d1 / 31 
				;Could Lsr #5,d1 which is faster
	Add.w	d5,d1		;Plus offset for top	

	CmpI.w	#255,d1		;Check if above the Pal/NTSC border
	Ble.s	.OkayNTSC		;Yes
	CmpI.w	#FALSE,d6		;No, check if we need to do an extra
				;wait for the Pal/NTSC border
	Bne.s	.DoneAlready		;If d6 = FALSE don't do
	Move.w	#TRUE,d6	
	Move.l	#$ffe1fffe,(a1)+	;Insert wait for last NTSC pos
.DoneAlready
	CmpI.w	#255+44,d1
	Bgt.s	CopperEnd		;End if larger than max Y

.OkayNTSC	Move.b	d1,(a1)+		;Insert Y wait position
	Move.b	#$09,(a1)+		;Insert X wait positon
	Move.w	#$fffe,(a1)+		;Insert wait command

	Move.w	#COLOR01,d4		;d4 = Which colour register
	MoveQ.w	#30,d3		;d3 = Counter for colours
.ForColours	Move.w	d4,(a1)+		;Insert a move for colour register 
	Move.w	#0,(a1)+		;Insert colour from chunky data
	AddI.w	#2,d4		;Increase colour register
	Dbf	d3,.ForColours


CopperEnd	Move.l	#$fffffffe,(a1)+	;Terminate copper list	
	Rts


;------------------------------------------------------------------------------------------------------


	;Set-up bitplane pointers in copper list.
	;
	;Uses d0,d1,a0
	;----------------------------------------
	;PRE: d0 -> Start of interleaved bpl data

SetUpBplPtrs	Move.l	CopBPsPtr,a0		;a0 -> BplPtrs in copper list

	MoveQ.l	#RAMPPLANES-1,d1	;d1 = Counter for no of bpls-1

.ForBpls	Move.w	d0,2(a0)		;High word of bpl pointer
	Swap	d0
	Move.w	d0,6(a0)		;Low word of bpl pointer
	Swap	d0
	Add.l	#RAMPWIDTH,d0		;Next bpl start
	AddQ.l	#8,a0		;Next ptr in copper list
	Dbf	d1,.ForBpls

	Rts


;======================================================================================================


	Section	CopperList,Data_C


CopListPtr	Dc.l	0		;The program uses these pointer to
CopSSPtr	Dc.l	0		;work on the list currently NOT being
CopBPsPtr	Dc.l	0		;shown.
CopCMsPtr	Dc.l	0


CopperList1	Dc.w	$1001,$fffe		;Wait till top of display
				;This is 28 lines from the actual	
				;display top. This leaves time
				;to change the bitplane pointer
				;and smooth scroll but also leaves
				;room for all 31 lines of colour
				;moves to be above the display.
	Dc.w	DIWSTRT,$2c81
	Dc.w	DIWSTOP,$2cc1
	Dc.w	DDFSTRT,$0030
	Dc.w	DDFSTOP,$00d0
   
	Dc.w	BPLCON0,$5200
	Dc.w	BPLCON1
SmoothScroll1	Dc.w	$00 
	Dc.w	BPL1MOD,-42		;-42 Repeats first line
	Dc.w	BPL2MOD,-42

	Dc.w	COLOR00,0,COLOR01,0,COLOR02,0,COLOR03,0
	Dc.w	COLOR04,0,COLOR05,0,COLOR06,0,COLOR07,0
	Dc.w	COLOR08,0,COLOR09,0,COLOR10,0,COLOR11,0
	Dc.w	COLOR12,0,COLOR13,0,COLOR14,0,COLOR15,0
	Dc.w	COLOR16,0,COLOR17,0,COLOR18,0,COLOR19,0
	Dc.w	COLOR20,0,COLOR21,0,COLOR22,0,COLOR23,0
	Dc.w	COLOR24,0,COLOR25,0,COLOR26,0,COLOR27,0
	Dc.w	COLOR28,0,COLOR29,0,COLOR30,0,COLOR31,0

BplPtrs1	Dc.w	BPL1PTL,0
	Dc.w	BPL1PTH,0
	Dc.w	BPL2PTL,0
	Dc.w	BPL2PTH,0
	Dc.w	BPL3PTL,0
	Dc.w	BPL3PTH,0
	Dc.w	BPL4PTL,0
	Dc.w	BPL4PTH,0
	Dc.w	BPL5PTL,0
	Dc.w	BPL5PTH,0

	;	  ______________________________; 1 Wait
	;	 |  ____________________________;31 Colour moves
	;	 | |     _______________________;31 Lines
	;	 | |    |   ____________________; 1 Line of blacks
	;	 | |    |  |   _________________; 1 Wait for Pal/NTSC border
	;                | |    |  |  |  _______________; 1 End command		
	;	 | |    |  |  | |
ColourMoves1	Ds.l	(1+31)*(31+1)+1+1

	Dc.l	$fffffffe		;Terminate Copper list


CopperList2	Dc.w	$1001,$fffe		;Wait till top of display
				;This is 28 lines from the actual	
				;display top. This leaves time
				;to change the bitplane pointer
				;and smooth scroll but also leaves
				;room for all 31 lines of colour
				;moves to be above the display.
	Dc.w	DIWSTRT,$2c81
	Dc.w	DIWSTOP,$2cc1
	Dc.w	DDFSTRT,$0030
	Dc.w	DDFSTOP,$00d0
   
	Dc.w	BPLCON0,$5200
	Dc.w	BPLCON1
SmoothScroll2	Dc.w	$00 
	Dc.w	BPL1MOD,-42		;-42 Repeats first line
	Dc.w	BPL2MOD,-42

	Dc.w	COLOR00,0,COLOR01,0,COLOR02,0,COLOR03,0
	Dc.w	COLOR04,0,COLOR05,0,COLOR06,0,COLOR07,0
	Dc.w	COLOR08,0,COLOR09,0,COLOR10,0,COLOR11,0
	Dc.w	COLOR12,0,COLOR13,0,COLOR14,0,COLOR15,0
	Dc.w	COLOR16,0,COLOR17,0,COLOR18,0,COLOR19,0
	Dc.w	COLOR20,0,COLOR21,0,COLOR22,0,COLOR23,0
	Dc.w	COLOR24,0,COLOR25,0,COLOR26,0,COLOR27,0
	Dc.w	COLOR28,0,COLOR29,0,COLOR30,0,COLOR31,0

BplPtrs2	Dc.w	BPL1PTL,0
	Dc.w	BPL1PTH,0
	Dc.w	BPL2PTL,0
	Dc.w	BPL2PTH,0
	Dc.w	BPL3PTL,0
	Dc.w	BPL3PTH,0
	Dc.w	BPL4PTL,0
	Dc.w	BPL4PTH,0
	Dc.w	BPL5PTL,0
	Dc.w	BPL5PTH,0

	;	  ______________________________; 1 Wait
	;	 |  ____________________________;31 Colour moves
	;	 | |     _______________________;31 Lines
	;	 | |    |   ____________________; 1 Line of blacks
	;	 | |    |  |   _________________; 1 Wait for Pal/NTSC border
	;                | |    |  |  |  _______________; 1 End command		
	;	 | |    |  |  | |
ColourMoves2	Ds.l	(1+31)*(31+1)+1+1

	Dc.l	$fffffffe		;Terminate Copper list


;------------------------------------------------------------------------------------------------------


	Section	BitmapData,Data_C
 
Bitmap	Incbin	Sources:BT-Intro/Ramp1024*256*5.Raw

	;These are long words because we want to use the upper word as the unnary part
	;and the lower word as the fractional part, i.e. a fixed point number.
Size	Dc.l	0		;Size of zoom
Speed	Dc.l	0		;Zooming speed, Down < 0 < Up
AnimOffset	Dc.l	0		;Offset for chunky data animation
XOffset	Dc.l	0		;X position offset for image centre
YOffset	Dc.l	0		;Y position offset for image centre
Brightness	Dc.w	0		;Used for brightness of frame 0..15


;------------------------------------------------------------------------------------------------------


	Section	StoryBoardData,Data

	;	    ____________________________;Time before performing this event
	;	   |     _______________________;AnimOffset - 1 frame (31*31*2) = 1922
	;	   |    |         ______________;Speed
	;	   |    |        |       _______;XOffset
	;	   |    |        |      |     __;YOffset
	;                  |    |        |      |    |	
StoryBoard	Dc.l	   5,0*(1922), $80000,   0, 352	
	Dc.l	   7,1*(1922),$100000,   0,-352
	Dc.l	   0,2*(1922),$100000, 352,   0
	Dc.l	  20,3*(1922), $80000,-352,   0
	Dc.l	   5,4*(1922),$100000,-352,-352
	Dc.l	   0,5*(1922), $c0000, 352,-352
	Dc.l	   0,6*(1922), $c0000,-352, 352

	Dc.l	   5,0*(1922), $80000,   0, 352	
	Dc.l	   7,1*(1922),$100000,   0,-352
	Dc.l	   0,2*(1922),$100000, 352,   0
	Dc.l	  20,3*(1922), $80000,-352,   0
	Dc.l	   5,4*(1922),$100000,-352,-352
	Dc.l	   0,5*(1922), $40000, 352,-352
	Dc.l	  20,6*(1922),$100000,   0,   0

	Dc.l	   5,0*(1922), $10000,   0,   0	
	Dc.l	   0,1*(1922), $10000,   0,   0
	Dc.l	   0,2*(1922), $10000,   0,   0
	Dc.l	   0,3*(1922), $10000,   0,   0
	Dc.l	   0,4*(1922), $10000,   0,   0
	Dc.l	   0,5*(1922), $10000,   0,   0
	Dc.l	   0,6*(1922), $10000,   0,   0
	Dc.l	   0,0*(1922),     $1,   0,   0
	
NOOFEVENTS	Equ	22		;Constant for the number of events in
				;the story board							

StoryPosition	Dc.l	0		;Keep track of position in story board
WaitFrames	Dc.l	0		;Used for timed waits before events
				;this is mainly for timing to music			


;------------------------------------------------------------------------------------------------------


	Section	ChunkyData,Data

	Incdir	Sources:BT-Intro/BigTime-Chunky/
Chunky	Incbin	1-B.Chunky
	Incbin	2-I.Chunky
	Incbin	3-G.Chunky
	Incbin	4-T.Chunky
	Incbin	5-I.Chunky
	Incbin	6-M.Chunky
	Incbin	7-E.Chunky