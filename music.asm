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

.DEFINE Control $F1
.DEFINE Timer0 $FA
.DEFINE Counter0 $FD
	
	
	;; first argument is a constant that specifies DSP address
	;; second argument is the value
.MACRO WriteDSP
	mov $F2, #\1
	mov $F3, #\2
.ENDM

.MACRO WriteDSPA
	mov $F2, #\1
	mov $F3, a
.ENDM
	

.BANK 0 SLOT 0

.ORG $0200
Directory:	
	.dw SamplesLong
	.dw SamplesLong

SamplesLong:
.INCBIN "samples_long.bin"
	
MidiNotes:
	;; TODO: generate this
	;; SRCN, PL, PH
	;; note 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	;; note 10
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	;; note 20
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	;; note 30
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	;; note 40
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	;; note 50
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	.db 0, 0, 0
	;; NB: these notes are all based on a sample at middle C
	;;     we should use multiple samples
	.db 0, $5f, $a
	;; note 60 (middle C)
	.db 0, $fd, $0a
	.db 0, $a4, $b
	.db 0, $55, $c
	.db 0, $11, $d
	.db 0, $d8, $d
	.db 0, $ab, $e
	.db 0, $8a, $f
	.db 0, $77, $10
	.db 0, $71, $11
	.db 0, $7b, $12
	.db 0, $94, $13
	.db 0, $be, $14
	;; node 72
	
Song:
	;; songs are bytes that represent a midi note
	;; a new note calls note off at the half beat
	;; before doing note on at the beat
	;; "0" means call note-off at half-beat, and do nothing on beat
	;; "ff" means do nothing
	;; "fe" means song is over
	
	;; each point in the vector is a beat
	;; this song is in 6/8 time
	.db 59, 63, 66, 70, 66, 63
	.db 59, 63, 66, 70, 66, 63
	.db 59, 63, 66, 70, 66, 63
	.db 59, 63, 66, 70, 66, 63
	
	.db 60, 63, 67, 70, 67, 63
	.db 60, 63, 67, 70, 67, 63
	.db 60, 63, 67, 70, 67, 63
	.db 60, 63, 67, 70, 67, 63
	
	.db $fe

.DEFINE NoteAddressLow $00
.DEFINE NoteAddressHigh $01
	
.DEFINE BPM 220
	
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

	;; WriteDSP SRCN0 $00
	;; WriteDSP PL0 $fd
	;; WriteDSP PH0 $a
	;; WriteDSP KON $01

	;; sleep

	;; play song (song can't be longer than 256 beats for now)
StartSong:	
	mov x, #0
	
SongLoop:
	;; starts at prior half-beat
	
	;; get note
	mov a, !Song+x

	;; don't do anything
	cmp a, #$ff
	beq FirstSleep

	;; song is over
	cmp a, #$fe
	beq StartSong

	;; first, set note off
	WriteDSP KOF $01

FirstSleep:	
	;; now sleep for half a beat
	mov Control, #$00	; disable timers
	mov Timer0, #255
	mov Control, #$01	; start timer0
wait_for_tick1:	
	mov a, Counter0
	beq wait_for_tick1

	;; now we're at the beat
	WriteDSP KOF $00
	
	;; get note
	mov a, !Song+x
	
	;; don't do anything
	beq SecondSleep
	cmp a, #$ff
	beq SecondSleep

	;;  get note offset & save to memory
	mov y, #3
	mul ya
	mov y, a

	;; load srcn
	mov a, !MidiNotes + y
	WriteDSPA SRCN0

	;; load pl
	inc y
	mov a, !MidiNotes + y	
	WriteDSPA PL0

	;; load ph
	inc y
	mov a, !MidiNotes + y	
	WriteDSPA PH0

	;; now note on!
	WriteDSP KON $01
	
SecondSleep:
	;; Sleep for half a beat
	;; now sleep for half a beat
	mov Control, #$00	; disable timers
	mov Timer0, #255	
	mov Control, #$01	; start timer0
wait_for_tick2:	
	mov a, Counter0
	beq wait_for_tick2
	
	inc x
	bra SongLoop
