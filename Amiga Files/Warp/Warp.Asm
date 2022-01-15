	;Warp
	;
	;By Jobbo 21/08/96

	section	MainCode,code

	incdir	Sources:Includes/
	include	Hardware.i
	include	StartUp.i
	incdir	Sources:Warp/

RASTER	equ	0

Raster	macro
	IFNE	RASTER
	move.w	#$ff,CUSTOM+BPLCON1
	ENDC
	endm

count	dc.w	0

Main	lea	custCop1,a0
	bsr.w	CustCopInit
	lea	custCop2,a0
	bsr.w	CustCopInit

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
	beq.b	.pause
	btst	#6,CIAAPRA
	beq.w	mouseExit
	addq.w	#1,count
	cmp.w	#64,count
	blt.b	show1

	move.w	#0,warpVal
warp1	bsr.w	CustCopDB
	bsr.w	VWait
	lea	srcMesh,a0
	lea	dstMesh,a1
	bsr.w	WarpCalc
	lea	pict,a0
	bsr.w	WarpPixels
	Raster
.pause	btst	#2,POTGOR+CUSTOM
	beq.b	.pause
	btst	#6,CIAAPRA
	beq.b	mouseExit
	add.w	#16,warpVal
	cmp.w	#256,warpVal
	blt.b	warp1

	move.w	#256,warpVal
warp2	bsr.w	CustCopDB
	bsr.w	VWait
	lea	srcMesh,a0
	lea	dstMesh,a1
	bsr.w	WarpCalc
	lea	pict,a0
	bsr.w	WarpPixels
	Raster
.pause	btst	#2,POTGOR+CUSTOM
	beq.b	.pause
	btst	#6,CIAAPRA
	beq.b	mouseExit
	sub.w	#16,warpVal
	tst.w	warpVal
	bgt.b	warp2

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
custIntPtr	dc.l	CustCopShake

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

CustCopShake
	move.l	#pattBitmap,d0
	move.l	vTimer(pc),d1
	btst	#0,d1
	beq.b	.zero
	add.l	#40*7,d0
.zero	moveq.l	#7-1,d1
	moveq.l	#40,d2
	lea	copBplPtrs,a0
	bsr.w	SetUpBplPtrs
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
	move.w	d0,a5
	moveq.l	#DISPLAYHEIGHT/17-1,d1
.forY	move.w	d1,a6

	movem.l	(a0)+,d0-d7
	move.w	d0,INSTRPERLINE*4(a4)
	swap	d0
	move.w	d0,(a4)
	move.w	d1,INSTRPERLINE*4*3(a4)
	swap	d1
	move.w	d1,INSTRPERLINE*4*2(a4)
	move.w	d2,INSTRPERLINE*4*5(a4)
	swap	d2
	move.w	d2,INSTRPERLINE*4*4(a4)
	move.w	d3,INSTRPERLINE*4*7(a4)
	swap	d3
	move.w	d3,INSTRPERLINE*4*6(a4)
	move.w	d4,INSTRPERLINE*4*9(a4)
	swap	d4
	move.w	d4,INSTRPERLINE*4*8(a4)
	move.w	d5,INSTRPERLINE*4*11(a4)
	swap	d5
	move.w	d5,INSTRPERLINE*4*10(a4)
	move.w	d6,INSTRPERLINE*4*13(a4)
	swap	d6
	move.w	d6,INSTRPERLINE*4*12(a4)
	move.w	d7,INSTRPERLINE*4*15(a4)
	swap	d7
	move.w	d7,INSTRPERLINE*4*14(a4)
	move.w	(a0)+,INSTRPERLINE*4*16(a4)
	add.l	a3,a4

	move.w	a6,d1
	dbf	d1,.forY
	move.w	a5,d0
	lea	(256-DISPLAYHEIGHT)*2(a0),a0
	dbf	d0,.forX
	rts

;------------------------------------------------------------------------------------------------------

	;PRE: a0 -> Source mesh
	;     a1 -> Destination mesh

MESHWIDTH	equ	8
MESHHEIGHT	equ	8

warpVal	dc.w	0
tmpMesh	ds.w	MESHWIDTH*MESHHEIGHT*2

WarpCalc
	move.w	warpVal(pc),d0
	move.w	#256,d1
	sub.w	d0,d1
	move.l	a0,a2
	move.l	a1,a3
	lea	tmpMesh(pc),a4
	moveq.l	#MESHWIDTH*MESHHEIGHT*2-1,d2
.forM	move.w	(a2)+,d3
	muls.w	d1,d3
	move.w	(a3)+,d4
	muls.w	d0,d4
	add.l	d3,d4
	asr.l	#8,d4
	clr.b	d4
	move.w	d4,(a4)+
	dbf	d2,.forM

warpPass1
	lea	tmpMesh(pc),a1
	lea	colSects,a2
	moveq.l	#0,d2
	moveq.l	#MESHHEIGHT-1,d0
.forMH	move.w	d0,-(sp)
	move.l	a0,a3
	lea	MESHWIDTH*2*2(a0),a0
	move.l	a1,a4
	lea	MESHWIDTH*2*2(a1),a1
	move.l	a2,a5
	lea	5*2(a2),a2
	moveq.l	#MESHWIDTH-2,d1
.forMW	move.w	4(a4),d0
	sub.w	(a4),d0
	asr.w	#8,d0					;d0 = xdist
	ble.b	.zero
	move.w	6(a4),d2
	move.w	d1,a6
	move.w	2(a4),d1				;d1 = y
	sub.w	d1,d2
	ext.l	d2
	divs.w	d0,d2					;d2 = y'
	movem.w	(a3),d3-d6				;d3 = tx, d4 = ty
	sub.w	d3,d5
	ext.l	d5
	divs.w	d0,d5					;d5 = tx'
	sub.w	d4,d6
	ext.l	d6
	divs.w	d0,d6					;d6 = ty'
	subq.w	#1,d0
.forX	move.w	d1,d7
	clr.b	d7
	move.w	d7,(a5)
	add.w	d2,d1
	move.w	d3,2(a5)
	add.w	d5,d3
	move.w	d4,4(a5)
	add.w	d6,d4
	lea	MESHHEIGHT*5*2(a5),a5
	dbf	d0,.forX
	move.w	a6,d1
.zero	addq.l	#2*2,a3
	addq.l	#2*2,a4
	dbf	d1,.forMW
	move.w	(sp)+,d0
	dbf	d0,.forMH

warpPass2
	lea	colSects,a0
	moveq.l	#MESHHEIGHT-2,d0
.forMH	move.l	a0,a1
	lea	5*2(a0),a0
	moveq.l	#DISPLAYWIDTH-1,d1
.forX	move.w	5*2(a1),d2
	sub.w	(a1),d2
	asr.w	#8,d2
	subq.w	#1,d2
	move.w	d2,(a1)
	addq.w	#1,d2
	ble.b	.zero
	move.w	5*2+2(a1),d4
	sub.w	2(a1),d4
	ext.l	d4
	move.w	5*2+4(a1),d5
	divs.w	d2,d4
	move.w	d4,6(a1)
	sub.w	4(a1),d5
	ext.l	d5
	divs.w	d2,d5
	move.w	d5,8(a1)
.zero	lea	MESHHEIGHT*5*2(a1),a1
	dbf	d1,.forX
	dbf	d0,.forMH

	rts

	;----------------------------------------------------------------------------------------------

	;PRE: a0 -> Pixels

WarpPixels
	move.l	custCopOffPtr(pc),a1
	lea	offsets(pc),a2
	lea	colSects,a3
	move.w	#INSTRPERLINE*4,a5
	moveq.l	#DISPLAYWIDTH-1,d0
.forX	add.w	(a2)+,a1
	move.l	a1,a4
	moveq.l	#MESHHEIGHT-2,d1
.forSec
	movem.w	(a3)+,d2-d6				;d2 = section height - 1
	tst.w	d2					;d3 = XXxx, d4 = YYyy
	blt.b	.zero					;d5 = XDxd, d6 = YDyd
	ror.l	#8,d4
	move.w	d4,d7					;d7 =     00YY
	move.w	d3,d4					;d4 = yy00XXxx
	ror.l	#8,d6
	move.w	d6,d3					;d3 =     00YD
	move.w	d5,d6					;d6 = yd00XDxd
.forY	move.w	d4,d5
	move.b	d7,d5					;d5 = XXYY
	move.w	(a0,d5.w*2),(a4)
	add.l	d6,d4
	addx.b	d3,d7
	add.l	a5,a4
	dbf	d2,.forY
.zero
	dbf	d1,.forSec
	lea	10(a3),a3
	dbf	d0,.forX
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
	dc.w	BPL1MOD,40*(7-1)
	dc.w	BPL2MOD,40*(7-1)
	dc.w	FMODE,$0003
copBplPtrs
	dc.w	BPL1PTL,0,BPL1PTH,0,BPL2PTL,0,BPL2PTH,0,BPL3PTL,0,BPL3PTH,0
	dc.w	BPL4PTL,0,BPL4PTH,0,BPL5PTL,0,BPL5PTH,0,BPL6PTL,0,BPL6PTH,0
	dc.w	BPL7PTL,0,BPL7PTH,0

	dc.w	COPJMP2,0				;Jump to COP2LC

	;----------------------------------------------------------------------------------------------

	cnop	0,8
pattBitmap	incbin	Patt.Raw

	;----------------------------------------------------------------------------------------------

	section	Stuff,data
	cnop	0,4

pict	incbin	Babies.Chunky
srcMesh	incbin	SrcMesh.Raw
dstMesh	incbin	DstMesh.Raw

	;----------------------------------------------------------------------------------------------

	section	BSSChipStuff,bss_c
	cnop	0,4
custCop1	ds.l	INSTRPERLINE*DISPLAYHEIGHT+2+1
custCop2	ds.l	INSTRPERLINE*DISPLAYHEIGHT+2+1

	;----------------------------------------------------------------------------------------------

	section	BSSStuff,bss
	cnop	0,4
colSects	ds.w	MESHHEIGHT*DISPLAYWIDTH*5