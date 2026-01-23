require 'waterfoul/boot_rom'

module Waterfoul
  # The MMU (Memory Management Unit) in a chip in the device that is the
  # interface to hardware for reading and writing to memory.
  #
  # The MMU also provides the program a way to interact with hardware
  # like the PPU and IO using memory registers. This is due to the CPU
  # not having any IO instructions.
  class MMU
    MEMORY_SIZE = 65536 # bytes
    # unmap boot rom register address
    UNMAP_BOOT_ROM_MEM_LOC = 0xFF50
    # DMA register function address
    DMA_TRANSFER_MEM_LOC = 0xFF46
    # DIV register memory location
    DIV_MEM_LOC = 0xFF04

    attr_reader :memory

    def initialize(cartridge = Cartridge.empty)
      # map the boot rom when the device starts
      @cartridge = BootROM.new(cartridge)
      # storage for usable memory (zero filled)
      @memory = Array.new MEMORY_SIZE, 0
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
        @memory[i]     # VRAM (0x8000-0x9FFF)
      when 0xA, 0xB
        @cartridge[i]  # External RAM (0xA000-0xBFFF)
      when 0xC, 0xD
        @memory[i]     # WRAM (0xC000-0xDFFF)
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
        @memory[i] = v     # VRAM (0x8000-0x9FFF)
      when 0xA, 0xB
        @cartridge[i] = v  # External RAM (0xA000-0xBFFF)
      when 0xC, 0xD
        @memory[i] = v     # WRAM (0xC000-0xDFFF)
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

    # read 2 bytes from memory
    def read_word(addr)
      self[addr] | (self[addr + 1] << 8)
    end

    # write 2 bytes into memory given an address
    def write_word(addr, word)
      write_byte addr, ( word & 0xFF )
      write_byte addr + 1, ( word >> 8 )
    end

    private

    # Handle reads from 0xF000-0xFFFF region
    def read_high_region(i)
      if i < 0xFE00
        # Echo RAM (0xF000-0xFDFF)
        @memory[i - 0x2000]
      elsif i == 0xFF00
        Input.read_keyboard @memory[i]
      elsif i == 0xFF0F
        # IF register: upper 3 bits always read as 1
        @memory[i] | 0xE0
      elsif i >= 0xFF10 && i <= 0xFF3F
        # APU registers and Wave RAM
        return $apu.read_register(i) if $apu
        @memory[i]
      else
        @memory[i]
      end
    end

    # Handle writes to 0xF000-0xFFFF region
    def write_high_region(i, v)
      if i < 0xFE00
        # Echo RAM (0xF000-0xFDFF)
        @memory[i - 0x2000] = v
      elsif i == UNMAP_BOOT_ROM_MEM_LOC
        # Unmap boot ROM when 0xFF50 is written to
        if v == 0x1 && @cartridge.is_a?(BootROM)
          @cartridge = @cartridge.cartridge
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
  end
end
