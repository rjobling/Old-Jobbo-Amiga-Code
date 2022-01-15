	;BITMAP VERTICAL ZOOMER
	;
	;By Jobbo 01/11/94


SPEED	Equ	$20000
MINSIZE	Equ	     0
MAXSIZE	Equ	   255


	Incdir	Sources:Includes/
	Include	Hardware.i
	Include	StartUpCrap.i


Main	;Switch on DMA for copper and bitplanes
	Move.w	#SETIT!DMAEN!BPLEN!COPEN,DMACON(a5)

	;Set address of Level 3 interrupt handler
	Move.l	#Level3,$6c

	;Switch on VBI interrupt
	Move.w	#SETIT!INTEN!VERTB,INTENA(a5)

	;Set copper list up and strobe
	Move.l	#CopperList,COP1LCH(a5)    
	Move.w	#0,COPJMP1(a5)

	;Point copper list at bitmap
	Move.l	#Bitmap,d0
	Bsr	SetUpBplPtrs

MouseWait	;Repeat until mouse key
	Btst	#6,CIAAPRA
	Bne.s	MouseWait

	;Exit
	Move.w	#INTEN,INTENA(a5)	;Stop Interrupts
	Rts


;======================================================================================================


Level3	Bsr	AddBplxmodMoves		;Add modulo changes in copper list
	
	;Change the size
	Move.l	Size,d2		;d2 = Size
	Add.l	Speed,d2		;Add speed to size
	Cmp.l	#$10000*MAXSIZE,d2	;Is size larger than max
	Blt.s	LessThan
	Move.l	#$10000*MAXSIZE,d2	;d2 = Max size
	Move.l	#-SPEED,Speed		;Speed = -Speed	
LessThan	Cmp.l	#$10000*MINSIZE,d2	;If size smaller than min
	Bgt.s	GreaterThan
	Move.l	#$10000*MINSIZE,d2	;d2 = Min size
	Move.l	#SPEED,Speed		;Speed = +Speed
GreaterThan	Move.l	d2,Size		;Store size value

	;If RMB then change COLOR00 to show current raster position
	Btst.b	#2,POTGOR(a5)
	Bne.s	.NotPressed
	Move.w	#$005,COLOR00(a5)
.NotPressed
	;Exit back to user mode
	Move.w	#VERTB,INTREQ(a5)	;Clear interrupt request bit
	Rte


;------------------------------------------------------------------------------------------------------


	;Alter copper list area so as to change the modulos
	;every line down the screen.
	;
	;Corrupts: d0-d6,a0
	;--------------------------------------------------

AddBplxmodMoves	Lea	BplxmodMoves,a0		;a0 -> Bplxmod changes in copper list		
	Move.w	Size,d2		;d2 = Size

	;Change window size in copper list
	Move.w	#255,d0		;d0 = Top of display window
	Sub.w	d2,d0
	Lsr.w	#1,d0
	Add.w	#44,d0
	Move.w	d2,d1		;d1 = Bottom of display
	Sub.w	#255,d1
	Asr.w	#1,d1
	Add.w	#43,d1
	Move.b	d0,WindowStrt		;Update DIWSTRT in copper list
	Move.b	d1,WindowStop		;Update DIWSTOP in copper list


	Move.w	d0,d5		;d5 = Offset for top of display
	Move.w	d1,d4		;d4 = Previous Y pos
	MoveQ	#0,d0		;d0 = Counter for lines
	MoveQ	#0,d3		;d3 = Counter at last Y pos


.ForLines	Move.w	d0,d1		;d1 = (Y pos * Size) / 256
	Mulu	d2,d1
	Lsr.l	#8,d1
	Add.w	d5,d1		;Add offset for top

	Cmp.w	d4,d1
	Ble.s	.SkipThisLine		;Skip if NOT bigger than last Y pos

	;Add wait command to copper list
	Move.b	d1,(a0)+		;Insert Y wait position
	Move.b	#$e1,(a0)+		;Insert X wait position
	Move.w	#$fffe,(a0)+		;Insert wait command

	Move.w	d0,d4		;d4 = Difference between this and
				;     the previous line
	Sub.w	d3,d4		;d4 = d4 - counter at last line
	Mulu	#200,d4		;200 bytes per line
	Sub.w	#40,d4		;40 for screen width

	Move.w	#BPL1MOD,(a0)+		;Insert BPLxMOD move commands
	Move.w	d4,(a0)+
	Move.w	#BPL2MOD,(a0)+
	Move.w	d4,(a0)+

	;Store these values for reference when calculating for the next line
	Move.w	d1,d4		;d4 = Last Y pos
	Move.w	d0,d3		;d3 = Counter at last Y pos
	
.SkipThisLine	AddQ	#1,d0		;Next line
	Cmp.w	#256,d0
	Blt.s	.ForLines


	Move.l	#$fffffffe,(a0)+	;Terminate copper list	
	Rts


;------------------------------------------------------------------------------------------------------


	;Set-up bitplane pointers in copper list
	;
	;Corrupts: d0,d1,a0
	;----------------------------------------
	;PRE: d0 -> Start of interleaved bpl data

SetUpBplPtrs	Lea	BplPtrs,a0		;a0 -> BplPtrs in copper list

	MoveQ	#5-1,d1		;d1 = Counter for no of bpls-1

.ForBpls	Move.w	d0,2(a0)		;High word of bpl pointer
	Swap	d0
	Move.w	d0,6(a0)		;Low word of bpl pointer
	Swap	d0
	Add.l	#40,d0		;Next bpl start
	AddQ	#8,a0		;Next ptr in copper list
	Dbf	d1,.ForBpls

	Rts


;======================================================================================================


	;These are long words because we want to use the upper word as the unnary part
	;and the lower word as the fractional part, i.e. a fixed point number.
Size	Dc.l	0		;Size of zoom
Speed	Dc.l	SPEED		;Zooming speed, Down < 0 < Up


;------------------------------------------------------------------------------------------------------


	Section	CopperList,Data_C

CopperList	Dc.w	$2a01,$fffe		;Wait till top of display
	
	Dc.w	DIWSTRT
WindowStrt	Dc.w	$2c81
	Dc.w	DIWSTOP
WindowStop	Dc.w	$2cc1
	Dc.w	DDFSTRT,$0038
	Dc.w	DDFSTOP,$00d0
   
	Dc.w	BPLCON0,$5200
	Dc.w	BPLCON1,$00 
	Dc.w	BPL1MOD,160
	Dc.w	BPL2MOD,160

	Dc.w	COLOR00,$000,COLOR01,$A67,COLOR02,$FCA,COLOR03,$FB9
	Dc.w	COLOR04,$FB8,COLOR05,$FA8,COLOR06,$FA7,COLOR07,$E96
	Dc.w	COLOR08,$D85,COLOR09,$D74,COLOR10,$C64,COLOR11,$C53
	Dc.w	COLOR12,$B42,COLOR13,$B32,COLOR14,$A21,COLOR15,$910
	Dc.w	COLOR16,$900,COLOR17,$800,COLOR18,$700,COLOR19,$600
	Dc.w	COLOR20,$500,COLOR21,$400,COLOR22,$300,COLOR23,$200
	Dc.w	COLOR24,$FA9,COLOR25,$F98,COLOR26,$E87,COLOR27,$D87
	Dc.w	COLOR28,$C87,COLOR29,$C77,COLOR30,$C67,COLOR31,$B67

BplPtrs	Dc.w	BPL1PTL,0
	Dc.w	BPL1PTH,0
	Dc.w	BPL2PTL,0
	Dc.w	BPL2PTH,0
	Dc.w	BPL3PTL,0
	Dc.w	BPL3PTH,0
	Dc.w	BPL4PTL,0
	Dc.w	BPL4PTH,0
	Dc.w	BPL5PTL,0
	Dc.w	BPL5PTH,0

BplxmodMoves	Ds.l	(1+2)*256+1
	;                | |   |  |_____________________;  1 End command
	;	 | |   |________________________;256 Lines
	;	 | |____________________________;  2 Bplxmod moves
	;	 |______________________________;  1 Wait

	Dc.l	$fffffffe		;Terminate Copper list


;------------------------------------------------------------------------------------------------------


	Section	BitmapData,Data_C

Bitmap	Incbin	Sources:VerticalZoom/PictILBM.Raw