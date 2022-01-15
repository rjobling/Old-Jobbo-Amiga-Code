	;Zoom
	;
	;By Jobbo 28/03/96

	section	MainCode,code

	incdir	Sources:Includes/
	include	Hardware.i
	include	StartUp.i
	incdir	Sources:Zoom/

Main	bsr.w	RampBitmapInit
	lea	custCop1,a0
	bsr.w	CustCopInit
	lea	custCop2,a0
	bsr.w	CustCopInit
	bsr.w	CustCopDB
	lea	pict1,a0
	bsr.w	CopyPixels
	bsr.w	CustCopDB
	lea	pict1,a0
	bsr.w	CopyPixels

	move.l	#rampBitmap,d0
	moveq.l	#7-1,d1
	moveq.l	#40,d2
	lea	copBplPtrs,a0
	bsr.w	SetUpBplPtrs

	move.l	VBRReg(pc),a0				;New Level3 handler
	move.l	#Level3,$6c(a0)
	lea	CUSTOM,a6
	move.w	#SETIT+DMAEN+BPLEN+COPEN,DMACON(a6)	;DMA - ON
	move.w	#SETIT+INTEN+VERTB,INTENA(a6)		;VBI interrupt - ON
	move.l	#copList,COP1LCH(a6)			;Point copper at list
	move.w	#0,COPJMP1(a6)				;Strobe to start

.mouseWait
	bsr.w	CustCopDB
	bsr.w	VWait
	bsr.w	Zoom
.pause	btst	#2,POTGOR+CUSTOM
	beq.s	.pause
	btst	#6,CIAAPRA
	bne.b	.mouseWait

	move.w	#INTEN,INTENA+CUSTOM			;Stop interrupts
	rts

;======================================================================================================

	;VBI Interrupt server, plays music. And if CustIntPtr is
	;non-zero then the subroutine it points to will be called.
	;
	;Restores all
	;---------------------------------------------------------

vTimer		dc.l	0
custIntPtr	dc.l	0

Level3	movem.l	d0-a6,-(sp)

	;bsr	pr_music
	
	addq.b	#1,vBlank
	addq.l	#1,vTimer

	tst.l	custIntPtr
	beq.b	.nil
	move.l	custIntPtr,a0
	jsr	(a0)
.nil
	move.w	#VERTB,INTREQ+CUSTOM			;Clear intreq bit
	movem.l	(sp)+,d0-a6
	rte

;------------------------------------------------------------------------------------------------------

	;Waits one vertical blank
	;
	;Corrupts: None
	;------------------------

vBlank	dc.b	0
	even

VWait	clr.b	vBlank
.wait	tst.b	vBlank
	beq.b	.wait
	rts

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
	move.w	d0,2(a0)				;High word of bpl ptr
	swap.w	d0
	move.w	d0,6(a0)				;Low word of bpl ptr
	swap.w	d0
	add.l	d2,d0					;Next bpl start
	addq.l	#8,a0					;Next ptr in cop list
	dbf	d1,SetUpBplPtrs
	rts

;======================================================================================================

custCopOnPtr	dc.l	custCop2
custCopOffPtr	dc.l	custCop1

CustCopDB
	move.l	custCopOffPtr(pc),d0
	move.l	custCopOnPtr(pc),custCopOffPtr
	move.l	d0,custCopOnPtr
	move.l	custCopOnPtr(pc),COP2LCH+CUSTOM
	rts

;------------------------------------------------------------------------------------------------------

	;PRE: a0 -> Custom copper buffer

DISPLAYWIDTH	equ	106
DISPLAYHEIGHT	equ	85
INSTRPERLINE	equ	(1+1+(1+DISPLAYWIDTH/32)+DISPLAYWIDTH)

CustCopInit
	moveq.l	#0,d2
	move.l	#$27e1fffe,d1
	moveq.l	#DISPLAYHEIGHT-1,d0
.forLns	move.l	d1,(a0)+
	add.l	#$03000000,d1
	bchg.l	#0,d2
	beq.b	.even
	move.l	#BPLCON4<<16+$8000,(a0)+
	move.l	#BPLCON3<<16+$0020,d3
	bra.b	.done
.even	move.l	#BPLCON4<<16+$0000,(a0)+
	move.l	#BPLCON3<<16+$8020,d3
.done	move.l	#(COLOR31+2)<<16+$0000,d4
	moveq.l	#DISPLAYWIDTH-1,d5
.forCl	cmp.l	#COLOR31<<16+$0000,d4
	ble.b	.ok
	move.l	#COLOR00<<16+$0000,d4
	move.l	d3,(a0)+
	add.w	#$2000,d3
.ok	move.l	d4,(a0)+
	add.l	#2<<16+$0000,d4
	dbf	d5,.forCl
	dbf	d0,.forLns
	move.l	d1,(a0)+
	bchg.l	#0,d2
	beq.b	.even2
	move.l	#BPLCON4<<16+$8000,(a0)+
	bra.b	.done2
.even2	move.l	#BPLCON4<<16+$0000,(a0)+
.done2	move.l	#$fffffffe,(a0)+
	rts

;------------------------------------------------------------------------------------------------------

	;PRE: a0 -> Pixels

offsets	dc.w 14,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
	dc.w  8,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
	dc.w  8,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
	dc.w  8,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4

CopyPixels
	move.l	custCopOffPtr(pc),a1
	lea	offsets(pc),a2
	lea	palette,a3
	moveq.l	#0,d2
	moveq.l	#DISPLAYHEIGHT-1,d0
.forY	move.l	a1,a4
	lea	INSTRPERLINE*4(a1),a1
	move.l	a2,a5
	moveq.l	#DISPLAYWIDTH-1,d1
.forX	move.b	(a0)+,d2
	add.w	(a5)+,a4
	move.w	(a3,d2.w*2),(a4)
	dbf	d1,.forX
	dbf	d0,.forY
	rts

;------------------------------------------------------------------------------------------------------

RampBitmapInit
	lea	rampBitmap,a0
	moveq.l	#0,d6
	move.l	#3<<16,d3
	moveq.l	#0,d1
.whileY	move.l	d3,d4
	mulu.l	#53,d4
	sub.l	#159<<16,d4
	moveq.l	#0,d0
.whileX	move.l	d0,d2
	swap	d2
	add.l	d4,d2
	divu.l	d3,d2
	move.w	d1,d5
	mulu.w	#40*7,d5
	move.w	d0,d6
	lsr.w	#3,d6
	add.l	d6,d5
	moveq.l	#7,d6
	sub.b	d0,d6
	and.b	#7,d6
	moveq.l	#0,d7
.whileP	btst	d7,d2
	beq.s	.zero
	bset	d6,(a0,d5.l)
.zero	add.l	#40,d5
	addq.l	#1,d7
	cmp.w	#7,d7
	blt.s	.whileP
	move.w	d5,COLOR00+CUSTOM
	addq.l	#1,d0
	cmp.w	#318,d0
	blt.s	.whileX
	mulu.l	#129,d3
	lsr.l	#7,d3
	addq.l	#1,d1
	cmp.w	#512,d1
	blt.s	.whileY
	rts

;------------------------------------------------------------------------------------------------------

zoomVal	dc.w	0
pixSize	dc.l	3<<16

Zoom	move.l	#rampBitmap,d0
	move.w	zoomVal(pc),d1
	mulu.w	#40*7,d1
	add.l	d1,d0
	moveq.l	#7-1,d1
	moveq.l	#40,d2
	lea	copBplPtrs,a0
	bsr.w	SetUpBplPtrs

	move.l	custCopOffPtr(pc),a0
	move.b	#$27,(a0)
	lea	INSTRPERLINE*4(a0),a0
	move.l	pixSize(pc),d2
	move.l	#$2a0000,d1
	moveq.l	#84-1,d0
.forLns	swap	d1
	cmp.w	#256+44,d1
	blt.s	.inView
	move.w	#$ffff,(a0)
	bra.s	.done
.inView	move.b	d1,(a0)
	move.b	#$e1,1(a0)
.done	swap	d1
	lea	INSTRPERLINE*4(a0),a0
	add.l	d2,d1
	dbf	d0,.forLns

	addq.w	#1,zoomVal
	cmp.w	#512,zoomVal
	blt.s	.lt
	move.w	#0,zoomVal
	move.l	#3<<16,pixSize
	bra.s	.ok
.lt	move.l	pixSize(pc),d0
	mulu.l	#129,d0
	lsr.l	#7,d0
	move.l	d0,pixSize
.ok
	rts

;======================================================================================================

	section	ChipStuff,data_c
	cnop	0,4

copList	dc.w	DIWSTRT,$2b81
	dc.w	DIWSTOP,$2abf
	dc.w	DDFSTRT,$0030
	dc.w	DDFSTOP,$00b0

	dc.w	BPLCON0,$7205
	dc.w	BPLCON1,$0000
	dc.w	BPLCON2,$0000
	dc.w	BPLCON3,$0020
	dc.w	BPL1MOD,-40
	dc.w	BPL2MOD,-40
	dc.w	FMODE,$0003
copBplPtrs
	dc.w	BPL1PTL,0,BPL1PTH,0,BPL2PTL,0,BPL2PTH,0,BPL3PTL,0,BPL3PTH,0
	dc.w	BPL4PTL,0,BPL4PTH,0,BPL5PTL,0,BPL5PTH,0,BPL6PTL,0,BPL6PTH,0
	dc.w	BPL7PTL,0,BPL7PTH,0

	dc.w	COPJMP2,0				;Jump to COP2LC

	;----------------------------------------------------------------------------------------------

	section	Stuff,data
	cnop	0,4
palette	incbin	Palette.Raw
pict1	incbin	Pict106x85-1.Chunky

	;----------------------------------------------------------------------------------------------

	section	BSSChipStuff,bss_c
	cnop	0,8
rampBitmap	ds.b	40*7*512
custCop1	ds.l	INSTRPERLINE*DISPLAYHEIGHT+2+1
custCop2	ds.l	INSTRPERLINE*DISPLAYHEIGHT+2+1