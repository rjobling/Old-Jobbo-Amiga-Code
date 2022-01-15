	;CrossFade
	;
	;By Jobbo 21/08/96

	section	MainCode,code

	incdir	Sources:Includes/
	include	Hardware.i
	include	StartUp.i
	incdir	Sources:CrossFade/

RASTER	equ	0

Raster	macro
	IFNE	RASTER
	move.w	#$ff,$dff102
	ENDC
	endm

count	dc.w	0

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
	move.w	#0,count
show1	bsr.w	CustCopDB
	bsr.w	VWait
	lea	pict,a0
	bsr.w	CopyPixels
	Raster
.pause	btst	#2,POTGOR+CUSTOM
	beq.s	.pause
	btst	#6,CIAAPRA
	beq.w	mouseExit
	addq.w	#1,count
	cmp.w	#64,count
	blt.s	show1

	move.w	#0,fadeVal
x1to2	bsr.w	CustCopDB
	bsr.w	VWait
	lea	pict,a0
	lea	pict+85*2,a1
	bsr.w	CrossFadePixels
	Raster
.pause	btst	#2,POTGOR+CUSTOM
	beq.s	.pause
	btst	#6,CIAAPRA
	beq.w	mouseExit
	add.w	#16,fadeVal
	cmp.w	#256,fadeVal
	blt.w	x1to2

	move.w	#0,count
show2	bsr.w	CustCopDB
	bsr.w	VWait
	lea	pict+85*2,a0
	bsr.w	CopyPixels
	Raster
.pause	btst	#2,POTGOR+CUSTOM
	beq.s	.pause
	btst	#6,CIAAPRA
	beq.w	mouseExit
	addq.w	#1,count
	cmp.w	#64,count
	blt.s	show2

	move.w	#0,fadeVal
x2to3	bsr.w	CustCopDB
	bsr.w	VWait
	lea	pict+85*2,a0
	lea	pict+85*4,a1
	bsr.w	CrossFadePixels
	Raster
.pause	btst	#2,POTGOR+CUSTOM
	beq.s	.pause
	btst	#6,CIAAPRA
	beq.w	mouseExit
	add.w	#16,fadeVal
	cmp.w	#256,fadeVal
	blt.b	x2to3

	move.w	#0,count
show3	bsr.w	CustCopDB
	bsr.w	VWait
	lea	pict+85*4,a0
	bsr.w	CopyPixels
	Raster
.pause	btst	#2,POTGOR+CUSTOM
	beq.s	.pause
	btst	#6,CIAAPRA
	beq.w	mouseExit
	addq.w	#1,count
	cmp.w	#64,count
	blt.s	show3

	move.w	#0,fadeVal
x3to4	bsr.w	CustCopDB
	bsr.w	VWait
	lea	pict+85*4,a0
	lea	pict+512*106,a1
	bsr.w	CrossFadePixels
	Raster
.pause	btst	#2,POTGOR+CUSTOM
	beq.s	.pause
	btst	#6,CIAAPRA
	beq.w	mouseExit
	add.w	#16,fadeVal
	cmp.w	#256,fadeVal
	blt.b	x3to4

	move.w	#0,count
show4	bsr.w	CustCopDB
	bsr.w	VWait
	lea	pict+512*106,a0
	bsr.w	CopyPixels
	Raster
.pause	btst	#2,POTGOR+CUSTOM
	beq.s	.pause
	btst	#6,CIAAPRA
	beq.w	mouseExit
	addq.w	#1,count
	cmp.w	#64,count
	blt.s	show4

	move.w	#0,fadeVal
x4to5	bsr.w	CustCopDB
	bsr.w	VWait
	lea	pict+512*106,a0
	lea	pict+512*106+85*2,a1
	bsr.w	CrossFadePixels
	Raster
.pause	btst	#2,POTGOR+CUSTOM
	beq.s	.pause
	btst	#6,CIAAPRA
	beq.w	mouseExit
	add.w	#16,fadeVal
	cmp.w	#256,fadeVal
	blt.b	x4to5

	move.w	#0,count
show5	bsr.w	CustCopDB
	bsr.w	VWait
	lea	pict+512*106+85*2,a0
	bsr.w	CopyPixels
	Raster
.pause	btst	#2,POTGOR+CUSTOM
	beq.s	.pause
	btst	#6,CIAAPRA
	beq.w	mouseExit
	addq.w	#1,count
	cmp.w	#64,count
	blt.s	show5

	move.w	#0,fadeVal
x5to6	bsr.w	CustCopDB
	bsr.w	VWait
	lea	pict+512*106+85*2,a0
	lea	pict+512*106+85*4,a1
	bsr.w	CrossFadePixels
	Raster
.pause	btst	#2,POTGOR+CUSTOM
	beq.s	.pause
	btst	#6,CIAAPRA
	beq.w	mouseExit
	add.w	#16,fadeVal
	cmp.w	#256,fadeVal
	blt.b	x5to6

	move.w	#0,count
show6	bsr.w	CustCopDB
	bsr.w	VWait
	lea	pict+512*106+85*4,a0
	bsr.w	CopyPixels
	Raster
.pause	btst	#2,POTGOR+CUSTOM
	beq.s	.pause
	btst	#6,CIAAPRA
	beq.b	mouseExit
	addq.w	#1,count
	cmp.w	#64,count
	blt.s	show6

	move.w	#0,fadeVal
x6to1	bsr.w	CustCopDB
	bsr.w	VWait
	lea	pict+512*106+85*4,a0
	lea	pict,a1
	bsr.w	CrossFadePixels
	Raster
.pause	btst	#2,POTGOR+CUSTOM
	beq.s	.pause
	btst	#6,CIAAPRA
	beq.b	mouseExit
	add.w	#16,fadeVal
	cmp.w	#256,fadeVal
	blt.b	x6to1

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
	move.w	#INSTRPERLINE*4*17,a3
	moveq.l	#DISPLAYWIDTH-1,d0
.forX	add.w	(a2)+,a1
	move.l	a1,a4
	moveq.l	#DISPLAYHEIGHT/17-1,d1
.forY
	movem.l	(a0)+,d2-d7
	move.w	d2,INSTRPERLINE*4(a4)
	swap	d2
	move.w	d2,(a4)
	move.w	d3,INSTRPERLINE*4*3(a4)
	swap	d3
	move.w	d3,INSTRPERLINE*4*2(a4)
	move.w	d4,INSTRPERLINE*4*5(a4)
	swap	d4
	move.w	d4,INSTRPERLINE*4*4(a4)
	move.w	d5,INSTRPERLINE*4*7(a4)
	swap	d5
	move.w	d5,INSTRPERLINE*4*6(a4)
	move.w	d6,INSTRPERLINE*4*9(a4)
	swap	d6
	move.w	d6,INSTRPERLINE*4*8(a4)
	move.w	d7,INSTRPERLINE*4*11(a4)
	swap	d7
	move.w	d7,INSTRPERLINE*4*10(a4)

	movem.w	(a0)+,d2-d6
	move.w	d2,INSTRPERLINE*4*12(a4)
	move.w	d3,INSTRPERLINE*4*13(a4)
	move.w	d4,INSTRPERLINE*4*14(a4)
	move.w	d5,INSTRPERLINE*4*15(a4)
	move.w	d6,INSTRPERLINE*4*16(a4)

	add.l	a3,a4

	dbf	d1,.forY
	lea	(256-DISPLAYHEIGHT)*2(a0),a0
	dbf	d0,.forX
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

	moveq.l	#0,d1
	move.w	d0,d1
	lsl.w	#8,d1
	lsl.l	#8,d1
	add.l	d1,a4

	move.l	#INSTRPERLINE*4,d2
	moveq.l	#0,d3
	moveq.l	#0,d4
	moveq.l	#DISPLAYWIDTH-1,d0
.forX	add.w	(a3)+,a2
	move.l	a2,a5
	moveq.l	#DISPLAYHEIGHT-1,d1
.forY
	move.w	(a0)+,d3				;d3 = xRGB
	move.b	d3,d5
	move.w	(a1)+,d4				;d4 = xRGB
	ror.w	#8,d4
	move.b	d4,d3					;d3 = xRxR
	move.b	d5,d4
	ror.w	#8,d4					;d4 = GBGB
	move.b	(a4,d3.l),d3				;d3 = new xR
	lsl.w	#8,d3
	move.b	(a4,d4.l),d3				;d3 = new xRGB
	move.w	d3,(a5)
	add.l	d2,a5

	dbf	d1,.forY
	lea	(256-DISPLAYHEIGHT)*2(a0),a0
	lea	(256-DISPLAYHEIGHT)*2(a1),a1
	dbf	d0,.forX

	rts

;------------------------------------------------------------------------------------------------------

FadeLUTInit
	lea	fadeLUT,a0

	moveq.l	#0,d0
	moveq.l	#16,d1
.forBri	moveq.l	#0,d2
.forCl1	moveq.l	#0,d3
.forCl2
	move.w	d2,d4
	and.b	#$0f,d4
	mulu.w	d1,d4
	move.w	d3,d5
	and.b	#$0f,d5
	mulu.w	d0,d5
	add.b	d5,d4
	lsr.b	#4,d4

	move.w	d2,d5
	and.b	#$f0,d5
	mulu.w	d1,d5
	move.w	d3,d6
	and.b	#$f0,d6
	mulu.w	d0,d6
	add.w	d6,d5
	lsr.w	#4,d5

	and.b	#$f0,d5
	or.b	d5,d4

	move.b	d4,(a0)+
	move.w	d4,COLOR00+CUSTOM

	addq.w	#1,d3
	cmp.w	#256,d3
	blt.b	.forCl2
	addq.w	#1,d2
	cmp.w	#256,d2
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

	dc.w	BPLCON0,$7201
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
pict	incbin	Pict256x212.Chunky

	;----------------------------------------------------------------------------------------------

	section	BSSChipStuff,bss_c
	cnop	0,4
custCop1	ds.l	INSTRPERLINE*DISPLAYHEIGHT+2+1
custCop2	ds.l	INSTRPERLINE*DISPLAYHEIGHT+2+1

	;----------------------------------------------------------------------------------------------

	section	BSSStuff,bss
	cnop	0,4
fadeLUT	ds.b	256*256*16