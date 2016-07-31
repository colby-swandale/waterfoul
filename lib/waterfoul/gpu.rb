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
    end

    def update_stat_mode
      stat = $mmu.read_byte 0xFF41
      new_stat = (stat & 0xFC) | (@mode & 0x3)
      $mmu.write_byte 0xFF41, new_stat
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
