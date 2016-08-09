require 'waterfoul/io/lcd_control'

module Waterfoul
  class GPU
    include Helper

    attr_accessor :mode
    attr_accessor :modeclock
    attr_reader :framebuffer

    FRAMEBUFFER_SIZE = (Screen::SCREEN_WIDTH - 1) * (Screen::SCREEN_HEIGHT - 1)

    H_BLANK_STATE     = 0
    V_BLANK_STATE     = 1
    OAM_READ_STATE    = 2
    VMRAM_READ_STATE  = 3

    OAM_SCANLINE_TIME   = 80
    VRAM_SCANLINE_TIME  = 172
    H_BLANK_TIME        = 204
    V_BLANK_TIME        = 4560

    LCDC_Y_COORDINATE_MEM_LOC = 0xFF44

    def initialize
      @framebuffer = Array.new FRAMEBUFFER_SIZE, 0
      @mode = V_BLANK_STATE
      @modeclock = 0
      @vblank_line = 0
      @auxillary_modeclock = 0
      @screen_enabled = true
      @window_line = 0
    end

    def step(cycles = 1)
      @vblank = false
      @modeclock += cycles
      @auxillary_modeclock += cycles

      if IO::LCDControl.screen_enabled? && @screen_enabled
        case @mode
        when H_BLANK_STATE
          hblank if @modeclock >= H_BLANK_TIME
        when V_BLANK_STATE
          vblank
        when OAM_READ_STATE
          oam if @modeclock >= OAM_SCANLINE_TIME
        when VMRAM_READ_STATE
          vram if @modeclock >= VRAM_SCANLINE_TIME
        end
      else
        if IO::LCDControl.screen_enabled?
          @screen_enabled = true
          @modeclock = 0
          @mode = 0
          @auxillary_modeclock = 0
          @window_line = 0
          reset_current_line
          update_stat_mode
          compare_lylc
        else
          @screen_enabled = false
        end
      end
    end

    def vblank?
      @vblank
    end

    private

    def vram
      @modeclock -= VRAM_SCANLINE_TIME
      @mode = H_BLANK_STATE
      scanline
      update_stat_mode
    end

    def oam
      @modeclock -= OAM_SCANLINE_TIME
      @scanline_transfered = false
      @mode = VMRAM_READ_STATE
      update_stat_mode
    end

    def hblank
      @modeclock -= H_BLANK_TIME
      @mode = OAM_READ_STATE
      next_line
      compare_lylc

      if current_line == 144
        @mode = V_BLANK_STATE
        @auxillary_modeclock = @modeclock
        @vblank = true
        @window_line = 0
        Interrupt.request_interrupt(Interrupt::INTERRUPT_VBLANK)
      end

      update_stat_mode
    end

    def vblank
      if @auxillary_modeclock >= 456
        @auxillary_modeclock -= 456
        @vblank_line += 1

        if @vblank_line <= 9
          next_line
          compare_lylc
        end
      end

      if @modeclock >= V_BLANK_TIME
        @modeclock -= V_BLANK_TIME
        @mode = OAM_READ_STATE
        update_stat_mode
        reset_current_line
        @vblank_line = 0
      end
    end

    def scanline
      render_bg
      render_window
      render_sprites
    end

    def update_stat_mode
      stat = $mmu.read_byte 0xFF41
      new_stat = (stat & 0xFC) | (@mode & 0x3)
      $mmu.write_byte 0xFF41, new_stat
    end

    def render_window
      line = current_line
      line_width = line * Screen::SCREEN_WIDTH
      # dont render if the window is outside the bounds of the screen or
      # if the LCDC window enable bit flag is not set
      return if @window_line > 143 || !IO::LCDControl.window_enabled?

      window_pos_x = $mmu.read_byte(0xFF4B) - 7
      window_pos_y = $mmu.read_byte(0xFF4A)

      # don't render if the window is outside the bounds of the screen
      return if window_pos_x > 159 || window_pos_y > 143 || window_pos_y > line

      map_select = IO::LCDControl.window_map_select
      tiles_select = IO::LCDControl.bg_tile_select

      line_adjusted = @window_line
      y_offset = (line_adjusted / 8) * 32
      tile_line = line_adjusted % 8
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
          buffer_addr = line_pixel_offset + pixelx + window_pos_x

          next if buffer_addr < 0 || buffer_addr >= SCREEN_WIDTH

          shift = 0x1 << (7 - pixelx)

          pixel = 0
          if (byte_1 & shift == shift) && (byte_2 & shift == shift)
            pixel = 3
          elsif (byte_1 & shift == 0x0) && (byte_2 & shift == shift)
            pixel = 1
          elsif (byte_1 & shift == shift) && (byte_2 & shift == 0x0)
            pixel = 2
          elsif (byte_1 & shift == 0x0) && (byte_2 & shift == 0x00)
            pixel = 0
          end

          position = line_width + buffer_addr
          @framebuffer[position] = pixel
        end
      end
      @window_line += 1
    end

    def render_sprites
      line = current_line
      line_width = line * Screen::SCREEN_WIDTH

      return unless IO::LCDControl.obj_display

      sprite_size = IO::LCDControl.obj_size

      39.downto(0) do |sprite|
        sprite_offset = sprite * 4

        sprite_y = $mmu.read_byte(0xFE00 + sprite_offset) - 16
        next if sprite_y > line || (sprite_y + sprite_size) <= line

        sprite_x = $mmu.read_byte(0xFE00 + sprite_offset + 1) - 8
        next if sprite_x < -7 || sprite_x >= SCREEN_WIDTH

        sprite_tile_offset = ($mmu.read_byte(0xFE00 + sprite_offset + 2) & (sprite_size == 16 ? 0xFE : 0xFF)) * 16
        sprite_flags = $mmu.read_byte(0xFE00 + sprite_offset + 3)
        x_flip = sprite_flags & 0x20 == 0x20 ? true : false
        y_flip = sprite_flags & 0x40 == 0x40 ? true : false
        #above_bg = sprite_flags & 0x80 == 0x80 ? true : false

        tiles = 0x8000
        pixel_y = y_flip ? (sprite_size == 16 ? 15 : 7) - (line - sprite_y) : line - sprite_y

        pixel_y_2 = 0
        offset = 0

        if sprite_size == 16 && (pixel_y >= 8)
          pixel_y_2 = (pixel_y - 8) * 2
          offset = 16
        else
          pixel_y_2 = pixel_y * 2
        end

        tile_address = tiles + sprite_tile_offset + pixel_y_2 + offset

        byte_1 = $mmu.read_byte tile_address
        byte_2 = $mmu.read_byte (tile_address + 1)

        0.upto(7) do |pixelx|
          shift = 0x1 << (x_flip ? pixelx : 7 - pixelx)
          pixel = 0

          if (byte_1 & shift == shift) && (byte_2 & shift == shift)
            pixel = 3
          elsif (byte_1 & shift == 0x0) && (byte_2 & shift == shift)
            pixel = 1
          elsif (byte_1 & shift == shift) && (byte_2 & shift == 0x0)
            pixel = 2
          elsif (byte_1 & shift == 0x0) && (byte_2 & shift == 0x00)
            pixel = 0
          end

          buffer_x = sprite_x + pixelx
          next if buffer_x < 0 || buffer_x >= Screen::SCREEN_WIDTH

          position = line_width + buffer_x

          @framebuffer[position] = pixel
        end
      end
    end

    def render_bg
      line = current_line
      line_width = line * Screen::SCREEN_WIDTH

      if IO::LCDControl.bg_display
        # tile and map select
        tiles_select = IO::LCDControl.bg_tile_select
        map_select = IO::LCDControl.bg_map_select
        # x pixel offset
        scx = $mmu.read_byte 0xFF43
        # y pixel offset
        scy = $mmu.read_byte 0xFF42
        # line with y offset
        line_adjusted = (line + scy) & 0xFF
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
            buffer_addr = line_pixel_offset + pixelx - scx

            next if buffer_addr >= Screen::SCREEN_WIDTH

            pixel = (byte_1 & (0x1 << (7 - pixelx)) > 0) ? 1 : 0
            pixel |= (byte_2 & (0x1 << (7 - pixelx)) > 0) ? 2 : 0
            position = line_width + buffer_addr
            palette = $mmu.read_byte 0xFF47
            color = (palette >> (pixel * 2)) & 0x3

            @framebuffer[position] = color
          end
        end
      else
        0.upto(Screen::SCREEN_WIDTH) do |i|
          @framebuffer[line_width + i] = 0
        end
      end
    end

    def compare_lylc
      if IO::LCDControl.screen_enabled?
        lyc = $mmu.read_byte 0xFF45
        stat = $mmu.read_byte 0xFF41

        if lyc == current_line
          stat = stat | 0x4
        else
          stat = stat & 0xFB
        end
        $mmu.write_byte 0xFF41, stat
      end
    end

    def current_line
      $mmu.read_byte LCDC_Y_COORDINATE_MEM_LOC
    end

    def reset_current_line
      $mmu.write_byte LCDC_Y_COORDINATE_MEM_LOC, 0
    end

    def next_line
      $mmu.write_byte LCDC_Y_COORDINATE_MEM_LOC, current_line + 1
    end
  end
end
