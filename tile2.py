import math

NUMBER_COLORS = 256
DIM_X = 32
DIM_Y = 28

def gen_snes_tile_data(number_planes, get_tile_pixel_palette_index):
    if number_planes not in (2, 4, 8): raise NotImplementedError()
    for plane_pattern in xrange(number_planes / 2):
        for tile_row in xrange(8):
            for plane_offset in xrange(2):
                # output byte for this tile row

                plane_number = plane_pattern * 2 + plane_offset

                tile_row_data = 0
                for x in xrange(8):
                    palette_number = get_tile_pixel_palette_index(x, tile_row)
                    relevant_palette_index_bit = (palette_number >> plane_number) & 0x1
                    # MSB is left-most pixel
                    tile_row_data |= relevant_palette_index_bit << (7 - x)

                yield tile_row_data

LOG2_NUMBER_COLORS = math.log(NUMBER_COLORS) / math.log(2)
NUMBER_PLANES = int(LOG2_NUMBER_COLORS)
assert NUMBER_PLANES == LOG2_NUMBER_COLORS, "only works for power of 2 number of colors"

# this is how many xor values are possible from the tile positions
log_2_number_of_types_of_tiles = math.ceil(math.log(max(DIM_X, DIM_Y)) / math.log(2))

# now figure out how many tiles can be produced given the possible number of colors
# tile number occupies the higher bits
number_of_types_of_tiles_given_palette = int(2 ** min(log_2_number_of_types_of_tiles,
                                                      max(0, LOG2_NUMBER_COLORS - 3)))

tiles = {}

# generate all possible tiles
print "TileData:"
for tile_n in xrange(number_of_types_of_tiles_given_palette):
    def tile_pixels_gen(tile_x_coord, tile_y_coord):
        return ((tile_n * 8 + tile_x_coord) ^
                (0 * 8 + tile_y_coord)) % NUMBER_COLORS

    print "        ;; packed format for debug"
    for tile_row in xrange(8):
        print "        ;;",
        for tile_col in xrange(8):
            palette_index = tile_pixels_gen(tile_col, tile_row)
            print "$%x" % (palette_index,),
        print

    for (i, tile_data) in enumerate(gen_snes_tile_data(NUMBER_PLANES, tile_pixels_gen)):
        if not (i % 2):
            print "        .db",
        binary_string = bin(tile_data)[2:]
        print "%%%s%s" % ("0" * (8 - len(binary_string)), binary_string),
        if (i % 2):
            print
        else:
            print ",",
print "EndTileData:"

print "TileMap:"
for tile_y in xrange(DIM_Y):
    print "        .dw",
    print_comma = False
    for tile_x in xrange(DIM_X):
        tile_index = (tile_y ^ tile_x) & int(2 ** max(0, LOG2_NUMBER_COLORS - 3) - 1)
        if print_comma: print ",",
        print "$%x" % (tile_index,),
        print_comma = True
    print
print "EndTileMap:"
