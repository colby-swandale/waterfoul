module Waterfoul
  module MBC
    class MBC3
      def initialize(program)
        @game_program = program
        @ram_bank = 0
        @rom_bank = 0
        @ram_enable = false
      end

      def [](i)
        case i
        when 0x0...0x4000 # ROM Bank 0
          @game_program[i]
        when 0x4000...0x8000 # ROM Bank n
          addr = i - 0x4000
          offset = @rom_bank * 0x4000
          @game_program[offset + addr]
        when 0xA000...0xC000
          if @ram_enabled
            addr = i - 0xA000
            if @ram_bank == 0
              @ram[addr]
            else
              offset = @ram_bank * 0x8000
              @ram[offset + addr]
            end
          else
            0xFF
          end
        end
      end

      def []=(i,v)
        case i
        when 0x0...0x2000
          @ram_enable = (v & 0xA == 0xA ? true : false)
        when 0x2000...0x4000
          @rom_bank = (v & 0x7F)
          @rom_bank += 1 if @rom_bank == 0
        when 0x4000...0x6000
          if v <= 0x3
            @ram_bank = (v & 0x3)
          #elsif (0x8..0xC) === v
          end
        when 0x6000...0x8000
        end
      end
    end
  end
end
