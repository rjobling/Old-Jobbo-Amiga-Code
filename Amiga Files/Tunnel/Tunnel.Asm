	;Tunnel
	;
	;By Jobbo 10/11/96

RASTER	equ	0

	section	MainCode,code

	incdir	Sources:Includes/
	include	Hardware.i
	include	StartUp.i
	incdir	Sources:Tunnel/

Main	bsr.w	PattBitmapInit

	lea	custCop1,a0
	bsr.w	CustCopInit
	lea	custCop2,a0
	bsr.w	CustCopInit

	move.l	#pattBitmap,d0
	moveq.l	#7-1,d1
	moveq.l	#192/8,d2
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
	bsr.w	Flip
	bsr.w	VWait
	bsr.w	Tunnel
	IFNE	RASTER
	move.w	#$ff,CUSTOM+BPLCON1
	ENDC
.pause	btst	#2,POTGOR+CUSTOM
	beq.b	.pause
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
custIntPtr	dc.l	CustCopShake

Level3	movem.l	d0-a6,-(sp)

	addq.b	#1,vBlank
	addq.l	#1,vTimer

	tst.l	custIntPtr
	beq.b	.nil
	move.l	custIntPtr,a0
	jsr	(a0)
.nil
	move.w	#VERTB,INTREQ+CUSTOM			;Clear interrupt request bit
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

custCopFrontPtr	dc.l	custCop2
custCopBackPtr	dc.l	custCop1

Flip	move.l	custCopBackPtr(pc),d0
	move.l	custCopFrontPtr(pc),custCopBackPtr
	move.l	d0,custCopFrontPtr
	move.l	custCopFrontPtr(pc),COP2LCH+CUSTOM
	rts

;------------------------------------------------------------------------------------------------------

	;PRE: a0 -> Custom copper buffer

DISPLAYWIDTH	equ	96
DISPLAYHEIGHT	equ	128
INSTRPERLINE	equ	(1+1+(1+(DISPLAYWIDTH-1)/32)+DISPLAYWIDTH)

CustCopInit
	moveq.l	#0,d2
	move.l	#$29e1fffe,d1
	moveq.l	#DISPLAYHEIGHT-1,d0
.forLns	move.l	d1,(a0)+
	add.l	#$02000000,d1
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
	add.l	#(192/8)*7,d0
.zero	moveq.l	#7-1,d1
	moveq.l	#192/8,d2
	lea	copBplPtrs,a0
	bsr.w	SetUpBplPtrs
	rts

;------------------------------------------------------------------------------------------------------

PattBitmapInit
	lea	pattBitmap,a0
	lea	(192/8)*7(a0),a1
	moveq.l	#0,d0
.whileX	move.w	d0,d2
	lsr.w	#1,d2
	move.w	d0,d3
	addq.w	#1,d3
	lsr.w	#1,d3
	move.w	d0,d4
	lsr.w	#3,d4
	moveq.l	#7,d5
	sub.b	d0,d5
	and.b	#7,d5
	moveq.l	#0,d1
.whileP	btst	d1,d2
	beq.b	.zero1
	bset	d5,(a0,d4.w)
.zero1	btst	d1,d3
	beq.b	.zero2
	bset	d5,(a1,d4.w)
.zero2	add.l	#192/8,d4
	addq.l	#1,d1
	cmp.w	#7,d1
	blt.b	.whileP
	addq.w	#1,d0
	cmp.w	#191,d0
	blt.b	.whileX
	lea	(192/8)*7*2(a0),a1
	move.w	#128-1,d0
.forY	move.l	a0,a2
	moveq.l	#(192/32)*7*2-1,d1
.forLns	move.l	(a2)+,(a1)+
	dbf	d1,.forLns
	dbf	d0,.forY
	rts

;------------------------------------------------------------------------------------------------------

offsets	dc.w	14,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
	dc.w	8,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
	dc.w	8,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
	dc.w	8,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4

oldTime	dc.l	0
turn	dc.b	0
dist	dc.b	0

Tunnel	move.l	vTimer(pc),d0
	move.l	oldTime(pc),d1
	move.l	d0,oldTime
	sub.w	d1,d0
	sub.b	d0,turn
	lsl.b	#2,d0
	add.b	d0,dist

	move.w	turn(pc),d2
	lea	pict+128*256*2,a0
	lea	(a0,d2.w*2),a0
	move.l	custCopBackPtr(pc),a1
	lea	offsets(pc),a2
	lea	table,a3
	moveq.l	#DISPLAYWIDTH-1,d0
.forX	add.w	(a2)+,a1
	move.l	a1,a4
	move.w	d0,a5
	moveq.l	#DISPLAYHEIGHT/32-1,d1
.forY	move.w	d1,a6

	movem.l	(a3)+,d0-d7
	move.w	(a0,d0.w*2),INSTRPERLINE*4*1(a4)
	swap	d0
	move.w	(a0,d0.w*2),(a4)
	move.w	(a0,d1.w*2),INSTRPERLINE*4*3(a4)
	swap	d1
	move.w	(a0,d1.w*2),INSTRPERLINE*4*2(a4)
	move.w	(a0,d2.w*2),INSTRPERLINE*4*5(a4)
	swap	d2
	move.w	(a0,d2.w*2),INSTRPERLINE*4*4(a4)
	move.w	(a0,d3.w*2),INSTRPERLINE*4*7(a4)
	swap	d3
	move.w	(a0,d3.w*2),INSTRPERLINE*4*6(a4)
	move.w	(a0,d4.w*2),INSTRPERLINE*4*9(a4)
	swap	d4
	move.w	(a0,d4.w*2),INSTRPERLINE*4*8(a4)
	move.w	(a0,d5.w*2),INSTRPERLINE*4*11(a4)
	swap	d5
	move.w	(a0,d5.w*2),INSTRPERLINE*4*10(a4)
	move.w	(a0,d6.w*2),INSTRPERLINE*4*13(a4)
	swap	d6
	move.w	(a0,d6.w*2),INSTRPERLINE*4*12(a4)
	move.w	(a0,d7.w*2),INSTRPERLINE*4*15(a4)
	swap	d7
	move.w	(a0,d7.w*2),INSTRPERLINE*4*14(a4)
	movem.l	(a3)+,d0-d7
	move.w	(a0,d0.w*2),INSTRPERLINE*4*17(a4)
	swap	d0
	move.w	(a0,d0.w*2),INSTRPERLINE*4*16(a4)
	move.w	(a0,d1.w*2),INSTRPERLINE*4*19(a4)
	swap	d1
	move.w	(a0,d1.w*2),INSTRPERLINE*4*18(a4)
	move.w	(a0,d2.w*2),INSTRPERLINE*4*21(a4)
	swap	d2
	move.w	(a0,d2.w*2),INSTRPERLINE*4*20(a4)
	move.w	(a0,d3.w*2),INSTRPERLINE*4*23(a4)
	swap	d3
	move.w	(a0,d3.w*2),INSTRPERLINE*4*22(a4)
	move.w	(a0,d4.w*2),INSTRPERLINE*4*25(a4)
	swap	d4
	move.w	(a0,d4.w*2),INSTRPERLINE*4*24(a4)
	move.w	(a0,d5.w*2),INSTRPERLINE*4*27(a4)
	swap	d5
	move.w	(a0,d5.w*2),INSTRPERLINE*4*26(a4)
	move.w	(a0,d6.w*2),INSTRPERLINE*4*29(a4)
	swap	d6
	move.w	(a0,d6.w*2),INSTRPERLINE*4*28(a4)
	move.w	(a0,d7.w*2),INSTRPERLINE*4*31(a4)
	swap	d7
	move.w	(a0,d7.w*2),INSTRPERLINE*4*30(a4)
	lea	INSTRPERLINE*4*32(a4),a4

	move.w	a6,d1
	dbf	d1,.forY
	move.w	a5,d0
	dbf	d0,.forX

	rts

;======================================================================================================

	section	ChipStuff,data_c
	cnop	0,4

copList	dc.w	DIWSTRT,$2cc1
	dc.w	DIWSTOP,$2c80
	dc.w	DDFSTRT,$0050
	dc.w	DDFSTOP,$0090

	dc.w	BPLCON0,$7201
	dc.w	BPLCON1,$0000
	dc.w	BPLCON2,$0000
	dc.w	BPLCON3,$0020
	dc.w	BPL1MOD,24*(7-1)
	dc.w	BPL2MOD,24*(7-1)
	dc.w	FMODE,$0003
copBplPtrs
	dc.w	BPL1PTL,0,BPL1PTH,0,BPL2PTL,0,BPL2PTH,0,BPL3PTL,0,BPL3PTH,0
	dc.w	BPL4PTL,0,BPL4PTH,0,BPL5PTL,0,BPL5PTH,0,BPL6PTL,0,BPL6PTH,0
	dc.w	BPL7PTL,0,BPL7PTH,0

	dc.w	COPJMP2,0				;Jump to COP2LC

	;----------------------------------------------------------------------------------------------

	section	Stuff,data
	cnop	0,4
	incbin	Pict.Chunky
pict	incbin	Pict.Chunky
	incbin	Pict.Chunky
table	incbin	Table.Raw

	;----------------------------------------------------------------------------------------------

	section	BSSChipStuff,bss_c
	cnop	0,4
custCop1	ds.l	INSTRPERLINE*DISPLAYHEIGHT+2+1
custCop2	ds.l	INSTRPERLINE*DISPLAYHEIGHT+2+1
pattBitmap	ds.l	(192/32)*258*7