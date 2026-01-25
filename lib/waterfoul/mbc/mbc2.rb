module Waterfoul
  module MBC
    class MBC2
      # MBC2 has built-in 512x4-bit RAM (not external RAM)
      INTERNAL_RAM_SIZE = 512

      attr_reader :rom_bank

      def initialize(program)
        @game_program = program
        @rom_bank = 1
        @ram_enabled = false
        # 512 bytes, but only lower 4 bits of each are used
        @ram = Array.new INTERNAL_RAM_SIZE, 0x0F  # Upper nibble undefined, often 0xF
      end

      def [](i)
        case i
        when 0x0000...0x4000 # ROM Bank 0
          @game_program[i]
        when 0x4000...0x8000 # ROM Bank 1-15
          addr = i - 0x4000
          offset = @rom_bank * 0x4000
          @game_program[offset + addr] || 0xFF
        when 0xA000...0xC000 # Internal 512x4-bit RAM (with echo)
          if @ram_enabled
            # Only bottom 9 bits of address are used (0-511)
            ram_addr = (i - 0xA000) & 0x1FF
            # Upper 4 bits are undefined, return with upper nibble set to 0xF
            0xF0 | (@ram[ram_addr] & 0x0F)
          else
            0xFF
          end
        else
          0xFF
        end
      end

      def []=(i, v)
        case i
        when 0x0000...0x4000 # RAM Enable or ROM Bank (depends on bit 8)
          if (i & 0x0100) == 0
            # Bit 8 clear: RAM Enable
            @ram_enabled = (v & 0x0F) == 0x0A
          else
            # Bit 8 set: ROM Bank Number (4 bits)
            @rom_bank = v & 0x0F
            @rom_bank = 1 if @rom_bank == 0  # Bank 0 maps to bank 1
          end
        when 0xA000...0xC000 # Internal RAM write
          if @ram_enabled
            # Only bottom 9 bits of address are used
            ram_addr = (i - 0xA000) & 0x1FF
            # Only lower 4 bits are stored
            @ram[ram_addr] = v & 0x0F
          end
        end
      end
    end
  end
end
