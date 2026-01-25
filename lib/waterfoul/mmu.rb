module Waterfoul
  # The MMU (Memory Management Unit) in a chip in the device that is the
  # interface to hardware for reading and writing to memory.
  #
  # The MMU also provides the program a way to interact with hardware
  # like the PPU and IO using memory registers. This is due to the CPU
  # not having any IO instructions.
  class MMU
    MEMORY_SIZE = 65536 # bytes
    # DMA register function address
    DMA_TRANSFER_MEM_LOC = 0xFF46
    # DIV register memory location
    DIV_MEM_LOC = 0xFF04

    # GBC-specific registers
    VBK_REG = 0xFF4F   # VRAM bank select
    HDMA1_REG = 0xFF51 # HDMA source high
    HDMA2_REG = 0xFF52 # HDMA source low
    HDMA3_REG = 0xFF53 # HDMA destination high
    HDMA4_REG = 0xFF54 # HDMA destination low
    HDMA5_REG = 0xFF55 # HDMA length/mode/start
    BCPS_REG = 0xFF68  # Background palette index
    BCPD_REG = 0xFF69  # Background palette data
    OCPS_REG = 0xFF6A  # Object palette index
    OCPD_REG = 0xFF6B  # Object palette data
    SVBK_REG = 0xFF70  # WRAM bank select

    attr_reader :memory, :gbc_mode

    def initialize(cartridge = Cartridge.empty, gbc_mode: false)
      @gbc_mode = gbc_mode
      @cartridge = cartridge
      # storage for usable memory (zero filled)
      @memory = Array.new MEMORY_SIZE, 0

      if @gbc_mode
        # Color palette RAM (64 bytes each for BG and OBJ)
        @bg_cram = Array.new(64, 0xFF)
        @obj_cram = Array.new(64, 0xFF)
        @bg_cram_index = 0
        @obj_cram_index = 0
        @bg_cram_auto_inc = false
        @obj_cram_auto_inc = false

        # Pre-computed ARGB8888 colors (8 palettes × 4 colors each)
        # Updated when palette RAM is written
        @bg_colors = Array.new(32, 0xFFFFFFFF)
        @obj_colors = Array.new(32, 0xFFFFFFFF)
        precompute_all_palette_colors

        # VRAM bank 1 (8KB) - bank 0 uses existing @memory
        @vram_bank = 0
        @vram_bank1 = Array.new(0x2000, 0)

        # WRAM banks 1-7 (7 x 4KB) - bank 0 uses existing @memory
        @wram_bank = 1
        @wram_banks = Array.new(7) { Array.new(0x1000, 0) }

        # HDMA (HBlank DMA) state
        @hdma_source = 0
        @hdma_dest = 0
        @hdma_length = 0
        @hdma_active = false  # HBlank DMA in progress
      end
    end

    # Pre-compute all palette colors at once (used during init)
    def precompute_all_palette_colors
      8.times do |palette|
        4.times do |color|
          update_bg_color_cache(palette, color)
          update_obj_color_cache(palette, color)
        end
      end
    end

    # Update a single cached BG color
    def update_bg_color_cache(palette, color)
      idx = (palette * 8) + (color * 2)
      @bg_colors[(palette * 4) + color] = gbc_to_rgb(@bg_cram[idx], @bg_cram[idx + 1])
    end

    # Update a single cached OBJ color
    def update_obj_color_cache(palette, color)
      idx = (palette * 8) + (color * 2)
      @obj_colors[(palette * 4) + color] = gbc_to_rgb(@obj_cram[idx], @obj_cram[idx + 1])
    end

    # Read 1 byte from memory given address
    # Uses region-based dispatch (shift + case) for performance
    def [](i)
      raise MemoryOutOfBounds if i > MEMORY_SIZE || i < 0

      region = i >> 12  # Get high nibble (0x0-0xF)

      case region
      when 0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7
        @cartridge[i]  # ROM (0x0000-0x7FFF)
      when 0x8, 0x9
        # VRAM (0x8000-0x9FFF) - banked in GBC mode
        if @gbc_mode && @vram_bank == 1
          @vram_bank1[i - 0x8000]
        else
          @memory[i]
        end
      when 0xA, 0xB
        @cartridge[i]  # External RAM (0xA000-0xBFFF)
      when 0xC
        @memory[i]     # WRAM bank 0 (0xC000-0xCFFF) - fixed
      when 0xD
        # WRAM bank 1-7 (0xD000-0xDFFF) - switchable in GBC mode
        if @gbc_mode
          @wram_banks[@wram_bank - 1][i - 0xD000]
        else
          @memory[i]
        end
      when 0xE
        @memory[i - 0x2000]  # Echo RAM (0xE000-0xEFFF)
      else # 0xF
        read_high_region(i)
      end
    end

    # Write 1 byte into memory
    # Uses region-based dispatch (shift + case) for performance
    def []=(i, v, options = {})
      # raise exception if an attempt is made to write memory that is out of bounds
      raise MemoryOutOfBounds if i > MEMORY_SIZE || i < 0

      # Fast path: bypass memory rules for hardware operations
      return @memory[i] = v if options[:hardware_operation]

      region = i >> 12  # Get high nibble (0x0-0xF)

      case region
      when 0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7
        @cartridge[i] = v  # ROM writes go to MBC (0x0000-0x7FFF)
      when 0x8, 0x9
        # VRAM (0x8000-0x9FFF) - banked in GBC mode
        if @gbc_mode && @vram_bank == 1
          @vram_bank1[i - 0x8000] = v
        else
          @memory[i] = v
        end
      when 0xA, 0xB
        @cartridge[i] = v  # External RAM (0xA000-0xBFFF)
      when 0xC
        @memory[i] = v     # WRAM bank 0 (0xC000-0xCFFF) - fixed
      when 0xD
        # WRAM bank 1-7 (0xD000-0xDFFF) - switchable in GBC mode
        if @gbc_mode
          @wram_banks[@wram_bank - 1][i - 0xD000] = v
        else
          @memory[i] = v
        end
      when 0xE
        @memory[i - 0x2000] = v  # Echo RAM (0xE000-0xEFFF)
      else # 0xF
        write_high_region(i, v)
      end
    end

    alias_method :write_byte, :[]=
    alias_method :read_byte, :[]

    def read_memory_byte(i)
      @memory[i]
    end

    # GBC helper methods for PPU

    # Get a color from the background palette
    # palette: palette number (0-7)
    # color: color index within palette (0-3)
    # Returns: 32-bit ARGB color
    def bg_palette_color(palette, color)
      return 0xFF000000 unless @gbc_mode
      @bg_colors[(palette << 2) + color]
    end

    # Get a color from the object palette
    # palette: palette number (0-7)
    # color: color index within palette (0-3)
    # Returns: 32-bit ARGB color
    def obj_palette_color(palette, color)
      return 0xFF000000 unless @gbc_mode
      @obj_colors[(palette << 2) + color]
    end

    # Get tile attributes from VRAM bank 1
    # map_addr: address in tile map (0x9800-0x9BFF or 0x9C00-0x9FFF)
    # Returns: attribute byte
    def tile_attribute(map_addr)
      return 0 unless @gbc_mode
      @vram_bank1[map_addr - 0x8000]
    end

    # Read a byte from VRAM bank 0 (for tile map indices in GBC mode)
    def read_vram_bank0(addr)
      @memory[addr]
    end

    # Read a byte from VRAM bank 1 (for tile data)
    def read_vram_bank1(addr)
      return 0 unless @gbc_mode
      @vram_bank1[addr - 0x8000]
    end

    # Convert GBC RGB555 to ARGB8888
    # low: low byte of color
    # high: high byte of color
    # Returns: 32-bit ARGB color
    def gbc_to_rgb(low, high)
      rgb555 = low | (high << 8)
      # Extract 5-bit components and expand to 8-bit
      r = ((rgb555 & 0x1F) << 3) | ((rgb555 & 0x1F) >> 2)
      g = (((rgb555 >> 5) & 0x1F) << 3) | (((rgb555 >> 5) & 0x1F) >> 2)
      b = (((rgb555 >> 10) & 0x1F) << 3) | (((rgb555 >> 10) & 0x1F) >> 2)
      0xFF000000 | (r << 16) | (g << 8) | b
    end

    # read 2 bytes from memory
    def read_word(addr)
      self[addr] | (self[addr + 1] << 8)
    end

    # write 2 bytes into memory given an address
    def write_word(addr, word)
      write_byte addr, ( word & 0xFF )
      write_byte addr + 1, ( word >> 8 )
    end

    # General purpose DMA - transfers all data immediately
    def perform_gdma
      return unless @gbc_mode

      bytes_to_copy = @hdma_length * 16
      bytes_to_copy.times do |i|
        byte = read_byte(@hdma_source + i)
        write_vram_for_hdma(@hdma_dest + i, byte)
      end

      @hdma_source += bytes_to_copy
      @hdma_dest += bytes_to_copy
      @hdma_length = 0
    end

    # HBlank DMA - transfers one 16-byte block, called by PPU during HBlank
    def perform_hdma_block
      return false unless @gbc_mode && @hdma_active

      # Transfer 16 bytes
      16.times do |i|
        byte = read_byte(@hdma_source + i)
        write_vram_for_hdma(@hdma_dest + i, byte)
      end

      @hdma_source += 16
      @hdma_dest += 16
      @hdma_length -= 1

      if @hdma_length == 0
        @hdma_active = false
        @memory[HDMA5_REG] = 0xFF  # Indicate complete
      else
        @memory[HDMA5_REG] = (@hdma_length - 1) & 0x7F
      end

      true  # Return true if transfer happened
    end

    def hdma_active?
      @hdma_active
    end

    private

    # Handle reads from 0xF000-0xFFFF region
    def read_high_region(i)
      if i < 0xFE00
        # Echo RAM (0xF000-0xFDFF) - needs WRAM banking in GBC mode
        if @gbc_mode && i >= 0xF000
          offset = i - 0x2000
          if offset >= 0xD000
            @wram_banks[@wram_bank - 1][offset - 0xD000]
          else
            @memory[offset]
          end
        else
          @memory[i - 0x2000]
        end
      elsif i == 0xFF00
        Input.read_keyboard @memory[i]
      elsif i == 0xFF0F
        # IF register: upper 3 bits always read as 1
        @memory[i] | 0xE0
      elsif i >= 0xFF10 && i <= 0xFF3F
        # APU registers and Wave RAM
        return $apu.read_register(i) if $apu
        @memory[i]
      elsif @gbc_mode
        read_gbc_register(i)
      else
        @memory[i]
      end
    end

    # Handle GBC-specific register reads
    def read_gbc_register(i)
      case i
      when VBK_REG
        # VRAM bank register: only bit 0 is used, upper bits read as 1
        @vram_bank | 0xFE
      when HDMA5_REG
        # HDMA5: bit 7 = 0 if HDMA active, 1 if inactive
        # bits 0-6 = remaining length - 1 (or 0x7F if inactive)
        if @hdma_active
          (@hdma_length - 1) & 0x7F
        else
          0xFF  # Bit 7 set = inactive
        end
      when BCPS_REG
        # BG palette index with auto-increment flag
        @bg_cram_index | (@bg_cram_auto_inc ? 0x80 : 0)
      when BCPD_REG
        # BG palette data
        @bg_cram[@bg_cram_index & 0x3F]
      when OCPS_REG
        # OBJ palette index with auto-increment flag
        @obj_cram_index | (@obj_cram_auto_inc ? 0x80 : 0)
      when OCPD_REG
        # OBJ palette data
        @obj_cram[@obj_cram_index & 0x3F]
      when SVBK_REG
        # WRAM bank register: bits 0-2 used, upper bits read as 1
        @wram_bank | 0xF8
      else
        @memory[i]
      end
    end

    # Handle writes to 0xF000-0xFFFF region
    def write_high_region(i, v)
      if i < 0xFE00
        # Echo RAM (0xF000-0xFDFF) - needs WRAM banking in GBC mode
        if @gbc_mode && i >= 0xF000
          offset = i - 0x2000
          if offset >= 0xD000
            @wram_banks[@wram_bank - 1][offset - 0xD000] = v
          else
            @memory[offset] = v
          end
        else
          @memory[i - 0x2000] = v
        end
      elsif i == 0xFF00
        @memory[i] = v | 0xF
      elsif i == DMA_TRANSFER_MEM_LOC
        dma_transfer v
        @memory[i] = v
      elsif i == DIV_MEM_LOC
        # Writing any value to DIV resets the internal counter
        $timer.reset_div if $timer
      elsif i >= 0xFF10 && i <= 0xFF3F
        # APU registers and Wave RAM
        $apu.write_register(i, v) if $apu
        @memory[i] = v
      elsif @gbc_mode
        write_gbc_register(i, v)
      else
        @memory[i] = v
      end
    end

    # Handle GBC-specific register writes
    def write_gbc_register(i, v)
      case i
      when VBK_REG
        # VRAM bank select (only bit 0 is used)
        @vram_bank = v & 0x01
        @memory[i] = v
      when HDMA1_REG
        # HDMA source high byte
        @hdma_source = (@hdma_source & 0x00FF) | (v << 8)
        @memory[i] = v
      when HDMA2_REG
        # HDMA source low byte (lower 4 bits ignored)
        @hdma_source = (@hdma_source & 0xFF00) | (v & 0xF0)
        @memory[i] = v
      when HDMA3_REG
        # HDMA destination high byte (only bits 0-4 used, always in VRAM 0x8000-0x9FF0)
        @hdma_dest = 0x8000 | ((v & 0x1F) << 8)
        @memory[i] = v
      when HDMA4_REG
        # HDMA destination low byte (lower 4 bits ignored)
        @hdma_dest = (@hdma_dest & 0xFF00) | (v & 0xF0)
        @memory[i] = v
      when HDMA5_REG
        # HDMA length/mode/start
        if @hdma_active && (v & 0x80) == 0
          # Writing 0 to bit 7 while HDMA active stops it
          @hdma_active = false
          @memory[i] = v | 0x80  # Set bit 7 to indicate inactive
        else
          @hdma_length = (v & 0x7F) + 1  # Length in 16-byte blocks
          if (v & 0x80) == 0
            # General purpose DMA (immediate transfer)
            perform_gdma
            @memory[i] = 0xFF  # Transfer complete
          else
            # HBlank DMA (transfer 16 bytes per HBlank)
            @hdma_active = true
            @memory[i] = v & 0x7F  # Store length, clear bit 7
          end
        end
      when BCPS_REG
        # BG palette index
        @bg_cram_index = v & 0x3F
        @bg_cram_auto_inc = (v & 0x80) != 0
        @memory[i] = v
      when BCPD_REG
        # BG palette data write
        cram_idx = @bg_cram_index & 0x3F
        @bg_cram[cram_idx] = v
        # Update cached color (each color is 2 bytes, so update when either byte changes)
        palette = cram_idx >> 3        # cram_idx / 8
        color = (cram_idx >> 1) & 0x03 # (cram_idx / 2) % 4
        update_bg_color_cache(palette, color)
        if @bg_cram_auto_inc
          @bg_cram_index = (@bg_cram_index + 1) & 0x3F
        end
        @memory[i] = v
      when OCPS_REG
        # OBJ palette index
        @obj_cram_index = v & 0x3F
        @obj_cram_auto_inc = (v & 0x80) != 0
        @memory[i] = v
      when OCPD_REG
        # OBJ palette data write
        cram_idx = @obj_cram_index & 0x3F
        @obj_cram[cram_idx] = v
        # Update cached color
        palette = cram_idx >> 3
        color = (cram_idx >> 1) & 0x03
        update_obj_color_cache(palette, color)
        if @obj_cram_auto_inc
          @obj_cram_index = (@obj_cram_index + 1) & 0x3F
        end
        @memory[i] = v
      when SVBK_REG
        # WRAM bank select (bits 0-2, bank 0 maps to bank 1)
        bank = v & 0x07
        @wram_bank = bank == 0 ? 1 : bank
        @memory[i] = v
      else
        @memory[i] = v
      end
    end

    def dma_transfer(start)
      addr = start << 8
      if addr >= 0x8000 && addr < 0xE000
        0.upto(0x9F) do |i|
          sprite_byte = $mmu.read_byte(addr + i)
          self[0xFE00 + i] = sprite_byte
        end
      end
    end

    # Write to VRAM for HDMA (respects current VRAM bank)
    def write_vram_for_hdma(addr, value)
      if @vram_bank == 1
        @vram_bank1[addr - 0x8000] = value
      else
        @memory[addr] = value
      end
    end
  end
end
