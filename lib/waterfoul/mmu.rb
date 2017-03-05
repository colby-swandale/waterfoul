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
    attr_accessor :cartridge

    def initialize(cartridge = Cartridge.empty)
      # map the boot rom when the device starts
      @cartridge = BootROM.new(cartridge)
      # storage for usable memory (zero filled)
      @memory = Array.new MEMORY_SIZE, 0
    end

    # Read 1 byte from memory given address
    def [](i)
      raise MemoryOutOfBounds if i > MEMORY_SIZE || i < 0

      if i == 0xFF00
        Input.read_keyboard @memory[i]
      elsif i >= 0x8000 && i < 0xA000 or i >= 0xC000 && i < 0xE000 or i >= 0xFE00
        @memory[i]
      elsif i < 0x8000 or i >= 0xA000 && i < 0xC000
        @cartridge[i]
      else # if (0xE000...0xFE00) === i
        @memory[i - 0x2000]
      end
    end

    # Write 1 byte into memory
    def []=(i, v, options = {})
      # raise exception if an attempt is made to read memory that is out of bounds
      raise MemoryOutOfBounds if i > MEMORY_SIZE || i < 0
      # ignore memory rules if emulated hardware components need to write to
      # memory
      unless options[:hardware_operation]
        case i
        when UNMAP_BOOT_ROM_MEM_LOC # unmap the boot rom when 0xFF50 is wrtiten to in memory
          if v == 0x1 && @cartridge.is_a?(BootROM)
            @cartridge = @cartridge.cartridge
          end
        when 0xFF00
          @memory[i] = v | 0xF
        when 0xFF46 # DMA transfer
          dma_transfer v
          @memory[i] = v
        when 0xFF04 # reset divider register
          @memory[i] = 0
        when 0x0...0x8000 # ROM Bank 0 + n
          @cartridge[i] = v
        when 0x8000...0xA000 # Video RAM
          @memory[i] = v
        when 0xA000...0xC000 # RAM Bank
          @cartridge[i] = v
        when 0xC000...0xE000 # Internal RAM
          @memory[i] = v
        when 0xE000...0xFE00 # Internal RAM (Shadow)
          @memory[i - 0x2000] = v
        when 0xFE00..0xFFFF # Graphics (OAM), IO, Zero Page
          @memory[i] = v
        end
      else
        @memory[i] = v
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
