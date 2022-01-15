Start	Lea	$dff000,a5		;Hardware base
	Move.l	a7,InitStack		;Save stack pointer

	;Find our process structure and disable DOS requesters
	Sub.l	a1,a1		;Clear
	Move.l	$4,a6		;SysBase
	Jsr	-$126(a6)		;FindTask()
	Move.l	d0,a3
	Move.l	#-1,184(a3)		;no DOS requesters

	;Determine if from CLI or WorkBench and act accordingly
	Tst.l	172(a3)		;From CLI?
	Bne.s	.Go		;Yep!, skip
	Lea	92(a3),a0		;a0 -> MsgPort
	Jsr	-$180(a6)		;WaitPort()
	Lea	92(a3),a0
	Jsr	-$174(a6)		;GetMsg()
	Move.l	d0,WBMessage		;and save it!

	;Obtain address of systems Copper List so we can restore it later
.Go	Lea	GrafName,a1		;Library name
	MoveQ	#39,d0		;Version v39
	Move.l	$4,a6		;Exec base
	Jsr	-$228(a6)		;OpenLibrary()
	Tst.l	d0		;Check!
	Beq	Error		;Whoops, quit now!
	Move.l	d0,GFXBase
	Move.l	d0,a1		;a1 -> GFXBase
	Move.l	$26(a1),SysCOP		;Save address
	Move.l	$22(a1),OldView
	Move.l	GFXBase(PC),a6
	Sub.l	a1,a1
	Jsr	-$de(a6)		;LoadView(a1)
	;Jsr	-$10e(a6)		;WaitTOF()
	;Jsr	-$10e(a6)		;WaitTOF()
	Move.l	$4,a6		;Exec base
	Jsr	-$19e(a6)		;CloseLibrary()

	Jsr	-$84(a6)		;Forbid()
	Move.w	DMACONR(a5),SysDMA	;Save DMA settings
	Move.w	INTENAR(a5),SysINTS	;Save Interrupt settings

	;Preserve system autovectors
	Lea	$64,a0		;Autovectors
	Lea	SysVECTS,a1		;Storage area
	Move.l	(a0)+,(a1)+		;Level 1
	Move.l	(a0)+,(a1)+		;Level 2
	Move.l	(a0)+,(a1)+		;Level 3
	Move.l	(a0)+,(a1)+		;Level 4
	Move.l	(a0)+,(a1)+		;Level 5
	Move.l	(a0)+,(a1)+		;Level 6

	;Stop all DMA, paying particular attention to sprite0
	Move.w	#VERTB,$dff000+INTENA
	Move.w	#VERTB,$dff000+INTREQ
.Vbl	Btst	#5,$dff01f
	Beq.s	.Vbl
	Move.w	#VERTB,$dff000+INTREQ
	Move.l	#0,COLOR16(a5)
	Move.l	#0,COLOR18(a5)
	Move.l	#0,COLOR20(a5)
	Move.l	#0,COLOR22(a5)
	Move.l	#0,COLOR24(a5)
	Move.l	#0,COLOR26(a5)
	Move.l	#0,COLOR28(a5)
	Move.l	#0,COLOR30(a5)
	Move.w	#$7fff,DMACON(a5)	;Stop DMA

	Move.w	#$7fff,INTENA(a5)	;Stop Interrupts

	;Set all autovectors to a safe handler
	Lea	Handler,a0		;Safe handler
	Lea	$64,a1		;Autovectors
	Move.l	a0,(a1)+		;Level 1
	Move.l	a0,(a1)+		;Level 2
	Move.l	a0,(a1)+		;Level 3
	Move.l	a0,(a1)+		;Level 4
	Move.l	a0,(a1)+		;Level 5
	Move.l	a0,(a1)		;Level 6

	;Stop drive motors
	OR.b	#$f8,CIABPRB
	And.b	#$87,CIABPRB
	OR.b	#$f8,CIABPRB

	;---- Call main program ----

	Jsr	Main 

	;---------------------------
	
QuitFast	Move.l	InitStack,a7		;Restore stack
	Lea	$dff000,a5		;Hardware base

	;Stop all interrupts and DMA
	Move.w	#$7fff,DMACON(a5)
	Move.w	#$7fff,INTENA(a5)
		
	;Restore system autovectors
	Lea	SysVECTS,a0		;Autovectors
	Lea	$64,a1		;Storage area
	Move.l	(a0)+,(a1)+		;Level 1
	Move.l	(a0)+,(a1)+		;Level 2
	Move.l	(a0)+,(a1)+		;Level 3
	Move.l	(a0)+,(a1)+		;Level 4
	Move.l	(a0)+,(a1)+		;Level 5
	Move.l	(a0)+,(a1)+		;Level 6

	;Restore system interrupt requirements
	Move.w	SysINTS,d0		;Get bits
	OR.w	#SETIT!INTEN,d0		;Set bits 14 & 15
	Move.w	d0,INTENA(a5)		;Set requirements

	;Restore system DMA requirements
	Move.w	SysDMA,d0		;DMA settings
	OR.w	#SETIT!DMAEN,d0		;Set enable bits
	Move.w	d0,DMACON(a5)		;Restore DMA

	;Restore old view
	Move.l	GFXBase(PC),a6
	Move.l	OldView(PC),a1
	Jsr	-$de(a6)		;LoadView(a1)

	;Restart systems Copper List
	Move.l	SysCOP,COP1LCH(a5)	;Write address
	Move.w	#0,COPJMP1(a5)		;Start list

	;Restart multitasking
Error	Move.l	$4,a6		;Exec base
	Jsr	-$8a(a6)		;Permit()

	;If started from WorkBench, reply the message now
	Tst.l	WBMessage
	Beq.s	.Done
	Move.l	$4,a6
	Jsr	-$084(a6)		;Forbid()
	Move.l	WBMessage,a1
	Jsr	-$17a(a6)		;ReplyMsg()
				
	;Return to system
.Done	MoveQ	#0,d0		;Be kind to DOS
	Rts
	
	;--------------------------------------------------------------------------------------

	;A safe interrupt handler
Handler	Lea	$dff000,a0
	Move.w	INTREQR(a0),d0		;Request bits
	And.w	#$7fff,d0		;Clear bit 15
	Move.w	d0,INTREQ(a0)		;Clear request
	Rte			;And exit

	;--------------------------------------------------------------------------------------
	

GrafName	Dc.b	'graphics.library',0
		Even

SysINTS	Ds.w	1		;For interrupt bits
SysCOP	Ds.l	1		;For Copper address
SysDMA	Ds.w	1		;For DMA bits
SysVECTS	Ds.l	6		;For autovectors
InitStack	Ds.l	1		;For stack pointer
WBMessage	Ds.l	1		;For Workbench message
OldView	Ds.l	1
GFXBase	Ds.l	1