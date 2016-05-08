module Waterfoul
  module MBC
    class MBC1 < ROM
      EXTERNAL_RAM_SIZE = 0x2000

      def initialize(program, rom_bank = 1)
        @rom_bank = rom_bank
        @cartridge_program = program
        @rom_offset = 0x4000
        @ram_bank = Array.new EXTERNAL_RAM_SIZE, 0
      end

      def [](i)
        case i & 0xE000
        when 0x4000, 0x6000
          relative_addr = (i - 0x4000) + @rom_offset
          @cartridge_program[relative_addr]
        when 0xA000
          byebug
        else
          @cartridge_program[i]
        end
      end

      def []=(i,v)
        byebug
      end
    end
  end
end
