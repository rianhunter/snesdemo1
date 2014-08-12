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
.DEFINE VOLL1 $10
.DEFINE VOLR1 $11
.DEFINE ADSR11 $15
.DEFINE ADSR21 $16
.DEFINE GAIN1 $17

.DEFINE Control $F1
.DEFINE Timer0 $FA
.DEFINE Counter0 $FD
.DEFINE DSPA $f2
.DEFINE DSPD $f3
	
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

Voice1:
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

Voice2:
	.db 70, 68, 66, 65, 66, 65
	.db 63, $ff, $ff, $ff, $ff, $ff
	.db 70, 68, 66, 65, 66, 65
	.db 63, $ff, $ff, 68, $ff, 66
	
	.db 70, $ff, $ff, $ff, $ff, $ff
	.db $ff, $ff, $ff, $ff, $ff, $ff
	.db $ff, $ff, $ff, $ff, $ff, $ff
	.db $ff, $ff, $ff, $ff, $ff, $ff

	.db 70, 63, 65, 70, $ff, $ff
	.db 70, 63, 65, 70, $ff, $ff
	.db 70, 63, 65, 70, 63, 65
	.db 70, 63, 65, 70, 63, 65

	.db 70, 63, 65, 70, $ff, $ff
	.db 70, 63, 65, 70, $ff, $ff
	.db 70, 63, 65, 70, 63, 65
	.db 70, 63, 65, 70, 63, 65	

	.db 70, 63, 65, 70, $ff, $ff
	.db 70, 63, 65, 70, $ff, $ff
	.db 70, 63, 65, 70, 63, 65
	.db 70, 63, 65, 70, 63, 65

	.db 70, 63, 65, 70, $ff, $ff
	.db 70, 63, 65, 70, $ff, $ff
	.db 70, 63, 65, 70, 63, 65
	.db 70, 63, 65, 70, 63, 65	

	.db $fe

ZeroPageInit:
	.dw MidiNotes		; MidiNotesPointer
	.dw Voice1, Voice2	; VoiceVector
ZeroPageInitEnd:
	
	;; these are the counter values we use to essentially derive
	;; beats per minute
	;; these should be per-voice but for now it's per-song
.DEFINE NoteOffSleep ($443 / 2)
.DEFINE NoteOnSleep ($443 / 2)
	
.DEFINE MidiNotesPointer $00
.DEFINE VoiceVector $02
.DEFINE VoiceVectorEnd $06
.DEFINE VoiceIndexVector $06
.DEFINE NoteDescPointer $0a
.DEFINE ScratchNoteAddress $0c
.DEFINE KeyScratch $0e
.DEFINE KeyFlag $0f
.DEFINE SleepCounter $10
	
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

	;; set left/right volume of channel 1
	WriteDSP VOLL1 $7F
	WriteDSP VOLR1 $7F

	;; set up ADSR for channel 0, just disable it, use gain instead
	WriteDSP ADSR10 $00
	WriteDSP ADSR20 $00
	
	WriteDSP ADSR11 $00
	WriteDSP ADSR21 $00

	;; set up GAIN for channel 0
	WriteDSP GAIN0 $1F
	WriteDSP GAIN1 $1F

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

	;; init zero page
	;; NB: we have to do this since we don't load the zero page from the ROM
	;; into the SPC memory when the SNES loads this program
	mov x, #0
-:	
	mov a, !ZeroPageInit+x
	mov (x)+, a
	cmp x, #(ZeroPageInitEnd - ZeroPageInit)
	bne -

SongLoop:
	;; start at note-off period

	;; iterate through voices
	mov x, #0
	mov KeyScratch, #0
	mov KeyFlag, #1
	
VoicesLoop1:
	call !GetVoiceNote

	;; don't do anything
	cmp a, #$ff
	beq DoneIter

	;; voice is over, reset VoiceIndexVector = 0
	cmp a, #$fe
	bne +

	mov a, #0
	mov VoiceIndexVector + x, a
	mov (VoiceIndexVector + 1) + x, a
	bra VoicesLoop1
	
+:	
	or KeyScratch, KeyFlag
	
DoneIter:
	asl KeyFlag
	inc x
	inc x	
	
	cmp x, #(VoiceVectorEnd - VoiceVector)
	bne VoicesLoop1

	;; set note off
	mov a, KeyScratch
	WriteDSPA KOF

	;; sleep for note-off period
	mov y, #(NoteOffSleep >> 8)
	mov a, #(NoteOffSleep & $ff)
	call !SleepTimer

	;; now we're at the note-on period
	WriteDSP KOF $00

	;; iterate through voices
	mov x, #0
	mov KeyScratch, #0
	mov KeyFlag, #1

VoicesLoop2:
	;; get note
	call !GetVoiceNote

	;; don't do anything
	cmp a, #0
	beq Next2
	cmp a, #$ff
	beq Next2

	;;  get note offset & save to memory
	mov y, #3
	mul ya
	addw ya, MidiNotesPointer
	movw NoteDescPointer, ya

	;; load P and SRC values
	mov a, x
	lsr a
	or a, #$20
	xcn a
	mov DSPA, a

	;; load pl
	mov y, #1
	mov a, [NoteDescPointer]+y
	mov DSPD, a

	;; load ph
	inc DSPA
	mov y, #2
	mov a, [NoteDescPointer]+y
	mov DSPD, a		

	;; load SRCN
	inc DSPA	
	mov y, #$0
	mov a, [NoteDescPointer]+y
	mov DSPD, a

	;; set note on
	or KeyScratch, KeyFlag

Next2:
	;; increment voice index (16-bit)
	mov a, VoiceIndexVector + x
	clrc
	adc a, #1
	mov VoiceIndexVector + x, a
	mov a, (VoiceIndexVector + 1) + x
	adc a, #0
	mov (VoiceIndexVector + 1) + x, a
	
	asl KeyFlag
	inc x
	inc x

	cmp x, #(VoiceVectorEnd - VoiceVector)
	bne VoicesLoop2

	;; actually turn note on
	mov a, KeyScratch
	WriteDSPA KON
	
	;; Sleep for note-on period
	mov y, #(NoteOnSleep >> 8)
	mov a, #(NoteOnSleep & $ff)
	call !SleepTimer

	jmp !SongLoop

	;; pass byte offset of voice in X
	;; Y,A mutated
GetVoiceNote:
	;; load the voice address into constant DP address
	mov a, (VoiceVector + 1) + x
	mov y, a
	mov a, VoiceVector + x
	movw ScratchNoteAddress, ya

	;; load the current voice index and add to voice base
	mov a, (VoiceIndexVector + 1) + x
	mov y, a
	mov a, VoiceIndexVector + x
	addw ya, ScratchNoteAddress
	movw ScratchNoteAddress, ya
	
	mov y, #0
	mov a, [ScratchNoteAddress]+y
	
	ret
	
	;; pass 16-bit counter value in Y:A
	;; Y,A mutated
SleepTimer:
	cmp y, #0
	beq PostSleepLoop

	;; save a
	push a

SleepLoop:	
	mov Control, #$00	; disable timers	
	mov Timer0, #0
	mov Control, #$01	; start timer0
-:	
	mov a, Counter0
	beq -
	dec y
	bne SleepLoop

	pop a

	cmp a, #00
	beq Done
	
PostSleepLoop:
	mov Control, #0
	mov Timer0, a
	mov Control, #1
-:	
	mov a, Counter0
	beq -

Done:
	ret
	

	
