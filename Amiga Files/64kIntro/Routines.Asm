	;64k Intro - Routines
	;
	;By Jobbo


FB_RUNNINGTIME	Equ	15*50
BW_RUNNINGTIME	Equ	15*50
MW_RUNNINGTIME	Equ	18*50
EP_RUNNINGTIME	Equ	5*60*50


;======================================================================================================


	;Shaded Feed Back Zoom Rotator - Routines
	;
	;By Jobbo 25/02/95


FB_VWIDTH	Equ	80
FB_VHEIGHT	Equ	64
FB_PHEIGHT	Equ	4

FB_VLINELEN	Equ	(2+FB_VWIDTH+(FB_VWIDTH/32))*4

FB_BMWIDTH	Equ	320/8
FB_BMHEIGHT	Equ	256
FB_BMPLANES	Equ	8


FB_Runner	;Point copper at list and strobe to start
	Move.l	#FB_CustomCop1,CopBufPtr1
	Move.l	#FB_CustomCop2,CopBufPtr2
	Bsr.b	DoCopListDB
	Move.l	#FB_CopList,COP1LCH(a5)
	Move.w	#0,COPJMP1(a5)

	Clr.l	CustIntPtr
	Clr.l	VTimer
.Run	Lea	CUSTOM,a5
	Bsr	VWait
	Bsr	FB_Main
	Bsr	DoCopListDB
	Cmp.l	#FB_RUNNINGTIME,VTimer
	Blt.s	.Run

	Rts


;======================================================================================================


	;Initalise routine. Call before calling the main loop.
	;
	;Corrupts: d0-d2
	;-----------------------------------------------------

FB_Init	;Set up copper lists
	Move.l	#FB_CustomCop1,CopBufPtr1
	Move.l	#FB_CustomCop2,CopBufPtr2
	Bsr	DoCopListDB
	Bsr	FB_MakeCopList
	Bsr	DoCopListDB
	Bsr	FB_MakeCopList

	;Init bitmap and point copper list at bitmap
	Bsr	FB_MakeBitmap
	Move.l	#FB_Bitmap,d0
	SubQ	#8,d0
	Move.w	#FB_BMPLANES-1,d1
	MoveQ	#FB_BMWIDTH,d2
	Lea	FB_BplPtrs,a0
	Bsr	SetUpBplPtrs

	Rts


;------------------------------------------------------------------------------------------------------


	;Initialises the custom copper area with Wait commands
	;and Colour Move command needed for a ChunkyView.
	;
	;Corrupts: d0-d4,a0
	;-----------------------------------------------------

FB_MakeCopList	Move.l	CustCopPtr,a0		;a0 -> Custom changes in copper list

	MoveQ	#0,d0		;d0 = Counter for lines
.ForLines	Move.w	d0,d1		;d1 = Y screen position
	Mulu	#FB_PHEIGHT,d1
	Add.w	#39,d1		;Add for top of display

	;Insert copper wait command
	Move.b	d1,(a0)+		;Insert Y wait position
	Move.b	#$df,(a0)+		;Insert X wait position
	Move.w	#$fffe,(a0)+		;Insert wait command

	;Select either banks 0..3 or 4..7
	Btst	#0,d0
	Bne.s	.OddLine
	Move.l	#BPLCON3<<16+$0020,d4
	Bra.s	.Selected
.OddLine	Move.l	#BPLCON3<<16+$8020,d4
.Selected
	;Insert colour palette move commands
	Move.w	#COLOR31+2,d2		;d2 = Which colour register
	Move.w	#FB_VWIDTH-1,d3		;d3 = Counter for colours
.ForColours	Cmp.w	#COLOR31,d2		;Check if steping into another bank
	Ble.s	.Ok
	Move.l	d4,(a0)+		;Insert a move for colour bank select
	Move.w	#COLOR00,d2		;Reset register to COLOR00
	Add.l	#$2000,d4		;Increase bank number
.Ok	Move.w	d2,(a0)+		;Insert a move for colour register
	Move.w	#$000,(a0)+		;Insert space for colour value
	AddQ	#2,d2		;Increase colour register
	Dbf	d3,.ForColours

	AddQ	#1,d0		;Next line
	Cmp.w	#FB_VHEIGHT,d0
	Blt.s	.ForLines

	Move.l	#$fffffffe,(a0)+
	Rts

	
;------------------------------------------------------------------------------------------------------


	;Draws the ideal 4x4 pixel size chunkyview bitmap.
	;Bitmap size is 320*256*8.
	;
	;Corrupts: d0-d4,a0
	;-------------------------------------------------

FB_VertBars	Dc.l	$17171717,$17171717,$17171717,$17171717,$17171717,$17171717,$17171717,$17171717,$17171717,$17171717
	Dc.l	$00ff00ff,$00ff00ff,$00ff00ff,$00ff00ff,$00ff00ff,$00ff00ff,$00ff00ff,$00ff00ff,$00ff00ff,$00ff00ff
	Dc.l	$0000ffff,$0000ffff,$0000ffff,$0000ffff,$0000ffff,$0000ffff,$0000ffff,$0000ffff,$0000ffff,$0000ffff
	Dc.l	$00000000,$ffffffff,$00000000,$ffffffff,$00000000,$ffffffff,$00000000,$ffffffff,$00000000,$ffffffff
	Dc.l	$00000000,$00000000,$ffffffff,$ffffffff,$00000000,$00000000,$ffffffff,$ffffffff,$00000000,$00000000
	Dc.l	$00000000,$00000000,$00000000,$00000000,$ffffffff,$ffffffff,$ffffffff,$ffffffff,$00000000,$00000000
	Dc.l	$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$ffffffff,$ffffffff

	Dc.l	$8e8e8e8e,$8e8e8e8e,$8e8e8e8e,$8e8e8e8e,$8e8e8e8e,$8e8e8e8e,$8e8e8e8e,$8e8e8e8e,$8e8e8e8e,$8e8e8e8e
	Dc.l	$817e817e,$817e817e,$817e817e,$817e817e,$817e817e,$817e817e,$817e817e,$817e817e,$817e817e,$817e817e
	Dc.l	$80017ffe,$80017ffe,$80017ffe,$80017ffe,$80017ffe,$80017ffe,$80017ffe,$80017ffe,$80017ffe,$80017ffe
	Dc.l	$80000001,$7ffffffe,$80000001,$7ffffffe,$80000001,$7ffffffe,$80000001,$7ffffffe,$80000001,$7ffffffe
	Dc.l	$80000000,$00000001,$7fffffff,$fffffffe,$80000000,$00000001,$7fffffff,$fffffffe,$80000000,$00000001
	Dc.l	$80000000,$00000000,$00000000,$00000001,$7fffffff,$ffffffff,$ffffffff,$fffffffe,$80000000,$00000000
	Dc.l	$80000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000001,$7fffffff,$ffffffff

FB_HoriBars	Dc.l	$00000000
	Dc.l	$00000000
	Dc.l	$aaaaaaaa
	Dc.l	$55555555
	Dc.l	$ffffffff
	Dc.l	$ffffffff
	Dc.l	$aaaaaaaa
	Dc.l	$55555555


FB_MakeBitmap	Lea	FB_Bitmap,a0
	
	MoveQ	#32-1,d0
.ForLines	Lea	FB_HoriBars(PC),a1
	MoveQ	#4-1,d1
.ForSections	Lea	FB_VertBars(PC),a2
	MoveQ	#2-1,d2
.ForPattern
	Move.w	#10*7-1,d3
.ForVertBars	Move.l	(a2)+,(a0)+
	Dbf	d3,.ForVertBars
	Move.l	(a1)+,d4
	MoveQ	#10-1,d3
.ForHoriBars	Move.l	d4,(a0)+
	Dbf	d3,.ForHoriBars

	Dbf	d2,.ForPattern
	Dbf	d1,.ForSections
	Dbf	d0,.ForLines
	
	Rts


;------------------------------------------------------------------------------------------------------


	;Shaded Feed Back Zoom Rotator.
	;
	;Draws new shape in shade mode then new rotated frame.
	;Copies current frame into the copper list chunky view.
	;
	;Corrupts: d0-d4,d6-d7,a0-a6
	;------------------------------------------------------

FB_XPOINT	Equ	(FB_VWIDTH-1)/2		;Rotation X size
FB_YPOINT	Equ	(FB_VHEIGHT-1)/2	;Rotation Y size
FB_ZOOMFACTOR	Equ	256-36		;256 = Scale 1:1

FB_ROTSPEED	Equ	6
FB_SWINGSPEED	Equ	13
FB_MOVESPEED	Equ	2

FB_SHAPESIZE	Equ	10

FB_RotCount	Dc.w 	0		;Changes rotation angle.
FB_SwingCount	Dc.w	0		;Changes centre of rotation
FB_MoveCount	Dc.w	0		;Changes position of shape

FB_ShapeData	Dc.b	0,0,0,1,1,1,1,0,0,0
	Dc.b	0,0,1,2,2,2,2,1,0,0
	Dc.b	0,1,2,3,3,3,3,2,1,0
	Dc.b	1,2,3,4,4,4,4,3,2,1
	Dc.b	1,2,3,4,5,5,4,3,2,1
	Dc.b	1,2,3,4,5,5,4,3,2,1
	Dc.b	1,2,3,4,4,4,4,3,2,1
	Dc.b	0,1,2,3,3,3,3,2,1,0
	Dc.b	0,0,1,2,2,2,2,1,0,0
	Dc.b	0,0,0,1,1,1,1,0,0,0
	Even

FB_CopOffsets	Dc.w	 10,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
	Dc.w	  8,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
	Dc.w	  8,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
	Dc.w	  8,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4

FB_ColPalette	Dc.w	$000,$100,$200,$300,$400,$500,$600,$700
	Dc.w	$800,$900,$a00,$b00,$c00,$d00,$e00,$f00
	Dc.w	$f10,$f20,$f30,$f40,$f50,$f60,$f70,$f80
	Dc.w	$f90,$fa0,$fb0,$fc0,$fd0,$fe0,$ff0,$ff1
	Dc.w	$ff2,$ff1,$ff0,$fe0,$fd0,$fc0,$fb0,$fa0
	Dc.w	$f90,$f80,$f70,$f60,$f50,$f40,$f30,$f20
	Dc.w	$f10,$f00,$e00,$d00,$c00,$b00,$a00,$900
	Dc.w	$800,$700,$600,$500,$400,$300,$200,$100
	

FB_Main	Lea	SinLUT,a0		;a0 -> Sin(0..511)*32767 table
	
	;Change Rotation Count
	Move.w	FB_RotCount(PC),d0
	AddQ	#FB_ROTSPEED,d0
	And.w	#$1ff,d0
	Move.w	d0,FB_RotCount

	;Get RotAngle
	Move.w	(a0,d0.w*2),d0		;d0 = RotAngle
	Asr.w	#8,d0
	Asr.w	#4,d0
	Add.w	#384,d0		;d0 = 384 + Sin(RotCount) * 8
	
	;Get Sin and Cos values for rotation
	Move.w	(a0,d0.w*2),d6		;d6 = Sin( d0 * Pi / 256 ) * 32767
	Add.w	#128,d0		;Cos(d0) = Sin(d0 + 128)
	And.w	#$1ff,d0
	Move.w	(a0,d0.w*2),d7		;d7 = Cos( d0 * Pi / 256 ) * 32767

	;Get scaled values
	Muls	#FB_ZOOMFACTOR,d6
	Asr.l	#8,d6
	Asr.l	#7,d6
	Muls	#FB_ZOOMFACTOR,d7
	Asr.l	#8,d7
	Asr.l	#7,d7

	;Calculate rotated X',Y'
	;
	;X' = (X * Cos(RotAngle)) + (Y * Sin(RotAngle))
	;Y' = (X * Sin(RotAngle)) - (Y * Cos(RotAngle))
	;
	Move.w	#FB_XPOINT,d0
	Muls	d7,d0
	Move.w	#FB_YPOINT,d1
	Muls	d6,d1
	Add.w	d1,d0
	Move.w	d0,a5		;a5 = X'
	Lea	(FB_VHEIGHT*256)/2-128(a5),a5	;For X Centre

	Move.w	#FB_XPOINT,d0
	Muls	d6,d0
	Move.w	#FB_YPOINT,d1
	Muls	d7,d1
	Sub.w	d1,d0
	Move.w	d0,a6		;a6 = Y'
	Lea	(FB_VWIDTH*256)/2-128(a6),a6	;For Y Centre


	;Change Swing Count
	Move.w	FB_SwingCount(PC),d0
	Add.w	#FB_SWINGSPEED,d0
	And.w	#$1ff,d0
	Move.w	d0,FB_SwingCount

	Move.w	(a0,d0.w*2),d1	
	Asr.w	#6,d1
	Add.w	d1,a5		;X' + Sin(SwingCount) * 2 * 256

	Add.w	#128,d0
	And.w	#$1ff,d0		
	Move.w	(a0,d0.w*2),d0
	Asr.w	#6,d0
	Add.w	d0,a6		;Y' + Cos(SwingCount) * 2 * 256


	;Change Movement counter
	Move.w	FB_MoveCount(PC),d0
	Addq.w	#FB_MOVESPEED,d0
	And.w	#$1ff,d0
	Move.w	d0,FB_MoveCount

	;Find offset from centre to draw the shape
	;
	;X = Sin(MoveCount * 5) * 16, Y = Sin(MoveCount * 4) * 16
	;
	Move.w	d0,d1
	Mulu	#5,d0
	And.w	#$1ff,d0
	Move.w	(a0,d0.w*2),d0		;d0 = X
	Asr.w	#8,d0		;Scale to -16..16
	Asr.w	#3,d0
	Lsl.w	#2,d1
	And.w	#$1ff,d1
	Move.w	(a0,d1.w*2),d1		;d1 = Y
	Asr.w	#8,d1		;Scale to -16..16
	Asr.w	#3,d1

	;Determine source and destination areas for this frame
	Tst.b	CopToggle
	Bne.s	.NonZero
	Lea	FB_ChunkyPict2,a0	;a0 -> Chunky Sour data ($xRGB)
	Lea	FB_ChunkyPict1,a1	;a1 -> Chunky Dest data ($xRGB)
	Bra.s	.Exit
.NonZero	Lea	FB_ChunkyPict1,a0	;a0 -> Chunky Sour data ($xRGB)
	Lea	FB_ChunkyPict2,a1	;a1 -> Chunky Dest data ($xRGB)
.Exit
	;Calculate pointer to drawing start position
	Move.l	a0,a2		;a2 -> Position for drawing to start
	Add.w	d0,a2		;Offset for X position
	Asl.w	#8,d1
	Add.w	d1,a2		;Offset for Y position

	;Add offset for centre
	Lea	(FB_VHEIGHT-FB_SHAPESIZE)/2*256+(FB_VWIDTH-FB_SHAPESIZE)/2(a2),a2

	;ADD the shape to the Source buffer
	Lea	FB_ShapeData(PC),a3
	Move.w	#FB_SHAPESIZE-1,d0
.ForShapeY	Move.w	#FB_SHAPESIZE-1,d1
.ForShapeX	Move.b	(a3)+,d2
	Move.b	(a2),d3
	Add.b	d2,d3
	And.b	#$3f,d3
	Move.b	d3,(a2)+
	Dbf	d1,.ForShapeX
	Lea	256-FB_SHAPESIZE(a2),a2
	Dbf	d0,.ForShapeY


	;Draw rotated Source image in the destination area

	MoveQ	#FB_VHEIGHT-1,d0
.ForVert	Move.w	a5,d2		;d2 = X'
	Move.w	a6,d3		;d3 = Y'

	Sub.w	d6,a5		;X' - Sin(RotAngle)
	Add.w	d7,a6		;Y' + Cos(RotAngle)
	
	Move.l	a1,a2		;a2 -> Dest area
	Lea	256(a1),a1		;Move down a line
	
	MoveQ	#FB_VWIDTH-1,d1
.ForHori	;Calculate offset to pixel colour value
	Move.w	d2,d4
	Ror.w	#8,d3
	Move.b	d3,d4		;d4.w = $XY
	And.w	#$7f7f,d4
	Rol.w	#8,d3

	Move.b	(a0,d4.w),(a2)+		;Put pixel value in Dest

	Sub.w	d7,d2		;d2 - Cos(RotAngle)
	Sub.w	d6,d3		;d3 - Sin(RotAngle)

	Dbf	d1,.ForHori
	Dbf	d0,.ForVert



	;Copy current frame in to the copper list (ChunkyView)

	Move.l	CustCopPtr,a1		;a1 -> Custom copper changes
	Lea	FB_CopOffsets(PC),a2	;a2 -> List of offsets between CopMoves
	Lea	FB_ColPalette(PC),a3	;a3 -> Colour LUT

	Move.l	#FB_VLINELEN,d2		;Offset between rows in copper list.

	MoveQ	#0,d3
	Move.w	#FB_VWIDTH-1,d0
.ForRow	Add.w	(a2)+,a1
	Move.l	a1,a4

	Move.l	a0,a5
	AddQ	#1,a0		;Next horizontal value of frame

	MoveQ	#FB_VHEIGHT-1,d1
.ForColumn	Move.b	(a5),d3		;Get colour value
	Move.w	(a3,d3.w*2),(a4)

	Lea	256(a5),a5		;Move on to next row of the frame
	Add.l	d2,a4		;Move on to next row of copper list
	
	Dbf	d1,.ForColumn
	Dbf	d0,.ForRow


	Lea	CUSTOM,a5
	Rts


;======================================================================================================


	;BallWrap Zoom, Rotate & Distort - Routines
	;
	;By Jobbo 27/01/95


BW_BMWIDTH	Equ	480/8
BW_BMHEIGHT	Equ	80
BW_BMPLANES	Equ	5

BW_ROTSPEED	Equ	1
BW_XPOINT	Equ	 24
BW_YPOINT	Equ	-36



BW_Runner	;Point copper at list and strobe to start
	Move.l	#BW_CustomCop1,CopBufPtr1
	Move.l	#BW_CustomCop2,CopBufPtr2
	Bsr	DoCopListDB
	Move.l	#BW_CopList,COP1LCH(a5)
	Move.w	#0,COPJMP1(a5)

	Clr.l	CustIntPtr
	Clr.l	VTimer
.Run	Lea	CUSTOM,a5
	Bsr	VWait
	Bsr	BW_Main
	Bsr	DoCopListDB
	Cmp.l	#BW_RUNNINGTIME,VTimer
	Blt.s	.Run

	Rts


;======================================================================================================


	;Initalise routine. Call before calling the main loop.
	;
	;Corrupts: d0-d2
	;-----------------------------------------------------

BW_Init	Move.l	#BW_CustomCop1,CopBufPtr1
	Move.l	#BW_CustomCop2,CopBufPtr2
	Bsr	DoCopListDB

	;Point copper list at bitmap
	Move.l	#BW_Bitmap,d0
	Move.w	#BW_BMPLANES-1,d1
	Move.w	#BW_BMWIDTH*BW_BMHEIGHT,d2
	Lea	BW_BplPtrs,a0
	Bsr	SetUpBplPtrs

	Rts


;------------------------------------------------------------------------------------------------------


BW_BouncePos	Dc.w	0		;Offset for data to read.
BW_XScrlOffset	Dc.w	0		;Offset for X position.

BW_RotAngle	Dc.w	0		;d0 = Rotation angle 0..511.

BW_Diameter	Dc.w	0		;Diameter of ball
BW_XCrush	Dc.w	0		;Pseudo percentage value (256 = 100%)
BW_YCrush	Dc.w	0		;Pseudo percentage value (256 = 100%)
BW_YPosOffset	Dc.w	0		;Y offset for display top


BW_Main	;Move on a frame, and read new control values from table.
	Lea	BW_BounceLUT,a0
	Clr.l	d0
	Move.w	BW_BouncePos(PC),d0
	AddQ	#5,d0
	Cmp.w	#1920,d0
	Blt.s	.OkayPos
	Sub.w	#1920,d0
.OkayPos	Move.w	d0,BW_BouncePos
	Add.l	d0,a0
	Clr.w	d0
	Move.b	(a0)+,d0
	Move.w	d0,BW_Diameter
	Move.b	(a0)+,d0
	Move.w	d0,BW_XCrush
	Move.b	(a0)+,d0
	Move.w	d0,BW_YCrush
	Move.b	(a0)+,d0
	Add.w	#44,d0
	Move.w	d0,BW_YPosOffset
	Clr.w	d0
	Move.b	(a0)+,d0
	Move.w	d0,BW_XScrlOffset

	;Change horizontal scrolling. Add an offset to the bitmap
	;pointer and changing the smoothscroll in the copper list.
	Move.l	#176,d1
	Sub.w	BW_XScrlOffset(PC),d1
	Move.w	d1,d2
	And.w	#$000f,d2
	Move.w	#$f,d3
	Sub.w	d2,d3
	Mulu	#$11,d3
	Lea	BW_SmoothScrl,a0
	Move.w	d3,(a0)		;Insert value in copper list
	Lsr.w	#4,d1		;Now for bitmap offset round to
	Lsl.w	#1,d1		;the last word.

	;Point copper list at bitmap
	Move.l	#BW_Bitmap,d0
	Add.l	d1,d0		;Add horizontal scrolling offset
	Move.w	#BW_BMPLANES-1,d1
	Move.w	#BW_BMWIDTH*BW_BMHEIGHT,d2
	Lea	BW_BplPtrs,a0
	Bsr	SetUpBplPtrs


	;--------------------------------------------------------------------------------------	


	;Draws the rotated picture in the frame buffer.
	;Both the source and the destination pictures are in chunky ($xRGB) form.
	;Source pict 64*64 pixels, dest pict 32*31 pixels.

DrawRotatedPict	Lea	BW_ChunkyPict,a0	;a0 -> Chunky data (IN)  ($xRGB)
	Lea	BW_ChunkyFrame,a1	;a1 -> Chunky data (OUT) ($xRGB)
	Lea	SinLUT,a2		;a2 -> Sin(0..511)*32767 table.
	
	;Change Rotation Angle
	Move.w	BW_RotAngle(PC),d0
	AddQ	#BW_ROTSPEED,d0
	And.w	#$1ff,d0
	Move.w	d0,BW_RotAngle
	
	;Get Sin and Cos values for rotation
	Move.w	(a2,d0.w*2),d6		;d6 = Sin( d0 * Pi / 256 ) * 32767
	Add.w	#128,d0		;Cos(d0) = Sin(d0 + 128)
	And.w	#$1ff,d0
	Move.w	(a2,d0.w*2),d7		;d7 = Cos( d0 * Pi / 256 ) * 32767
	Asr.w	#7,d6		;Scale down
	Asr.w	#7,d7		;Scale down

	;Calculate rotated X',Y'.
	;
	;X' = (X * Cos(RotAngle)) + (Y * Sin(RotAngle))
	;Y' = (X * Sin(RotAngle)) - (Y * Cos(RotAngle))
	;
	Move.w	#BW_XPOINT,d0
	Muls	d7,d0
	Move.w	#BW_YPOINT,d1
	Muls	d6,d1
	Add.w	d1,d0
	Move.w	d0,a3		;a3 = X'
	Lea	32*128+64(a3),a3		;For X Centre

	Move.w	#BW_XPOINT,d0
	Muls	d6,d0
	Move.w	#-BW_YPOINT,d1	;#BW_YPOINT,d1	;Fiddled for nice movement.
	Muls	d7,d1
	Sub.l	d1,d0
	Move.w	d0,a4		;a4 = Y'
	Lea	32*128+64(a4),a4		;For Y Centre
	
	MoveQ	#31-1,d0
.ForVert	Move.w	a3,d2		;d2 = X'
	Move.w	a4,d3		;d3 = Y'
	Add.w	d6,a3		;X' + Sin(RotAngle)
	Sub.w	d7,a4		;Y' + Cos(RotAngle)
	MoveQ	#32-1,d1
.ForHori	;Calculate offset to pixel colour value.
	Move.w	d3,d4
	And.w	#$3f<<7,d4
	Lsr.w	#1,d4
	Move.w	d2,d5
	Lsr.w	#7,d5
	And.b	#$3f,d5
	Or.b	d5,d4		;d4.w = %0000YYYYYYXXXXXX
	Move.w	(a0,d4.w*2),(a1)+	;Plot pixel value in frame.
	Add.w	d7,d2		;d2 + Cos(RotAngle)
	Add.w	d6,d3		;d3 + Sin(RotAngle)	
	Dbf	d1,.ForHori
	Dbf	d0,.ForVert
		

	;--------------------------------------------------------------------------------------
	

	;Alter copper list area so as to change the display

ChangeCopList	Move.l	CustCopPtr,a0		;a0 -> Custom changes in copper list
	Lea	BW_SqrtLUT,a1		;a1 -> Square root table
	Lea	BW_ChunkyFrame,a2		;a2 -> Chunky data ($xRGB)
	Lea	BW_YPosLUT,a3		;a3 -> Y pos values for colour changes
	Lea	BW_BrightLUT,a4		;a4 -> Values for light sourcing

	Move.w	BW_Diameter(PC),d0	;Radius
	Lsr.w	#1,d0		;Radius = Diameter / 2
	Move.w	d0,d1		;Radius * Radius
	Mulu	d1,d1
	Move.w	d0,a5		;a5 = Radius (Data)
	Move.w	d1,a6		;a6 = Radius * Radius (Data)

	MoveQ	#0,d0		;d0 = Counter 0..Diameter 
	MoveQ	#0,d2		;d2 = Last X value
	MoveQ	#0,d4		;d4 = Last Y screen position
	Move.w	(a3),d6		;d6 = Next Y colour change position
	Move.w	BW_YPosOffset(PC),d7	;d7 = Y offset for display top
	

ForLines	Move.w	d0,d5		;d5 = Y screen position
	Mulu	BW_YCrush(PC),d5	;d5 = (YCrush * Y) / 256
	Lsr.l	#8,d5
	Add.w	d7,d5		;Add for top of display

	Cmp.w	d4,d5
	Ble	.SkipThisLine		;If Y <= OldY
	Move.w	d5,d4		;Store this Y position as OldY

	;X = Sqrt(Y * Y - Radius * Radius)
	;
	Move.w	d0,d1		;d1 = Y
	Sub.w	a5,d1		;d1 = Y - Radius
				;So that Y in range -Radius..+Radius	
	Muls	d1,d1		;d1 = Y * Y
	Sub.l	a6,d1		;d1 =(Y * Y - Radius * Radius) / 8
	Lsr.l	#3,d1
	Neg.w	d1		;d1 = -d1

	Move.w	(a1,d1.w*2),d1		;d1 = X	
	Mulu	BW_XCrush(PC),d1	;d1 = (XCrush * X) / 256
	Lsr.l	#8,d1


	;Find difference between X and OldX and use this to choose a modulo value
	;Difference = X - OldX
	;Modulo = (Difference * BMWIDTH) - BMWIDTH
	;
	Move.w	d1,d3		;d3 = Difference
	Sub.w	d2,d3		;d3 = X - OldX	
	Move.w	d1,d2		;Store current X as OldX
	Mulu	#BW_BMWIDTH,d3		;d3 = Modulo
	Sub.w	#40,d3

	;Insert copper wait command
	Move.b	d5,(a0)+		;Insert Y wait position
	Move.b	#$e1,(a0)+		;Insert X wait position
	Move.w	#$fffe,(a0)+		;Insert wait command

	;Compare Y position of next colour changes with current Y.
	Mulu	BW_Diameter(PC),d6	;d6 = Next colour change Y
	Mulu	BW_YCrush(PC),d6	;ColY = (Diameter * YCrush) / (256*256)
	Swap	d6		;Fast shift right by 16
	Add.w	d7,d6		;For top of display
	Cmp.w	d5,d6		;Compare ColY with current Y
	Bgt	.NotThisLine		;Not the same so no colour changed
				;this line.

	;This part is executed if the current line is the same as the line where the next
	;set of colour changes should take place. Inserts copper moves for all colours.
	;	
	MoveM	d0-d4/d7,-(SP)		;Save used registers
	Move.w	#COLOR01,d4		;d4 = Which colour register
	MoveQ	#30,d3		;d3 = Counter for colours
	Clr.w	d1
.ForColours	Move.w	d4,(a0)+		;Insert a move for colour register
	Move.b	(a4)+,d1		;Get brightness value from table
	Move.w	(a2)+,d7		;Get colour from chunky data

	;Begin Scale Colour

	;Given a colour value and a brightness value returns
	;the scaled colour with respect to the brightness.
	;
	;Corrupts: d0-d2
	;---------------------------------------------------
	;PRE: d1 = Brightness value, d7 = $xRGB data     

	Tst.w	d1
	Ble.s	.Exit
	Tst.w	d7
	Beq.s	.Exit

	;Do Blue	
	Move.w	d7,d0
	And.w	#$00f,d0
	Sub.w	d1,d0
	Bgt.s	.NotToSmall
	MoveQ	#$0,d0
.NotToSmall	Move.w	d0,d2
	
	;Do Green	
	Move.w	d7,d0
	And.w	#$0f0,d0
	Lsr.w	#4,d0
	Sub.w	d1,d0
	Ble.s	.EndGreen
	Lsl.w	#4,d0
	Or.w	d0,d2
.EndGreen
	;Do Red	
	Move.w	d7,d0
	And.w	#$f00,d0
	Lsr.w	#8,d0
	Sub.w	d1,d0
	Ble.s	.EndRed
	Lsl.w	#8,d0
	Or.w	d0,d2
.EndRed
	Move.w	d2,d7		;Return scaled colour to d7
.Exit		
	;End   Scale Colour

	Move.w	d7,(a0)+		
	AddQ	#2,d4		;Increase colour register
	Dbf	d3,.ForColours
	AddQ	#2,a2
	AddQ	#2,a3		;a3 -> Y pos for next colour changes
	MoveM	(SP)+,d0-d4/d7		;Restore destroyed registers

.NotThisLine	Move.w	(a3),d6		;d6 = Next Y colour change position


	;Insert copper modulo move commands
	Move.w	#BPL1MOD,(a0)+
	Move.w	d3,(a0)+
	Move.w	#BPL2MOD,(a0)+
	Move.w	d3,(a0)+

.SkipThisLine	AddQ	#1,d0		;Next line
	Cmp.w	BW_Diameter(PC),d0
	Blt	ForLines


	;This next part simply sets the last line to the top of the bitmap i.e. a blank line.
	;And then the line after this is given the modulo -RAMPWIDTH to repeat this line.
	;
.DoEndLine	AddQ	#1,d5		;Next line
	MoveQ	#0,d1		;X = 0
	Move.w	d1,d3		;d3 = Difference
	Sub.w	d2,d3		;d3 = X - OldX	
	Mulu	#BW_BMWIDTH,d3		;d3 = Modulo
	Sub.w	#40,d3
	Move.b	d5,(a0)+		;Insert Y wait position
	Move.b	#$e1,(a0)+		;Insert X wait position
	Move.w	#$fffe,(a0)+		;Insert wait command
	Move.w	#BPL1MOD,(a0)+		;Insert modulo moves
	Move.w	d3,(a0)+
	Move.w	#BPL2MOD,(a0)+
	Move.w	d3,(a0)+
	AddQ	#1,d5		;Next line
	Move.b	d5,(a0)+		;Insert Y wait position
	Move.b	#$e1,(a0)+		;Insert X wait position
	Move.w	#$fffe,(a0)+		;Insert wait command
	Move.w	#BPL1MOD,(a0)+		;Insert modulo moves
	Move.w	#-40,(a0)+
	Move.w	#BPL2MOD,(a0)+
	Move.w	#-40,(a0)+


CopperEnd	Move.l	#$fffffffe,(a0)+	;Terminate copper list	


	Lea	CUSTOM,a5
	Rts


;======================================================================================================


	;Mesh Warper - Routines
	;
	;By Jobbo 24/03/95


MW_VWIDTH	Equ	84
MW_VHEIGHT	Equ	84
MW_PHEIGHT	Equ	3
MW_VLINELEN	Equ	(2+MW_VWIDTH+(MW_VWIDTH/32))*4

MW_BMWIDTH	Equ	256/8
MW_BMHEIGHT	Equ	258
MW_BMPLANES	Equ	8

MW_MESHWIDTH	Equ	8
MW_MESHHEIGHT	Equ	8
MW_WIDTHSPACE	Equ	MW_VWIDTH/(MW_MESHWIDTH-1)
MW_HEIGHTSPACE	Equ	MW_VHEIGHT/(MW_MESHHEIGHT-1)
MW_FRAMES	Equ	4		;Actual number of frames is 2^FRAMES


MW_Runner	;Point copper at list and strobe to start
	Move.l	#MW_CustomCop1,CopBufPtr1
	Move.l	#MW_CustomCop2,CopBufPtr2
	Bsr	DoCopListDB
	Move.l	#MW_CopList,COP1LCH(a5)
	Move.w	#0,COPJMP1(a5)

	Bsr	MW_InitNextMesh

	Clr.l	CustIntPtr
	Clr.l	VTimer
.Run	Lea	CUSTOM,a5
	Bsr	VWait
	Bsr	MW_Main
	Bsr	DoCopListDB
	Cmp.l	#MW_RUNNINGTIME,VTimer
	Blt.s	.Run

	Rts


;======================================================================================================


	;Initalise routine. Call before calling the main loop.
	;
	;Corrupts: d0-d2
	;-----------------------------------------------------

MW_Init	;Set up copper lists
	Move.l	#MW_CustomCop1,CopBufPtr1
	Move.l	#MW_CustomCop2,CopBufPtr2
	Bsr	DoCopListDB
	Bsr	MW_MakeCopList
	Bsr	DoCopListDB
	Bsr	MW_MakeCopList
	
	;Init bitmap and point copper list at bitmap
	Bsr	MW_MakeBitmap
	Move.l	#MW_Bitmap,d0
	SubQ	#8,d0
	Move.w	#MW_BMPLANES-1,d1
	MoveQ	#MW_BMWIDTH,d2
	Lea	MW_BplPtrs,a0
	Bsr	SetUpBplPtrs

	Rts


;------------------------------------------------------------------------------------------------------


	;Initialises the custom copper area with Wait commands
	;and Colour Move command needed for a ChunkyView.
	;
	;Corrupts: d0-d4,a0
	;-----------------------------------------------------

MW_MakeCopList	Move.l	CustCopPtr,a0		;a0 -> Custom changes in copper list

	MoveQ	#0,d0		;d0 = Counter for lines
.ForLines	Move.w	d0,d1		;d1 = Y screen position
	Mulu	#MW_PHEIGHT,d1
	Add.w	#41,d1		;Add for top of display

	;Insert copper wait command
	Move.b	d1,(a0)+		;Insert Y wait position
	Move.b	#$df,(a0)+		;Insert X wait position
	Move.w	#$fffe,(a0)+		;Insert wait command

	;Select either banks 0..3 or 4..7
	Btst	#0,d0
	Bne.s	.OddLine
	Move.l	#BPLCON3<<16+$0020,d4
	Bra.s	.Selected
.OddLine	Move.l	#BPLCON3<<16+$8020,d4
.Selected
	;Insert colour palette move commands
	Move.w	#COLOR31+2,d2		;d2 = Which colour register
	Move.w	#MW_VWIDTH-1,d3		;d3 = Counter for colours
.ForColours	Cmp.w	#COLOR31,d2		;Check if steping into another bank
	Ble.s	.Ok
	Move.l	d4,(a0)+		;Insert a move for colour bank select
	Move.w	#COLOR00,d2		;Reset register to COLOR00
	Add.l	#$2000,d4		;Increase bank number
.Ok	Move.w	d2,(a0)+		;Insert a move for colour register
	Move.w	#$000,(a0)+		;Insert space for colour value
	AddQ	#2,d2		;Increase colour register
	Dbf	d3,.ForColours

	AddQ	#1,d0		;Next line
	Cmp.w	#MW_VHEIGHT,d0
	Blt.s	.ForLines

	Move.l	#$fffffffe,(a0)+
	Rts

	
;------------------------------------------------------------------------------------------------------


	;Draws the ideal 3x3 pixel size chunkyview bitmap.
	;Bitmap size is 256*258*8.
	;
	;Corrupts: d0-d4,a0
	;-------------------------------------------------

MW_VertBars	Dc.l	$2cb2cb2c,$b2cb2cb2,$cb2cb2cb,$2cb2cb2c,$b2cb2cb2,$cb2cb2cb,$2cb2cb2c,$b2cb2cb2
	Dc.l	$03f03f03,$f03f03f0,$3f03f03f,$03f03f03,$f03f03f0,$3f03f03f,$03f03f03,$f03f03f0
	Dc.l	$000fff00,$0fff000f,$ff000fff,$000fff00,$0fff000f,$ff000fff,$000fff00,$0fff000f
	Dc.l	$000000ff,$ffff0000,$00ffffff,$000000ff,$ffff0000,$00ffffff,$000000ff,$ffff0000
	Dc.l	$00000000,$0000ffff,$ffffffff,$00000000,$0000ffff,$ffffffff,$00000000,$0000ffff
	Dc.l	$00000000,$00000000,$00000000,$ffffffff,$ffffffff,$ffffffff,$00000000,$00000000
	Dc.l	$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$ffffffff,$ffffffff

	Dc.l	$9a69a69a,$69a69a69,$a69a69a6,$9a69a69a,$69a69a69,$a69a69a6,$9a69a69a,$69a69a69
	Dc.l	$85e85e85,$e85e85e8,$5e85e85e,$85e85e85,$e85e85e8,$5e85e85e,$85e85e85,$e85e85e8
	Dc.l	$8017fe80,$17fe8017,$fe8017fe,$8017fe80,$17fe8017,$fe8017fe,$8017fe80,$17fe8017
	Dc.l	$8000017f,$fffe8000,$017ffffe,$8000017f,$fffe8000,$017ffffe,$8000017f,$fffe8000
	Dc.l	$80000000,$00017fff,$fffffffe,$80000000,$00017fff,$fffffffe,$80000000,$00017fff
	Dc.l	$80000000,$00000000,$00000001,$7fffffff,$ffffffff,$fffffffe,$80000000,$00000000
	Dc.l	$80000000,$00000000,$00000000,$00000000,$00000000,$00000001,$7fffffff,$ffffffff

MW_HoriBars	Dc.l	$00000000
	Dc.l	$00000000
	Dc.l	$55555555
	Dc.l	$ffffffff
	Dc.l	$ffffffff
	Dc.l	$aaaaaaaa


MW_MakeBitmap	Lea	MW_Bitmap,a0
	
	MoveQ	#43-1,d0
.ForLines	Lea	MW_HoriBars(PC),a1
	MoveQ	#3-1,d1
.ForSections	Lea	MW_VertBars(PC),a2
	MoveQ	#2-1,d2
.ForPattern
	Move.w	#8*7-1,d3
.ForVertBars	Move.l	(a2)+,(a0)+
	Dbf	d3,.ForVertBars
	Move.l	(a1)+,d4
	MoveQ	#8-1,d3
.ForHoriBars	Move.l	d4,(a0)+
	Dbf	d3,.ForHoriBars

	Dbf	d2,.ForPattern
	Dbf	d1,.ForSections
	Dbf	d0,.ForLines
	
	Rts


;------------------------------------------------------------------------------------------------------


	;MESH Warper - Main Loop.
	;
	;Corrupts: d0,a0-a3
	;------------------------

MW_FrameCt	Dc.w	0
MW_WarpDir	Dc.w	1
MW_SrcChunkyPtr	Dc.l	MW_ChunkyPict1
MW_MoveCount	Dc.w	0
MW_ScrlOffset	Dc.w	0
MW_MoveFlag	Dc.b	0


MW_Main	Tst.b	MW_MoveFlag
	Beq.s	.NoMove
	
	;Change Movement Count
	Move.w	MW_MoveCount(PC),d0
	AddQ	#6,d0
	And.w	#$1ff,d0
	Move.w	d0,MW_MoveCount

	;Get Sin and Cos values for rotation
	Lea	SinLUT,a0
	Move.w	(a0,d0.w*2),d1		;d6 = Sin( d0 * Pi / 256 ) * 32767
	Add.w	#128,d0		;Cos(d0) = Sin(d0 + 128)
	And.w	#$1ff,d0
	Move.w	(a0,d0.w*2),d2		;d7 = Cos( d0 * Pi / 256 ) * 32767
	Add.w	#32768,d1
	Mulu	#84,d1
	Asr.l	#8,d1
	Asr.l	#8,d1
	Add.w	#32768,d2
	Mulu	#84,d2
	Asr.l	#8,d2
	Asr.l	#8,d2
	
	Mulu	#84,d2
	Add.w	d1,d2
	Add.w	d2,d2
	Move.w	d2,MW_ScrlOffset
.NoMove
	Lea	MW_TempMeshXs,a0
	Lea	MW_TempMeshYs,a1
	Lea	MW_TempScanLnXs,a2
	Bsr	MW_ScanLnConXs

	Lea	MW_SrcScanLnXs,a0
	Lea	MW_TempScanLnXs,a1
	Move.l	MW_SrcChunkyPtr,a2
	Add.w	MW_ScrlOffset,a2
	Lea	MW_TempChunky,a3
	Bsr	MW_InterpolateX

	Lea	MW_TempMeshXs,a0
	Lea	MW_TempMeshYs,a1
	Lea	MW_TempScanLnYs,a2
	Bsr	MW_ScanLnConYs

	Lea	MW_SrcScanLnYs,a0
	Lea	MW_TempScanLnYs,a1
	Lea	MW_TempChunky,a2
	Move.l	CustCopPtr,a3
	Bsr	MW_InterpolateY


	Tst.w	MW_WarpDir
	Bgt.s	.Forward
	Bsr	MW_DecMesh
	Bra.s	.WentBack
.Forward	Bsr	MW_IncMesh
.WentBack
	Move.w	MW_WarpDir(PC),d0
	Add.w	d0,MW_FrameCt
	Cmp.w	#1<<MW_FRAMES-1,MW_FrameCt
	Bne.s	.Ok
	Move.w	#-1,MW_WarpDir
.Ok	Tst.w	MW_FrameCt
	Bne.s	.NotEnd
	Bsr	MW_InitNextMesh
.NotEnd
	Lea	CUSTOM,a5
	Rts


;------------------------------------------------------------------------------------------------------


	;Call before running the main loop. Every time this is called it
	;moves on to use a different set of Meshes, taken from a list.
	;
	;Corrupts: d0,a0-a4
	;---------------------------------------------------------------

MW_MeshListPtr	Dc.l	MW_MeshList1
MW_ListOffset	Dc.l	0


MW_InitNextMesh	Move.l	MW_MeshListPtr(PC),a4
	Add.l	MW_ListOffset(PC),a4
	Move.l	(a4),d0
	Tst.l	d0
	Bne.s	.NotListEnd
	Clr.l	MW_ListOffset
	Move.l	MW_MeshListPtr(PC),a4
.NotListEnd	Move.l	(a4)+,a0
	Move.l	(a4)+,a1
	Move.l	(a4)+,a2	
	Move.l	(a4)+,a3
	Bsr	MW_InitWarper
	Add.l	#4*4,MW_ListOffset

	Rts


;------------------------------------------------------------------------------------------------------


	;Scan-line X's Conversion.
	;
	;Corrupts: d0-d5,a0-a3
	;-------------------------------
	;PRE: a0 -> Mesh X Coords
	;     a1 -> Mesh Y Coords
	;     a2 -> Scan-line X's Buffer
	
MW_ScanLnConXs	AddQ	#2,a0		;Skip the first and last columns since
	AddQ	#2,a1		;they remain stationary.
	AddQ	#1,a2

	Move.w	#MW_MESHWIDTH-3,d0	;Do from 2nd column to the 2nd last.
.ForColumns	Move.l	a0,a4
	AddQ	#2,a0
	Move.l	a1,a5
	AddQ	#2,a1
	Move.l	a2,a3
	AddQ	#1,a2

	Move.w	#MW_MESHHEIGHT-2,d1
.ForRows	MoveQ	#0,d2
	Move.w	(a4),d2
	Lea	MW_MESHWIDTH*2(a4),a4
	MoveQ	#0,d3
	Move.w	(a4),d3
	Move.w	(a5),d4
	Lea	MW_MESHWIDTH*2(a5),a5
	Move.w	(a5),d5

	Sub.l	d2,d3		;XAdd = ( d3 - d2 ) / ( d5 - d4 )
	Sub.w	d4,d5
	Asr.w	#8,d5
	Divs	d5,d3		;d3 = XAdd

	Ror.w	#8,d2
	Ror.w	#8,d3
	
	SubQ	#1,d5
.ForScanLns	Move.b	d2,(a3)
	AddX.w	d3,d2
	AddQ	#MW_MESHWIDTH,a3
	Dbf	d5,.ForScanLns
	
	Dbf	d1,.ForRows
	Dbf	d0,.ForColumns


	Rts


;------------------------------------------------------------------------------------------------------


	;Scan-line Y's Conversion.
	;
	;Corrupts: d0-d5,a0-a3
	;-------------------------------
	;PRE: a0 -> Mesh X Coords
	;     a1 -> Mesh Y Coords
	;     a2 -> Scan-line Y's Buffer

MW_ScanLnConYs	Lea	MW_MESHWIDTH*2(a0),a0	;Skip the first and last rows since
	Lea	MW_MESHWIDTH*2(a1),a1	;they remain stationary.
	AddQ	#1,a2

	Move.w	#MW_MESHHEIGHT-3,d0	;Do from 2nd row to the 2nd last.
.ForRows	Move.l	a2,a3
	AddQ	#1,a2

	Move.w	#MW_MESHWIDTH-2,d1
.ForColumns	MoveQ	#0,d2
	Move.w	(a1)+,d2
	MoveQ	#0,d3
	Move.w	(a1),d3
	Move.w	(a0)+,d4
	Move.w	(a0),d5

	Sub.l	d2,d3		;YAdd = ( d3 - d2 ) / ( d5 - d4 )
	Sub.w	d4,d5
	Asr.w	#8,d5
	Divs	d5,d3		;d3 = YAdd

	Ror.w	#8,d2
	Ror.w	#8,d3
	
	SubQ	#1,d5
.ForVertLns	Move.b	d2,(a3)
	AddX.w	d3,d2
	AddQ	#MW_MESHHEIGHT,a3
	Dbf	d5,.ForVertLns
	
	Dbf	d1,.ForColumns

	AddQ	#2,a0
	AddQ	#2,a1

	Dbf	d0,.ForRows


	Rts


;------------------------------------------------------------------------------------------------------


	;Interpolate Image data between Scan-line X values.
	;
	;Corrupts: d0-d5,a0-a4
	;--------------------------------------------------
	;PRE: a0 -> Source Scan-line X's
	;     a1 -> Destimation Scan-line X's
	;     a2 -> Source Chunky Image ($xRGB)
	;     a3 -> Destimation Chunky Image ($xRGB)

MW_InterpolateX
	Move.w	#(MW_MESHHEIGHT-1)*MW_HEIGHTSPACE-1,d0
.ForScanLns	Move.l	a3,a4
	AddQ	#2,a3

	Move.w	#MW_MESHWIDTH-2,d1
.ForColumns	MoveQ	#0,d2
	Move.b	(a0)+,d2
	MoveQ	#0,d3
	Move.b	(a0),d3
	Move.b	(a1)+,d4
	MoveQ	#0,d5
	Move.b	(a1),d5
	
	Sub.b	d2,d3		;SrcAdd = ( d3 - d2 ) / ( d5 - d4 )
	Lsl.w	#8,d3
	Sub.b	d4,d5
	Divu	d5,d3
	And.l	#$0000ffff,d3		;d3 = SrcAdd
	Ror.l	#8,d3

	SubQ	#1,d5
.ForDestPixels	Move.w	(a2,d2.w*2),(a4)
	Lea	MW_VHEIGHT*2(a4),a4
	AddX.l	d3,d2
	Dbf	d5,.ForDestPixels

	Dbf	d1,.ForColumns

	Lea	MW_VWIDTH*2(a2),a2

	AddQ	#1,a0
	AddQ	#1,a1

	Dbf	d0,.ForScanLns
	

	Rts


;------------------------------------------------------------------------------------------------------


	;Interpolate Image data between Vertical-line Y values.
	;
	;Corrupts: d0-d5,a0-a6
	;------------------------------------------------------
	;PRE: a0 -> Source Vertical-line Y's
	;     a1 -> Destimation Vertical-line Y's
	;     a2 -> Source Chunky Image ($xRGB)
	;     a3 -> Destimation Custom Copper Area

MW_CopOffsets	Dc.w	10,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
	Dc.w	 8,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
	Dc.w	 8,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
	Dc.w	 8,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4


MW_InterpolateY	Move.w	#MW_VLINELEN,a6
	Lea	MW_CopOffsets(PC),a4

	Move.w	#(MW_MESHWIDTH-1)*MW_WIDTHSPACE-1,d0
.ForVertLns	Add.w	(a4)+,a3
	Move.l	a3,a5

	Move.w	#MW_MESHHEIGHT-2,d1
.ForRows	MoveQ	#0,d2
	Move.b	(a0)+,d2
	MoveQ	#0,d3
	Move.b	(a0),d3
	Move.b	(a1)+,d4
	MoveQ	#0,d5
	Move.b	(a1),d5
	
	Sub.b	d2,d3		;SrcAdd = ( d3 - d2 ) / ( d5 - d4 )
	Lsl.w	#8,d3
	Sub.b	d4,d5
	Divu	d5,d3
	And.l	#$0000ffff,d3		;d3 = SrcAdd
	Ror.l	#8,d3

	SubQ	#1,d5
.ForDestPixels	Move.w	(a2,d2.w*2),(a5)
	Add.w	a6,a5
	AddX.l	d3,d2
	Dbf	d5,.ForDestPixels

	Dbf	d1,.ForRows

	Lea	MW_VHEIGHT*2(a2),a2

	AddQ	#1,a0
	AddQ	#1,a1

	Dbf	d0,.ForVertLns
	

	Rts


;------------------------------------------------------------------------------------------------------


	;Initialise the tables needed for the Warper routine.
	;
	;These are: Temp Co-ords
	;           Movement Speeds
	;           Source Scan-line conversion
	;
	;Corrupts: d0-d2,a0-a3
	;----------------------------------------------------
	;PRE: a0 -> Source Mesh X Coords
	;     a1 -> Source Mesh Y Coords
	;     a2 -> Destination Mesh X Coords
	;     a3 -> Destination Mesh Y Coords


MW_InitWarper	MoveM.l	a0-a3,-(SP)
	Lea	MW_MeshXSpds,a4
	Lea	MW_MeshYSpds,a5
	Move.w	#MW_MESHWIDTH*MW_MESHHEIGHT-1,d0
.ForSpds	Move.w	(a0)+,d1
	Move.w	(a2)+,d2
	Sub.w	d1,d2
	Asr.w	#MW_FRAMES,d2
	Move.w	d2,(a4)+
	Move.w	(a1)+,d1
	Move.w	(a3)+,d2
	Sub.w	d1,d2
	Asr.w	#MW_FRAMES,d2
	Move.w	d2,(a5)+
	Dbf	d0,.ForSpds
	MoveM.l	(SP)+,a0-a3

	MoveM.l	a0-a1,-(SP)
	Lea	MW_TempMeshXs,a4
	Lea	MW_TempMeshYs,a5
	Move.w	#MW_MESHWIDTH*MW_MESHHEIGHT-1,d0
.ForPts	Move.w	(a0)+,(a4)+
	Move.w	(a1)+,(a5)+
	Dbf	d0,.ForPts
	MoveM.l	(SP)+,a0-a1

	MoveM.l	a0-a1,-(SP)
	Lea	MW_SrcScanLnXs,a2
	Bsr	MW_ScanLnConXs
	MoveM.l	(SP)+,a0-a1

	MoveM.l	a0-a1,-(SP)
	Lea	MW_SrcScanLnYs,a2
	Bsr	MW_ScanLnConYs
	MoveM.l	(SP)+,a0-a1

	Lea	MW_SrcScanLnXs,a0
	Lea	MW_TempScanLnXs,a1
	Move.w	#MW_VHEIGHT-1,d0
.ForScanLns	Move.b	#0,(a0)
	Move.b	#MW_VWIDTH,MW_MESHWIDTH-1(a0)
	AddQ	#MW_MESHWIDTH,a0
	Move.b	#0,(a1)
	Move.b	#MW_VWIDTH,MW_MESHWIDTH-1(a1)
	AddQ	#MW_MESHWIDTH,a1
	Dbf	d0,.ForScanLns

	Lea	MW_SrcScanLnYs,a0
	Lea	MW_TempScanLnYs,a1
	Move.w	#MW_VWIDTH-1,d0
.ForVertLns	Move.b	#0,(a0)
	Move.b	#MW_VHEIGHT,MW_MESHHEIGHT-1(a0)
	AddQ	#MW_MESHHEIGHT,a0
	Move.b	#0,(a1)
	Move.b	#MW_VHEIGHT,MW_MESHHEIGHT-1(a1)
	AddQ	#MW_MESHHEIGHT,a1
	Dbf	d0,.ForVertLns

	Clr.w	MW_FrameCt
	Move.w	#1,MW_WarpDir

	Rts


;------------------------------------------------------------------------------------------------------


MW_IncMesh	Lea	MW_MeshXSpds,a0
	Lea	MW_TempMeshXs,a1
	Lea	MW_MeshYSpds,a2
	Lea	MW_TempMeshYs,a3

	Move.w	#MW_MESHWIDTH*MW_MESHHEIGHT-1,d0
.ForPts	Move.w	(a0)+,d1
	Add.w	d1,(a1)+
	Move.w	(a2)+,d1
	Add.w	d1,(a3)+
	Dbf	d0,.ForPts

	Rts

	;--------------------------------------------------------------------------------------

MW_DecMesh	Lea	MW_MeshXSpds,a0
	Lea	MW_TempMeshXs,a1
	Lea	MW_MeshYSpds,a2
	Lea	MW_TempMeshYs,a3

	Move.w	#MW_MESHWIDTH*MW_MESHHEIGHT-1,d0
.ForPts	Move.w	(a0)+,d1
	Sub.w	d1,(a1)+
	Move.w	(a2)+,d1
	Sub.w	d1,(a3)+
	Dbf	d0,.ForPts

	Rts


;======================================================================================================


	;EndPart Rotator and Scroller - Routines
	;
	;By Jobbo 12/02/95


EP_VWIDTH	Equ	32
EP_VHEIGHT	Equ	128
EP_PHEIGHT	Equ	2

EP_BMWIDTH	Equ	320/8
EP_BMHEIGHT	Equ	(16+256+16)*2
EP_BMPLANES	Equ	6


EP_Runner	;Point copper at list and strobe to start
	Move.l	#EP_CustomCop1,CopBufPtr1
	Move.l	#EP_CustomCop2,CopBufPtr2
	Bsr	DoCopListDB
	Move.l	#EP_CopList,COP1LCH(a5)
	Move.w	#0,COPJMP1(a5)

	Move.l	#EP_Scrl,CustIntPtr

	Clr.l	VTimer
.Run	Lea	CUSTOM,a5
	Bsr	VWait
	Bsr	EP_Main
	Bsr	DoCopListDB
	Btst.b	#6,CIAAPRA
	Beq.s	.End
	Cmp.l	#EP_RUNNINGTIME,VTimer
	Blt.s	.Run

.End	Clr.l	CustIntPtr

	Rts


;======================================================================================================


	;Initalise routine. Call before calling the main loop.
	;
	;Corrupts: d0-d2,a0
	;-----------------------------------------------------

EP_Init	;Set up copper lists
	Move.l	#EP_CustomCop1,CopBufPtr1
	Move.l	#EP_CustomCop2,CopBufPtr2
	Bsr	DoCopListDB
	Bsr	EP_MakeCopList
	Bsr	DoCopListDB
	Bsr	EP_MakeCopList

	;Init bitmap and point copper list at bitmap
	Bsr	EP_MakeBitmap
	Move.l	#EP_Bitmap,d0
	SubQ	#8,d0
	Move.w	#EP_BMPLANES-1,d1
	MoveQ	#EP_BMWIDTH,d2
	Lea	EP_BplPtrs,a0
	Bsr	SetUpBplPtrs

	Rts


;------------------------------------------------------------------------------------------------------


	;Initialises the custom copper area with Wait commands
	;and Colour Move command needed for a ChunkyView.
	;
	;Corrupts: d0-d3,a0
	;-----------------------------------------------------

EP_MakeCopList	Move.l	CustCopPtr,a0		;a0 -> Custom changes in copper list

	MoveQ	#0,d0		;d0 = Counter for lines
.ForLines	Move.w	d0,d1		;d1 = Y screen position
	Mulu	#EP_PHEIGHT,d1
	Add.w	#43-EP_PHEIGHT,d1	;Add for top of display

	;Insert copper wait command
	Move.b	d1,(a0)+		;Insert Y wait position
	Move.b	#$df,(a0)+		;Insert X wait position
	Move.w	#$fffe,(a0)+		;Insert wait command

	;Do a nice fade on COLOR00
	Move.w	d0,d2
	Lsr.w	#5,d2
	AddQ	#$003,d2
	Move.l	#BPLCON3<<16+$0020,(a0)+
	Move.w	#COLOR00,(a0)+
	Move.w	d2,(a0)+
	Move.l	#BPLCON3<<16+$4020,(a0)+
	Move.w	#COLOR00,(a0)+
	Move.w	d2,(a0)+
	Move.w	d0,d2
	Lsr.w	#1,d2
	And.w	#$f,d2
	Move.l	#BPLCON3<<16+$0220,(a0)+
	Move.w	#COLOR00,(a0)+
	Move.w	d2,(a0)+
	Move.l	#BPLCON3<<16+$4220,(a0)+
	Move.w	#COLOR00,(a0)+
	Move.w	d2,(a0)+

	;Insert colour palette move commands
	Btst	#0,d0
	Bne.s	.OddLineH
	Move.l	#BPLCON3<<16+$2020,(a0)+
	Move.l	#BPLCON4<<16+$4000,(a0)+
	Bra.s	.SelectedH
.OddLineH	Move.l	#BPLCON3<<16+$6020,(a0)+
	Move.l	#BPLCON4<<16+$0000,(a0)+
.SelectedH
	Move.w	#COLOR00,d2		;d2 = Which colour register
	Move.w	#EP_VWIDTH-1,d3		;d3 = Counter for colours
.ForColoursH	Move.w	d2,(a0)+		;Insert a move for colour register
	Move.w	#$000,(a0)+		;Insert space for colour value
	AddQ	#2,d2		;Increase colour register
	Dbf	d3,.ForColoursH

	Btst	#0,d0
	Bne.s	.OddLineL
	Move.l	#BPLCON3<<16+$2220,(a0)+
	Bra.s	.SelectedL
.OddLineL	Move.l	#BPLCON3<<16+$6220,(a0)+
.SelectedL
	Move.w	#COLOR00,d2		;d2 = Which colour register
	Move.w	#EP_VWIDTH-1,d3		;d3 = Counter for colours
.ForColoursL	Move.w	d2,(a0)+		;Insert a move for colour register
	Move.w	#$000,(a0)+		;Insert space for colour value
	AddQ	#2,d2		;Increase colour register
	Dbf	d3,.ForColoursL

	AddQ	#1,d0		;Next line
	Cmp.w	#EP_VHEIGHT,d0
	Blt	.ForLines


EP_LastLine	Move.w	d0,d1		;d1 = Y screen position
	Mulu	#EP_PHEIGHT,d1
	Add.w	#43-EP_PHEIGHT,d1	;Add for top of display
	Move.b	d1,(a0)+		;Insert Y wait position
	Move.b	#$df,(a0)+		;Insert X wait position
	Move.w	#$fffe,(a0)+		;Insert wait command
	Move.w	d0,d2
	Lsr.w	#5,d2
	AddQ	#$003,d2
	Move.l	#BPLCON3<<16+$0020,(a0)+
	Move.w	#COLOR00,(a0)+
	Move.w	d2,(a0)+
	Move.l	#BPLCON3<<16+$4020,(a0)+
	Move.w	#COLOR00,(a0)+
	Move.w	d2,(a0)+
	Move.w	d0,d2
	Lsr.w	#1,d2
	And.w	#$f,d2
	Move.l	#BPLCON3<<16+$0220,(a0)+
	Move.w	#COLOR00,(a0)+
	Move.w	d2,(a0)+
	Move.l	#BPLCON3<<16+$4220,(a0)+
	Move.w	#COLOR00,(a0)+
	Move.w	d2,(a0)+
	Btst	#0,d0
	Bne.s	.OddLineH
	Move.l	#BPLCON4<<16+$4000,(a0)+
	Bra.s	.SelectedH
.OddLineH	Move.l	#BPLCON4<<16+$0000,(a0)+
.SelectedH

	Move.l	#$fffffffe,(a0)+
	Rts


;------------------------------------------------------------------------------------------------------


	;Draws the striping needed for the ChunkyView
	;
	;Corrupts: d0,a0
	;--------------------------------------------

EP_MakeBitmap	Lea	EP_Bitmap,a0		;a0 -> Screen bitmap

	Lea	32(a0),a0
	Move.l	#EP_BMHEIGHT-1,d0
.ForHeight	Move.l	#%00110011001100110011001100110011,(a0)
	Move.l	#%00110011001100110011001100110011,4(a0)
	Lea	EP_BMWIDTH(a0),a0
	Move.l	#%00001111000011110000111100001111,(a0)
	Move.l	#%00001111000011110000111100001111,4(a0)
	Lea	EP_BMWIDTH(a0),a0
	Move.l	#%00000000111111110000000011111111,(a0)
	Move.l	#%00000000111111110000000011111111,4(a0)
	Lea	EP_BMWIDTH(a0),a0
	Move.l	#%00000000000000001111111111111111,(a0)
	Move.l	#%00000000000000001111111111111111,4(a0)
	Lea	EP_BMWIDTH(a0),a0
	Move.l	#%00000000000000000000000000000000,(a0)
	Move.l	#%11111111111111111111111111111111,4(a0)
	Lea	EP_BMWIDTH(a0),a0
	Move.l	#%11111111111111111111111111111111,(a0)
	Move.l	#%11111111111111111111111111111111,4(a0)
	Lea	EP_BMWIDTH(a0),a0
	Dbf	d0,.ForHeight

	Rts

	
;------------------------------------------------------------------------------------------------------


	;Rotator with RGB Ghosting.
	;
	;Corrupts: d0-d7,a0-a6
	;--------------------------

EP_XPOINT	Equ	EP_VWIDTH/2		;Rotation X size
EP_YPOINT	Equ	EP_VHEIGHT/2		;Rotation Y size

EP_RotAngle	Dc.w	0		;Rotation angle 0..511
EP_ZoomFactor	Dc.w	0		;ZoomScalar = Sin(ZoomFactor)
EP_RotSpeed	Dc.w	1
EP_ZoomSpeed	Dc.w	4


EP_Main	Lea	SinLUT,a0		;a0 -> Sin(0..511)*32767 table
	
	;Change Rotation Angle
	Move.w	EP_RotAngle(PC),d0
	Add.w	EP_RotSpeed(PC),d0
	And.w	#$1ff,d0
	Move.w	d0,EP_RotAngle
	
	;Get Sin and Cos values for rotation
	Move.w	(a0,d0.w*2),d6		;d6 = Sin( d0 * Pi / 256 ) * 32767
	Add.w	#128,d0		;Cos(d0) = Sin(d0 + 128)
	And.w	#$1ff,d0
	Move.w	(a0,d0.w*2),d7		;d7 = Cos( d0 * Pi / 256 ) * 32767

	;Change Zoom Factor
	Move.w	EP_ZoomFactor(PC),d0
	Add.w	EP_ZoomSpeed(PC),d0
	And.w	#$1ff,d0
	Move.w	d0,EP_ZoomFactor

	;Get ZoomScalar
	Move.w	(a0,d0.w*2),d0
	Asr.w	#7,d0
	Add.w	#352,d0

	;Get scaled values
	Muls	d0,d6
	Asr.l	#8,d6
	Asr.l	#7,d6
	Muls	d0,d7
	Asr.l	#8,d7
	Asr.l	#7,d7

	;Calculate rotated X',Y'
	;
	;X' = (X * Cos(RotAngle)) + (Y * Sin(RotAngle))
	;Y' = (X * Sin(RotAngle)) - (Y * Cos(RotAngle))
	;
	Move.w	#EP_XPOINT,d0
	Muls	d7,d0
	Move.w	#EP_YPOINT,d1
	Muls	d6,d1
	Add.w	d1,d0
	Move.w	d0,a5		;a5 = X'
	Lea	32*256+128(a5),a5		;For X Centre

	Move.w	#EP_XPOINT,d0
	Muls	d6,d0
	Move.w	#-EP_YPOINT,d1	;#EP_YPOINT,d1	;Fiddle for nice movement
	Muls	d7,d1
	Sub.l	d1,d0
	Move.w	d0,a6		;a6 = Y'
	Lea	32*256+128(a6),a6		;For Y Centre


	;Draws the rotated picture in the copper list.
	;Source pict 128*64 pixels (Byte per pixel monochrome.)

	Lea	EP_ChunkyPict,a0	;a0 -> Chunky data ($xRGB)
	Move.l	CustCopPtr,a1		;a1 -> Custom changes in copper list

	Lea	-2-(EP_VWIDTH*4)(a1),a1

	Move.w	#EP_VHEIGHT-1,d0
.ForVert	Move.w	a5,d2		;d2 = X'
	Move.w	a6,d3		;d3 = Y'

	Sub.w	d6,a5		;X' - Sin(RotAngle)
	Add.w	d7,a6		;Y' + Cos(RotAngle)

	Lea	(12+EP_VWIDTH)*4(a1),a1
	
	MoveQ	#EP_VWIDTH-1,d1
.ForHori	;Calculate offset to pixel colour value
	Move.w	d3,d4
	And.w	#$3f00,d4
	Lsr.w	#2,d4
	Move.w	d2,d5
	Lsr.w	#8,d5
	And.b	#$3f,d5
	Or.b	d5,d4		;d4.w = %0000YYYYYYXXXXXX

	Clr.w	d5
	Move.b	(a0,d4.w),d5		;Get pixel value

	Ror.w	#4,d5
	Move.w	(a1),d4		;Get value at X,Y
	Lsl.w	#4,d4		;Shift RGB value for ghosting
	Or.b	d5,d4		;Move in new blue value
	Move.w	d4,(a1)		;Insert as colour operand

	Rol.w	#4,d5
	And.b	#$0f,d5
	Move.w	(EP_VWIDTH+1)*4(a1),d4	;Get value at X,Y
	Lsl.w	#4,d4		;Shift RGB value for ghosting
	Or.b	d5,d4		;Move in new blue value
	Move.w	d4,(EP_VWIDTH+1)*4(a1)	;Insert as colour operand

	AddQ	#4,a1		;Next colour change operand

	Sub.w	d7,d2		;d2 - Cos(RotAngle)
	Sub.w	d6,d3		;d3 - Sin(RotAngle)

	Dbf	d1,.ForHori
	Dbf	d0,.ForVert


	Lea	CUSTOM,a5
	Rts


;------------------------------------------------------------------------------------------------------


	;Updates the bitplane pointers in the copper list
	;and draws the chars for a scrolling message.
	;
	;Corrupts: d0-d2,a0-a3
	;------------------------------------------------

EP_ScrlOffset	Dc.w	0
EP_ScrlTextPtr	Dc.l	EP_ScrlText


EP_Scrl	;Find the offset from the bitmap for scrolling
	Clr.w	d1
	Move.w	EP_ScrlOffset(PC),d1
	Lsr.w	#1,d1
	Add.w	#16,d1
	Mulu	#EP_BMWIDTH*EP_BMPLANES,d1	;Multiply by bytes per line
	
	;Point copper list at bitmap
	Move.l	#EP_Bitmap,d0
	SubQ	#8,d0
	Add.l	d1,d0		;Add scrolling offset
	Move.w	#EP_BMPLANES-1,d1
	MoveQ	#EP_BMWIDTH,d2
	Lea	EP_BplPtrs,a0
	Bsr	SetUpBplPtrs

	;If RMB then dont move scroller
	Btst.b	#2,POTGOR(a5)
	Beq	.Exit

	Move.l	EP_ScrlTextPtr(PC),a0	;a0 -> ASCII Text
	Lea	EP_ScrlFont,a1		;a1 -> Font bitmap data
	Lea	EP_Bitmap,a2		;a2 -> Screen bitmap

	;Find the offset into the Font for drawing the right char
	Clr.w	d0
	Move.b	(a0)+,d0
	Bne.s	.OkText
	Move.l	#EP_ScrlText,a0
	Move.b	(a0)+,d0
.OkText	Move.l	a0,EP_ScrlTextPtr
	Sub.b	#" ",d0
	Mulu	#16*3,d0		;Multiply by size of one char
	Add.l	d0,a1

	;Find the offset into the bitmap for drawing the char
	Move.w	EP_ScrlOffset(PC),d0
	Move.w	d0,d1
	Lsr.w	#1,d0
	And.w	#$fff0,d0
	Mulu	#EP_BMWIDTH*EP_BMPLANES,d0	;Multiply by bytes per line
	And.w	#$1f,d1
	Add.w	d1,d0
	Add.l	d0,a2

	;Draw the two copies of the char
	Move.l	a2,a3		;a3 -> Lower section of bitmap
	Add.l	#EP_BMWIDTH*EP_BMHEIGHT/2*EP_BMPLANES,a3

	MoveQ	#16-1,d0
.ForCharLines	MoveQ	#3-1,d1
.ForCharPlanes	Move.b	(a1),(a2)
	Lea	EP_BMWIDTH(a2),a2
	Move.b	(a1)+,(a3)
	Lea	EP_BMWIDTH(a3),a3
	Dbf	d1,.ForCharPlanes
	Lea	EP_BMWIDTH*(EP_BMPLANES-3)(a2),a2
	Lea	EP_BMWIDTH*(EP_BMPLANES-3)(a3),a3
	Dbf	d0,.ForCharLines

	;Move on the scrolling position
	Move.w	EP_ScrlOffset(PC),d0
	AddQ	#1,d0
	Cmp.w	#EP_BMHEIGHT,d0
	Blt.s	.OkScroll
	Clr.w	d0
.OkScroll	Move.w	d0,EP_ScrlOffset
.Exit
	Rts
	

;======================================================================================================


	Section	FB_ChunkyPictBufs,BSS

FB_ChunkyPict1	Ds.b	256*256
FB_ChunkyPict2	Ds.b	256*256

	;--------------------------------------------------------------------------------------
	
	Section	FB_BitmapData,BSS_C
	CNOP	0,8

FB_Bitmap	Ds.b	FB_BMWIDTH*FB_BMHEIGHT*FB_BMPLANES

	;--------------------------------------------------------------------------------------

	Section	FB_CopList,Data_C

FB_CopList	Dc.w	DIWSTRT,$2c82
	Dc.w	DIWSTOP,$2ac0
	Dc.w	DDFSTRT,$0010
	Dc.w	DDFSTOP,$00b0
   
	Dc.w	BPLCON0,$0211
	Dc.w	BPLCON1,$0000
	Dc.w	BPLCON2,$0200
	Dc.w	BPLCON3,$0020
	Dc.w	BPLCON4,$0000
	Dc.w	BPL1MOD,-8+FB_BMWIDTH*(FB_BMPLANES-1)
	Dc.w	BPL2MOD,-8+FB_BMWIDTH*(FB_BMPLANES-1)
	Dc.w	FMODE,$0003

FB_BplPtrs	Dc.w	BPL1PTL,0,BPL1PTH,0,BPL2PTL,0,BPL2PTH,0
	Dc.w	BPL3PTL,0,BPL3PTH,0,BPL4PTL,0,BPL4PTH,0
	Dc.w	BPL5PTL,0,BPL5PTH,0,BPL6PTL,0,BPL6PTH,0
	Dc.w	BPL7PTL,0,BPL7PTH,0,BPL8PTL,0,BPL8PTH,0
	
	Dc.w	COPJMP2,0		;Jump to COP2LC

	;--------------------------------------------------------------------------------------

	Section	FB_CustomCopBufs,BSS_C

	;	 _______________________________;End Command
	;	|   ____________________________;Colour select
	;	|  |      ______________________;Colours for a line
	;	|  |     |          ____________;Colour Bank select
	;	|  |     |         |           _;Number of lines
	;	|  |     |         |          |
FB_CustomCop1	Ds.l	1+(2+FB_VWIDTH+FB_VWIDTH/32)*FB_VHEIGHT
FB_CustomCop2	Ds.l	1+(2+FB_VWIDTH+FB_VWIDTH/32)*FB_VHEIGHT


;======================================================================================================


	Section	BW_LookUpData,Data

	;Word data
BW_SqrtLUT	Incbin	"BW_Sqrt(0..16383 Step 8)"

	;Word data
BW_BrightLUT	Incbin	BW_BrightLUT31x31.Chunky

	;Word ($xRGB) data
BW_ChunkyPict	Incbin	BW_Pict64x64.Chunky

	;31 Word Y positions, the last one is too big to be acheived so ends it.
BW_YPosLUT	Dc.w	000,003,006,010,015,020,027,034,042,051,060,071,082,094,107,120
	Dc.w	135,148,161,173,184,195,204,213,221,228,235,240,245,249,255,1000

	;Word data values to read in each frame.
	;Of the form:	Diameter.w
	;	XCrush.w
	;	YCrush.w
	;	YPosOffset.w
	;	XScrollOffset.w
	;
	;Repeated for n number of frames.
	;
BW_BounceLUT	Incbin	BW_BounceLUT.Bin

	;--------------------------------------------------------------------------------------

	Section	BW_ChunkyPictBufs,BSS

BW_ChunkyFrame	Ds.w	32*31

	;--------------------------------------------------------------------------------------

	Section	BW_BitmapData,Data_C

BW_Bitmap	Incbin	BW_Ramp480x80x5.Raw

	;--------------------------------------------------------------------------------------

	Section	BW_CopList,Data_C

BW_CopList	Dc.w	DIWSTRT,$2c81
	Dc.w	DIWSTOP,$2cc1
	Dc.w	DDFSTRT,$0038
	Dc.w	DDFSTOP,$00d0
   
	Dc.w	BPLCON0,$5201
	Dc.w	BPLCON1
BW_SmoothScrl	Dc.w	$00 
	Dc.w	BPLCON2,$0200
	Dc.w	BPLCON3,$0020
	Dc.w	BPLCON4,$0000
	Dc.w	BPL1MOD,-40
	Dc.w	BPL2MOD,-40
	Dc.w	FMODE,$0000
	
	Dc.w	COLOR00,$005

BW_BplPtrs	Dc.w	BPL1PTL,0,BPL1PTH,0,BPL2PTL,0,BPL2PTH,0
	Dc.w	BPL3PTL,0,BPL3PTH,0,BPL4PTL,0,BPL4PTH,0
	Dc.w	BPL5PTL,0,BPL5PTH,0
	
	Dc.w	COPJMP2,0		;Jump to custom copper list

	;--------------------------------------------------------------------------------------

	Section	BW_CustomCopBufs,BSS_C

	;	   _____________________________;  1 Wait
	;	  |  ___________________________;  2 Modulo moves
	;	  | |    _______________________;256 Lines
	;	  | |   |     __________________; 31 Colour moves
	;	  | |   |    |   _______________; 31 Lines
	;	  | |   |    |  |    ___________;  2 lines set the bottom to clear
	;                 | |   |    |  |   |  _________;  1 End command		
	;	  | |   |    |  |   | |
BW_CustomCop1	Ds.l	((1+2)*256)+(31*31)+6+1
BW_CustomCop2	Ds.l	((1+2)*256)+(31*31)+6+1


;======================================================================================================


	Section	MW_LookUpData,Data

MW_ChunkyPict1	Incbin	MW_Pict84x84-1.Chunky
	Incbin	MW_Pict84x84-1.Chunky

MW_ChunkyPict2	Incbin	MW_Pict84x84-2.Chunky

MW_MeshList1	Dc.l	MW_Mesh1Xs,MW_Mesh1Ys,MW_Mesh2Xs,MW_Mesh2Ys
	Dc.l	MW_Mesh1Xs,MW_Mesh1Ys,MW_Mesh2Xs,MW_Mesh2Ys
	Dc.l	MW_Mesh1Xs,MW_Mesh1Ys,MW_Mesh2Xs,MW_Mesh2Ys
	Dc.l	MW_Mesh1Xs,MW_Mesh1Ys,MW_Mesh3Xs,MW_Mesh3Ys
	Dc.l	MW_Mesh1Xs,MW_Mesh1Ys,MW_Mesh3Xs,MW_Mesh3Ys
	Dc.l	MW_Mesh1Xs,MW_Mesh1Ys,MW_Mesh3Xs,MW_Mesh3Ys
	Dc.l	MW_Mesh1Xs,MW_Mesh1Ys,MW_Mesh4Xs,MW_Mesh4Ys
	Dc.l	MW_Mesh1Xs,MW_Mesh1Ys,MW_Mesh4Xs,MW_Mesh4Ys
	Dc.l	MW_Mesh1Xs,MW_Mesh1Ys,MW_Mesh4Xs,MW_Mesh4Ys
	Dc.l	MW_Mesh1Xs,MW_Mesh1Ys,MW_Mesh1Xs,MW_Mesh1Ys
	Dc.l	0

MW_MeshList2	Dc.l	MW_Mesh5Xs,MW_Mesh5Ys,MW_Mesh6Xs,MW_Mesh6Ys
	Dc.l	MW_Mesh5Xs,MW_Mesh5Ys,MW_Mesh7Xs,MW_Mesh7Ys
	Dc.l	MW_Mesh8Xs,MW_Mesh8Ys,MW_Mesh9Xs,MW_Mesh9Ys
	Dc.l	MW_Mesh10Xs,MW_Mesh10Ys,MW_Mesh11Xs,MW_Mesh11Ys
	Dc.l	0

MW_Mesh1Xs	Incbin	MW_Mesh1Xs.Bin
MW_Mesh1Ys	Incbin	MW_Mesh1Ys.Bin
MW_Mesh2Xs	Incbin	MW_Mesh2Xs.Bin
MW_Mesh2Ys	Incbin	MW_Mesh2Ys.Bin
MW_Mesh3Xs	Incbin	MW_Mesh3Xs.Bin
MW_Mesh3Ys	Incbin	MW_Mesh3Ys.Bin
MW_Mesh4Xs	Incbin	MW_Mesh4Xs.Bin
MW_Mesh4Ys	Incbin	MW_Mesh4Ys.Bin
MW_Mesh5Xs	Incbin	MW_Mesh5Xs.Bin
MW_Mesh5Ys	Incbin	MW_Mesh5Ys.Bin
MW_Mesh6Xs	Incbin	MW_Mesh6Xs.Bin
MW_Mesh6Ys	Incbin	MW_Mesh6Ys.Bin
MW_Mesh7Xs	Incbin	MW_Mesh7Xs.Bin
MW_Mesh7Ys	Incbin	MW_Mesh7Ys.Bin
MW_Mesh8Xs	Incbin	MW_Mesh8Xs.Bin
MW_Mesh8Ys	Incbin	MW_Mesh8Ys.Bin
MW_Mesh9Xs	Incbin	MW_Mesh9Xs.Bin
MW_Mesh9Ys	Incbin	MW_Mesh9Ys.Bin
MW_Mesh10Xs	Incbin	MW_Mesh10Xs.Bin
MW_Mesh10Ys	Incbin	MW_Mesh10Ys.Bin
MW_Mesh11Xs	Incbin	MW_Mesh11Xs.Bin
MW_Mesh11Ys	Incbin	MW_Mesh11Ys.Bin

	;--------------------------------------------------------------------------------------

	Section	MW_WarpBuffers,BSS

MW_TempChunky	Ds.w	MW_VHEIGHT*MW_VWIDTH

MW_TempMeshXs	Ds.w	MW_MESHWIDTH*MW_MESHHEIGHT
MW_TempMeshYs	Ds.w	MW_MESHWIDTH*MW_MESHHEIGHT
MW_MeshXSpds	Ds.w	MW_MESHWIDTH*MW_MESHHEIGHT
MW_MeshYSpds	Ds.w	MW_MESHWIDTH*MW_MESHHEIGHT

MW_SrcScanLnXs	Ds.b	MW_MESHWIDTH*(MW_MESHHEIGHT-1)*MW_HEIGHTSPACE
MW_SrcScanLnYs	Ds.b	MW_MESHHEIGHT*(MW_MESHWIDTH-1)*MW_WIDTHSPACE
MW_TempScanLnXs	Ds.b	MW_MESHWIDTH*(MW_MESHHEIGHT-1)*MW_HEIGHTSPACE
MW_TempScanLnYs	Ds.b	MW_MESHHEIGHT*(MW_MESHWIDTH-1)*MW_WIDTHSPACE

	;--------------------------------------------------------------------------------------

	Section	MW_BitmapData,BSS_C
	CNOP	0,8

MW_Bitmap	Ds.b	MW_BMWIDTH*MW_BMHEIGHT*MW_BMPLANES

	;--------------------------------------------------------------------------------------

	Section	MW_CopList,Data_C

MW_CopList	Dc.w	DIWSTRT,$2da4
	Dc.w	DIWSTOP,$289e
	Dc.w	DDFSTRT,$0010
	Dc.w	DDFSTOP,$0080
   
	Dc.w	BPLCON0,$0211
	Dc.w	BPLCON1,$8822
	Dc.w	BPLCON2,$0200
	Dc.w	BPLCON3,$0020
	Dc.w	BPLCON4,$0000
	Dc.w	BPL1MOD,-8+MW_BMWIDTH*(MW_BMPLANES-1)
	Dc.w	BPL2MOD,-8+MW_BMWIDTH*(MW_BMPLANES-1)
	Dc.w	FMODE,$0003

MW_BplPtrs	Dc.w	BPL1PTL,0,BPL1PTH,0,BPL2PTL,0,BPL2PTH,0
	Dc.w	BPL3PTL,0,BPL3PTH,0,BPL4PTL,0,BPL4PTH,0
	Dc.w	BPL5PTL,0,BPL5PTH,0,BPL6PTL,0,BPL6PTH,0
	Dc.w	BPL7PTL,0,BPL7PTH,0,BPL8PTL,0,BPL8PTH,0
	
	Dc.w	COPJMP2,0		;Jump to COP2LC

	;--------------------------------------------------------------------------------------

	Section	MW_CustomCopBufs,BSS_C

	;	 _______________________________;End Command
	;	|   ____________________________;Colour select
	;	|  |      ______________________;Colours for a line
	;	|  |     |          ____________;Colour Bank select
	;	|  |     |         |           _;Number of lines
	;	|  |     |         |          |
MW_CustomCop1	Ds.l	1+(2+MW_VWIDTH+MW_VWIDTH/32)*MW_VHEIGHT
MW_CustomCop2	Ds.l	1+(2+MW_VWIDTH+MW_VWIDTH/32)*MW_VHEIGHT


;======================================================================================================


	Section	EP_LookUpData,Data

	;Byte data
EP_ChunkyPict	Incbin	EP_Pict64x64.Chunky

	;Interlaced Font data, size 8x16x3
EP_ScrlFont	Incbin	EP_ScrlFont8x16x3.Bin

	;Width of text is 32 chars
	;
	;Charset =  !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_
EP_QUOTE	Equ	"!"+1

EP_ScrlText	Dc.b	"                                "
	Dc.b	"  CREDITS:                      "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	"  CODE & GFX:                   "
	Dc.b	"                                "
	Dc.b	"         JOBBO/SPACEBALLS       "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	"  MUSIC:                        "
	Dc.b	"                                "
	Dc.b	"        LIZARD/SPACEBALLS       "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	"THIS INTRO REALLY WAS RUSHED AT "
	Dc.b	"THE END, HENCE THERE IS A TOTAL "
	Dc.b	"LACK OF NICE DESIGN!            "
	Dc.b	"                                "
	Dc.b	"BUT SINCE I WANTED TO ENTER THE "
	Dc.b	"COMPO I HAVE DONE THE BEST I    "
	Dc.b	"COULD WITH THE TIME I HAD.      "
	Dc.b	"                                "
	Dc.b	"HOPEFULLY I'LL RELEASE A FINAL  "
	DC.B	"VERSION WHEN I GET BACK HOME.   "
	Dc.b	"SO LOOK OUT FOR THAT!           "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	"THANKS TO THE FOLLOWING:        "
	Dc.b	"                                "
	Dc.b	"        FUZZ/TRSI               "
	Dc.b	"                                "
	Dc.b	"        NIKOLAI DRAGNES         "
	Dc.b	"                                "
	Dc.b	"        MYSTERY 040 OWNER       "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	"GREETS TO:                      "
	Dc.b	"                                "
	Dc.b	" LIZARD, SHORTY, MAJOR-ASSHOLE  "
	Dc.b	" AXEN, COBRA, SOPHOCLES, BAMPOT "
	Dc.b	" SUNJAMMER, FLAME, PB, YOLK     "
	Dc.b	" DESTOP, JESTER, WAYNE-MENDOSA  "
	Dc.b	" APPY, STELIOS, ASTRO, SUPERNAO "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	"IF YOU WANT TO CONTACT ME, JOBBO"
	Dc.b	"FOR ANY REASON THEN HERE IS MY  "
	Dc.b	"ADDRESS:                        "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	" RICHARD JOBLING                "
	Dc.b	" 9 HAZELDEN GDNS                "
	Dc.b	" GLASGOW                        "
	Dc.b	" G44 3HQ                        "
	Dc.b	" SCOTLAND, UK                   "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	" EMAIL: 9361441J@UDCF.GLA.AC.UK "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	"                                "
	Dc.b	0

	;--------------------------------------------------------------------------------------

	Section	EP_BitmapData,BSS_C
	CNOP	0,8

EP_Bitmap	Ds.b	EP_BMWIDTH*EP_BMHEIGHT*EP_BMPLANES

	;--------------------------------------------------------------------------------------

	Section	EP_CopList,Data_C

EP_CopList	Dc.w	DIWSTRT,$2c81
	Dc.w	DIWSTOP,$2cc1
	Dc.w	DDFSTRT,$0018
	Dc.w	DDFSTOP,$00d0
   
	Dc.w	BPLCON0,$0201+EP_BMPLANES<<12
	Dc.w	BPLCON1,$0000
	Dc.w	BPLCON2,$0200
	Dc.w	BPLCON3,$0020
	Dc.w	BPLCON4,$0000
	Dc.w	BPL1MOD,-16+EP_BMWIDTH*(EP_BMPLANES-1)
	Dc.w	BPL2MOD,-16+EP_BMWIDTH*(EP_BMPLANES-1)
	Dc.w	FMODE,$0003

EP_BplPtrs	Dc.w	BPL1PTL,0,BPL1PTH,0,BPL2PTL,0,BPL2PTH,0
	Dc.w	BPL3PTL,0,BPL3PTH,0,BPL4PTL,0,BPL4PTH,0
	Dc.w	BPL5PTL,0,BPL5PTH,0,BPL6PTL,0,BPL6PTH,0

	Dc.w	COLOR00,$005,COLOR01,$fff,COLOR02,$ddd,COLOR03,$aaa
	Dc.w	COLOR04,$555,COLOR05,$000,COLOR06,$f0f,COLOR07,$f0f
	Dc.w	BPLCON3,$4020
	Dc.w	COLOR00,$005,COLOR01,$fff,COLOR02,$ddd,COLOR03,$aaa
	Dc.w	COLOR04,$555,COLOR05,$000,COLOR06,$f0f,COLOR07,$f0f

	Dc.w	COPJMP2,0		;Jump to COP2LC

	;--------------------------------------------------------------------------------------

	Section	EP_CustomCopBufs,BSS_C

	;	 _______________________________;End command
	;	|   ____________________________;Wait for line
	;	|  |  __________________________;For COLOR00 fade
	;	|  | |  ________________________;Bank select
	;	|  | | |   _____________________;High/Low select
	;	|  | | |  |      _______________;For the pixels on one line
	;	|  | | |  |     |       ________;For High and Low colour values
	;	|  | | |  |     |      |     ___;For ever chunky line
	;	|  | | |  |     |      |    |
EP_CustomCop1	Ds.l	1+(1+8+1+(1+EP_VWIDTH)*2)*EP_VHEIGHT+10
EP_CustomCop2	Ds.l	1+(1+8+1+(1+EP_VWIDTH)*2)*EP_VHEIGHT+10