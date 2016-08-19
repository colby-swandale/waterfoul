require 'waterfoul/boot_rom'

module Waterfoul
  # The MMU (Memory Management Unit) in a chip in the device that acts a switch.
  # It allows programs to interact with subsytems like the GPU and IO depending
  # on the location in memory when reading from or writing to seeing the CPU
  # does not implement any IO instructions.
  class MMU
    MEMORY_SIZE = 65536 # bytes
    # unmap boot rom register address
    UNMAP_BOOT_ROM_MEM_LOC = 0xFF50
    # location in memory where the boot rom ends
    BOOT_ROM_END_MEM_LOC = 0xFF
    # DMA register function address
    DMA_TRANSFER_MEM_LOC = 0xFF46
    # DIV register memory location
    DIV_MEM_LOC = 0xFF04

    attr_reader :memory
    attr_accessor :cartridge

    # Set the initial state the memory management unit when program starts
    def initialize
      @cartridge = []
      # map the boot rom by default
      @map_boot_rom = true
      # storage for usable memory (zero filled)
      @memory = Array.new MEMORY_SIZE, 0
    end

    # Read 1 byte from memory given address
    def [](i)
      raise MemoryOutOfBounds if i > MEMORY_SIZE || i < 0

      case i
      when 0x0000...0x8000 # ROM Bank 0 + n
        # if the boot rom is enabled and the address is < 0x100
        if @map_boot_rom && i <= BOOT_ROM_END_MEM_LOC
          BootROM[i]
        else
          @cartridge[i]
        end
      when 0x8000...0xA000 # Video RAM
        @memory[i]
      when 0xA000...0xC000 # RAM Bank
        @cartridge[i]
      when 0xC000...0xE000 # Internal RAM
        @memory[i]
      when 0xE000...0xFE00 # Internal RAM (shadow)
        @memory[i - 0x2000]
      when 0xFE00..0xFFFF # Graphics (OAM), IO, Zero-page
        @memory[i]
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
          @map_boot_rom = false if v == 0x1 && @map_boot_rom
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

    ##
    # Read 2 bytes from memory
    # @param addr Integer
    def read_word(addr)
      self[addr] + (self[addr + 1] << 8)
    end

    ##
    # write 2 bytes into memory given an address
    # @param addr Integer point in memory to save word
    # @param word Integer 2 byte value to be stored into memory
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
