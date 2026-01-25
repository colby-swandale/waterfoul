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

    # Pre-computed bit masks for tile pixels (avoid shift per pixel)
    BIT_MASKS = [0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01].freeze

    # Pre-computed reversed bit masks for x-flipped sprites
    BIT_MASKS_REVERSED = BIT_MASKS.reverse.freeze

    # Pre-computed RGB values (avoid case statement per pixel)
    RGB_COLORS = [0xFFFFFFFF, 0xFFA8A8A8, 0xFF555555, 0x00000000].freeze

    def initialize(gbc_mode: false)
      @gbc_mode = gbc_mode
      @framebuffer = Array.new FRAMEBUFFER_SIZE, 0
      # Store raw color indices (0-3) for BG priority checking
      @bg_color_indices = Array.new FRAMEBUFFER_SIZE, 0
      # Store BG priority flags for GBC mode (bit 7 of tile attributes)
      @bg_priority_flags = Array.new(FRAMEBUFFER_SIZE, false) if @gbc_mode
      @mode = V_BLANK_STATE
      @modeclock = 0
      @vblank_line = 0
      @auxillary_modeclock = 0
      @screen_enabled = true
      @window_line = 0
      # Pre-allocate sprite palette arrays to reduce GC pressure
      @obp0_colors = Array.new(4, 0)
      @obp1_colors = Array.new(4, 0)
      # Pre-allocate sprite scanline cache (which sprites are visible on each line)
      # Each entry is an array of sprite indices that overlap that scanline
      @sprite_scanlines = Array.new(144) { [] }
      @sprite_cache_obj_size_16 = false
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
          # Update sprite cache when screen is re-enabled
          lcdc = $mmu.read_memory_byte(0xFF40)
          update_sprite_cache((lcdc & 0x04) != 0)
        end
      else
        @screen_enabled = false
      end
    end

    def vblank?
      @vblank
    end

    private

    # Update sprite scanline cache at start of each frame
    # Pre-computes which sprites are visible on each scanline to avoid
    # checking all 40 sprites every scanline
    def update_sprite_cache(obj_size_16)
      @sprite_cache_obj_size_16 = obj_size_16
      sprite_height = obj_size_16 ? 16 : 8

      # Clear all scanline lists
      line = 0
      while line < 144
        @sprite_scanlines[line].clear
        line += 1
      end

      # Populate with visible sprites (in reverse order for correct priority)
      sprite = 39
      while sprite >= 0
        sprite_offset = sprite << 2
        sprite_y = $mmu.read_memory_byte(0xFE00 + sprite_offset) - 16

        # Add sprite to all scanlines it overlaps
        scan_line = sprite_y
        end_line = sprite_y + sprite_height
        while scan_line < end_line
          if scan_line >= 0 && scan_line < 144
            @sprite_scanlines[scan_line] << sprite
          end
          scan_line += 1
        end

        sprite -= 1
      end
    end

    def vram
      @modeclock -= VRAM_SCANLINE_TIME
      @mode = H_BLANK_STATE
      scanline
      # Perform HDMA transfer during HBlank (GBC only)
      $mmu.perform_hdma_block if @gbc_mode
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
        # Update sprite cache at start of new frame
        lcdc = $mmu.read_memory_byte(0xFF40)
        update_sprite_cache((lcdc & 0x04) != 0)
      end
    end

    def scanline
      # Cache LCDC register once per scanline (eliminates ~10 MMU reads)
      lcdc = $mmu.read_memory_byte(0xFF40)

      # Extract all LCDC flags locally
      lcdc_bg_enable = (lcdc & 0x01) != 0
      obj_enabled = (lcdc & 0x02) != 0
      obj_size_16 = (lcdc & 0x04) != 0
      bg_tile_select = (lcdc & 0x10) != 0 ? 0x8000 : 0x8800
      bg_map_select = (lcdc & 0x08) != 0 ? 0x9C00 : 0x9800
      window_enabled = (lcdc & 0x20) != 0
      window_map_select = (lcdc & 0x40) != 0 ? 0x9C00 : 0x9800

      # In GBC mode, LCDC bit 0 has different meaning:
      # - DMG: bit 0 = 0 disables BG/window rendering entirely
      # - GBC: bit 0 = 0 means BG/window still render but sprites always on top
      if @gbc_mode
        bg_enabled = true  # Always render BG in GBC mode
        bg_priority_enabled = lcdc_bg_enable  # But priority only when bit 0 set
      else
        bg_enabled = lcdc_bg_enable
        bg_priority_enabled = true  # N/A for DMG, always check priority
      end

      # Cache scroll registers once per scanline
      scx = $mmu.read_memory_byte(0xFF43)
      scy = $mmu.read_memory_byte(0xFF42)
      wx = $mmu.read_memory_byte(0xFF4B) - 7
      wy = $mmu.read_memory_byte(0xFF4A)

      # Cache palette once per scanline
      palette = $mmu.read_memory_byte(0xFF47)

      render_bg(bg_enabled, bg_tile_select, bg_map_select, scx, scy, palette)
      render_window(window_enabled, bg_tile_select, window_map_select, wx, wy, palette)
      render_sprites(obj_enabled, obj_size_16, bg_priority_enabled)
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

    def render_window(window_enabled, tiles_select, map_select, window_pos_x, window_pos_y, palette)
      line = current_line
      line_width = line * Screen::SCREEN_WIDTH
      # dont render if the window is outside the bounds of the screen or
      # if the LCDC window enable bit flag is not set
      return if @window_line > 143 || !window_enabled

      # don't render if the window is outside the bounds of the screen
      return if window_pos_x > 159 || window_pos_y > 143 || window_pos_y > line

      # Pre-compute palette lookup table for DMG mode
      unless @gbc_mode
        palette_colors = [
          RGB_COLORS[palette & 0x3],
          RGB_COLORS[(palette >> 2) & 0x3],
          RGB_COLORS[(palette >> 4) & 0x3],
          RGB_COLORS[(palette >> 6) & 0x3]
        ]
      end

      line_adjusted = @window_line
      y_offset = (line_adjusted >> 3) << 5   # (line_adjusted / 8) * 32
      tile_line = line_adjusted & 0x07       # line_adjusted % 8

      x = 0
      while x < 32
        map_address = map_select + y_offset + x

        if @gbc_mode
          # Read tile attributes from VRAM bank 1
          attr = $mmu.tile_attribute(map_address)
          gbc_palette = attr & 0x07
          vram_bank = (attr & 0x08) != 0 ? 1 : 0
          x_flip = (attr & 0x20) != 0
          y_flip = (attr & 0x40) != 0
          gbc_priority = (attr & 0x80) != 0

          # Apply Y flip to tile line
          effective_tile_line = y_flip ? (7 - tile_line) : tile_line
          tile_line_offset = effective_tile_line << 1

          # Select mask array based on x flip
          masks = x_flip ? BIT_MASKS_REVERSED : BIT_MASKS
        else
          tile_line_offset = tile_line << 1
          masks = BIT_MASKS
        end

        # In GBC mode, tile indices are always in VRAM bank 0
        if @gbc_mode
          raw_tile = $mmu.read_vram_bank0(map_address)
        else
          raw_tile = $mmu.read_byte(map_address)
        end

        if tiles_select == 0x8800
          tile = signed_value(raw_tile)
          tile += 128
        else
          tile = raw_tile
        end

        line_pixel_offset = x << 3           # x * 8
        tile_select_offset = tile << 4       # tile * 16
        tile_address = tiles_select + tile_select_offset + tile_line_offset

        if @gbc_mode
          # Read tile data from the bank specified in tile attributes
          if vram_bank == 1
            byte_1 = $mmu.read_vram_bank1(tile_address)
            byte_2 = $mmu.read_vram_bank1(tile_address + 1)
          else
            byte_1 = $mmu.read_vram_bank0(tile_address)
            byte_2 = $mmu.read_vram_bank0(tile_address + 1)
          end
        else
          byte_1 = $mmu.read_byte(tile_address)
          byte_2 = $mmu.read_byte(tile_address + 1)
        end

        pixelx = 0
        while pixelx < 8
          buffer_addr = line_pixel_offset + pixelx + window_pos_x

          if buffer_addr >= 0 && buffer_addr < Screen::SCREEN_WIDTH
            # Use pre-computed bit mask (may be reversed for x-flip)
            mask = masks[pixelx]
            pixel = ((byte_1 & mask) != 0 ? 1 : 0) | ((byte_2 & mask) != 0 ? 2 : 0)

            position = line_width + buffer_addr
            @bg_color_indices[position] = pixel  # Store raw index for sprite priority

            if @gbc_mode
              @bg_priority_flags[position] = gbc_priority
              @framebuffer[position] = $mmu.bg_palette_color(gbc_palette, pixel)
            else
              @framebuffer[position] = palette_colors[pixel]
            end
          end

          pixelx += 1
        end

        x += 1
      end
      @window_line += 1
    end

    def render_sprites(obj_enabled, obj_size_16, bg_priority_enabled = true)
      return unless obj_enabled

      line = current_line
      line_width = line * Screen::SCREEN_WIDTH

      # Get pre-filtered sprites for this scanline (already in correct priority order)
      visible_sprites = @sprite_scanlines[line]
      return if visible_sprites.empty?

      sprite_size = obj_size_16 ? 16 : 8

      # DMG mode: pre-compute palette colors
      unless @gbc_mode
        obp0 = $mmu.read_memory_byte 0xFF48
        obp1 = $mmu.read_memory_byte 0xFF49

        # Update pre-allocated palette arrays (avoids array allocation each scanline)
        @obp0_colors[0] = RGB_COLORS[obp0 & 0x3]
        @obp0_colors[1] = RGB_COLORS[(obp0 >> 2) & 0x3]
        @obp0_colors[2] = RGB_COLORS[(obp0 >> 4) & 0x3]
        @obp0_colors[3] = RGB_COLORS[(obp0 >> 6) & 0x3]

        @obp1_colors[0] = RGB_COLORS[obp1 & 0x3]
        @obp1_colors[1] = RGB_COLORS[(obp1 >> 2) & 0x3]
        @obp1_colors[2] = RGB_COLORS[(obp1 >> 4) & 0x3]
        @obp1_colors[3] = RGB_COLORS[(obp1 >> 6) & 0x3]
      end

      sprite_mask = obj_size_16 ? 0xFE : 0xFF
      tiles = 0x8000

      # Only process sprites that overlap this scanline (pre-filtered, in priority order)
      sprite_idx = 0
      sprite_count = visible_sprites.size
      while sprite_idx < sprite_count
        sprite = visible_sprites[sprite_idx]
        sprite_offset = sprite << 2          # sprite * 4

        sprite_y = $mmu.read_memory_byte(0xFE00 + sprite_offset) - 16
        sprite_x = $mmu.read_memory_byte(0xFE00 + sprite_offset + 1) - 8

        if sprite_x >= -7 && sprite_x < Screen::SCREEN_WIDTH
          sprite_tile_offset = ($mmu.read_memory_byte(0xFE00 + sprite_offset + 2) & sprite_mask) << 4
          sprite_flags = $mmu.read_memory_byte(0xFE00 + sprite_offset + 3)
          x_flip = (sprite_flags & 0x20) != 0
          y_flip = (sprite_flags & 0x40) != 0
          bg_priority = (sprite_flags & 0x80) != 0  # If set, sprite behind BG colors 1-3

          if @gbc_mode
            # GBC: palette from bits 0-2, VRAM bank from bit 3
            gbc_palette = sprite_flags & 0x07
            vram_bank = (sprite_flags & 0x08) != 0 ? 1 : 0
          else
            # DMG: palette select from bit 4
            use_obp1 = (sprite_flags & 0x10) != 0
            palette_colors = use_obp1 ? @obp1_colors : @obp0_colors
          end

          pixel_y = y_flip ? (obj_size_16 ? 15 : 7) - (line - sprite_y) : line - sprite_y

          pixel_y_2 = 0
          offset = 0

          if obj_size_16 && (pixel_y >= 8)
            pixel_y_2 = (pixel_y - 8) << 1   # * 2
            offset = 16
          else
            pixel_y_2 = pixel_y << 1          # * 2
          end

          tile_address = tiles + sprite_tile_offset + pixel_y_2 + offset

          if @gbc_mode
            # Read sprite tile data from the bank specified in sprite flags
            if vram_bank == 1
              byte_1 = $mmu.read_vram_bank1(tile_address)
              byte_2 = $mmu.read_vram_bank1(tile_address + 1)
            else
              byte_1 = $mmu.read_vram_bank0(tile_address)
              byte_2 = $mmu.read_vram_bank0(tile_address + 1)
            end
          else
            byte_1 = $mmu.read_byte(tile_address)
            byte_2 = $mmu.read_byte(tile_address + 1)
          end

          # Select mask array based on flip (eliminates conditional per pixel)
          masks = x_flip ? BIT_MASKS_REVERSED : BIT_MASKS

          pixelx = 0
          while pixelx < 8
            mask = masks[pixelx]

            pixel = ((byte_1 & mask) != 0 ? 1 : 0) | ((byte_2 & mask) != 0 ? 2 : 0)

            # Color 0 is transparent for sprites
            if pixel != 0
              buffer_x = sprite_x + pixelx

              if buffer_x >= 0 && buffer_x < Screen::SCREEN_WIDTH
                position = line_width + buffer_x

                # Check sprite priority
                # In GBC mode with LCDC bit 0 = 0, sprites always appear on top
                show_sprite = true
                if bg_priority_enabled
                  if bg_priority && @bg_color_indices[position] != 0
                    show_sprite = false
                  elsif @gbc_mode && @bg_priority_flags[position] && @bg_color_indices[position] != 0
                    # BG tile has priority flag set and color is not 0
                    show_sprite = false
                  end
                end
                # When bg_priority_enabled is false, show_sprite stays true (sprites on top)

                if show_sprite
                  if @gbc_mode
                    @framebuffer[position] = $mmu.obj_palette_color(gbc_palette, pixel)
                  else
                    @framebuffer[position] = palette_colors[pixel]
                  end
                end
              end
            end

            pixelx += 1
          end
        end

        sprite_idx += 1
      end
    end

    def render_bg(bg_enabled, tiles_select, map_select, scx, scy, palette)
      line = current_line
      line_width = line * Screen::SCREEN_WIDTH

      if bg_enabled
        # Pre-compute palette lookup table for DMG mode (4 entries)
        unless @gbc_mode
          palette_colors = [
            RGB_COLORS[palette & 0x3],
            RGB_COLORS[(palette >> 2) & 0x3],
            RGB_COLORS[(palette >> 4) & 0x3],
            RGB_COLORS[(palette >> 6) & 0x3]
          ]
        end

        # Calculate the Y position in the 256x256 background map
        bg_y = (line + scy) & 0xFF
        tile_row = bg_y >> 3         # Faster than / 8
        tile_y = bg_y & 0x07         # Faster than % 8

        # Cache for tile data (avoid re-reading same tile)
        cached_tile_col = -1
        byte_1 = 0
        byte_2 = 0
        # GBC-specific cached values
        gbc_palette = 0
        gbc_x_flip = false
        gbc_priority = false
        masks = BIT_MASKS

        # Replace .times with while loop for better performance
        screen_x = 0
        while screen_x < 160
          # Calculate the X position in the 256x256 background map (with wrap)
          bg_x = (screen_x + scx) & 0xFF
          tile_col = bg_x >> 3       # Faster than / 8
          tile_x = bg_x & 0x07       # Faster than % 8

          # Only fetch new tile data when we move to a different tile
          if tile_col != cached_tile_col
            cached_tile_col = tile_col
            map_offset = (tile_row << 5) + tile_col  # tile_row * 32
            map_address = map_select + map_offset

            if @gbc_mode
              # Read tile attributes from VRAM bank 1
              attr = $mmu.tile_attribute(map_address)
              gbc_palette = attr & 0x07
              vram_bank = (attr & 0x08) != 0 ? 1 : 0
              gbc_x_flip = (attr & 0x20) != 0
              y_flip = (attr & 0x40) != 0
              gbc_priority = (attr & 0x80) != 0

              # Apply Y flip to tile line
              effective_tile_y = y_flip ? (7 - tile_y) : tile_y
              tile_line_offset = effective_tile_y << 1

              # Select mask array based on x flip
              masks = gbc_x_flip ? BIT_MASKS_REVERSED : BIT_MASKS
            else
              tile_line_offset = tile_y << 1
            end

            # In GBC mode, tile indices are always in VRAM bank 0
            if @gbc_mode
              raw_tile = $mmu.read_vram_bank0(map_address)
            else
              raw_tile = $mmu.read_byte(map_address)
            end

            if tiles_select == 0x8800
              tile = signed_value(raw_tile)
              tile += 128
            else
              tile = raw_tile
            end

            tile_address = tiles_select + (tile << 4) + tile_line_offset

            if @gbc_mode
              # Read tile data from the bank specified in tile attributes
              if vram_bank == 1
                byte_1 = $mmu.read_vram_bank1(tile_address)
                byte_2 = $mmu.read_vram_bank1(tile_address + 1)
              else
                byte_1 = $mmu.read_vram_bank0(tile_address)
                byte_2 = $mmu.read_vram_bank0(tile_address + 1)
              end
            else
              byte_1 = $mmu.read_byte(tile_address)
              byte_2 = $mmu.read_byte(tile_address + 1)
            end
          end

          # Use pre-computed bit mask (may be reversed for x-flip)
          mask = masks[tile_x]
          pixel = ((byte_1 & mask) != 0 ? 1 : 0) | ((byte_2 & mask) != 0 ? 2 : 0)

          position = line_width + screen_x
          @bg_color_indices[position] = pixel  # Store raw index for sprite priority

          if @gbc_mode
            @bg_priority_flags[position] = gbc_priority
            @framebuffer[position] = $mmu.bg_palette_color(gbc_palette, pixel)
          else
            @framebuffer[position] = palette_colors[pixel]
          end

          screen_x += 1
        end
      else
        # Clear line - use while loop
        i = 0
        while i < 160
          position = line_width + i
          @bg_color_indices[position] = 0
          @bg_priority_flags[position] = false if @gbc_mode
          @framebuffer[position] = @gbc_mode ? 0xFFFFFFFF : 0
          i += 1
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
