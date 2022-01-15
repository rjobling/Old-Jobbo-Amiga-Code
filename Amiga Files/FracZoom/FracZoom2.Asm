	;FracZoom
	;
	;By Jobbo 05/10/96

RASTER	equ	0

	section	MainCode,code

	incdir	Sources:Includes/
	include	Hardware.i
	include	StartUp.i
	incdir	Sources:FracZoom/

Main	bsr.w	PattBitmapInit
	bsr.w	MixLUTInit

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
	bsr.w	TranslatePts
	bsr.w	DrawLines
	bsr.w	RotateZoomBlur
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

	;PRE: a0 -> Custom copper buffer

DISPLAYWIDTH	equ	96
DISPLAYHEIGHT	equ	96
INSTRPERLINE	equ	(1+1+(1+(DISPLAYWIDTH-1)/32)+DISPLAYWIDTH)

CustCopInit
	moveq.l	#0,d2
	move.l	#$49e1fffe,d1
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

MixLUTInit
	lea	mixLUT,a0
	moveq.l	#0,d0
.whileJ	moveq.l	#0,d1
.whileI	move.w	d0,d2
	sub.w	d1,d2
	bge.b	.dark
	moveq.l	#0,d2
.dark	move.b	d2,64(a0)
	move.w	d0,d2
	add.w	d1,d2
	cmp.w	#63,d2
	blt.b	.brite
	moveq.l	#63,d2
.brite	move.b	d2,(a0)+
	addq.w	#1,d1
	cmp.w	#64,d1
	blt.b	.whileI
	lea	256-64(a0),a0
	addq.w	#1,d0
	cmp.w	#64,d0
	blt.b	.whileJ
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

custCopFrontPtr	dc.l	custCop2
custCopBackPtr	dc.l	custCop1
pictFrontPtr	dc.l	pict+(128-DISPLAYHEIGHT/2)+128+(128-DISPLAYWIDTH/2)*256
pictBackPtr	dc.l	pict+(128-DISPLAYHEIGHT/2)+(128-DISPLAYWIDTH/2)*256

Flip	move.l	custCopBackPtr(pc),d0
	move.l	custCopFrontPtr(pc),custCopBackPtr
	move.l	d0,custCopFrontPtr
	move.l	custCopFrontPtr(pc),COP2LCH+CUSTOM
	move.l	pictBackPtr(pc),d0
	move.l	pictFrontPtr(pc),pictBackPtr
	move.l	d0,pictFrontPtr
	rts

;------------------------------------------------------------------------------------------------------

NOOFPOINTS	equ	8
NOOFLINES	equ	12

vectPts	dc.w	-500,-500,-500
	dc.w	 500,-500,-500
	dc.w	 500, 500,-500
	dc.w	-500, 500,-500
	dc.w	 500,-500, 500
	dc.w	-500,-500, 500
	dc.w	-500, 500, 500
	dc.w	 500, 500, 500

lines	dc.w	0*4,1*4
	dc.w	1*4,2*4
	dc.w	2*4,3*4
	dc.w	3*4,0*4
	dc.w	4*4,5*4
	dc.w	5*4,6*4
	dc.w	6*4,7*4
	dc.w	7*4,4*4
	dc.w	0*4,5*4
	dc.w	1*4,4*4
	dc.w	2*4,7*4
	dc.w	3*4,6*4

xAng	dc.w	0
yAng	dc.w	0
zAng	dc.w	0
xPos	dc.w	0
yPos	dc.w	0
zPos	dc.w	3500
matrix	ds.w	9

TranslatePts

	; .                                        .  .   .
	; | cy*cz           -cy*sz          sy     |  | X |
	; | cx*sz+sx*sy*cz  cz*cx-sz*sx*sy  -sx*cy |  | Y |
	; | sx*sz-cz*sy*cx  sx*cz+cx*sy*sz  cy*cx  |  | Z |
	; `                                        '  `   '

	lea	sinLUT,a0				;a0 -> SinLUT
	lea	matrix(pc),a2				;a2 -> Rotation Matrix
	movem.w	xAng(pc),d3-d5				;d3 = xAng,  d4 = yAng,  d5 = zAng
	and.w	#$1ff,d3
	and.w	#$1ff,d4
	and.w	#$1ff,d5
	addq.w	#2,xAng
	addq.w	#4,yAng
	addq.w	#3,zAng
	move.w	(a0,d3.w),d0
	ext.w	d0					;d0 = Sin(xAng)
	add.w	#128,d3
	and.w	#$1ff,d3
	move.w	(a0,d3.w),d1
	ext.w	d1					;d1 = Cos(xAng)
	move.w	(a0,d4.w),d2
	ext.w	d2					;d2 = Sin(yAng)
	add.w	#128,d4
	and.w	#$1ff,d4
	move.w	(a0,d4.w),d3
	ext.w	d3					;d3 = Cos(yAng)
	move.w	(a0,d5.w),d4
	ext.w	d4					;d4 = Sin(zAng)
	add.w	#128,d5
	and.w	#$1ff,d5
	move.w	(a0,d5.w),d5
	ext.w	d5					;d5 = Cos(zAng)

	move.w	d3,d6
	muls.w	d5,d6
	asr.l	#7,d6
	move.w	d6,(a2)+				;cy*cz
	move.w	d3,d6
	muls.w	d4,d6
	asr.l	#7,d6
	neg.w	d6
	move.w	d6,(a2)+				;-cy*sz
	move.w	d2,(a2)+				;sy
	move.w	d1,d6
	muls.w	d4,d6
	asr.l	#7,d6
	move.w	d0,d7
	muls.w	d2,d7
	asr.l	#7,d7
	move.w	d7,a3					;a3 = sx*sy, stored for re-use
	muls.w	d5,d7
	asr.l	#7,d7
	add.w	d7,d6
	move.w	d6,(a2)+				;cx*sz+sx*sy*cz
	move.w	d5,d6
	muls.w	d1,d6
	asr.l	#7,d6
	move.w	a3,d7					;d7 = sx*sy
	muls.w	d4,d7
	asr.l	#7,d7
	sub.w	d7,d6
	move.w	d6,(a2)+				;cx*cz-sz*sx*sy	
	move.w	d0,d6
	muls.w	d3,d6
	asr.l	#7,d6
	neg.w	d6
	move.w	d6,(a2)+				;-sx*cy
	move.w	d4,d6
	muls.w	d0,d6
	asr.l	#7,d6
	muls.w	d1,d2
	asr.l	#7,d2
	move.w	d2,a3					;a3 = cx*sy, stored for re-use
	muls.w	d5,d2
	asr.l	#7,d2
	sub.w	d2,d6
	move.w	d6,(a2)+				;sx*sz-cz*sy*cx
	muls.w	d0,d5
	asr.l	#7,d5
	move.w	a3,d6					;d6 = cx*sy
	muls.w	d4,d6
	asr.l	#7,d6
	add.w	d6,d5
	move.w	d5,(a2)+				;sx*cz-cx*sy*cz
	muls.w	d3,d1
	asr.l	#7,d1
	move.w	d1,(a2)+				;cz*cy
	
	lea	vectPts(pc),a0
	lea	scrnPts,a1
	movem.w	xPos(pc),d6-d7/a6			;a6 = ZPOS
	ext.l	d6
	ext.l	d7
	asl.l	#7,d6					;d6 = XPOS * 128
	asl.l	#7,d7
	move.w	d7,a5					;a5 = YPOS * 128
	moveq.l	#NOOFPOINTS-1,d7
.forPts	movem.w	(a0)+,d0-d2				;d0-d2 = X, Y, Z
	lea	-18(a2),a2				;a2 -> Rotation Matrix
	movem.w	(a2)+,d3-d5				;d3-d5 = Row of matrix
	muls.w	d0,d3
	muls.w	d1,d4
	muls.w	d2,d5
	add.l	d5,d4
	add.l	d4,d3
	move.l	d3,a3					;a3 = X'
	movem.w	(a2)+,d3-d5				;d3-d5 = Row of matrix
	muls.w	d0,d3
	muls.w	d1,d4
	muls.w	d2,d5
	add.l	d5,d4
	add.l	d4,d3
	move.l	d3,a4					;a4 = Y'
	movem.w	(a2)+,d3-d5				;d3-d5 = Row of matrix
	muls.w	d0,d3
	muls.w	d1,d4
	muls.w	d5,d2
	add.l	d4,d2
	add.l	d3,d2					;d2 = Z'
	move.l	a3,d0
	move.l	a4,d1
	add.l	d6,d0					;d0 = (X' * 128) + (XPOS * 128)
	add.l	a5,d1					;d1 = (Y' * 128) + (YPOS * 128)
	asr.l	#7,d2
	add.w	a6,d2					;d2 = Z' + ZPOS
	divs.w	d2,d0					;d0 = ((X' + XPOS) * 128) / (Z' + ZPOS)
	divs.w	d2,d1					;d1 = ((Y' + YPOS) * 128) / (Z' + ZPOS)
	add.w	#DISPLAYWIDTH/2,d0
	move.w	d0,(a1)+
	add.w	#DISPLAYHEIGHT/2,d1
	move.w	d1,(a1)+
	dbf	d7,.forPts
	rts

;------------------------------------------------------------------------------------------------------

DrawLines
	move.l	pictFrontPtr(pc),a0
	lea	mixLUT,a1
	lea	lines(pc),a2
	lea	scrnPts,a3
	moveq.l	#NOOFLINES-1,d0
.forLns	move.w	d0,-(sp)
	movem.w	(a2)+,d6/d7
	movem.w	(a3,d6.w),d0/d1
	movem.w	(a3,d7.w),d2/d3
	moveq.l	#16,d4
	bsr.b	DrawLine
	move.w	(sp)+,d0
	dbf	d0,.forLns
	rts

;------------------------------------------------------------------------------------------------------

	;Line drawing routine for chunky buffer.
	;
	;Corrupts: d0-d7,a6
	;---------------------------------------
	;PRE: d0.w,d1.w =  x1, y1
	;     d2.w,d3.w =  x2, y2
	;     d4.w      =  Line Colour
	;     a0.l      -> Chunky Buffer
	;     a1.l      -> Mix Table

DrawLine
	cmp.w	d1,d3
	bgt.b	.okYOrd
	exg.l	d0,d2
	exg.l	d1,d3
.okYOrd	tst.w	d3
	bge.b	.okTop1
	rts
.okTop1	tst.w	d1
	bge.b	.okTop2
	
	;X1 = X1 - (Y1 * (X2 - X1) / (Y2 - Y1))
	;Y1 = 0
	move.w	d2,d5
	move.w	d3,d6
	sub.w	d0,d5
	sub.w	d1,d6
	muls.w	d5,d1
	divs.w	d6,d1
	sub.w	d1,d0
	moveq.l	#0,d1

.okTop2	cmp.w	#DISPLAYHEIGHT,d1
	blt.b	.okBot1
	rts
.okBot1	cmp.w	#DISPLAYHEIGHT,d3
	blt.b	.okBot2

	;X2 = X1 - ((Y1 - DISPLAYHEIGHT - 1) * (X2 - X1) / (Y2 - Y1))
	;Y2 = DISPLAYHEIGHT - 1
	sub.w	d0,d2
	sub.w	d1,d3
	move.w	d1,d5
	sub.w	#DISPLAYHEIGHT-1,d5
	muls.w	d2,d5
	divs.w	d3,d5
	move.w	d0,d2
	sub.w	d5,d2
	move.w	#DISPLAYHEIGHT-1,d3

.okBot2	cmp.w	d0,d2
	bgt.b	.okXOrd
	exg.l	d0,d2
	exg.l	d1,d3
.okXOrd	tst.w	d2
	bge.b	.okLef1
	rts
.okLef1	tst.w	d0
	bge.b	.okLef2

	;X1 = 0
	;Y1 = Y1 - (X1 * (Y2 - Y1) / (X2 - X1))
	move.w	d2,d5
	move.w	d3,d6
	sub.w	d0,d5
	sub.w	d1,d6
	muls.w	d6,d0
	divs.w	d5,d0
	sub.w	d0,d1
	moveq.l	#0,d0

.okLef2	cmp.w	#DISPLAYWIDTH,d0
	blt.b	.okRit1
	rts
.okRit1	cmp.w	#DISPLAYWIDTH,d2
	blt.b	.okRit2

	;X2 = DISPLAYWIDTH - 1
	;Y2 = Y1 - ((X1 - DISPLAYWIDTH - 1) * (Y2 - Y1) / (X2 - X1))
	sub.w	d0,d2
	sub.w	d1,d3
	move.w	d0,d5
	sub.w	#DISPLAYWIDTH-1,d5
	muls.w	d3,d5
	divs.w	d2,d5
	move.w	d1,d3
	sub.w	d5,d3
	move.w	#DISPLAYWIDTH-1,d2

.okRit2

	lsl.w	#8,d4
	lea	(a1,d4.w),a6
	moveq.l	#0,d4
	move.w	d2,d5
	move.w	d3,d6
	sub.w	d0,d5
	bge.b	.okXDif
	neg.w	d5
.okXDif	sub.w	d1,d6
	bge.b	.okYDif
	neg.w	d6
.okYDif	cmp.w	d6,d5
	blt.b	majY

majX	cmp.w	d2,d0
	blt.b	.left
	move.w	#$ff00,d7	
	cmp.w	d3,d1
	blt.b	.go
	neg.w	d6
	bra.b	.go
.left	move.w	#$100,d7
	cmp.w	d3,d1
	blt.b	.go
	neg.w	d6
.go	asl.w	#8,d0
	asl.w	#8,d1
	tst.w	d5
	beq.b	.forX
	asl.w	#8,d6
	ext.l	d6
	divs.w	d5,d6
.forX	ror.w	#8,d1
	move.b	d1,d0
	ror.w	#8,d1
	move.b	(a0,d0.w),d4
	add.w	d6,d1
	move.b	(a6,d4.w),(a0,d0.w)
	add.w	d7,d0
	dbf	d5,.forX
	rts

majY	cmp.w	d3,d1
	blt.b	.top
	moveq.l	#-1,d7
	cmp.w	d2,d0
	blt.b	.go
	neg.w	d5
	bra.b	.go
.top	moveq.l	#1,d7
	cmp.w	d2,d0
	blt.b	.go
	neg.w	d5
.go	asl.w	#8,d0
	tst.w	d6
	beq.b	.forY
	asl.w	#8,d5
	ext.l	d5
	divs.w	d6,d5
.forY	move.w	d0,d3
	move.b	d1,d3
	move.b	(a0,d3.w),d4
	add.w	d5,d0
	move.b	(a6,d4.w),(a0,d3.w)
	add.w	d7,d1
	dbf	d6,.forY
	rts

;------------------------------------------------------------------------------------------------------

offsets	dc.w	14,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
	dc.w	8,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
	dc.w	8,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
	dc.w	8,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4

palette	dc.w	$000,$001,$101,$011,$111,$112,$212,$122,$222,$223,$323,$233,$333,$334,$434,$344
	dc.w	$444,$445,$545,$455,$555,$556,$656,$566,$666,$667,$767,$677,$777,$778,$878,$788
	dc.w	$888,$889,$989,$899,$999,$99a,$a9a,$9aa,$aaa,$aab,$bab,$abb,$bbb,$bbc,$cbc,$bcc
	dc.w	$ccc,$ccd,$dcd,$cdd,$ddd,$dde,$ede,$dee,$eee,$eef,$fef,$eff,$fff,$fff,$fff,$fff

count	dc.w	0
scale	dc.w	256-16

RotateZoomBlur

	;#define XP -DSTWIDTH / 2
	;#define YP -DSTHEIGHT / 2
	;xs = ( XP * cos(-a * PI / 180) + YP * sin(-a * PI / 180)) * s;
	;ys = (-XP * sin(-a * PI / 180) + YP * cos(-a * PI / 180)) * s;
	;xs += SRCWIDTH / 2;
	;ys += SRCHEIGHT / 2;
	;cosa = cos(a * PI / 180) * s;
	;sina = sin(a * PI / 180) * s;

	lea	sinLUT,a0
	move.w	count(pc),d0
	addq.w	#3,count
	and.w	#$1ff,d0
	move.b	(a0,d0.w),d0
	ext.w	d0
	asr.w	#4,d0
	move.w	d0,d1
	neg.w	d1
	and.w	#$1ff,d0
	move.b	(a0,d0.w),d6
	ext.w	d6
	add.w	#128,d0
	and.w	#$1ff,d0
	move.b	(a0,d0.w),d7
	ext.w	d7
	and.w	#$1ff,d1
	move.b	(a0,d1.w),d0
	ext.w	d0
	add.w	#128,d1
	and.w	#$1ff,d1
	move.b	(a0,d1.w),d1
	ext.w	d1
	move.w	d1,d2
	move.w	d0,d3
	muls.w	#-DISPLAYWIDTH/2,d2
	muls.w	#DISPLAYWIDTH/2,d3
	muls.w	#-DISPLAYHEIGHT/2,d0
	muls.w	#-DISPLAYHEIGHT/2,d1
	add.w	d2,d0
	add.w	d3,d1
	move.w	scale(pc),d2
	muls.w	d2,d0
	muls.w	d2,d1
	asr.l	#7,d0
	asr.l	#7,d1
	add.w	#(DISPLAYWIDTH*258)/2,d0
	add.w	#(DISPLAYHEIGHT*258)/2,d1
	muls.w	d2,d6
	muls.w	d2,d7
	asr.l	#7,d6
	asr.l	#7,d7
	swap	d6
	swap	d7
	move.w	d0,d6
	move.w	d1,d7
	swap	d6					;d6 = (xs << 16) + sina
	swap	d7					;d7 = (ys << 16) + cosa

	move.l	pictFrontPtr(pc),a0
	move.l	pictBackPtr(pc),a1
	lea	palette(pc),a2
	move.l	custCopBackPtr(pc),a3
	lea	offsets(pc),a4
	moveq.l	#0,d2
	moveq.l	#0,d3
	moveq.l	#DISPLAYWIDTH-1,d0
.forX	add.w	(a4)+,a3
	move.l	a3,a5
	move.w	d6,d4					;d4 = sina
	move.w	d7,d5					;d5 = cosa
	swap	d6
	swap	d7
	move.w	d7,d2
	ror.l	#8,d2
	swap	d0
	move.w	d2,d0
	move.w	d6,d2
	move.w	d5,d3
	ror.l	#8,d3
	move.w	d3,d1
	move.w	d4,d3
	neg.w	d3
	add.w	d5,d6					;xs = xs + cosa
	add.w	d4,d7					;ys = ys + sina
	swap	d6
	swap	d7
	move.l	d7,-(sp)
	moveq.l	#0,d5
	move.w	d1,d7
	moveq.l	#DISPLAYHEIGHT-1,d1
.forY
	move.b	(a1),d5
	move.w	(a2,d5.w*2),(a5)
	lea	INSTRPERLINE*4(a5),a5
	move.w	d2,d4
	move.b	d0,d4
	lea	-1(a0,d4.w),a6
	add.l	d3,d2					;tx = tx - sina
	addx.b	d7,d0					;ty = ty + cosa
	move.b	2(a6),d5
	add.b	(a6)+,d5
	add.b	256(a6),d5
	add.b	-256(a6),d5
	moveq.l	#0,d4
	move.b	(a6),d4
	lsl.w	#2,d4
	add.w	d5,d4
	subq.w	#7,d4
	bge.b	.ok
	moveq.l	#0,d4
.ok	lsr.w	#3,d4
	move.b	d4,(a1)+

	dbf	d1,.forY
	lea	256-DISPLAYHEIGHT(a1),a1
	move.l	(sp)+,d7
	swap	d0
	dbf	d0,.forX

	rts

;======================================================================================================

	section	ChipStuff,data_c
	cnop	0,4

copList	dc.w	DIWSTRT,$4cc1
	dc.w	DIWSTOP,$0c80
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
sinLUT	incbin	Sin(0..511)*127.Raw

	;----------------------------------------------------------------------------------------------

	section	BSSChipStuff,bss_c
	cnop	0,4
custCop1	ds.l	INSTRPERLINE*DISPLAYHEIGHT+2+1
custCop2	ds.l	INSTRPERLINE*DISPLAYHEIGHT+2+1
pattBitmap	ds.l	(192/32)*258*7

	;----------------------------------------------------------------------------------------------

	section	BSSStuff,bss
	cnop	0,4
pict		ds.b	256*256
mixLUT		ds.b	256*64
scrnPts		ds.w	NOOFPOINTS*2