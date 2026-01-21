require 'waterfoul/io/lcd_control'

module Waterfoul
  class PPU
    include Helper

    attr_accessor :mode
    attr_accessor :modeclock
    attr_reader :framebuffer

    FRAMEBUFFER_SIZE = Screen::SCREEN_WIDTH * Screen::SCREEN_HEIGHT

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
      # Store raw color indices (0-3) for BG priority checking
      @bg_color_indices = Array.new FRAMEBUFFER_SIZE, 0
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

      if IO::LCDControl.screen_enabled?
        if @screen_enabled
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
          @screen_enabled = true
          @modeclock = 0
          @mode = 0
          @auxillary_modeclock = 0
          @window_line = 0
          reset_current_line
          update_stat_mode
          compare_lylc
        end
      else
        @screen_enabled = false
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
      stat = $mmu.read_memory_byte 0xFF41
      new_stat = (stat & 0xFC) | (@mode & 0x3)
      $mmu.write_byte 0xFF41, new_stat

      # Request STAT interrupt based on mode and enable bits
      request_stat = false
      case @mode
      when H_BLANK_STATE
        # Mode 0 (H-Blank) - bit 3
        request_stat = (stat & 0x08) != 0
      when V_BLANK_STATE
        # Mode 1 (V-Blank) - bit 4
        request_stat = (stat & 0x10) != 0
      when OAM_READ_STATE
        # Mode 2 (OAM) - bit 5
        request_stat = (stat & 0x20) != 0
      end

      if request_stat
        Interrupt.request_interrupt(Interrupt::INTERRUPT_LCDSTAT)
      end
    end

    def render_window
      line = current_line
      line_width = line * Screen::SCREEN_WIDTH
      # dont render if the window is outside the bounds of the screen or
      # if the LCDC window enable bit flag is not set
      return if @window_line > 143 || !IO::LCDControl.window_enabled?

      window_pos_x = $mmu.read_memory_byte(0xFF4B) - 7
      window_pos_y = $mmu.read_memory_byte(0xFF4A)

      # don't render if the window is outside the bounds of the screen
      return if window_pos_x > 159 || window_pos_y > 143 || window_pos_y > line

      map_select = IO::LCDControl.window_map_select
      tiles_select = IO::LCDControl.bg_tile_select
      palette = $mmu.read_memory_byte 0xFF47

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

          next if buffer_addr < 0 || buffer_addr >= Screen::SCREEN_WIDTH

          shift = 0x1 << (7 - pixelx)

          # Correct pixel calculation: byte_1 = low bit, byte_2 = high bit
          pixel = (byte_1 & shift > 0) ? 1 : 0
          pixel |= (byte_2 & shift > 0) ? 2 : 0

          color = (palette >> (pixel * 2)) & 0x3
          position = line_width + buffer_addr
          @bg_color_indices[position] = pixel  # Store raw index for sprite priority
          @framebuffer[position] = rgb(color)
        end
      end
      @window_line += 1
    end

    def render_sprites
      line = current_line
      line_width = line * Screen::SCREEN_WIDTH

      return unless IO::LCDControl.obj_display

      sprite_size = IO::LCDControl.obj_size
      obp0 = $mmu.read_memory_byte 0xFF48
      obp1 = $mmu.read_memory_byte 0xFF49

      39.downto(0) do |sprite|
        sprite_offset = sprite * 4

        sprite_y = $mmu.read_memory_byte(0xFE00 + sprite_offset) - 16
        next if sprite_y > line || (sprite_y + sprite_size) <= line

        sprite_x = $mmu.read_memory_byte(0xFE00 + sprite_offset + 1) - 8
        next if sprite_x < -7 || sprite_x >= Screen::SCREEN_WIDTH

        sprite_tile_offset = ($mmu.read_memory_byte(0xFE00 + sprite_offset + 2) & (sprite_size == 16 ? 0xFE : 0xFF)) * 16
        sprite_flags = $mmu.read_memory_byte(0xFE00 + sprite_offset + 3)
        x_flip = (sprite_flags & 0x20) != 0
        y_flip = (sprite_flags & 0x40) != 0
        bg_priority = (sprite_flags & 0x80) != 0  # If set, sprite behind BG colors 1-3
        use_obp1 = (sprite_flags & 0x10) != 0     # Palette select

        palette = use_obp1 ? obp1 : obp0
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

          # Correct pixel calculation: byte_1 = low bit, byte_2 = high bit
          pixel = (byte_1 & shift > 0) ? 1 : 0
          pixel |= (byte_2 & shift > 0) ? 2 : 0

          # Color 0 is transparent for sprites
          next if pixel == 0

          buffer_x = sprite_x + pixelx
          next if buffer_x < 0 || buffer_x >= Screen::SCREEN_WIDTH

          position = line_width + buffer_x

          # BG priority: if set, sprite only shows over BG color 0
          if bg_priority && @bg_color_indices[position] != 0
            next
          end

          color = (palette >> (pixel * 2)) & 0x3
          @framebuffer[position] = rgb(color)
        end
      end
    end

    def render_bg
      line = current_line
      line_width = line * Screen::SCREEN_WIDTH

      if IO::LCDControl.bg_display
        tiles_select = IO::LCDControl.bg_tile_select
        map_select = IO::LCDControl.bg_map_select
        scx = $mmu.read_memory_byte 0xFF43
        scy = $mmu.read_memory_byte 0xFF42
        palette = $mmu.read_memory_byte 0xFF47

        # Calculate the Y position in the 256x256 background map
        bg_y = (line + scy) & 0xFF
        tile_row = bg_y / 8
        tile_y = bg_y % 8
        tile_line_offset = tile_y * 2

        # Cache for tile data (avoid re-reading same tile)
        cached_tile_col = -1
        byte_1 = 0
        byte_2 = 0

        # For each pixel on the screen (0-159)
        Screen::SCREEN_WIDTH.times do |screen_x|
          # Calculate the X position in the 256x256 background map (with wrap)
          bg_x = (screen_x + scx) & 0xFF
          tile_col = bg_x / 8
          tile_x = bg_x % 8

          # Only fetch new tile data when we move to a different tile
          if tile_col != cached_tile_col
            cached_tile_col = tile_col
            map_offset = tile_row * 32 + tile_col

            if tiles_select == 0x8800
              tile = signed_value $mmu.read_byte(map_select + map_offset)
              tile += 128
            else
              tile = $mmu.read_byte(map_select + map_offset)
            end

            tile_address = tiles_select + (tile * 16) + tile_line_offset
            byte_1 = $mmu.read_byte tile_address
            byte_2 = $mmu.read_byte(tile_address + 1)
          end

          # Get the pixel color
          shift = 0x1 << (7 - tile_x)
          pixel = (byte_1 & shift > 0) ? 1 : 0
          pixel |= (byte_2 & shift > 0) ? 2 : 0
          color = (palette >> (pixel * 2)) & 0x3

          position = line_width + screen_x
          @bg_color_indices[position] = pixel  # Store raw index for sprite priority
          @framebuffer[position] = rgb(color)
        end
      else
        Screen::SCREEN_WIDTH.times do |i|
          position = line_width + i
          @bg_color_indices[position] = 0
          @framebuffer[position] = 0
        end
      end
    end

    def rgb(color_code)
      case color_code
      when 0
        0xFFFFFFFF
      when 1
        0xFFA8A8A8
      when 2
        0xFF555555
      when 3
        0x00000000
      end
    end

    def compare_lylc
      if IO::LCDControl.screen_enabled?
        lyc = $mmu.read_memory_byte 0xFF45
        stat = $mmu.read_memory_byte 0xFF41

        if lyc == current_line
          # Set coincidence flag (bit 2)
          stat = stat | 0x04
          $mmu.write_byte 0xFF41, stat
          # Request STAT interrupt if LYC interrupt enabled (bit 6)
          if stat & 0x40 != 0
            Interrupt.request_interrupt(Interrupt::INTERRUPT_LCDSTAT)
          end
        else
          stat = stat & 0xFB
          $mmu.write_byte 0xFF41, stat
        end
      end
    end

    def current_line
      $mmu.read_memory_byte LCDC_Y_COORDINATE_MEM_LOC
    end

    def reset_current_line
      $mmu.write_byte LCDC_Y_COORDINATE_MEM_LOC, 0
    end

    def next_line
      $mmu.write_byte LCDC_Y_COORDINATE_MEM_LOC, current_line + 1
    end
  end
end
