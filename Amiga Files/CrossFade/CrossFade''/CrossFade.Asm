	;CrossFade
	;
	;By Jobbo 25/01/96

	section	MainCode,code

	incdir	Sources:Includes/
	include	Hardware.i
	include	StartUp.i
	;incdir	Sources:CrossFade/
	incdir	Sources:CrossFade''/

Main	lea	custCop1,a0
	bsr.w	CustCopInit
	lea	custCop2,a0
	bsr.w	CustCopInit
	bsr.w	FadeLUTInit

	move.l	#pattBitmap,d0
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

loop
	move.w	#64,d7
show1	bsr.w	CustCopDB
	bsr.w	VWait
	lea	pict1,a0
	bsr.w	CopyPixels
.pause	btst	#2,POTGOR+CUSTOM
	beq.s	.pause
	btst	#6,CIAAPRA
	beq.w	mouseExit
	dbf	d7,show1

	move.w	#0,fadeVal
x1to2	bsr.w	CustCopDB
	bsr.w	VWait
	lea	pict1,a0
	lea	pict2,a1
	bsr.w	CrossFadePixels
.pause	btst	#2,POTGOR+CUSTOM
	beq.s	.pause
	btst	#6,CIAAPRA
	beq.w	mouseExit
	add.w	#16,fadeVal
	cmp.w	#256,fadeVal
	blt.w	x1to2

	move.w	#64,d7
show2	bsr.w	CustCopDB
	bsr.w	VWait
	lea	pict2,a0
	bsr.w	CopyPixels
.pause	btst	#2,POTGOR+CUSTOM
	beq.s	.pause
	btst	#6,CIAAPRA
	beq.w	mouseExit
	dbf	d7,show2

	move.w	#0,fadeVal
x2to3	bsr.w	CustCopDB
	bsr.w	VWait
	lea	pict2,a0
	lea	pict3,a1
	bsr.w	CrossFadePixels
.pause	btst	#2,POTGOR+CUSTOM
	beq.s	.pause
	btst	#6,CIAAPRA
	beq.w	mouseExit
	add.w	#16,fadeVal
	cmp.w	#256,fadeVal
	blt.b	x2to3

	move.w	#64,d7
show3	bsr.w	CustCopDB
	bsr.w	VWait
	lea	pict3,a0
	bsr.w	CopyPixels
.pause	btst	#2,POTGOR+CUSTOM
	beq.s	.pause
	btst	#6,CIAAPRA
	beq.b	mouseExit
	dbf	d7,show3

	move.w	#0,fadeVal
x3to1	bsr.w	CustCopDB
	bsr.w	VWait
	lea	pict3,a0
	lea	pict1,a1
	bsr.w	CrossFadePixels
.pause	btst	#2,POTGOR+CUSTOM
	beq.s	.pause
	btst	#6,CIAAPRA
	beq.b	mouseExit
	add.w	#16,fadeVal
	cmp.w	#256,fadeVal
	blt.b	x3to1

	bra.w	loop

mouseExit
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

	;----------------------------------------------------------------------------------------------

	;PRE: a0 -> Pixels
	;     a1 -> Pixels

fadeVal	dc.w	0

CrossFadePixels
	move.l	custCopOffPtr(pc),a2
	lea	offsets(pc),a3
	lea	fadeLUT,a4

	move.w	fadeVal(pc),d0
	move.w	#256,d1
	sub.w	d0,d1
	lsr.w	#4,d0
	lsr.w	#4,d1

	moveq.l	#0,d2
	move.w	d0,d2
	lsl.w	#8,d2
	lsl.l	#7,d2
	add.l	d2,a4

	moveq.l	#DISPLAYHEIGHT-1,d2
.forY	move.l	a2,a5
	lea	INSTRPERLINE*4(a2),a2
	move.l	a3,a6
	moveq.l	#DISPLAYWIDTH-1,d3
.forX	moveq.l	#0,d4
	move.b	(a0)+,d4
	lsl.w	#7,d4
	or.b	(a1)+,d4
	add.w	(a6)+,a5
	move.w	(a4,d4.w*2),(a5)
	dbf	d3,.forX
	dbf	d2,.forY

	rts

;------------------------------------------------------------------------------------------------------

FadeLUTInit
	lea	palette,a0
	lea	fadeLUT,a1

	moveq.l	#0,d0
	moveq.l	#16,d1
.forBri	moveq.l	#0,d2
.forCl1	moveq.l	#0,d3
.forCl2
	move.w	(a0,d2.w*2),d4
	move.w	(a0,d3.w*2),d5

	move.b	d4,d6
	move.b	d5,d7
	and.w	#$f,d6
	and.w	#$f,d7
	mulu.w	d1,d6
	mulu.w	d0,d7
	add.w	d6,d7
	lsr.w	#4,d7
	move.w	d7,a2

	lsr.w	#4,d4
	lsr.w	#4,d5
	move.b	d4,d6
	move.b	d5,d7
	and.w	#$f,d6
	and.w	#$f,d7
	mulu.w	d1,d6
	mulu.w	d0,d7
	add.w	d6,d7
	and.b	#$f0,d7
	move.w	a2,d6
	or.b	d7,d6

	lsr.b	#4,d4
	lsr.b	#4,d5
	and.b	#$f,d4
	and.b	#$f,d5
	mulu.w	d1,d4
	mulu.w	d0,d5
	add.w	d4,d5
	lsl.w	#4,d5
	and.w	#$f00,d5
	move.b	d6,d5

	move.w	d5,(a1)+
	move.w	d5,COLOR00+CUSTOM

	addq.w	#1,d3
	cmp.w	#128,d3
	blt.b	.forCl2
	addq.w	#1,d2
	cmp.w	#128,d2
	blt.b	.forCl1
	addq.w	#1,d0
	subq.w	#1,d1
	cmp.w	#16,d0
	blt.b	.forBri

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

	cnop	0,8
pattBitmap
	dc.l	$1c71c71c,$71c71c71,$c71c71c7,$1c71c71c,$71c71c71
	dc.l	$c71c71c7,$1c71c71c,$71c71c71,$c71c71c7,$1c71c71c
	dc.l	$03f03f03,$f03f03f0,$3f03f03f,$03f03f03,$f03f03f0
	dc.l	$3f03f03f,$03f03f03,$f03f03f0,$3f03f03f,$03f03f03
	dc.l	$000fff00,$0fff000f,$ff000fff,$000fff00,$0fff000f
	dc.l	$ff000fff,$000fff00,$0fff000f,$ff000fff,$000fff00
	dc.l	$000000ff,$ffff0000,$00ffffff,$000000ff,$ffff0000
	dc.l	$00ffffff,$000000ff,$ffff0000,$00ffffff,$000000ff
	dc.l	$00000000,$0000ffff,$ffffffff,$00000000,$0000ffff
	dc.l	$ffffffff,$00000000,$0000ffff,$ffffffff,$00000000
	dc.l	$00000000,$00000000,$00000000,$ffffffff,$ffffffff
	dc.l	$ffffffff,$00000000,$00000000,$00000000,$ffffffff
	dc.l	$00000000,$00000000,$00000000,$00000000,$00000000
	dc.l	$00000000,$ffffffff,$ffffffff,$ffffffff,$ffffffff

	;----------------------------------------------------------------------------------------------

	section	Stuff,data
	cnop	0,4
palette	incbin	Palette.Raw
pict1	incbin	Pict106x85-1.Chunky
pict2	incbin	Pict106x85-2.Chunky
pict3	incbin	Pict106x85-3.Chunky

	;----------------------------------------------------------------------------------------------

	section	BSSChipStuff,bss_c
	cnop	0,4
custCop1	ds.l	INSTRPERLINE*DISPLAYHEIGHT+2+1
custCop2	ds.l	INSTRPERLINE*DISPLAYHEIGHT+2+1

	;----------------------------------------------------------------------------------------------

	section	BSSStuff,bss
	cnop	0,4
fadeLUT	ds.w	128*128*16