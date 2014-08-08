.MEMORYMAP
SLOTSIZE $8000
DEFAULTSLOT 0
SLOT 0 $0000
.ENDME

.ROMBANKMAP
BANKSTOTAL 1
BANKSIZE $8000
BANKS 1
.ENDRO

.DEFINE FLG $6C
.DEFINE KON $4C
.DEFINE KOF $5C
.DEFINE DIR $5D
.DEFINE VOLL0 $00
.DEFINE VOLR0 $01
.DEFINE PL0 $02
.DEFINE PH0 $03
.DEFINE SRCN0 $04
.DEFINE ADSR10 $05
.DEFINE ADSR20 $06
.DEFINE GAIN0 $07
.DEFINE NON $3D
.DEFINE EON $4D
.DEFINE MVOLL $0C
.DEFINE MVOLR $1C
.DEFINE EVOLL $2C
.DEFINE EVOLR $3C	
	
	
	;; first argument is a constant that specifies DSP address
	;; second argument is the value
.MACRO WriteDSP
	mov $F2, #\1
	mov $F3, #\2
.ENDM

.BANK 0 SLOT 0

.ORG $0200	
Directory:	
	.dw SamplesLong
	.dw SamplesLong
	.dw SamplesShort
	.dw SamplesShort	

SamplesLong:
.INCBIN "samples_long.bin"
	
SamplesShort:
	.db $C0,$78,$78,$78,$78,$78,$78,$78,$78
	.db $C3,$78,$78,$78,$78,$78,$78,$78,$78

.ORG $2000
_Start:	
	;; just do a bunch of init

	;; set FLG register, disable echo, disable noise, disable mute
	WriteDSP FLG $20

	;; send keyon to false for all channels
	WriteDSP KON $00

	;; send keyoff to true for all channels
	WriteDSP KOF $FF

	;; set offset(*0x100) of sample directory
	WriteDSP DIR (Directory / $100)

	;; set left/right volume of channel 0
	WriteDSP VOLL0 $7F
	WriteDSP VOLR0 $7F

	;; set pitch value of channel 0
	;; this is a magic number governed by:
	;; 32000.0 * P / (2 ** 12  * T) = Freq
	;; where P is this pitch value, and T is our period length in samples
	WriteDSP PL0 $4e
	WriteDSP PH0 $3c
	;; WriteDSP PL0 $43
	;; WriteDSP PH0 $00

	;; set index of source sample in DIR for channel 0
	WriteDSP SRCN0 $00

	;; set up ADSR for channel 0, just disable it, use gain instead
	WriteDSP ADSR10 $00
	WriteDSP ADSR20 $00

	;; set up GAIN for channel 0
	WriteDSP GAIN0 $1F

	;; send key off to false
	;; (we do this up here because you need some time between KOF and KON)
	WriteDSP KOF $00

	;; disable noise
	WriteDSP NON $00

	;; disable echo
	WriteDSP EON $00

	;; set main volume to max
	WriteDSP MVOLL $7F
	WriteDSP MVOLR $7F

	;; set echo volume to min
	WriteDSP EVOLL $00
	WriteDSP EVOLR $00

	;; finally send key on for channel 0
	WriteDSP KON $01

	sleep
