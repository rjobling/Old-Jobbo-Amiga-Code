	;Hellfire - Cracktro
	;
	;By Jobbo 03/07/95

	Section	MainCode,Code

	Incdir	Sources:Includes/
	Include	Hardware.i
	Include	StartUpOCS.i
	Include	ProRunner.i
	Incdir	Sources:Cracktro/


Main	Move.l	#textBitmap,d0					;Set up text bpls
	MoveQ	#2-1,d1
	Move.w	#28,d2
	Lea	bplPtrs+3*8,a0
	Bsr	SetUpBplPtrs

	Bsr	ScreenDB					;Set up background bpls
	Bsr	SetUpBGColour					;Set up copper background

	Move.l	#module,pr_module				;Set up music replay
	Move.w	#0,pr_startposition
	Bsr	pr_init		

	Lea	CUSTOM,a6
	Move.l	VBRReg(PC),a0
	Lea	$6c(a0),a0
	Move.l	#Level3,(a0)					;New Level3 handler
	Move.w	#SETIT+DMAEN+BPLEN+COPEN+BLTPRI+BLTEN,DMACON(a6);DMA - ON
	Move.w	#SETIT+INTEN+VERTB,INTENA(a6)			;VBI interrupt - ON
	Move.l	#copList,COP1LCH(a6)				;Point copper at list
	Move.l	#copCust,COP2LCH(a6)
	Move.w	#0,COPJMP1(a6)					;Strobe to start

	Move.w	#2,fadeSpeed
	MoveQ	#16*2-1,d0
.forFadeIn
	Move.w	d0,-(SP)
	Bsr	VWait
	Bsr	InsertPalette
	Bsr	BlitTwirl
	Bsr	ScreenDB
	Bsr	FadeToPalette
	;Move.w	#$080,COLOR00(a6)
	Move.w	(SP)+,d0
	Dbf	d0,.forFadeIn

.mouseWait
	Bsr	VWait
	Bsr	BlitTwirl
	Bsr	ScreenDB
	;Move.w	#$080,COLOR00(a6)
	Btst	#6,CIAAPRA
	Bne.s	.mouseWait

	Move.w	#-1,pr_musicfadedirection
	Move.w	#-1,twirlCounter
	Move.w	#-1,clearCounter
	Move.w	#2,fadeSpeed
	MoveQ	#16*2+16-1,d0
.forFadeOut
	Move.w	d0,-(SP)
	Bsr	VWait
	Bsr	InsertPalette
	Bsr	BlitTwirl
	Bsr	ScreenDB
	Bsr	FadeToBlack
	;Move.w	#$080,COLOR00(a6)
	Move.w	(SP)+,d0
	Dbf	d0,.forFadeOut

	Bsr	pr_end
	Move.w	#INTEN,INTENA(a6)				;Stop Interrupts
	Rts


;======================================================================================================


	;VBI Interrupt server, plays music. And if CustIntPtr is
	;non-zero then the subroutine it points to will be called.
	;
	;Restores all
	;---------------------------------------------------------

vTimer		Dc.l	0
custIntPtr	Dc.l	TextWriter

Level3	MoveM.l	d0-a6,-(SP)

	Bsr	pr_music
	
	AddQ.b	#1,vBlank
	AddQ.l	#1,vTimer

	Tst.l	custIntPtr
	Beq.s	.nil
	MoveM.l	d0-a6,-(SP)
	Move.l	custIntPtr,a0
	Jsr	(a0)
	MoveM.l	(SP)+,d0-a6
.nil	
	Lea	CUSTOM,a6
	Move.w	#VERTB,INTREQ(a6)				;Clear interrupt request bit
	MoveM.l	(SP)+,d0-a6
	Rte


;------------------------------------------------------------------------------------------------------


	;Waits one vertical blank
	;
	;Corrupts: None
	;------------------------

vBlank	Dc.b	0
	Even

VWait	Clr.b	vBlank
.wait	Tst.b	vBlank
	Beq.s	.wait
	Rts

;------------------------------------------------------------------------------------------------------


	;Set-up bitplane pointers in copper list.
	;
	;Corrupts: d0-d1
	;----------------------------------------
	;PRE: d0.l -> Start of bpl data
	;     d1.w =  Counter for no of bpls - 1
	;     d2.l =  Bytes between planes
	;     a0.l -> BplPtrs in copper list
	
SetUpBplPtrs
	Move.w	d0,2(a0)					;High word of bpl pointer
	Swap	d0
	Move.w	d0,6(a0)					;Low word of bpl pointer
	Swap	d0
	Add.l	d2,d0						;Next bpl start
	AddQ	#8,a0						;Next ptr in copper list
	Dbf	d1,SetUpBplPtrs
	Rts


;======================================================================================================


SetUpBGColour
	Lea	copCust,a0

	Move.l	#$2c57fffe,d4
	Move.l	#$01800000,d5
	Move.l	#$2cc7fffe,d6
	Move.l	#$01800000,d7

	Move.l	d4,(a0)+
	Move.l	d5,(a0)+
	Move.l	d6,(a0)+
	Move.l	d7,(a0)+
	Add.l	#$01000000,d4
	Add.l	#$01000000,d6

	Sub.l	#$00020000,d4
	Move.w	#198-1,d3
.forLns	Move.l	d4,(a0)+
	Move.l	d5,(a0)+
	Move.l	d6,(a0)+
	Move.l	d7,(a0)+
	Add.l	#$01000000,d4
	Add.l	#$01000000,d6
	Dbf	d3,.forLns

	Add.l	#$00020000,d4
	Move.l	d4,(a0)+
	Move.l	d5,(a0)+
	Move.l	d6,(a0)+
	Move.l	d7,(a0)+

	Move.l	#$fffffffe,(a0)	
	Rts


;------------------------------------------------------------------------------------------------------


InsertPalette
	Lea	currentPalette,a0
	Lea	colours+6,a1
	Lea	copCust+6,a2
	Move.w	(a0)+,d7
	
	MoveQ	#30-1,d0
.forPal	Move.w	(a0)+,(a1)
	AddQ	#4,a1
	Dbf	d0,.forPal
	Move.w	(a0)+,d6
	Move.w	d6,(a1)
	AddQ	#4,a1

	Move.w	d6,(a2)
	Lea	16(a2),a2
	Move.w	#198/9-1,d1
.forLns	MoveQ	#9-1,d0
.forMvs	Move.w	d7,(a2)
	Lea	16(a2),a2
	Dbf	d0,.forMvs
	Dbf	d1,.forLns
	Move.w	d6,(a2)

	Rts


;------------------------------------------------------------------------------------------------------


fadeSpeed	Dc.w	0
fadeCounter	Dc.w	0

FadeToPalette
	AddQ.w	#1,fadeCounter
	Move.w	fadeCounter(PC),d0
	Cmp.w	fadeSpeed,d0
	Blt.s	.exit
	Move.w	#0,fadeCounter	
	Lea	palette(PC),a0
	Lea	currentPalette,a1
	
	MoveQ	#0,d3
	MoveQ	#0,d4
	MoveQ	#32-1,d0
.forCuls
	Move.w	(a0)+,d1
	Move.w	(a1)+,d2
	Cmp.w	d2,d1
	Beq.s	.skip
	
	Move.w	d2,d7
	Move.b	d1,d3
	Move.b	d2,d4
	Move.b	d1,d5
	Move.b	d2,d6
	Lsr.w	#8,d1
	Lsr.w	#8,d2
	And.b	#$f0,d3
	And.b	#$f0,d4
	And.b	#$0f,d5
	And.b	#$0f,d6

	Cmp.b	d2,d1
	Beq.s	.redOk
	Bgt.s	.redBig
	Sub.w	#$100,d7
	Bra.s	.redOk
.redBig	Add.w	#$100,d7
.redOk	Cmp.w	d4,d3
	Beq.s	.grnOk
	Bgt.s	.grnBig
	Sub.b	#$010,d7
	Bra.s	.grnOk
.grnBig	Add.b	#$010,d7
.grnOk	Cmp.b	d6,d5
	Beq.s	.bluOk
	Bgt.s	.bluBig
	SubQ	#$001,d7
	Bra.s	.bluOk
.bluBig	AddQ	#$001,d7
.bluOk
	Move.w	d7,-2(a1)
.skip	Dbf	d0,.forCuls	

.exit	Rts

	;----------------------------------------------------------------------------------------------

FadeToBlack
	AddQ.w	#1,fadeCounter
	Move.w	fadeCounter(PC),d0
	Cmp.w	fadeSpeed,d0
	Blt.s	.exit
	Move.w	#0,fadeCounter
	Lea	currentPalette,a1
	
	MoveQ	#32-1,d0
.forCuls
	Move.w	(a1)+,d1
	Tst.w	d1
	Beq.s	.skip
	
	Move.w	d1,d7
	Move.b	d1,d2
	Move.b	d1,d3
	Lsr.w	#8,d1
	And.b	#$f0,d2
	And.b	#$0f,d3

	Tst.b	d1
	Beq.s	.redOk
	Sub.w	#$100,d7
.redOk	Tst.b	d2
	Beq.s	.grnOk
	Sub.w	#$010,d7
.grnOk	Tst.b	d3
	Beq.s	.blueOk
	SubQ	#$001,d7
.blueOk
	Move.w	d7,-2(a1)
.skip	Dbf	d0,.forCuls	

.exit	Rts


;------------------------------------------------------------------------------------------------------


TEXTSTARTOFFSET	Equ	28*7*2
PAUSETIME	Equ	21*3+50*7

xOffset		Dc.w	0
lineOffset	Dc.l	textBitmap+TEXTSTARTOFFSET
charPtr		Dc.l	message
clearCounter	Dc.w	32
clearLineOffset	Dc.l	textBitmap+TEXTSTARTOFFSET


TextWriter
	Tst.w	clearCounter
	Blt.s	.endClear
	Beq.s	.nextChar
	SubQ.w	#1,clearCounter
	Cmp.w	#21*3,clearCounter
	Bge.s	.paused
.endClear
	Move.l	clearLineOffset(PC),a0
	Cmp.l	#textBitmap+TEXTSTARTOFFSET+28*3*2*21*3,a0		;Ugh!
	Bge.s	.paused
	Add.l	#28*3*2,clearLineOffset
	MoveQ	#3*2-1,d0
.forLgs
	REPT	7
	Clr.l	(a0)+
	ENDR
	Dbf	d0,.forLgs
.paused	Rts

.nextChar
	Move.l	#textBitmap+TEXTSTARTOFFSET,clearLineOffset
	Move.l	charPtr(PC),a0
	AddQ.l	#1,charPtr
	MoveQ	#0,d0
	Move.b	(a0),d0
	Bne.s	.notEOT
	Clr.w	xOffset							;End of Text
	Move.l	#textBitmap+TEXTSTARTOFFSET,lineOffset
	Move.l	#message,charPtr
	Move.w	#PAUSETIME,clearCounter
	Move.l	#textBitmap+TEXTSTARTOFFSET,clearLineOffset
	Rts
.notEOT	Cmp.b	#1,d0
	Bne.s	.notEOL
	Clr.w	xOffset							;End of Line
	Add.l	#28*9*2,lineOffset
	Bra.s	.nextChar
.notEOL	Cmp.b	#2,d0
	Bne.s	.notEOP
	Clr.w	xOffset							;End of Page
	Move.l	#textBitmap+TEXTSTARTOFFSET,lineOffset
	Move.w	#PAUSETIME,clearCounter
	Move.l	#textBitmap+TEXTSTARTOFFSET,clearLineOffset
	Rts
.notEOP	Cmp.b	#" ",d0							;Space char
	Bne.s	.notSpace
	AddQ.w	#1,xOffset
	Bra	.nextChar
.notSpace

	;Draw Char

	Lea	font(PC),a0
	Move.l	lineOffset(PC),a1
	Add.w	xOffset(PC),a1
	AddQ.w	#1,xOffset
	Sub.w	#" ",d0
	Mulu	#12*2*2,d0
	Add.w	d0,a0
	MoveQ	#12-1,d0
.forLns	Move.l	(a0)+,d1
	Move.l	d1,d2
	Swap	d2
	Or.w	d1,d2
	Not.w	d2
	Ror.w	#8,d2
	Ror.w	#8,d1
	And.b	d2,(a1)
	Or.b	d1,(a1)
	Rol.w	#8,d2
	Rol.w	#8,d1
	And.b	d2,1(a1)
	Or.b	d1,1(a1)
	Swap	d1
	Ror.w	#8,d2
	Ror.w	#8,d1
	And.b	d2,28(a1)
	Or.b	d1,28(a1)
	Rol.w	#8,d2
	Rol.w	#8,d1
	And.b	d2,28+1(a1)
	Or.b	d1,28+1(a1)
	Lea	28*2(a1),a1
	Dbf	d0,.forLns
	Rts

	;----------------------------------------------------------------------------------------------

message	Include	Text.Asm


;------------------------------------------------------------------------------------------------------


bitmapSrcPtr	Dc.l	bitmap2
bitmapDestPtr	Dc.l	bitmap1

ScreenDB
	Move.l	bitmapDestPtr(PC),d0
	Move.l	bitmapSrcPtr(PC),bitmapDestPtr
	Move.l	d0,bitmapSrcPtr

	Move.l	bitmapSrcPtr(PC),d0
	Add.l	#40*61*3+6,d0
	MoveQ	#3-1,d1
	MoveQ	#40,d2
	Lea	bplPtrs,a0
	Bsr	SetUpBplPtrs
	Rts


;------------------------------------------------------------------------------------------------------


twirlCounter	Dc.w	0


BlitTwirl
	Lea	blitVals+960*4,a0
	Tst.w	twirlCounter
	Blt	.twirl

	AddQ.w	#1,twirlCounter
	Move.w	twirlCounter(PC),d0
	Cmp.w	#$40,d0
	Blt.s	.still
	Lea	blitVals+960*0,a0
	Cmp.w	#$100*1+$40*1,d0
	Blt	.twirl
	Lea	blitVals+960*1,a0
	Cmp.w	#$100*2+$40*1,d0
	Blt	.twirl
	Cmp.w	#$100*2+$40*2,d0
	Blt.s	.still
	Lea	blitVals+960*2,a0
	Cmp.w	#$80*1+$100*2+$40*2,d0
	Blt	.twirl
	Lea	blitVals+960*3,a0
	Cmp.w	#$80*2+$100*2+$40*2-1,d0
	Blt	.twirl
	Clr.w	twirlCounter
	Bra.s	.twirl

.still	Move.l	bitmapSrcPtr(PC),BLTAPTH(a6)
	Move.l	bitmapDestPtr(PC),BLTDPTH(a6)
	Move.l	#0,BLTAMOD(a6)
	Move.l	#$ffffffff,BLTAFWM(a6)
	Move.l	#$09f00000,BLTCON0(a6)
	Move.w	#320*3<<6+20,BLTSIZE(a6)
.bWait	Btst	#14,DMACONR(a6)
	Bne.s	.bWait
	Rts


.twirl
	MoveQ	#20-1,d0
.forBlits1
	Move.l	bitmapSrcPtr(PC),a1
	Move.l	bitmapDestPtr(PC),a2
	Add.l	(a0)+,a1
	Add.l	(a0)+,a2
	MoveM.l	a1/a2,BLTAPTH(a6)
	Move.l	(a0)+,BLTAMOD(a6)
	Move.l	(a0)+,BLTAFWM(a6)
	Move.l	(a0)+,BLTCON0(a6)
	Move.w	(a0)+,BLTSIZE(a6)
	Addq.l	#2,a0
.bWait1	Btst	#14,DMACONR(a6)
	Bne.s	.bWait1
	Dbf	d0,.forBlits1

	MoveQ	#20-1,d0
.forBlits2
	Move.l	bitmapDestPtr(PC),a1
	Move.l	a1,a2
	Add.l	(a0)+,a1
	Add.l	(a0)+,a2
	MoveM.l	a1/a2,BLTAPTH(a6)
	Move.l	(a0)+,BLTAMOD(a6)
	Move.l	(a0)+,BLTAFWM(a6)
	Move.l	(a0)+,BLTCON0(a6)
	Move.w	(a0)+,BLTSIZE(a6)
	Addq.l	#2,a0
.bWait2	Btst	#14,DMACONR(a6)
	Bne.s	.bWait2
	Dbf	d0,.forBlits2
	Rts

	;----------------------------------------------------------------------------------------------

blitVals	
	Include	BlitVals.Asm


;======================================================================================================


	CNOP	0,4
font	Incbin	Font12x12x2.Raw

	CNOP	0,2
palette	Incbin	Palette.Raw

	;----------------------------------------------------------------------------------------------

	Section	ChipStuff,Data_C

copList	Dc.w	$2001,$fffe
	Dc.w	DIWSTRT,$2db0
	Dc.w	DIWSTOP,$f391
	Dc.w	DDFSTRT,$0050
	Dc.w	DDFSTOP,$00b8
   
	Dc.w	BPLCON0,$5204
	Dc.w	BPLCON1,$0060
	Dc.w	BPLCON2,$007f
	Dc.w	BPLCON3,$0c00
	Dc.w	BPL1MOD,40*(3-1)+12
	Dc.w	BPL2MOD,28*(2-1)
	
bplPtrs	Dc.w	BPL1PTL,0,BPL1PTH,0,BPL3PTL,0,BPL3PTH,0,BPL5PTL,0,BPL5PTH,0
	Dc.w	BPL2PTL,0,BPL2PTH,0,BPL4PTL,0,BPL4PTH,0

colours	Dc.w	COLOR00,0,COLOR01,0,COLOR04,0,COLOR05,0			;Backgound colours (0..7)
	Dc.w	COLOR16,0,COLOR17,0,COLOR20,0,COLOR21,0
	Dc.w	COLOR10,0,COLOR11,0,COLOR14,0,COLOR15,0			;Text shadow colour (0..7)
	Dc.w	COLOR26,0,COLOR27,0,COLOR30,0,COLOR31,0
	Dc.w	COLOR02,0,COLOR03,0,COLOR06,0,COLOR07,0			;Text colour 1 (0..7)
	Dc.w	COLOR18,0,COLOR19,0,COLOR22,0,COLOR23,0
	Dc.w	COLOR08,0,COLOR09,0,COLOR12,0,COLOR13,0			;Text colour 2 (0..7)
	Dc.w	COLOR24,0,COLOR25,0,COLOR28,0,COLOR29,0

	;These sprites use COLOR29
	Dc.w	SPR6POS,$0057,SPR6CTL,$0001,SPR6DATB,$0000,SPR6DATA,$8000
	Dc.w	SPR7POS,$00c0,SPR7CTL,$0000,SPR7DATB,$0000,SPR7DATA,$0001

	Dc.w	COPJMP2,0						;Jump to COP2LC

	;----------------------------------------------------------------------------------------------
	
module	Incbin	MOD.Monty(HiScore)

	;----------------------------------------------------------------------------------------------

	CNOP	0,2
	Ds.b	40*10*3
bitmap1	Incbin	Pict320x320x3.Raw
	Ds.b	40*10*3

	;----------------------------------------------------------------------------------------------

	Section	BSSChipStuff,BSS_C

	CNOP	0,2
	Ds.b	40*10*3
bitmap2	Ds.b	40*320*3
	Ds.b	40*10*3

	CNOP	0,2
textBitmap
	Ds.b	28*198*2
	
	CNOP	0,4
copCust	Ds.l	4*200+1

	;----------------------------------------------------------------------------------------------

	Section	BSSStuff,BSS

	CNOP	0,2
currentPalette
	Ds.w	32