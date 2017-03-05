module Waterfoul
  module IO
    class LCDControl
      LCDC_MEM_LOC = 0xFF40

      class << self
        # screen on/off
        def screen_enabled?
          lcdc & 0x80 == 0x80
        end

        # map select index
        def window_map_select
          lcdc & 0x40 == 0x40 ? 1 : 0
        end

        # window show/hide
        def window_enabled?
          lcdc & 0x20 == 0x20 ? true : false
        end

        # BG Window map tile data
        def bg_tile_select
          lcdc & 0x10 == 0x10 ? 0x8000 : 0x8800
        end

        # BG map tile data
        def bg_map_select
          lcdc & 0x8 == 0x8 ? 0x9C00 : 0x9800
        end

        def obj_size
          lcdc & 0x4 == 0x4 ? 16 : 8
        end

        def obj_display
          lcdc & 0x2 == 0x2 ? true : false
        end

        def bg_display
          lcdc & 0x1 == 0x1 ? true : false
        end

        private

        def lcdc
          $mmu.read_memory_byte LCDC_MEM_LOC
        end
      end
    end
  end
end
