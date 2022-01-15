	;BlurPict
	;
	;By Jobbo 26/01/96

	Section	MainCode,Code

	Incdir	Sources:Includes/
	Include	Hardware.i
	Include	StartUp.i
	Incdir	Sources:BlurPict/

Main	Lea	custCop1,a0
	Bsr.w	CustCopInit
	Lea	custCop2,a0
	Bsr.w	CustCopInit

	Move.l	#pattBitmap,d0
	MoveQ.l	#7-1,d1
	MoveQ.l	#40,d2
	Lea	copBplPtrs,a0
	Bsr.w	SetUpBplPtrs

	Lea	CUSTOM,a6
	Move.l	VBRReg(PC),a0					;New Level3 handler
	Move.l	#Level3,$6c(a0)
	Move.w	#SETIT+DMAEN+BPLEN+COPEN,DMACON(a6)		;DMA - ON
	Move.w	#SETIT+INTEN+VERTB,INTENA(a6)			;VBI interrupt - ON
	Move.l	#copList,COP1LCH(a6)				;Point copper at list
	Move.w	#0,COPJMP1(a6)					;Strobe to start

.mouseWait
	Bsr.w	CustCopDB
	Bsr.w	PictDB
	Bsr.w	VWait
	Move.l	pictOffPtr,a0
	Bsr.w	CopyPixels
	Bsr.w	BlurPict
.pause	btst	#2,POTGOR+CUSTOM
	beq.s	.pause
	Btst	#6,CIAAPRA
	Bne.w	.mouseWait

	Lea	CUSTOM,a6
	Move.w	#INTEN,INTENA(a6)				;Stop Interrupts
	Rts

;======================================================================================================

	;VBI Interrupt server, plays music. And if CustIntPtr is
	;non-zero then the subroutine it points to will be called.
	;
	;Restores all
	;---------------------------------------------------------

vTimer		Dc.l	0
custIntPtr	Dc.l	0

Level3	MoveM.l	d0-a6,-(SP)

	;Bsr.w	pr_music
	
	AddQ.b	#1,vBlank
	AddQ.l	#1,vTimer

	Tst.l	custIntPtr
	Beq.b	.nil
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
	Beq.b	.wait
	Rts

;------------------------------------------------------------------------------------------------------

	;Set-up bitplane pointers in copper list.
	;
	;Corrupts: d0-d1,a0
	;----------------------------------------
	;PRE: d0.l -> Start of bpl data
	;     d1.w =  Counter for no of bpls - 1
	;     d2.l =  Bytes between planes
	;     a0.l -> BplPtrs in copper list
	
SetUpBplPtrs
	Move.w	d0,2(a0)					;High word of bpl pointer
	Swap.w	d0
	Move.w	d0,6(a0)					;Low word of bpl pointer
	Swap.w	d0
	Add.l	d2,d0						;Next bpl start
	AddQ.l	#8,a0						;Next ptr in copper list
	Dbf	d1,SetUpBplPtrs
	Rts

;======================================================================================================

custCopOnPtr	Dc.l	custCop2
custCopOffPtr	Dc.l	custCop1

CustCopDB
	Move.l	custCopOffPtr(PC),d0
	Move.l	custCopOnPtr(PC),custCopOffPtr
	Move.l	d0,custCopOnPtr
	Move.l	custCopOnPtr(PC),COP2LCH+CUSTOM
	Rts

;------------------------------------------------------------------------------------------------------

	;PRE: a0 -> Custom copper buffer

DISPLAYWIDTH	Equ	106
DISPLAYHEIGHT	Equ	85
INSTRPERLINE	Equ	(1+1+(1+DISPLAYWIDTH/32)+DISPLAYWIDTH)

CustCopInit
	MoveQ.l	#0,d2
	Move.l	#$27e1fffe,d1
	MoveQ.l	#DISPLAYHEIGHT-1,d0
.forLns	Move.l	d1,(a0)+
	Add.l	#$03000000,d1
	BChg.l	#0,d2
	Beq.b	.even
	Move.l	#BPLCON4<<16+$8000,(a0)+
	Move.l	#BPLCON3<<16+$0020,d3
	Bra.b	.done
.even	Move.l	#BPLCON4<<16+$0000,(a0)+
	Move.l	#BPLCON3<<16+$8020,d3
.done	Move.l	#(COLOR31+2)<<16+$0000,d4
	MoveQ.l	#DISPLAYWIDTH-1,d5
.forCl	Cmp.l	#COLOR31<<16+$0000,d4
	Ble.b	.ok
	Move.l	#COLOR00<<16+$0000,d4
	Move.l	d3,(a0)+
	Add.w	#$2000,d3
.ok	Move.l	d4,(a0)+
	Add.l	#2<<16+$0000,d4
	Dbf	d5,.forCl
	Dbf	d0,.forLns
	Move.l	d1,(a0)+
	BChg.l	#0,d2
	Beq.b	.even2
	Move.l	#BPLCON4<<16+$8000,(a0)+
	Bra.b	.done2
.even2	Move.l	#BPLCON4<<16+$0000,(a0)+
.done2	Move.l	#$fffffffe,(a0)+
	Rts

;------------------------------------------------------------------------------------------------------

	;PRE: a0 -> Pixels

offsets	Dc.w	14,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
	Dc.w	8,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
	Dc.w	8,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
	Dc.w	8,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4

CopyPixels
	Move.l	custCopOffPtr(PC),a1
	Lea	offsets(PC),a2
	Lea	palette,a3
	MoveQ.l	#0,d2
	MoveQ.l	#DISPLAYHEIGHT-1,d0
.forY	Move.l	a1,a4
	Lea	INSTRPERLINE*4(a1),a1
	Move.l	a2,a5
	MoveQ.l	#DISPLAYWIDTH-1,d1
.forX	Move.b	(a0)+,d2
	Add.w	(a5)+,a4
	Move.w	(a3,d2.w*2),(a4)
	Dbf	d1,.forX
	Dbf	d0,.forY
	Rts

;------------------------------------------------------------------------------------------------------

pictOnPtr	Dc.l	pict2
pictOffPtr	Dc.l	pict1

PictDB
	Move.l	pictOffPtr(PC),d0
	Move.l	pictOnPtr(PC),pictOffPtr
	Move.l	d0,pictOnPtr
	Rts

;------------------------------------------------------------------------------------------------------

BlurPict
	Move.l	pictOnPtr,a0
	Move.l	pictOffPtr,a1
	MoveQ.w	#0,d2
	MoveQ.l	#DISPLAYHEIGHT-1,d0
.forY	MoveQ.l	#DISPLAYWIDTH-1,d1
.forX	Move.b	1(a0),d2
	Add.b	-1(a0),d2
	Add.b	106(a0),d2
	Add.b	-106(a0),d2
	MoveQ.w	#0,d3
	Move.b	(a0)+,d3
	Lsl.w	#2,d3
	Add.w	d2,d3
	Lsr.w	#3,d3
	Move.b	d3,(a1)+
	Dbf	d1,.forX
	Dbf	d0,.forY
	Rts

;======================================================================================================

	Section	ChipStuff,Data_C
	CNOP	0,4

copList	Dc.w	DIWSTRT,$2b81
	Dc.w	DIWSTOP,$2abf
	Dc.w	DDFSTRT,$0030
	Dc.w	DDFSTOP,$00b0

	Dc.w	BPLCON0,$7205
	Dc.w	BPLCON1,$0000
	Dc.w	BPLCON2,$0000
	Dc.w	BPLCON3,$0020
	Dc.w	BPL1MOD,-40
	Dc.w	BPL2MOD,-40
	Dc.w	FMODE,$0003
copBplPtrs
	Dc.w	BPL1PTL,0,BPL1PTH,0,BPL2PTL,0,BPL2PTH,0,BPL3PTL,0,BPL3PTH,0,BPL4PTL,0,BPL4PTH,0
	Dc.w	BPL5PTL,0,BPL5PTH,0,BPL6PTL,0,BPL6PTH,0,BPL7PTL,0,BPL7PTH,0

	Dc.w	COPJMP2,0					;Jump to COP2LC

	;----------------------------------------------------------------------------------------------

	CNOP	0,8
pattBitmap
	Dc.l	$1c71c71c,$71c71c71,$c71c71c7,$1c71c71c,$71c71c71
	Dc.l	$c71c71c7,$1c71c71c,$71c71c71,$c71c71c7,$1c71c71c
	Dc.l	$03f03f03,$f03f03f0,$3f03f03f,$03f03f03,$f03f03f0
	Dc.l	$3f03f03f,$03f03f03,$f03f03f0,$3f03f03f,$03f03f03
	Dc.l	$000fff00,$0fff000f,$ff000fff,$000fff00,$0fff000f
	Dc.l	$ff000fff,$000fff00,$0fff000f,$ff000fff,$000fff00
	Dc.l	$000000ff,$ffff0000,$00ffffff,$000000ff,$ffff0000
	Dc.l	$00ffffff,$000000ff,$ffff0000,$00ffffff,$000000ff
	Dc.l	$00000000,$0000ffff,$ffffffff,$00000000,$0000ffff
	Dc.l	$ffffffff,$00000000,$0000ffff,$ffffffff,$00000000
	Dc.l	$00000000,$00000000,$00000000,$ffffffff,$ffffffff
	Dc.l	$ffffffff,$00000000,$00000000,$00000000,$ffffffff
	Dc.l	$00000000,$00000000,$00000000,$00000000,$00000000
	Dc.l	$00000000,$ffffffff,$ffffffff,$ffffffff,$ffffffff

	;----------------------------------------------------------------------------------------------

	Section	Stuff,Data
	CNOP	0,4
palette	Incbin	Palette.Raw
	Ds.b	106+1
pict1	Incbin	Pict106x85-1.Chunky
	Ds.b	106+1

	;----------------------------------------------------------------------------------------------

	Section	BSSChipStuff,BSS_C
	CNOP	0,4
custCop1	Ds.l	INSTRPERLINE*DISPLAYHEIGHT+2+1
custCop2	Ds.l	INSTRPERLINE*DISPLAYHEIGHT+2+1

	;----------------------------------------------------------------------------------------------

	Section	BSSStuff,BSS
	CNOP	0,4
	Ds.b	106+1
pict2	Ds.b	106*85
	Ds.b	106+1