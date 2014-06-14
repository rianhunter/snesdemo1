;; == Include memorymap, header info, and SNES initialization routines
.INCLUDE "header.inc"
.INCLUDE "InitSNES.asm"

;; ========================
;;  Start
;; ========================

.DEFINE SCREEN_MODE_REGISTER $2105
.DEFINE BG1_TILE_MAP_LOCATION_REGISTER $2107
.DEFINE BG3_TILE_MAP_LOCATION_REGISTER $2109
.DEFINE BG1_VERTICAL_SCROLL_REGISTER $210E
.DEFINE BG1_BG2_CHARACTER_LOCATION_REGISTER $210B
.DEFINE MAIN_SCREEN_DESIGNATION_REGISTER $212C
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

.BANK 1 SLOT 0
.ORG 0
.SECTION "TileData"        
.INCLUDE "tiledata.inc"
.ENDS        

.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

.EQU g_palette_offset $0000
.EQU g_pixelate_counter $0002

PaletteData:
.INCLUDE "palettedata.inc"
EndPaletteData:        
        
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
        
        ;; okay first set up the palette data
        stz CGRAM_ADDRESS_REGISTER
        ldx #PaletteData                ; run loop 32 times
LoadPaletteLoop:
        lda $00,X
        sta CGRAM_DATA_WRITE_REGISTER
        inx
        cpx #EndPaletteData
        bne LoadPaletteLoop
        
        ;; write out tile data
        LoadBlockToVRAM TileData, $0000, (EndTileData - TileData)

        ;; tile map (at nearest multiple of $400 after TileData)
        LoadBlockToVRAM TileMap, (((($0000 + (EndTileData - TileData)) >> 10) + 1) << 10), (EndTileMap - TileMap)

        ;; set location of tile data (character) in VRAM
        ;; our tile data is at *word* address 0 in VRAM
        stz BG1_BG2_CHARACTER_LOCATION_REGISTER

        ;; set tile map data location for BG1 in VRAM
        ;; our tile map data is at *word* address 0x3800 in VRAM
        lda #((((($0000 + (EndTileData - TileData)) >> 10) + 1) << 10) >> 8)
        sta BG1_TILE_MAP_LOCATION_REGISTER
        
        ;; we're using mode 2 with 1 BG, 16 color (4-bits per pixel) tiles
        lda #%00000011
        sta SCREEN_MODE_REGISTER

        ;; set screen to only show BG1 (no sprites, no other BGs)
        lda #%00000001
        sta MAIN_SCREEN_DESIGNATION_REGISTER

        ;; vertically scroll the background up by 255 (32 * 8 - 1) pixels
        ;; (since it's starts one pixel up)
        ;; then also scroll 16 pixesl up, 255 + 16 = 0x10f
        lda #$0f
        sta BG1_VERTICAL_SCROLL_REGISTER
        lda #$01
        sta BG1_VERTICAL_SCROLL_REGISTER
        
        ;; Turn on screen, full brightness
        lda #$0F
        sta $2100

        stz g_pixelate_counter

        ;; nullify palette offset
        ldx #PaletteData
        stx g_palette_offset

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

        ;; increment palette offset (by 2)
        ldx g_palette_offset
        inx
        inx
        ;; if palette offset == EndPaletteData, then reset to PaletteData
        cpx #EndPaletteData
        bne Not512
        ldx #PaletteData
Not512:
        stx g_palette_offset

        ;; write out new palette
        stz CGRAM_ADDRESS_REGISTER

        ;; first move everything from the offset to the end
        ;; to the beginning of cgram
        bra LoadPaletteLoop2Pre
LoadPaletteLoop2:
        lda $00,X
        sta CGRAM_DATA_WRITE_REGISTER
        inx
LoadPaletteLoop2Pre:
        cpx #EndPaletteData
        bne LoadPaletteLoop2

        ;; the move everything from the beginning to the offset
        ;; to the rest of cgram
        ldx #PaletteData
        bra LoadPaletteLoop3Pre
LoadPaletteLoop3:
        lda $00,X
        sta CGRAM_DATA_WRITE_REGISTER
        inx
LoadPaletteLoop3Pre:
        cpx g_palette_offset
        bne LoadPaletteLoop3

        ;; check joypad to see if we should rotate
        ;; the pixelation register

        ;; check if joypad is connected
        lda JOYSER0_REGISTER
        beq exit_vblank

        ;; wait for joypad to be ready to read from
WaitForJoyPad:
        lda HVBJOY_REGISTER
        and #$01
        bne WaitForJoyPad

        ;; check if any button is pressed
        lda JOY1L_REGISTER
        ora JOY1H_REGISTER
        beq exit_vblank

        ;; okay we controller is pressed
        ;; let's change the pixelate value

        ;; allocate local variable
        pha

        inc g_pixelate_counter

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

exit_vblank:
        ;; this clears the NMI flag
        ;; NB: this is not strictly necessary as long as long
        ;;     as we don't toggle $4200 (COUNTER_ENABLE_REGISTR)
        lda READ_NMI_REGISTER
        rti
.ENDS