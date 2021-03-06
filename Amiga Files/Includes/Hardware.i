;Amiga Hardware Registers Include File

;CIA addresses

;These are absolute addresses

;Set Devpac tab setting to 16 for readable list.

CIAAPRA	EQU	$BFE001
CIAAPRB	EQU	$BFE101
CIAADDRA	EQU	$BFE201
CIAADDRB	EQU	$BFE301
CIAATALO	EQU	$BFE401
CIAATAHI	EQU	$BFE501
CIAATBLO	EQU	$BFE601
CIAATBHI	EQU	$BFE701
CIAAE.LSB	EQU	$BFE801
CIAAE.MID	EQU	$BFE901
CIAAE.MSB	EQU	$BFEA01
CIAASP	EQU	$BFEC01
CIAAICR	EQU	$BFED01
CIAACRA	EQU	$BFEE01
CIAACRB	EQU	$BFEF01

CIABPRA	EQU	$BFD000
CIABPRB	EQU	$BFD100
CIABDDRA	EQU	$BFD200
CIABDDRB	EQU	$BFD300
CIABTALO	EQU	$BFD400
CIABTAHI	EQU	$BFD500
CIABTBLO	EQU	$BFD600
CIABTBHI	EQU	$BFD700
CIAJE.LSB	EQU	$BFD800
CIABE.MID	EQU	$BFD900
CIABE.MSB	EQU	$BFDA00
CIABSP	EQU	$BFDC00
CIABICR	EQU	$BFDD00
CIABCRA	EQU	$BFDE00
CIABCRB	EQU	$BFDF00


;Custom Chip Register Values
;All values are offsets from $DFF000

CUSTOM	EQU	$DFF000

BLTDDAT	EQU	$000	;early read-68000 can't access

DMACONR	EQU	$002	;DMA controller read
VPOSR	EQU	$004
VHPOSR	EQU	$006

DSKDATR	EQU	$008	;when non-DMA disk transferring

JOY0DAT	EQU	$00A
JOY1DAT	EQU	$00C

CLXDAT	EQU	$00E	;sprite collision data
ADKCONR	EQU	$010	;disk/audio status read

POT0DAT	EQU	$012
POT1DAT	EQU	$014
POTGOR	EQU	$016

SERDATA	EQU	$018
DSKBYTR	EQU	$01A

INTENAR	EQU	$01C	;interrupt enable read
INTREQR	EQU	$01E	;interrupt request read

DSKPTH	EQU	$020
DSKPTL	EQU	$022

DSKLEN	EQU	$024
DSKDAT	EQU	$026

REFPTR	EQU	$028	;refresh counter write (CARE!!)

VPOSW	EQU	$02A
VHPOSW	EQU	$02C

COPCON	EQU	$02E	;COPPER danger bit

SERDAT	EQU	$030
SERPER	EQU	$032

POTGO	EQU	$034

JOYTEST	EQU	$036

STREQU	EQU	$038	;horizontal sync with VB and equal frame

STRVBL	EQU	$03A	;horizontal sync with vertical blank

STRHOR	EQU	$03C	;horizontal sync signal

STRLONG	EQU	$03E

;following registers accessible when
;Copper Danger Bit set (COPCON = 1)

BLTCON0	EQU	$040
BLTCON1	EQU	$042

BLTAFWM	EQU	$044
BLTALWM	EQU	$046

BLTCPTH	EQU	$048
BLTCPTL	EQU	$04A

BLTBPTH	EQU	$04C
BLTBPTL	EQU	$04E

BLTAPTH	EQU	$050
BLTAPTL	EQU	$052

BLTDPTH	EQU	$054
BLTDPTL	EQU	$056

BLTSIZE	EQU	$058

BLTCMOD	EQU	$060
BLTBMOD	EQU	$062
BLTAMOD	EQU	$064
BLTDMOD	EQU	$066

BLTCDAT	EQU	$070
BLTBDAT	EQU	$072
BLTADAT	EQU	$074

DSKSYNC	EQU	$07E

;Following registers can always be written by the Copper

COP1LCH	EQU	$080
COP1LCL	EQU	$082

COP2LCH	EQU	$084
COP2LCL	EQU	$086

COPJMP1	EQU	$088
COPJMP2	EQU	$08A

COPINS	EQU	$08C	;COPPER command register

DIWSTRT	EQU	$08E	;window start, stop values
DIWSTOP	EQU	$090

DDFSTRT	EQU	$092	;DMA data fetch start, stop
DDFSTOP	EQU	$094

DMACON	EQU	$096	;main DMA controller write (SETIT)

CLXCON	EQU	$098	;collision register

INTENA	EQU	$09A	;interrupt enable write (SETIT)

INTREQ	EQU	$09C	;interrupt request write (force an int) (SETIT)

ADKCON	EQU	$09E	;audio/disk controller (SETIT)

;audio control registers

AUD0LCH	EQU	$0A0
AUD0LCL	EQU	$0A2
AUD0LEN	EQU	$0A4
AUD0PER	EQU	$0A6
AUD0VOL	EQU	$0A8
AUD0DAT	EQU	$0AA

AUD1LCH	EQU	$0B0
AUD1LCL	EQU	$0B2
AUD1LEN	EQU	$0B4
AUD1PER	EQU	$0B6
AUD1VOL	EQU	$0B8
AUD1DAT	EQU	$0BA

AUD2LCH	EQU	$0C0
AUD2LCL	EQU	$0C2
AUD2LEN	EQU	$0C4
AUD2PER	EQU	$0C6
AUD2VOL	EQU	$0C8
AUD2DAT	EQU	$0CA

AUD3LCH	EQU	$0D0
AUD3LCL	EQU	$0D2
AUD3LEN	EQU	$0D4
AUD3PER	EQU	$0D6
AUD3VOL	EQU	$0D8
AUD3DAT	EQU	$0DA

;bitplane DMA control registers

BPL1PTH	EQU	$0E0
BPL1PTL	EQU	$0E2

BPL2PTH	EQU	$0E4
BPL2PTL	EQU	$0E6

BPL3PTH	EQU	$0E8
BPL3PTL	EQU	$0EA

BPL4PTH	EQU	$0EC
BPL4PTL	EQU	$0EE

BPL5PTH	EQU	$0F0
BPL5PTL	EQU	$0F2

BPL6PTH	EQU	$0F4
BPL6PTL	EQU	$0F6

BPL7PTH	EQU	$0F8
BPL7PTL	EQU	$0FA

BPL8PTH	EQU	$0FC
BPL8PTL	EQU	$0FE

BPLCON0	EQU	$100
BPLCON1	EQU	$102
BPLCON2	EQU	$104
BPLCON3	EQU	$106

BPL1MOD	EQU	$108
BPL2MOD	EQU	$10A

BPLCON4	EQU	$10C

BPL1DAT	EQU	$110
BPL2DAT	EQU	$112
BPL3DAT	EQU	$114
BPL4DAT	EQU	$116
BPL5DAT	EQU	$118
BPL6DAT	EQU	$11A

;sprite control registers

SPR0PTH	EQU	$120
SPR0PTL	EQU	$122

SPR1PTH	EQU	$124
SPR1PTL	EQU	$126

SPR2PTH	EQU	$128
SPR2PTL	EQU	$12A

SPR3PTH	EQU	$12C
SPR3PTL	EQU	$12E

SPR4PTH	EQU	$130
SPR4PTL	EQU	$132

SPR5PTH	EQU	$134
SPR5PTL	EQU	$136

SPR6PTH	EQU	$138
SPR6PTL	EQU	$13A

SPR7PTH	EQU	$13C
SPR7PTL	EQU	$13E

SPR0POS	EQU	$140
SPR0CTL	EQU	$142
SPR0DATA	EQU	$144
SPR0DATB	EQU	$146

SPR1POS	EQU	$148
SPR1CTL	EQU	$14A
SPR1DATA	EQU	$14C
SPR1DATB	EQU	$14E

SPR2POS	EQU	$150
SPR2CTL	EQU	$152
SPR2DATA	EQU	$154
SPR2DATB	EQU	$156

SPR3POS	EQU	$158
SPR3CTL	EQU	$15A
SPR3DATA	EQU	$15C
SPR3DATB	EQU	$15E

SPR4POS	EQU	$160
SPR4CTL	EQU	$162
SPR4DATA	EQU	$164
SPR4DATB	EQU	$166

SPR5POS	EQU	$168
SPR5CTL	EQU	$16A
SPR5DATA	EQU	$16C
SPR5DATB	EQU	$16E

SPR6POS	EQU	$170
SPR6CTL	EQU	$172
SPR6DATA	EQU	$174
SPR6DATB	EQU	$176

SPR7POS	EQU	$178
SPR7CTL	EQU	$17A
SPR7DATA	EQU	$17C
SPR7DATB	EQU	$17E

;palette control registers

COLOR00	EQU	$180
COLOR01	EQU	$182
COLOR02	EQU	$184
COLOR03	EQU	$186
COLOR04	EQU	$188
COLOR05	EQU	$18A
COLOR06	EQU	$18C
COLOR07	EQU	$18E
COLOR08	EQU	$190
COLOR09	EQU	$192
COLOR10	EQU	$194
COLOR11	EQU	$196
COLOR12	EQU	$198
COLOR13	EQU	$19A
COLOR14	EQU	$19C
COLOR15	EQU	$19E
COLOR16	EQU	$1A0
COLOR17	EQU	$1A2
COLOR18	EQU	$1A4
COLOR19	EQU	$1A6
COLOR20	EQU	$1A8
COLOR21	EQU	$1AA
COLOR22	EQU	$1AC
COLOR23	EQU	$1AE
COLOR24	EQU	$1B0
COLOR25	EQU	$1B2
COLOR26	EQU	$1B4
COLOR27	EQU	$1B6
COLOR28	EQU	$1B8
COLOR29	EQU	$1BA
COLOR30	EQU	$1BC
COLOR31	EQU	$1BE

FMODE	EQU	$1FC
BEAMCON0	EQU	$1DC

* DMA and INT register bit assignments (SETIT used for DMACON
* type registers throughout! All such registers comment flagged
* with (SETIT) by name)

SETIT	EQU	$8000
BBUSY	EQU	$4000
BZERO	EQU	$2000
BLTPRI	EQU	$0400
DMAEN	EQU	$0200
BPLEN	EQU	$0100
COPEN	EQU	$0080
BLTEN	EQU	$0040
SPREN	EQU	$0020
DSKEN	EQU	$0010
AUD3EN	EQU	$0008
AUD2EN	EQU	$0004
AUD1EN	EQU	$0002
AUD0EN	EQU	$0001

INTEN	EQU	$4000
EXTER	EQU	$2000
DSKSYN	EQU	$1000
RBF	EQU	$0800
AUD3	EQU	$0400
AUD2	EQU	$0200
AUD1	EQU	$0100
AUD0	EQU	$0080
BLIT	EQU	$0040
VERTB	EQU	$0020
COPER	EQU	$0010
PORTS	EQU	$0008
SOFT	EQU	$0004
DSKBLK	EQU	$0002
TBE	EQU	$0001

CDANG	EQU	$02E	;COPPER DANGER BIT REG

* BPLCON0 BIT ASSIGNMENTS

HIRES	EQU	$8000	;HIRES mode on
BPU2	EQU	$4000
BPU1	EQU	$2000	;BPU2-0 = no of bit planes used
BPU0	EQU	$1000
HOMOD	EQU	$0800	;HAM on
DBPLF	EQU	$0400	;Dual Playfield on
COLOR	EQU	$0200	;Video output colour
GAUD	EQU	$0100	;Genlock Audio on

LPEN	EQU	$0008	;Light Pen input active
LACE	EQU	$0004	;interlace on
ERSY	EQU	$0002	;external synchronsiation on

* Blitter Minterm Definitions
* NA = not A, NB = not B etc

MINTERM_ABC	EQU	%111
MINTERM_ABNC	EQU	%110
MINTERM_ANBC	EQU	%101
MINTERM_ANBNC	EQU	%100
MINTERM_NABC	EQU	%011
MINTERM_NABNC	EQU	%010
MINTERM_NANBC	EQU	%001
MINTERM_NANBNC	EQU	%000


* BLTCON0 Bit Assignments

ASH3	EQU	$8000
ASH2	EQU	$4000
ASH1	EQU	$2000
ASH0	EQU	$1000
USEA	EQU	$0800
USEB	EQU	$0400
USEC	EQU	$0200
USED	EQU	$0100
LF7	EQU	$0080
LF6	EQU	$0040
LF5	EQU	$0020
LF4	EQU	$0010
LF3	EQU	$0008
LF2	EQU	$0004
LF1	EQU	$0002
LF0	EQU	$0001

START3	EQU	$8000
START2	EQU	$4000
START1	EQU	$2000
START0	EQU	$1000

* BLTCON1 Bit Assignments

BSH3	EQU	$8000
BSH2	EQU	$4000
BSH1	EQU	$2000
BSH0	EQU	$1000

EFE	EQU	$0010
IFE	EQU	$0008
FCI	EQU	$0004
DESC	EQU	$0002
LINE	EQU	$0001

TEXTURE3	EQU	$8000
TEXTURE2	EQU	$4000
TEXTURE1	EQU	$2000
TEXTURE0	EQU	$1000

SIGN	EQU	$0040

SUD	EQU	$0010
SUL	EQU	$0008
AUL	EQU	$0004
SING	EQU	$0002
	
* ADKCON bit assignments (SETIT)

PRECOMP1	EQU	$4000
PRECOMP0	EQU	$2000

MFMPREC	EQU	$1000
UARTNRK	EQU	$0800
WORDSYNC	EQU	$0400
MSBSYNC	EQU	$0200
FAST	EQU	$0100

USE3PN	EQU	$0080
USE2P3	EQU	$0040
USE1P2	EQU	$0020
USE0P1	EQU	$0010
USE3VN	EQU	$0008
USE2V3	EQU	$0004
USE1V2	EQU	$0002
USE0V1	EQU	$0001

* POTGO bit assignments

OUTRY	EQU	$8000
DATRY	EQU	$4000
OUTRX	EQU	$2000
DATRX	EQU	$1000
OUTLY	EQU	$0800
DATLY	EQU	$0400
OUTLX	EQU	$0200
DATLX	EQU	$0100

POTGOSTART	EQU	$0001

*SERPER bit assignments

LONG	EQU	$8000

* SERDAT/SERDATR bit assignments

SD_OVRUN	EQU	$8000
SD_RBF	EQU	$4000
SD_TBE	EQU	$2000
SD_RXD	EQU	$1000

SD_STP	EQU	$0200
SD_DB8	EQU	$0100
SD_DB7	EQU	$0080
SD_DB6	EQU	$0040
SD_DB5	EQU	$0020
SD_DB4	EQU	$0010
SD_DB3	EQU	$0008
SD_DB2	EQU	$0004
SD_DB1	EQU	$0002
SD_DB0	EQU	$0001

*DSKBYT/DSKBYTR bit assignments

BYTEREADY	EQU	$8000
DMAON	EQU	$4000
DSKWRITE	EQU	$2000
WORDEQUAL	EQU	$1000

DB_DATA7	EQU	$0080
DB_DATA6	EQU	$0040
DB_DATA5	EQU	$0020
DB_DATA4	EQU	$0010
DB_DATA3	EQU	$0008
DB_DATA2	EQU	$0004
DB_DATA1	EQU	$0002
DB_DATA0	EQU	$0001

* DSKLEN	bit assignments

DK_DMAEN	EQU	$8000
DK_WRITE	EQU	$4000