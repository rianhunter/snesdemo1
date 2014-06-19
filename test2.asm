;; == Include memorymap, header info, and SNES initialization routines
.INCLUDE "header.inc"
.INCLUDE "InitSNES.asm"

;; ========================
;;  Start
;; ========================

.DEFINE SCREEN_MODE_REGISTER $2105
.DEFINE BG1_TILE_MAP_LOCATION_REGISTER $2107
.DEFINE BG2_TILE_MAP_LOCATION_REGISTER $2108
.DEFINE BG3_TILE_MAP_LOCATION_REGISTER $2109
.DEFINE BG1_VERTICAL_SCROLL_REGISTER $210E
.DEFINE BG2_VERTICAL_SCROLL_REGISTER $2110
.DEFINE BG1_BG2_CHARACTER_LOCATION_REGISTER $210B
.DEFINE MAIN_SCREEN_DESIGNATION_REGISTER $212C
.DEFINE SUB_SCREEN_DESIGNATION_REGISTER $212D
.DEFINE CGRAM_ADDRESS_REGISTER $2121        
.DEFINE CGRAM_DATA_WRITE_REGISTER $2122
.DEFINE VRAM_ADDRESS_REGISTER $2116
.DEFINE VRAM_DATA_WRITE_REGISTER $2118
.DEFINE VIDEO_PORT_CONTROL_REGISTER $2115
.DEFINE COUNTER_ENABLE_REGISTER $4200
.DEFINE READ_NMI_REGISTER $4210
.DEFINE JOYSER0_REGISTER $4016
.DEFINE JOY1L_REGISTER $4218
.DEFINE JOY1H_REGISTER $4219
.DEFINE HVBJOY_REGISTER $4212
.DEFINE MOSAIC_REGISTER $2106
.DEFINE SCREEN_DISPLAY_REGISTER $2100
.DEFINE CGWSEL_REGISTER $2130
.DEFINE CGADSUB_REGISTER $2131

.BANK 1 SLOT 0
.ORG 0
.SECTION "TileData"        
.INCLUDE "tiledata.inc"
.ENDS        

.BANK 2 SLOT 0
.ORG 0
.SECTION "PaletteData"
PaletteData:
.INCLUDE "palettedata.inc"
.ENDS

.BANK 3 SLOT 0
.ORG 0
.SECTION "SplashTileData"
SplashTileData:
.INCLUDE "splashtiledata.inc"
EndSplashTileData:
InvSplashTileData:
.INCLUDE "invsplashtiledata.inc"
EndInvSplashTileData:
SplashTileMap:
.INCLUDE "splashtilemap.inc"
EndSplashTileMap:
.ENDS

.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

.EQU g_palette_offset $0000
.EQU g_palette_select $0001
.EQU g_pixelate_counter $0002
.EQU g_fade_counter $0003
.EQU g_fade_temp $0004
.EQU g_fade_temp_hi $0005

        ;; ============================================================================
        ;; LoadPalette - Macro that loads palette information into CGRAM
        ;; ----------------------------------------------------------------------------
        ;;  In: SRC_ADDR -- 24 bit address of source data,
        ;;      START -- Color # to start on,
        ;;      SIZE -- # of COLORS to copy
        ;; ----------------------------------------------------------------------------
        ;;  Out: None
        ;; ----------------------------------------------------------------------------
        ;;  Modifies: A,X
        ;;  Requires: mem/A = 8 bit, X/Y = 16 bit
        ;; ----------------------------------------------------------------------------
        .MACRO LoadPalette
            lda #\2
            sta $2121           ; Start at START color
            lda #:\1            ; Using : before the parameter gets its bank.
            ldx #\1             ; Not using : gets the offset address.
            ldy #(\3 * 2)       ; 2 bytes for every color
            jsr DMAPalette
        .ENDM

        ;; ============================================================================
        ;;  DMAPalette -- Load entire palette using DMA
        ;; ----------------------------------------------------------------------------
        ;;  In: A:X  -- points to the data
        ;;       Y   -- Size of data
        ;; ----------------------------------------------------------------------------
        ;;  Out: None
        ;; ----------------------------------------------------------------------------
        ;;  Modifies: none
        ;; ----------------------------------------------------------------------------
DMAPalette:
            phb
            php                 ; Preserve Registers

            stx $4302           ; Store data offset into DMA source offset
            sta $4304           ; Store data bank into DMA source bank
            sty $4305           ; Store size of data block

            stz $4300           ; Set DMA Mode (byte, normal increment)
            lda #$22            ; Set destination register ($2122 - CGRAM Write)
            sta $4301
            lda #$01            ; Initiate DMA transfer
            sta $420B

            plp
            plb
            rts                 ; return from subroutine
        
        ;; ============================================================================
        ;;  LoadBlockToVRAM -- Macro that simplifies calling LoadVRAM to copy data to VRAM
        ;; ----------------------------------------------------------------------------
        ;;  In: SRC_ADDR -- 24 bit address of source data
        ;;      DEST -- VRAM address to write to (WORD address!!)
        ;;      SIZE -- number of BYTEs to copy
        ;; ----------------------------------------------------------------------------
        ;;  Out: None
        ;; ----------------------------------------------------------------------------
        ;;  Modifies: A, X, Y
        ;; ----------------------------------------------------------------------------

        ;; LoadBlockToVRAM SRC_ADDRESS, DEST, SIZE
        ;;    requires:  mem/A = 8 bit, X/Y = 16 bit
        .MACRO LoadBlockToVRAM
            lda #$80
            sta $2115
            ldx #\2             ; DEST
            stx $2116           ; $2116: Word address for accessing VRAM.
            lda #:\1            ; SRCBANK
            ldx #\1             ; SRCOFFSET
            ldy #\3             ; SIZE
            jsr LoadVRAM
        .ENDM
        

        ;; ============================================================================
        ;;  LoadVRAM -- Load data into VRAM
        ;; ----------------------------------------------------------------------------
        ;;  In: A:X  -- points to the data
        ;;      Y     -- Number of bytes to copy (0 to 65535)  (assumes 16-bit index)
        ;; ----------------------------------------------------------------------------
        ;;  Out: None
        ;; ----------------------------------------------------------------------------
        ;;  Modifies: none
        ;; ----------------------------------------------------------------------------
        ;;  Notes:  Assumes VRAM address has been previously set!!
        ;; ----------------------------------------------------------------------------
LoadVRAM:
            php                 ; Preserve Registers

            stx $4302           ; Store Data offset into DMA source offset
            sta $4304           ; Store data Bank into DMA source bank
            sty $4305           ; Store size of data block

            lda #$01
            sta $4300           ; Set DMA mode (word, normal increment)
            lda #$18            ; Set the destination register (VRAM write register)
            sta $4301
            lda #$01            ; Initiate DMA transfer (channel 1)
            sta $420B

            plp                 ; restore registers
            rts                 ; return
        ;; ============================================================================
        
Start:
        ;; setup stack, initialize external hardware
        InitializeSNES

        ;; mem/A = 8 bit, X/Y = 16 bit
        REP #$10
        SEP #$20

        ;; TODO: initialize palette?
        
        ;; write out tile data
        LoadBlockToVRAM TileData, $0000, (EndTileData - TileData)

        ;; tile map (at nearest multiple of $400 after TileData)
        LoadBlockToVRAM TileMap, (((($0000 + (EndTileData - TileData)) >> 10) + 1) << 10), (EndTileMap - TileMap)

        ;; write out splash tile data
        LoadBlockToVRAM SplashTileData, $1000, (EndSplashTileData - SplashTileData)
        LoadBlockToVRAM InvSplashTileData, $2000, (EndInvSplashTileData - InvSplashTileData)
        LoadBlockToVRAM SplashTileMap, $3000, (EndSplashTileMap - SplashTileMap)

        ;; set location of tile data (character) in VRAM
        ;; our BG1 tile data is at *word* address 0 in VRAM
        ;; our BG2 tile data is at *word* address 0x1000 in VRAM
        lda #%00010000
        sta BG1_BG2_CHARACTER_LOCATION_REGISTER

        ;; set tile map data location for BG1 in VRAM
        ;; our tile map data is at *word* address 0x3800 in VRAM
        lda #((((($0000 + (EndTileData - TileData)) >> 10) + 1) << 10) >> 8)
        sta BG1_TILE_MAP_LOCATION_REGISTER

        ;; set tile map location for BG2
        lda #$30
        sta BG2_TILE_MAP_LOCATION_REGISTER

        ;; we're using mode 3 with 1 BG, 256 color (8-bits per pixel) tiles
        lda #%00000011
        sta SCREEN_MODE_REGISTER

        ;; set main screen to show BG1
        lda #%00000001
        sta MAIN_SCREEN_DESIGNATION_REGISTER

        ;; set sub screen to show BG2
        lda #%00000010
        sta SUB_SCREEN_DESIGNATION_REGISTER

        ;; enable sub screen color add/sub
        lda #$02
        sta CGWSEL_REGISTER

        ;; set color add/sub on bg1 and backdrop
        lda #%00100001
        sta CGADSUB_REGISTER

        ;; vertically scroll the background up by 255 (32 * 8 - 1) pixels
        ;; (since it's starts one pixel up)
        ;; then also scroll 16 pixesl up, 255 + 16 = 0x10f
        lda #$0f
        sta BG1_VERTICAL_SCROLL_REGISTER
        lda #$01
        sta BG1_VERTICAL_SCROLL_REGISTER

        ;; scroll BG2 down 1 pixel, this is 32 * 8 - 1 = 255
        lda #$ff
        sta BG2_VERTICAL_SCROLL_REGISTER
        lda #$00
        sta BG2_VERTICAL_SCROLL_REGISTER

        ;; Turn on screen, full brightness
        lda #$0F
        sta SCREEN_DISPLAY_REGISTER

        ;; nullify initial state
        stz g_pixelate_counter
        stz g_palette_offset
        stz g_palette_select
        stz g_fade_temp
        stz g_fade_temp_hi

        ;; write $0 to $4016 so we can use it
        ;; to detect if the controller is connected
        ;; otherwise the values read are random
        stz JOYSER0_REGISTER

        ;;  enable nmi v-blank
        ;;  and joypad
        lda #%10000001
        sta COUNTER_ENABLE_REGISTER

        ;; loop forever
forever:
        ;; wait for vblank
        wai
        jmp forever

VBlank:
        ;; this is basically our redraw method
        ;; a vblank occurs every frame
        ;; in non-interlace mode on NTSC this is on average
        ;; (262 * 1364 * (1/21.477MHz)) + ((261 * 1364 + 1360) * (1/21.477MHz))
        ;; / 2
        ;; (1/21.477Mhz) * (1364 * (262 + 261) + 1360) / 2
        ;; => ~0.016639474786981422 seconds
        ;; => ~60.098Hz
        ;; under same conditions without overscan, vblank is trigged on scanline 225
        ;; this leaves us on average
        ;; ((262 - 225 - 1) * 1364 + (1364 + 1360) / 2)
        ;; => 50466 cycles to run

        ;; 8 bit A, 16 bit X,Y
        rep #$10
        sep #$20

        ;; wait for joypad to be ready to read from
WaitForJoyPad:
        lda HVBJOY_REGISTER
        and #$01
        bne WaitForJoyPad

        ;; check if joypad is connected
        lda JOYSER0_REGISTER
        beq exit_vblank

CheckPixelate:
        ;; check if the 'b' button was pressed
        lda JOY1H_REGISTER
        and #$80
        beq CheckPaletteSwap

        ;; let's change the pixelate value
        inc g_pixelate_counter

        ;; allocate local variable
        pha

        lda g_pixelate_counter
        and #$80
        beq Store
        ;; compute 15 - X = 15 + (~X + 1) = 16 + ~X = ~X, X = xxxx0000 (g_palette_offset)
        lda #$FF
Store:
        sta $01, S

        lda g_pixelate_counter
        asl a
        eor $01, S
        and #$F0
        ora #$01
        sta MOSAIC_REGISTER

        ;; deallocate local variable
        pla

CheckPaletteSwap:
        ;; check if the 'a' button was pressed
        lda JOY1L_REGISTER
        and #$80
        beq CheckPaletteRotate

        ;; swap palette
        inc g_palette_select

CheckPaletteRotate:
        ;; check if the 'b' button was pressed
        lda JOY1H_REGISTER
        and #$40
        beq CheckFadeCredits

        ;; increment palette offset (0 -> 255 -> 0)
        inc g_palette_offset

CheckFadeCredits:
        ;; check if the 'x' button was pressed
        lda JOY1L_REGISTER
        and #$40
        beq exit_vblank

        inc g_fade_counter

exit_vblank:
        ;; put a,x,y in 16-bit mode
        rep #$30

        ;; compute PaletteData + g_palette_select * 512
        lda g_palette_select
        lsr
        lsr
        and #$003F              ; only use lower 6-bits (we only have 64 palettes)
        ;; shift left 9 times (multiply by 512)
        asl
        asl
        asl
        asl
        asl
        asl
        asl
        asl
        asl
        clc
        adc #PaletteData
        tax

        ;; put a register back in 8 bits
        REP #$10
        SEP #$20

        ;; write out new palette
        ;; NB: use DMA to cut down on CPU cycles

        ;; start at g_palette_offset color address (will loop around)
        lda g_palette_offset
        sta CGRAM_ADDRESS_REGISTER
        lda #:PaletteData
        ldy #512
        jsr DMAPalette

        ;; write out color addition as computed from g_fade_counter

        ;; reserve space to compute color addition
        pha

        ;; figure out if we're fading in or out
        ;; g_fade_counter: msb: if43210x
        ;; i: use inverted splash screen or not
        ;; f: 0: fade in, 1: fade out
        lda g_fade_counter
        and #$40
        beq NoXor
        lda #$ff
NoXor:
        sta $1, S

        lda g_fade_counter
        eor $1, S
        lsr
        and #$1F
        sta g_fade_temp
        stz g_fade_temp_hi

        pla

        ;; switch palette if i bit has changed
        lda g_fade_counter
        and #$7e
        bne NoSwitch

        lda g_fade_counter
        and #$80
        beq LoadSplash

        lda #%00100000
        sta BG1_BG2_CHARACTER_LOCATION_REGISTER
        bra NoSwitch
LoadSplash:
        ;; TODO: switch tile data location of bg2
        lda #%00010000
        sta BG1_BG2_CHARACTER_LOCATION_REGISTER

NoSwitch:
        ;; g_fade_temp contains 5 counting bits, use them to
        ;; build the addition color
        rep #$30

        lda g_fade_temp
        asl
        asl
        asl
        asl
        asl
        ora g_fade_temp
        asl
        asl
        asl
        asl
        asl
        ora g_fade_temp
        sta g_fade_temp

        REP #$10
        SEP #$20

        ;; write our color addition at palette index 1,
        ;; NB: color index 1 is unused by our cycling background

        lda #$01
        sta CGRAM_ADDRESS_REGISTER
        lda g_fade_temp
        sta CGRAM_DATA_WRITE_REGISTER
        lda g_fade_temp_hi
        sta CGRAM_DATA_WRITE_REGISTER

        ;; this clears the NMI flag
        ;; NB: this is not strictly necessary as long as long
        ;;     as we don't toggle $4200 (COUNTER_ENABLE_REGISTR)
        lda READ_NMI_REGISTER
        rti
.ENDS