	;64k Intro - Main Program
	;
	;By Jobbo 07/03/95


	Section	MainCode,Code

	Incdir	Sources:Includes/
	Include	Hardware.i
	Include	StartUpCrap.i
	Include	ProRunner.i


Main	Bsr	FB_Init
	Bsr	BW_Init
	Bsr	MW_Init
	Bsr	EP_Init

	;Set up music replay
	Move.l	#Module,pr_module
	Bsr	pr_init
	
	;Set address of Level 3 interrupt handler
	Move.l	#Level3,$6c

	;Switch on DMA for copper and bitplanes
	lea	CUSTOM,a5
	Move.w	#SETIT!DMAEN!BPLEN!COPEN,DMACON(a5)
	;Switch on VBI interrupt
	Move.w	#SETIT!INTEN!VERTB,INTENA(a5)


	Bsr	FB_Runner
	Bsr	VWait

	Move.l	#MW_MeshList2,MW_MeshListPtr
	Move.l	#MW_ChunkyPict2,MW_SrcChunkyPtr
	Move.b	#0,MW_MoveFlag
	Move.w	#0,MW_ScrlOffset
	Bsr	MW_Runner
	Bsr	VWait

	Bsr	BW_Runner
	Bsr	VWait

	Move.l	#MW_MeshList1,MW_MeshListPtr
	Move.l	#MW_ChunkyPict1,MW_SrcChunkyPtr
	Move.b	#1,MW_MoveFlag
	Move.w	#0,MW_ScrlOffset
	Bsr	MW_Runner
	Bsr	VWait

	Bsr	EP_Runner
	Bsr	VWait


	;Exit
	Bsr	pr_end
	Move.w	#INTEN,INTENA+CUSTOM	;Stop Interrupts
	Rts


;======================================================================================================


	;VBI Interrupt server, plays music. And if CustIntPtr is
	;non-zero then the subroutine it points to will be called.
	;
	;Restores all
	;---------------------------------------------------------

VTimer	Dc.l	0
CustIntPtr	Dc.l	0


Level3	MoveM.l	d0-a6,-(SP)

	Bsr	pr_music

	Addq.b	#1,VBlank
	Addq.l	#1,VTimer

	Tst.l	CustIntPtr
	Beq.s	.Nil
	MoveM.l	d0-a6,-(SP)
	Move.l	CustIntPtr,a0
	Jsr	(a0)
	MoveM.l	(SP)+,d0-a6
.Nil	
	;Exit back to user mode
	Move.w	#VERTB,INTREQ+CUSTOM	;Clear interrupt request bit
	MoveM.l	(SP)+,d0-a6
	Rte


;------------------------------------------------------------------------------------------------------


	;Waits one vertical blank
	;
	;Corrupts: None
	;------------------------

VBlank	Dc.b	0
	Even

VWait	Clr.b	VBlank
.Wait	Tst.b	VBlank
	Beq.s	.Wait
	Rts


;------------------------------------------------------------------------------------------------------


	;Deals with double buffering of copper lists.
	;Points the copper at one list and my work pointers at the other list.
	;Which list is which depends on CopToggle.
	;
	;Corrupts: None
	;---------------------------------------------------------------------
	;PRE: CopBufPtr1 -> A Valid Copper-List areas.
	;     CopBufPtr2 -> A Valid Copper-List areas.

CopToggle	Dc.b	0
	Even

DoCopListDB	BChg.b	#0,CopToggle
	Bne.s	.NonZero
	Move.l	CopBufPtr2,CustCopPtr
	Move.l	CopBufPtr1,COP2LCH(a5)
	Bra.s	.Exit
.NonZero	Move.l	CopBufPtr1,CustCopPtr
	Move.l	CopBufPtr2,COP2LCH(a5)
.Exit	Rts


;------------------------------------------------------------------------------------------------------


	;Set-up bitplane pointers in copper list.
	;
	;Corrupts: d0-d1
	;----------------------------------------
	;PRE: d0.l -> Start of bpl data
	;     d1.w =  Counter for no of bpls - 1
	;     d2.l =  Bytes between planes
	;     a0.l -> BplPtrs in copper list
	
SetUpBplPtrs	Move.w	d0,2(a0)		;High word of bpl pointer
	Swap	d0
	Move.w	d0,6(a0)		;Low word of bpl pointer
	Swap	d0
	Add.l	d2,d0		;Next bpl start
	AddQ	#8,a0		;Next ptr in copper list
	Dbf	d1,SetUpBplPtrs

	Rts


;======================================================================================================


	Incdir	Bins/
	Include	Routines.Asm


;======================================================================================================


	Section	CopperAnimationPtrs,Data
CustCopPtr	Dc.l	0
CopBufPtr1	Dc.l	0
CopBufPtr2	Dc.l	0

	;--------------------------------------------------------------------------------------

	Section	LookUpData,Data
SinLUT	Incbin	Sin(0..511)x32767.Bin	;Word Data.

	;--------------------------------------------------------------------------------------
	
	Section	Module,Data_C
Module	Incbin	MOD.HipChip!