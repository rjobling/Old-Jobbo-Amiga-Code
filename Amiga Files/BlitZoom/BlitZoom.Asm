	;Bitmap Zoomer
	;
	;By Jobbo 11/07/95

	Section	MainCode,Code

	Incdir	Sources:Includes/
	Include	Hardware.i
	Include	StartUpOCS.i


Main	Bsr	ScreenDB

	Lea	CUSTOM,a6
	Move.l	#Level3,$6c					;New Level3 handler
	Move.w	#SETIT+DMAEN+BPLEN+COPEN+BLTPRI+BLTEN,DMACON(a6);DMA - ON
	Move.w	#SETIT+INTEN+VERTB,INTENA(a6)			;VBI interrupt - ON
	Move.l	#copList,COP1LCH(a6)				;Point copper at list
	Move.w	#0,COPJMP1(a6)					;Strobe to start


	MoveQ	#64-1,d0
.wait	Bsr	VWait
	Dbf	d0,.wait

.mouseWait
	Bsr	VWait
	Bsr	BlitHoriZoom
	Bsr	ScreenDB
	Move.w	#$080,COLOR00(a6)
.pause	Btst.b	#2,POTGOR(a6)
	Beq.s	.pause
	Btst	#6,CIAAPRA
	Bne.s	.mouseWait


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

	;Bsr	pr_music
	
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


bitmapSrcPtr	Dc.l	bitmap2
bitmapDestPtr	Dc.l	bitmap1

ScreenDB
	Move.l	bitmapDestPtr(PC),d0
	Move.l	bitmapSrcPtr(PC),bitmapDestPtr
	Move.l	d0,bitmapSrcPtr

	Move.l	bitmapSrcPtr(PC),d0
	Add.l	#40*32*3,d0
	MoveQ	#3-1,d1
	Move.l	#40,d2
	Lea	bplPtrs,a0
	Bsr	SetUpBplPtrs
	Rts


;------------------------------------------------------------------------------------------------------


blitWidthPtr	Dc.l	blitWidths

BlitHoriZoom
	Move.l	blitWidthPtr(PC),a0
	MoveQ	#0,d0
	Move.b	(a0),d0
	Cmp.b	#-1,d0
	Bne.s	.ok
	Lea	blitWidths(PC),a0
	Move.b	(a0),d0
	Move.l	a0,blitWidthPtr
.ok	AddQ.l	#1,blitWidthPtr

	Move.w	d0,d7
	Move.w	#160,d6
	Sub.w	d0,d6
	Move.l	bitmapSrcPtr,a0
	Move.l	bitmapDestPtr,a1



	Lsr.w	#4,d0
	AddQ	#1,d0						;d0 = Blit width in words

	MoveQ	#20,d1
	Sub.w	d0,d1
	Add.w	d1,d1						;d1 = Blit modulo

	Move.w	d7,d2
	Mulu	#40*3,d2
	SubQ	#2,d2
	Lea	40*3(a0,d2.l),a2
	Lea	(a1,d2.l),a3
	Sub.w	d1,a2
	Sub.w	d1,a3

	Move.w	d0,d2
	Move.w	d7,d3
	Mulu	#3,d3
	Lsl.w	#6,d3
	Add.w	d3,d2
	
.bWaitTop1
	Btst	#14,DMACONR(a6)
	Bne.s	.bWaitTop1
	MoveM.l	a2/a3,BLTAPTH(a6)
	Move.w	d1,BLTAMOD(a6)
	Move.w	d1,BLTDMOD(a6)
	Move.l	#$ffffffff,BLTAFWM(a6)
	Move.l	#$19f00002,BLTCON0(a6)
	Move.w	d2,BLTSIZE(a6)

	Lea	159*40*3(a2),a2
	Lea	160*40*3(a3),a3
	Move.w	d0,d2
	Add.w	#160*3<<6,d2

.bWaitMiddle1
	Btst	#14,DMACONR(a6)
	Bne.s	.bWaitMiddle1
	MoveM.l	a2/a3,BLTAPTH(a6)
	Move.w	d1,BLTAMOD(a6)
	Move.w	d1,BLTDMOD(a6)
	Move.l	#$ffffffff,BLTAFWM(a6)
	Move.l	#$19f00002,BLTCON0(a6)
	Move.w	d2,BLTSIZE(a6)

	Move.l	#320*40*3-2,d2
	Lea	-40*3(a0,d2.l),a2
	Lea	(a1,d2.l),a3
	Sub.w	d1,a2
	Sub.w	d1,a3
	Move.w	d0,d2
	Move.w	d6,d3
	Mulu	#3,d3
	Lsl.w	#6,d3
	Add.w	d3,d2

.bWaitBottom1
	Btst	#14,DMACONR(a6)
	Bne.s	.bWaitBottom1
	MoveM.l	a2/a3,BLTAPTH(a6)
	Move.w	d1,BLTAMOD(a6)
	Move.w	d1,BLTDMOD(a6)
	Move.l	#$ffffffff,BLTAFWM(a6)
	Move.l	#$19f00002,BLTCON0(a6)
	Move.w	d2,BLTSIZE(a6)



	Move.w	d0,d5
	AddQ	#8,d0
	MoveQ	#20,d1
	Sub.w	d0,d1						;d1 = Blit width in words
	Add.w	d0,d0						;d0 = Blit modulo
	Lea	40*3(a0,d0.w),a2
	Lea	(a1,d0.w),a3
	Move.w	d1,d2
	Move.w	d7,d3
	Mulu	#3,d3
	Lsl.w	#6,d3
	Add.w	d3,d2

.bWaitTop2
	Btst	#14,DMACONR(a6)
	Bne.s	.bWaitTop2
	MoveM.l	a2/a3,BLTAPTH(a6)
	Move.w	d0,BLTAMOD(a6)
	Move.w	d0,BLTDMOD(a6)
	Move.l	#$ffffffff,BLTAFWM(a6)
	Move.l	#$19f00000,BLTCON0(a6)
	Move.w	d2,BLTSIZE(a6)

	Move.w	d7,d3
	Mulu	#40*3,d3
	Lea	-40*3(a2,d3.l),a2
	Lea	(a3,d3.l),a3
	Move.w	d1,d2
	Add.w	#160*3<<6,d2

.bWaitMiddle2
	Btst	#14,DMACONR(a6)
	Bne.s	.bWaitMiddle2
	MoveM.l	a2/a3,BLTAPTH(a6)
	Move.w	d0,BLTAMOD(a6)
	Move.w	d0,BLTDMOD(a6)
	Move.l	#$ffffffff,BLTAFWM(a6)
	Move.l	#$19f00000,BLTCON0(a6)
	Move.w	d2,BLTSIZE(a6)

	Lea	40*159*3(a2),a2
	Lea	40*160*3(a3),a3
	Move.w	d1,d2
	Move.w	d6,d3
	Mulu	#3,d3
	Lsl.w	#6,d3
	Add.w	d3,d2

.bWaitBottom2
	Btst	#14,DMACONR(a6)
	Bne.s	.bWaitBottom2
	MoveM.l	a2/a3,BLTAPTH(a6)
	Move.w	d0,BLTAMOD(a6)
	Move.w	d0,BLTDMOD(a6)
	Move.l	#$ffffffff,BLTAFWM(a6)
	Move.l	#$19f00000,BLTCON0(a6)
	Move.w	d2,BLTSIZE(a6)



	Add.w	d5,d5
	Lea	40*3(a0,d5.w),a2
	Lea	(a1,d5.w),a3
	Move.w	d7,d2
	AddQ	#1,d2
	Mulu	#3,d2
	Lsl.w	#6,d2
	Add.w	#9,d2

.bWaitTop3
	Btst	#14,DMACONR(a6)
	Bne.s	.bWaitTop3
	MoveM.l	a2/a3,BLTAPTH(a6)
	Move.l	#22<<16+22,BLTAMOD(a6)
	Move.l	#$ffffffff,BLTAFWM(a6)
	Move.l	#$09f00000,BLTCON0(a6)
	Move.w	d2,BLTSIZE(a6)

	Move.w	d7,d2
	Mulu	#40*3,d2
	Lea	-40*3(a2,d2.l),a2
	Lea	(a3,d2.l),a3

.bWaitMiddle3
	Btst	#14,DMACONR(a6)
	Bne.s	.bWaitMiddle3
	MoveM.l	a2/a3,BLTAPTH(a6)
	Move.l	#22<<16+22,BLTAMOD(a6)
	Move.l	#$ffffffff,BLTAFWM(a6)
	Move.l	#$09f00000,BLTCON0(a6)
	Move.w	#160*3<<6+9,BLTSIZE(a6)

	Lea	40*159*3(a2),a2
	Lea	40*160*3(a3),a3
	Move.w	d6,d2
	Mulu	#3,d2
	Lsl.w	#6,d2
	Add.w	#9,d2

.bWaitBottom3
	Btst	#14,DMACONR(a6)
	Bne.s	.bWaitBottom3
	MoveM.l	a2/a3,BLTAPTH(a6)
	Move.l	#22<<16+22,BLTAMOD(a6)
	Move.l	#$ffffffff,BLTAFWM(a6)
	Move.l	#$09f00000,BLTCON0(a6)
	Move.w	d2,BLTSIZE(a6)



	SubQ	#2,d5
	Lea	40*3(a0,d5.w),a3
	Lea	(a1,d5.w),a2

	MoveQ	#-1,d0
	Move.w	d7,d0
	And.w	#$f,d0
	Add.w	d0,d0
	Lea	blitMasks(PC),a4
	Move.w	(a4,d0.w),d0

	Move.w	d7,d2
	Mulu	#3,d2
	Lsl.w	#6,d2
	AddQ	#1,d2

.bWaitTop4
	Btst	#14,DMACONR(a6)
	Bne.s	.bWaitTop4
	Move.w	#$ffff,BLTADAT(a6)
	MoveM.l	a2/a3,BLTCPTH(a6)
	Move.l	a2,BLTDPTH(a6)
	Move.l	#38<<16+38,BLTCMOD(a6)
	Move.w	#38,BLTDMOD(a6)
	Move.l	d0,BLTAFWM(a6)
	Move.l	#$07ca0000,BLTCON0(a6)
	Move.w	d2,BLTSIZE(a6)

	Move.w	d7,d2
	Mulu	#40*3,d2
	Lea	-40*3(a3,d2.l),a3
	Lea	(a2,d2.l),a2

.bWaitMiddle4
	Btst	#14,DMACONR(a6)
	Bne.s	.bWaitMiddle4
	Move.w	#$ffff,BLTADAT(a6)
	MoveM.l	a2/a3,BLTCPTH(a6)
	Move.l	a2,BLTDPTH(a6)
	Move.l	#38<<16+38,BLTCMOD(a6)
	Move.w	#38,BLTDMOD(a6)
	Move.l	d0,BLTAFWM(a6)
	Move.l	#$07ca0000,BLTCON0(a6)
	Move.w	#160*3<<6+1,BLTSIZE(a6)

	Lea	40*159*3(a3),a3
	Lea	40*160*3(a2),a2
	Move.w	d6,d2
	Mulu	#3,d2
	Lsl.w	#6,d2
	AddQ	#1,d2

.bWaitBottom4
	Btst	#14,DMACONR(a6)
	Bne.s	.bWaitBottom4
	Move.w	#$ffff,BLTADAT(a6)
	MoveM.l	a2/a3,BLTCPTH(a6)
	Move.l	a2,BLTDPTH(a6)
	Move.l	#38<<16+38,BLTCMOD(a6)
	Move.w	#38,BLTDMOD(a6)
	Move.l	d0,BLTAFWM(a6)
	Move.l	#$07ca0000,BLTCON0(a6)
	Move.w	d2,BLTSIZE(a6)



	Add.w	#20,d5
	Lea	40*3(a0,d5.w),a3
	Lea	(a1,d5.w),a2

	Not.w	d0
	
	Move.w	d7,d2
	Mulu	#3,d2
	Lsl.w	#6,d2
	AddQ	#1,d2

.bWaitTop5
	Btst	#14,DMACONR(a6)
	Bne.s	.bWaitTop5
	Move.w	#$ffff,BLTADAT(a6)
	MoveM.l	a2/a3,BLTCPTH(a6)
	Move.l	a2,BLTDPTH(a6)
	Move.l	#38<<16+38,BLTCMOD(a6)
	Move.w	#38,BLTDMOD(a6)
	Move.l	d0,BLTAFWM(a6)
	Move.l	#$07ca0000,BLTCON0(a6)
	Move.w	d2,BLTSIZE(a6)

	Move.w	d7,d2
	Mulu	#40*3,d2
	Lea	-40*3(a3,d2.l),a3
	Lea	(a2,d2.l),a2

.bWaitMiddle5
	Btst	#14,DMACONR(a6)
	Bne.s	.bWaitMiddle5
	Move.w	#$ffff,BLTADAT(a6)
	MoveM.l	a2/a3,BLTCPTH(a6)
	Move.l	a2,BLTDPTH(a6)
	Move.l	#38<<16+38,BLTCMOD(a6)
	Move.w	#38,BLTDMOD(a6)
	Move.l	d0,BLTAFWM(a6)
	Move.l	#$07ca0000,BLTCON0(a6)
	Move.w	#160*3<<6+1,BLTSIZE(a6)

	Lea	40*159*3(a3),a3
	Lea	40*160*3(a2),a2
	Move.w	d6,d2
	Mulu	#3,d2
	Lsl.w	#6,d2
	AddQ	#1,d2

.bWaitBottom5
	Btst	#14,DMACONR(a6)
	Bne.s	.bWaitBottom5
	Move.w	#$ffff,BLTADAT(a6)
	MoveM.l	a2/a3,BLTCPTH(a6)
	Move.l	a2,BLTDPTH(a6)
	Move.l	#38<<16+38,BLTCMOD(a6)
	Move.w	#38,BLTDMOD(a6)
	Move.l	d0,BLTAFWM(a6)
	Move.l	#$07ca0000,BLTCON0(a6)
	Move.w	d2,BLTSIZE(a6)

	Rts


;======================================================================================================


blitMasks
	Dc.w	$ffff,$7fff,$3fff,$1fff,$0fff,$07ff,$03ff,$01ff
	Dc.w	$00ff,$007f,$003f,$001f,$000f,$0007,$0003,$0001

blitWidths								;Typing this was great fun :-/
	Dc.b	0+0,80+0,32+0,112+0,48+0,128+0,16+0,96+0,64+0,144+0
	Dc.b	0+8,80+8,32+8,112+8,48+8,128+8,16+8,96+8,64+8,144+8
	Dc.b	0+4,80+4,32+4,112+4,48+4,128+4,16+4,96+4,64+4,144+4
	Dc.b	0+12,80+12,32+12,112+12,48+12,128+12,16+12,96+12,64+12,144+12
	Dc.b	0+2,80+2,32+2,112+2,48+2,128+2,16+2,96+2,64+2,144+2
	Dc.b	0+10,80+10,32+10,112+10,48+10,128+10,16+10,96+10,64+10,144+10
	Dc.b	0+6,80+6,32+6,112+6,48+6,128+6,16+6,96+6,64+6,144+6
	Dc.b	0+14,80+14,32+14,112+14,48+14,128+14,16+14,96+14,64+14,144+14
	Dc.b	0+1,80+1,32+1,112+1,48+1,128+1,16+1,96+1,64+1,144+1
	Dc.b	0+9,80+9,32+9,112+9,48+9,128+9,16+9,96+9,64+9,144+9
	Dc.b	0+5,80+5,32+5,112+5,48+5,128+5,16+5,96+5,64+5,144+5
	Dc.b	0+13,80+13,32+13,112+13,48+13,128+13,16+13,96+13,64+13,144+13
	Dc.b	0+3,80+3,32+3,112+3,48+3,128+3,16+3,96+3,64+3,144+3
	Dc.b	0+11,80+11,32+11,112+11,48+11,128+11,16+11,96+11,64+11,144+11
	Dc.b	0+7,80+7,32+7,112+7,48+7,128+7,16+7,96+7,64+7,144+7
	Dc.b	0+15,80+15,32+15,112+15,48+15,128+15,16+15,96+15,64+15,144+15
	
	Dc.b	-1

	;----------------------------------------------------------------------------------------------

	Section	ChipStuff,Data_C

copList	Dc.w	DIWSTRT,$2c81
	Dc.w	DIWSTOP,$2cc1
	Dc.w	DDFSTRT,$0030
	Dc.w	DDFSTOP,$00a0
   
	Dc.w	BPLCON0,$3200
	Dc.w	BPLCON1,$0000
	Dc.w	BPLCON2,$0000
	Dc.w	BPLCON3,$0000
	Dc.w	BPL1MOD,40*(3-1)
	Dc.w	BPL2MOD,40*(3-1)
	Dc.w	FMODE,$0003
	
bplPtrs	Dc.w	BPL1PTL,0,BPL1PTH,0,BPL2PTL,0,BPL2PTH,0,BPL3PTL,0,BPL3PTH,0

colours	Dc.w	COLOR00,$000,COLOR01,$222,COLOR02,$444,COLOR03,$666
	Dc.w	COLOR04,$888,COLOR05,$aaa,COLOR06,$ccc,COLOR07,$eee

	Dc.w	$ffff,$fffe

	;----------------------------------------------------------------------------------------------

	CNOP	0,2
	Ds.b	40*3
bitmap1	Incbin	Pict320x320x3.Raw
	Ds.b	40*3

	;----------------------------------------------------------------------------------------------

	Section	BSSChipStuff,BSS_C

	CNOP	0,2
	Ds.b	40*3
bitmap2	Ds.b	40*320*3
	Ds.b	40*3