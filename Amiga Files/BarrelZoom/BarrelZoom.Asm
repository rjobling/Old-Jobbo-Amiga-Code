	;Barrel Zoomer
	;
	;By Jobbo 01/01/95

BMWIDTH	Equ	336
BMHEIGHT	Equ	64*2*8
BMPLANES	Equ	3

MAXSPEED	Equ	$60000
SPEEDCHANGE	Equ	$400

	Incdir	Sources:Includes/
	Include	Hardware.i
	Include	StartUpCrap.i

	Dc.b	"$VER: BarrelZoomer v0.6 - Jobbo '95",0
	Even	


Main	;Create nice copper effect
	Bsr	DoCustomCop
	
	;Switch on DMA for copper and bitplanes
	Move.w	#SETIT!DMAEN!BPLEN!COPEN,DMACON(a5)

	;Set address of Level 3 interrupt handler
	Move.l	#Level3,$6c

	;Switch on VBI interrupt
	Move.w	#SETIT!INTEN!VERTB,INTENA(a5)

	;Set copper list up and strobe
	Move.l	#CopperList,COP1LCH(a5)
	Move.w	#0,COPJMP1(a5)

MouseWait	;Repeat until LMB
	Btst.b	#6,CIAAPRA
	Bne.s	MouseWait

	;Exit
	Move.w	#INTEN,INTENA(a5)	;Stop Interrupts
	Rts


;======================================================================================================


	;Level 3 Interrupt Handler.
	;Just scrolls the screen back and forth.
	;
	;Corrupts: d0,d1
	;---------------------------------------
	;PRE: a5 -> Custom base

ScrollOffset	Dc.l	0
Speed	Dc.l	0
SpeedAdd	Dc.l	SPEEDCHANGE

Level3	;Change the Speed
	Move.l	Speed,d1
	Add.l	SpeedAdd,d1
	Cmp.l	#MAXSPEED,d1
	Blt.s	.LessThan
	Move.l	#MAXSPEED,d1
	Move.l	#-SPEEDCHANGE,SpeedAdd
.LessThan	Cmp.l	#-MAXSPEED,d1
	Bgt.s	.GreaterThan
	Move.l	#-MAXSPEED,d1
	Move.l	#SPEEDCHANGE,SpeedAdd
.GreaterThan	Move.l	d1,Speed

	;Change the ScrollOffset
	Move.l	ScrollOffset,d1
	Add.l	Speed,d1
	And.l	#$3fffff,d1
	Move.l	d1,ScrollOffset

	;Point copper list at the bitmap
	Move.w	ScrollOffset,d1
	Mulu	#42,d1
	Move.l	#Bitmap,d0
	Add.l	d1,d0
	Bsr	SetUpBplPtrs

	;If RMB then change COLOR00 to show current raster position
	Btst.b	#2,POTGOR(a5)
	Bne.s	.NotPressed
	Move.w	#$005,COLOR00(a5)
.NotPressed
	;Exit back to user mode
	Move.w	#VERTB,INTREQ(a5)	;Clear interrupt request bit
	Rte


;------------------------------------------------------------------------------------------------------


	;Alter copper list area to change the smooth scroll 
	;several times every line, to squash the display
	;horizontally, and the modulos for vertical squash.
	;
	;Corrupts: d0-d5,a0-a4
	;--------------------------------------------------

DOLINE	Macro
	Move.w	d0,d1		;d1 = Y pos
	Add.w	#43,d1		;Plus top of display
	;
	;Add wait command for this line
	Move.b	d1,(a0)+		;Insert Y wait position
	Move.b	#$e1,(a0)+		;Insert X wait position
	Move.w	#$fffe,(a0)+		;Insert wait command
	;
	Move.w	(a2)+,d2		;Read Modulo Value
	Move.w	#BPL1MOD,(a0)+		;Insert Modulo moves
	Move.w	d2,(a0)+
	Move.w	#BPL2MOD,(a0)+
	Move.w	d2,(a0)+
	;
	Move.w	(a3)+,d2		;Read X Value
	;
	Cmp.w	d2,d7
	Beq.s	.DontChange\@
	Bsr	DoPalette
.DontChange\@
	EndM


DoCustomCop	Lea	CustomCop,a0		;a0 -> Custom changes in copper list
	Lea	BarrelModulos,a2	;a2 -> Modulo LUT
	Lea	BarrelXValues,a3	;a3 -> X Value LUT
	MoveQ	#0,d0		;d0 = Counter for lines

ForLines1	DOLINE
	Bsr	BPLCON1CaseT
	AddQ.w	#1,d0		;Next line
	Cmp.w	#84,d0
	Blt.s	ForLines1

ForLines2	DOLINE
	Bsr	BPLCON1CaseB
	AddQ.w	#1,d0		;Next line
	Cmp.w	#212,d0
	Blt.s	ForLines2

ForLines3	DOLINE
	Bsr	BPLCON1CaseT
	AddQ.w	#1,d0		;Next line
	Cmp.w	#256,d0
	Blt.s	ForLines3

	Move.l	#$fffffffe,(a0)+	;Terminate copper list
	Rts


;------------------------------------------------------------------------------------------------------


	;Add palette changes to copper list.
	;The palette brightness is scaled depending on d2.
	;
	;Corrupts: d3-d6,a4
	;------------------------------------------------------
	;PRE: d2 = Brightness (0..63), a0 -> Custom copper area

DoPalette	Lea	Palette,a4		;a4 -> Palette colours ($xRGB)
	MoveM.l	d0-d1,-(SP)		;Save d0-d1
	
	Move.w	#74,d3		;d3 = (74 - d2)
	Sub.w	d2,d3		;d3 = Brightness multiplyer
	
	Move.w	#7-1,d0		;d0 = Counter
	Move.w	#COLOR01,d1		;d1 = Colour register
	
.ForColours	Move.w	d1,(a0)+
	Move.w	(a4)+,d4		;d4 = Colour ($xRGB)

	;Scale colour
	
	Move.w	d4,d5
	And.w	#$00f,d5		;d5 = Blue part
	Mulu	d3,d5		;Scale
	Lsr.l	#6,d5
	Blt.s	.NegBlue
	Cmp.w	#$f,d5
	Blt.s	.OkayBlue
	MoveQ	#15,d5
	Bra.s	.OkayBlue
.NegBlue	MoveQ	#0,d5
.OkayBlue	Move.w	d5,d6

	Move.w	d4,d5
	And.w	#$0f0,d5		;d5 = Green part
	Lsr.w	#4,d5
	Mulu	d3,d5		;Scale
	Lsr.l	#6,d5
	Blt.s	.NegGreen
	Cmp.w	#$f,d5
	Blt.s	.OkayGreen
	MoveQ	#15,d5
	Bra.s	.OkayGreen
.NegGreen	MoveQ	#0,d5
.OkayGreen	Lsl.w	#4,d5
	OR.w	d5,d6

	Move.w	d4,d5
	And.w	#$f00,d5		;d5 = Red part
	Lsr.w	#8,d5
	Mulu	d3,d5		;Scale
	Lsr.l	#6,d5
	Blt.s	.NegRed
	Cmp.w	#$f,d5
	Blt.s	.OkayRed
	MoveQ	#15,d5
	Bra.s	.OkayRed
.NegRed	MoveQ	#0,d5
.OkayRed	Lsl.w	#8,d5
	OR.w	d5,d6

	Move.w	d6,(a0)+
	AddQ.w	#2,d1
	Dbf	d0,.ForColours

	MoveM.l	(SP)+,d0-d1		;Restore d0-d1
	Rts


;------------------------------------------------------------------------------------------------------


	Include	BPLCON1Cases8.Asm


;------------------------------------------------------------------------------------------------------


	;Set-up bitplane pointers in copper list.
	;
	;Corrupts: d0,d1
	;----------------------------------------
	;PRE: d0 -> Start of bpl data

SetUpBplPtrs	Lea	BplPtrs,a0		;a0 -> BplPtrs in copper list

	MoveQ.l	#BMPLANES-1,d1		;d1 = Counter for no of bpls-1

.ForBpls	Move.w	d0,2(a0)		;High word of bpl pointer
	Swap	d0
	Move.w	d0,6(a0)		;Low word of bpl pointer
	Swap	d0
	Add.l	#BMHEIGHT*(BMWIDTH/8),d0	;Next bpl start
	AddQ.l	#8,a0		;Next ptr in copper list
	Dbf	d1,.ForBpls

	Rts


;======================================================================================================


	Section	CopperList,Data_C

CopperList	Dc.w	$2a01,$fffe		;Wait till top of display
	
	Dc.w	DIWSTRT,$2c81
	Dc.w	DIWSTOP,$2cc1
	Dc.w	DDFSTRT,$0030
	Dc.w	DDFSTOP,$00d0
   
	Dc.w	BPLCON0,$3200
	Dc.w	BPLCON1,$0088
	Dc.w	BPL1MOD,0
	Dc.w	BPL2MOD,0

	Dc.w	COLOR00,$000

BplPtrs	Dc.w	BPL1PTL,0
	Dc.w	BPL1PTH,0
	Dc.w	BPL2PTL,0
	Dc.w	BPL2PTH,0
	Dc.w	BPL3PTL,0
	Dc.w	BPL3PTH,0

	;	  ______________________________;  1 Wait
	;	 |  ____________________________; 25 Max for a line of BPLCON1 Moves
	;	 | |   _________________________;  2 BPLxMOD Moves
	;	 | |  |    _____________________;256 Lines
	;	 | |  |   |    _________________; 56 Palette changes
	;	 | |  |   |   |   ______________;  7 Colours of palette
	;	 | |  |   |   |  |   ___________;  1 End command
	;	 | |  |   |   |  |  |
CustomCop	Ds.l	(1+25+2)*256+(56*7)+1

	Dc.l	$fffffffe		;Terminate Copper list


;------------------------------------------------------------------------------------------------------


	Section	BitmapData,Data_C
 
Bitmap	Incbin	BarrelPict.Raw


;------------------------------------------------------------------------------------------------------

	
	Section	LUTData,Data

BarrelModulos	Incbin	ModulosLUT.Bin
BarrelXValues	Incbin	XValuesLUT.Bin

Palette	Dc.w	$293,$162,$b73,$951,$730,$510,$300