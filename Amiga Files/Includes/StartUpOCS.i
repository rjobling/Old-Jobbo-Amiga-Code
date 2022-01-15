

CACHEOFF	Equ	0					;1 = Disable caches
NTSCEXIT	Equ	0					;1 = Exit if no PAL
CHIPSETEXIT	Equ	0					;1 = Exit if <ECS, or 2 = Exit if <AGA


	Bsr	TakeSystem
	Bsr	Main
	Bsr	FreeSystem
	MoveQ	#0,d0
	Rts
	

;======================================================================================================


TakeSystem
	Move.l	4.w,a6
	Lea	gfxLib(PC),a1
	Jsr	-$198(a6)					;OldOpenLibrary()
	Lea	gfxBase(PC),a5
	Move.l	d0,(a5)
	Bne.s	.gfxLibOK
	Moveq	#-1,d0						;Error, no graphics.library
	Rts
.gfxLibOK
	Move.l	d0,a1
	Cmp.w	#36,$14(a6)					;Check for Kickstart 2
	Blo.s	.oldKS
	BTst	#2,$cf(a1)					;Proper NTSC check
	Bne.s	.PAL
	Bra.s	.NTSC
.oldKS	Cmp.w	#50+50<<8,$212(a6)				;Alternative NTSC check
	Beq.s	.PAL
.NTSC
	IFNE	NTSCEXIT
	Jsr	-$19e(a6)					;CloseLibrary()
	MoveQ	#-3,d0						;Error, no PAL display found
	Rts
	ELSE
	Lea	displayFlag(PC),a0
	St	(a0)
	ENDC
.PAL	MoveQ	#1,d1
	Move.l	#$400,d0
	Jsr	-$c6(a6)					;AllocMem()
	Lea	zeroPagePtr(PC),a0
	Move.l	d0,(a0)
	Bne.s	.zeroPageOK
	Move.l	(a5),a1
	Jsr	-$19e(a6)					;CloseLibrary()
	MoveQ	#-2,d0						;Error, could not allocate memory
	Rts
.zeroPageOK
	Lea	$dff000,a4
	IFNE	CHIPSETEXIT-2
	Lea	chipSetFlag(PC),a0
	Clr.b	(a0)
	ENDC
	Move.w	$7c(a4),d0					;AGA check
	Cmp.b	#$f8,d0
	IFEQ	CHIPSETEXIT-2
	Beq.s	.chipSetOK
	ELSE
	Bne.s	.notAGA
	AddQ.b	#2,(a0)
	Bra.s	.chipSetOK
.notAGA
	Cmp.b	#$fc,d0						;ECS check
	Bne.s	.noReqChip
	AddQ.b	#1,(a0)
	IFNE	CHIPSETEXIT
	Bra.s	.chipSetOK
	ENDC
.noReqChip
	ENDC
	IFNE	CHIPSETEXIT
	Move.l	(a5),a1
	Jsr	-$19e(a6)					;CloseLibrary()
	Move.l	zeroPagePtr(PC),a1
	Move.l	#$400,d0
	Jsr	-$d2(a6)					;FreeMem()
	MoveQ	#-4,d0						;Error, required chipset not found
	Rts
	ENDC
.chipSetOK
	Jsr	-$84(a6)					;Forbid()
	Move.l	(a5),a6
	IFEQ	CHIPSETEXIT
	Tst.b	(a0)
	Beq.s	.noViewFix
	ENDC
	Lea	oldView(PC),a0
	Move.l	$22(a6),(a0)					;Save old view
	Sub.l	a1,a1
	MoveQ	#$7f,d0
	Bsr	WaitBeam
	Jsr	-$de(a6)					;LoadView()
	Jsr	-$10e(a6)					;WaitTOF()
	Jsr	-$10e(a6)					;Twice
.noViewFix
	Jsr	-$1c8(a6)					;OwnBlitter()
	Jsr	-$e4(a6)					;WaitBlit()
	IFNE	CACHEOFF
	Bsr	DisableCache
	ENDC

	Btst	#6,$1a(a4)					;Wait for disk DMA
	Beq.s	.noDiskDMA
.waitDiskDMA
	Btst	#1,$1f(a4)
	Beq.s	.waitDiskDMA
.noDiskDMA
	Lea	oldDMACON(PC),a0
	Move.l	#$c0008000,d2
	MoveQ	#$1f,d0
	Bsr	WaitBeam
	Move.w	$02(a4),(a0)+					;Save DMACON
	Move.w	$10(a4),(a0)+					;Save ADKCON
	Move.l	$1c(a4),(a0)					;Save INTENA and INTREQ
	Move.l	#$7fff3fff,$9a(a4)				;Kill INTENA and INTREQ
	Move.w	#$7fff,$9e(a4)					;Kill ADKCON
	Move.w	#$07ff,$96(a4)					;Kill DMACON
	Or.l	d2,(a0)
	Or.w	d2,-(a0)
	Or.w	d2,-(a0)
	And.w	#$87ff,(a0)
	IFNE	CHIPSETEXIT-2
	MoveQ	#2,d0
	Cmp.b	chipSetFlag(PC),d0
	Bne.s	.noAGASpr
	ENDC
	MoveQ	#0,d0
	Move.w	d0,$106(a4)					;Reset AGA sprites to 140ns res.
	Move.w	d0,$1fc(a4)
.noAGASpr
	Lea	$bfd100,a5					;Turn off drive(s)
	Or.b	#$f8,(a5)
	MoveQ	#0,d0
	Bsr.s	.beamDelay
	And.b	#$87,(a5)
	MoveQ	#$60,d0
	Bsr.s	.beamDelay
	Or.b	#$f8,(a5)

	Bsr.s	getVBR
	Lea	VBRReg(PC),a0
	Move.l	d2,(a0)
	Move.l	d2,a0
	Move.l	zeroPagePtr(PC),a1
	Move.w	#$400/4-1,d7
.clp:	Move.l	(a0)+,(a1)+					;Save zero page
	Dbf	d7,.clp

	Lea	2(a4),a6
	MoveQ	#0,d0						;Everything ok
	Rts

.beamDelay
	Move.w	$06(a4),d1
	Lsr.w	#8,d1
.bmlp	Move.w	$06(a4),d2					;Word access
	Lsr.w	#8,d2
	Cmp.b	d2,d1
	Beq.s	.bmlp
	Dbf	d0,.beamDelay
	Rts

getVBR	MoveQ	#0,d2
	Move.l	4.w,a6
	Btst	#0,$129(a6)					;>= 68010 ?
	Beq.s	.no010
	Lea	.getVBRException(PC),a5
	Jmp	-$1e(a6)					;Supervisor()
.no010	Rts

	CNOP	0,4
.getVBRException
	Dc.l	$4e7a2801					;MoveC VBR,d2
	Rte

	IFNE	CACHEOFF
DisableCache
	Move.l	4.w,a6
	MoveQ	#0,d0						;Get old cache state
	MoveQ	#0,d1
	Bsr.s	CacheControl
	Lea	oldCache(PC),a0
	Move.l	d0,(a0)
	Move.l	d0,d1						;Disable cache
	MoveQ	#0,d0
CacheControl							;Based on KCS3.0
	MoveQ	#0,d3
	Move.w	$128(a6),d4
	Btst	#1,d4
	Beq.s	.no020
	And.l	d1,d0
	Or.w	#$808,d0
	Not.l	d1
	Lea	.cacheException(PC),a5
	Jsr	-$1e(a6)					;Supervisor()
.no020	Move.l	d3,d0
	Rts

	CNOP	0,4
.cacheException
	Or.w	#$700,SR
	Dc.l	$4e7a2002					;MoveC CACR,d2
	Btst	#3,d4
	Beq.s	.no040a
	Swap	d2
	Ror.w	#8,d2
	Rol.l	#1,d2
.no040a	Move.l	d2,d3
	And.l	d1,d2
	Or.l	d0,d2
	Btst	#3,d4
	Beq.s	.no040b
	Ror.l	#1,d2
	Rol.w	#8,d2
	Swap	d2
	And.l	#$80008000,d2
	Nop
	Dc.w	$f4f8						;CPushA BC
.no040b	Nop
	Dc.l	$4e7b2002					;MoveC d2,CACR
	Nop
	Rte

restoreCache
	Move.l	4.w,a6
	Move.l	oldCache(PC),d0
	Move.l	d0,d1
	Bra.s	CacheControl
	ENDC

WaitBeam
	Lsl.l	#8,d0
.wlp:	Move.l	$04(a4),d1
	And.l	#$1ff00,d1
	Cmp.l	d0,d1
	Bne.s	.wlp
	Rts


	;----------------------------------------------------------------------------------------------


FreeSystem
	Lea	$dff000,a4
	MoveQ	#$1f,d0
	Bsr.s	WaitBeam
	Move.l	#$7fff3fff,$9a(a4)				;Kill INTENA and INTREQ
	Move.w	#$7fff,$9e(a4)					;Kill ADKCON
	Move.w	#$07ff,$96(a4)					;Kill DMACON

	Move.l	zeroPagePtr(PC),a0
	Move.l	VBRReg(PC),a1
	Move.w	#$400/4-1,d7
.clp	Move.l	(a0)+,(a1)+
	Dbf	d7,.clp

	Lea	oldDMACON(PC),a0
	Move.w	(a0)+,$96(a4)					;Restore DMACON
	Move.w	(a0)+,$9e(a4)					;Restore ADKCON
	Move.l	(a0),$9a(a4)					;Restore INTENA and INTREQ

	IFNE	CACHEOFF
	Bsr.s	RestoreCache
	ENDC
	Move.l	gfxBase(PC),a6
	IFEQ	CHIPSETEXIT
	Move.b	chipSetFlag(PC),d0
	Beq.s	.noViewFix
	ENDC
	Move.l	oldView(PC),a1					;Old WorkBench view
	MoveQ	#$7f,d0
	Bsr.s	WaitBeam
	Jsr	-$de(a6)					;LoadView()
.noViewFix
	Move.l	$26(a6),$80(a4)					;Restore system copper list
	Move.l	$32(a6),$84(a4)
	Move.w	d0,$88(a4)
	Jsr	-$10e(a6)					;WaitTOF()
	Jsr	-$10e(a6)					;Twice
	Jsr	-$e4(a6)					;WaitBlit()
	Jsr	-$1ce(a6)					;DisownBlitter()

	Move.l	a6,a1
	Move.l	4.w,a6
	Jsr	-$19e(a6)					;CloseLibrary()
	Move.l	zeroPagePtr(pc),a1
	Move.l	#$400,d0
	Jsr	-$d2(a6)					;FreeMem()
	Jmp	-$8a(a6)					;Permit()


;======================================================================================================


oldDMACON	Ds.w	1
oldADKCON	Ds.w	1
oldINTENA	Ds.l	1
zeroPagePtr	Ds.l	1
VBRReg		Ds.l	1
oldView		Ds.l	1
gfxBase		Ds.l	1
	IFNE	CACHEOFF
oldCache	Ds.l	1
	ENDC
gfxLib:		Dc.b	'graphics.library',0
	IFNE	CHIPSETEXIT-2
chipSetFlag	Ds.b	1					;0 = OCS, 1 = ECS, 2 = AGA
	ENDC
	IFEQ	NTSCEXIT
displayFlag	Ds.b	1					;0 = PAL, -1 = NTSC
	ENDC
	Even