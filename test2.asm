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

.BANK 1 SLOT 0
.ORG 0
.SECTION "TileData"        
.INCLUDE "tiledata.inc"
.ENDS        

.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

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
        lda #$ff
        sta BG1_VERTICAL_SCROLL_REGISTER
        stz BG1_VERTICAL_SCROLL_REGISTER
        
        ;; Turn on screen, full brightness
        lda #$0F
        sta $2100

forever:
        jmp forever

.ENDS