import math
import sys

import png

NUMBER_COLORS = 186
NUMBER_PLANES = int(math.ceil(math.log(NUMBER_COLORS) / math.log(2)))

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


def main(argv):
    DIM_X = 32 * 8
    DIM_Y = 28 * 8

    file_path = argv[1]

    width, height, _image_data, info = png.Reader(file=open(file_path, "rb")).read()
    image_data = list(_image_data)

    if (width, height) != (DIM_X, DIM_Y):
        raise Exception("image is bad size: " + str((data[0], data[1])))

    bitdepth = int(argv[2])

    print_tile_data = True
    print_tile_map = False

    def create_pixel_generator_for_tile(bg_x_coord, bg_y_coord):
        def get_tile_pixel_palette_index(tile_x_coord, tile_y_coord):
            real_x = bg_x_coord * 8 + tile_x_coord
            real_y = bg_y_coord * 8 + tile_y_coord
            return 1 if image_data[real_y][real_x] else 0
        return get_tile_pixel_palette_index

    if print_tile_data:
        for tile_y in xrange(DIM_Y / 8):
            for tile_x in xrange(DIM_X / 8):
                tile_pixels_gen = create_pixel_generator_for_tile(tile_x, tile_y)

                print "        ;; tile data for tile (%d, %d)" % (tile_x, tile_y)
                print "        ;; (first in palette index for debug)"
                for tile_row in xrange(8):
                    print "        ;;",
                    for tile_col in xrange(8):
                        palette_index = tile_pixels_gen(tile_col, tile_row)
                        print "$%x" % (palette_index,),
                    print

                for (i, tile_data) in enumerate(gen_snes_tile_data(bitdepth, tile_pixels_gen)):
                    if not (i % 2):
                        print "        .db",
                    binary_string = bin(tile_data)[2:]
                    print "%%%s%s" % ("0" * (8 - len(binary_string)), binary_string),
                    if (i % 2):
                        print
                    else:
                        print ",",

if __name__ == "__main__":
    sys.exit(main(sys.argv))
