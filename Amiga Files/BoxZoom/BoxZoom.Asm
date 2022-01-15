	;Box Zoomer
	;
	;By Jobbo 29/12/94

MAXSPEED	Equ	$60000
SPEEDCHANGE	Equ	$400

	Incdir	Sources:Includes/
	Include	Hardware.i
	Include	StartUpCrap.i

	Dc.b	"$VER: BoxZoomer v0.7 - Jobbo '94",0
	Even
	

Main	;Switch on DMA for copper and bitplanes
	Move.w	#SETIT!DMAEN!BPLEN!COPEN,DMACON(a5)

	;Set address of Level 3 interrupt handler
	Move.l	#Level3,$6c

	;Switch on VBI interrupt
	Move.w	#SETIT!INTEN!VERTB,INTENA(a5)

	;Point both copper lists at the bitmap
	Bsr	DoCopListDB
	Move.l	#Bitmap,d0
	Bsr	SetUpBplPtrs
	Bsr	DoCopListDB
	Move.l	#Bitmap,d0
	Bsr	SetUpBplPtrs

	;Strobe copper to start
	Move.w	#0,COPJMP1(a5)

MouseWait	;Repeat until LMB
	Btst.b	#6,CIAAPRA
	Bne.s	MouseWait

	;Exit
	Move.w	#INTEN,INTENA(a5)	;Stop Interrupts
	Rts


;======================================================================================================


FrameCt	Dc.l	0		;Counter for anim, uses as an offset
				;for the X values and modulo values
				;in the LUT.
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

	Move.l	FrameCt,d0		;Move on a frame, FrameCt = 0..127
	Add.l	Speed,d0
	And.l	#$7fffff,d0
	Move.l	d0,FrameCt

	;Add the custom copper instructions for this frame
	Clr.l	d0
	Move.w	FrameCt,d0		;d0 = Offset for values in LUTs
	Lsl.l	#8,d0		;Offset = FrameCt * 256 * 2
	Add.l	d0,d0		;                    |    |
				;         NoOfLines__|    |
				;         WordsSize_______|
	Lea	BoxModulosLUT,a3
	Add.l	d0,a3
	Lea	BoxXValuesLUT,a4
	Add.l	d0,a4
	Bsr	DoCustomCop

	;Swap copper lists for double buffering
	Bsr	DoCopListDB
	
	;If RMB then change COLOR00 to show current raster position
	Btst.b	#2,POTGOR(a5)
	Bne.s	.NotPressed
	Move.w	#$005,COLOR00(a5)
.NotPressed
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

DoCopListDB	Tst.w	CopToggle
	Bne.s	.NonZero

	Move.w	#1,CopToggle
	Move.l	#CopperList1,CopListPtr	;Display list 1
	Move.l	#BplPtrs2,CopBPsPtr
	Move.l	#CustomCop2,CopCustPtr
	Bra	.View
.NonZero
	Move.w	#0,CopToggle
	Move.l	#CopperList2,CopListPtr	;Display list 2
	Move.l	#BplPtrs1,CopBPsPtr
	Move.l	#CustomCop1,CopCustPtr

	;Point copper at list to view
.View	Move.l	CopListPtr,COP1LCH(a5)
	
	Rts


;------------------------------------------------------------------------------------------------------


	;Alter copper list area so as to change the smooth
	;scroll several times every line, to squash the display
	;horizontally.
	;
	;Uses d0-d2,a0-a2
	;------------------------------------------------------
	;PRE: a3 -> 256 Modulo values, a4 -> 256 X values

DOLINESTART	Macro
	Move.w	d0,d1		;d1 = Y pos
	Add.w	#43,d1		;Plus top of display
	;
	;Add wait command for this line
	Move.b	d1,(a0)+		;Insert Y wait position
	Move.b	#$e1,(a0)+		;Insert X wait position
	Move.w	#$fffe,(a0)+		;Insert wait command
	;
	;Add modulo moves
	Move.w	(a3)+,d2		;Get modulo value from LUT
	Move.w	#BPL1MOD,(a0)+
	Move.w	d2,(a0)+
	Move.w	#BPL2MOD,(a0)+
	Move.w	d2,(a0)+
	;	
	;Which set of BPLCON1 Moves to add
	Move.w	(a4)+,d2		;d2 = Offset for which BPLCON1 moves
	EndM


DoCustomCop	Move.l	CopCustPtr,a0		;a0 -> Custom changes in copper list
	MoveQ	#0,d0		;d0 = Counter for lines

ForLines1	DOLINESTART
	Bsr	BPLCON1CaseT
	AddQ	#1,d0		;Next line
	Cmp.w	#84,d0
	Blt.s	ForLines1

ForLines2	DOLINESTART
	Bsr	BPLCON1CaseB
	AddQ	#1,d0		;Next line
	Cmp.w	#212,d0
	Blt.s	ForLines2

ForLines3	DOLINESTART
	Bsr	BPLCON1CaseT
	AddQ	#1,d0		;Next line
	Cmp.w	#256,d0
	Blt.s	ForLines3

	Move.l	#$fffffffe,(a0)+	;Terminate copper list

	Rts


;------------------------------------------------------------------------------------------------------


	Include	BPLCON1Case.Asm


;------------------------------------------------------------------------------------------------------


	;Set-up bitplane pointers in copper list
	;
	;Uses d0,d1,a0
	;----------------------------------------
	;PRE: d0 -> Start of bpl data

SetUpBplPtrs	Move.l	CopBPsPtr,a0		;a0 -> BplPtrs in copper list

	MoveQ.l	#4-1,d1		;d1 = Counter for no of bpls-1

.ForBpls	Move.w	d0,2(a0)		;High word of bpl pointer
	Swap	d0
	Move.w	d0,6(a0)		;Low word of bpl pointer
	Swap	d0
	Add.l	#801*40,d0		;Next bpl start
	AddQ	#8,a0		;Next ptr in copper list
	Dbf	d1,.ForBpls

	Rts


;======================================================================================================


	Section	CopperVars,Bss
	
CopToggle	Ds.w	1		;Used for copper list double buffering.
CopListPtr	Ds.l	1		;The program uses these pointer to
CopBPsPtr	Ds.l	1		;work on the list currently NOT being
CopCustPtr	Ds.l	1		;shown.


	Section	CopperList,Data_C

CopperList1	Dc.w	$2a01,$fffe		;Wait till top of display
	
	Dc.w	DIWSTRT,$2c81
	Dc.w	DIWSTOP,$2cc1
	Dc.w	DDFSTRT,$0038
	Dc.w	DDFSTOP,$00d0
   
	Dc.w	BPLCON0,$4200
	Dc.w	BPLCON1,$0088
	Dc.w	BPL1MOD,0
	Dc.w	BPL2MOD,0

	Dc.w	COLOR00,$000,COLOR01,$fff,COLOR02,$eee,COLOR03,$ddd
	Dc.w	COLOR04,$ccc,COLOR05,$bbb,COLOR06,$aaa,COLOR07,$999
	Dc.w	COLOR08,$888,COLOR09,$777,COLOR10,$666,COLOR11,$555
	Dc.w	COLOR12,$444,COLOR13,$333,COLOR14,$222,COLOR15,$111

BplPtrs1	Dc.w	BPL1PTL,0
	Dc.w	BPL1PTH,0
	Dc.w	BPL2PTL,0
	Dc.w	BPL2PTH,0
	Dc.w	BPL3PTL,0
	Dc.w	BPL3PTH,0
	Dc.w	BPL4PTL,0
	Dc.w	BPL4PTH,0

	;	  ______________________________;  1 Wait
	;	 |  ____________________________; 25 Max for a line of BPLCON1 Moves
	;	 | |   _________________________;  2 BPLxMOD Moves
	;	 | |  |    _____________________;256 Lines
	;	 | |  |   |   __________________;  1 End command
	;	 | |  |   |  |
CustomCop1	Ds.l	(1+25+2)*256+1

	Dc.l	$fffffffe		;Terminate Copper list


CopperList2	Dc.w	$2a01,$fffe		;Wait till top of display
	
	Dc.w	DIWSTRT,$2c81
	Dc.w	DIWSTOP,$2cc1
	Dc.w	DDFSTRT,$0038
	Dc.w	DDFSTOP,$00d0
   
	Dc.w	BPLCON0,$4200
	Dc.w	BPLCON1,$0088
	Dc.w	BPL1MOD,0
	Dc.w	BPL2MOD,0

	Dc.w	COLOR00,$000,COLOR01,$fff,COLOR02,$eee,COLOR03,$ddd
	Dc.w	COLOR04,$ccc,COLOR05,$bbb,COLOR06,$aaa,COLOR07,$999
	Dc.w	COLOR08,$888,COLOR09,$777,COLOR10,$666,COLOR11,$555
	Dc.w	COLOR12,$444,COLOR13,$333,COLOR14,$222,COLOR15,$111

BplPtrs2	Dc.w	BPL1PTL,0
	Dc.w	BPL1PTH,0
	Dc.w	BPL2PTL,0
	Dc.w	BPL2PTH,0
	Dc.w	BPL3PTL,0
	Dc.w	BPL3PTH,0
	Dc.w	BPL4PTL,0
	Dc.w	BPL4PTH,0

	;	  ______________________________;  1 Wait
	;	 |  ____________________________; 25 Max for a line of BPLCON1 Moves
	;	 | |   _________________________;  2 BPLxMOD Moves
	;	 | |  |    _____________________;256 Lines
	;	 | |  |   |   __________________;  1 End command
	;	 | |  |   |  |
CustomCop2	Ds.l	(1+25+2)*256+1

	Dc.l	$fffffffe		;Terminate Copper list


;------------------------------------------------------------------------------------------------------


	Section	BitmapData,Data_C
 
Bitmap	Incbin	BoxPict.Raw


;------------------------------------------------------------------------------------------------------


	Section	LUTData,Data

BoxModulosLUT	Incbin	BoxModulosLUT.Bin
BoxXValuesLUT	Incbin	BoxXValuesLUT.Bin