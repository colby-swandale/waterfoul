module Waterfoul
  module Render
    class Background
      class << self
        def render
          line = current_line
          line_width = line * SCREEN_WIDTH

          if IO::LCDControl.bg_display
            # tile and map select
            tiles_select = IO::LCDControl.bg_tile_select
            map_select = IO::LCDControl.bg_map_select
            # x pixel offset
            scx = $mmu.read_byte 0xFF43
            # y pixel offset
            scy = $mmu.read_byte 0xFF42
            # adjusted line with y offset
            line_adjusted = line + scy
            # get position of tile row to read
            y_offset = (line_adjusted / 8) * 32
            # relative line number in tile
            tile_line = line_adjusted % 8
            # relative line number offset
            tile_line_offset = tile_line * 2

            0.upto(31) do |x|
              tile = 0
              if tiles_select == 0x8800
                tile = signed_value $mmu.read_byte(map_select + y_offset + x)
                tile += 128
              else
                tile = $mmu.read_byte map_select + y_offset + x
              end

              line_pixel_offset = x * 8
              tile_select_offset = tile * 16
              tile_address = tiles_select + tile_select_offset + tile_line_offset

              byte_1 = $mmu.read_byte tile_address
              byte_2 = $mmu.read_byte (tile_address + 1)

              0.upto(7) do |pixelx|
                buffer_addr = (line_pixel_offset + pixelx - scx)

                next if (buffer_addr >= SCREEN_WIDTH)

                pixel = (byte_1 & (0x1 << (7 - pixelx)) > 0) ? 1 : 0
                pixel |= (byte_2 & (0x1 << (7 - pixelx)) > 0) ? 2 : 0
                position = line_width + buffer_addr
                palette = $mmu.read_byte 0xFF47
                color = (palette >> (pixel * 2)) & 0x3

                @framebuffer[position] = color
              end
            end
          else
            0.upto(SCREEN_WIDTH) do |i|
              @framebuffer[line_width + i] = 0
            end
          end
        end
      end
    end
  end
end
