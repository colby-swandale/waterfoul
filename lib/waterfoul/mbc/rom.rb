module Waterfoul
  module MBC
    class ROM
      EXTERNAL_RAM_START_ADDR = 0xA000

      def initialize(program)
        @external_ram = []
        @program = program
      end

      def [](i)
        case i & 0xE000
        when 0xA000,0xB000
          @external_ram[i]
        else
          @program[i]
        end
      end

      def []=(i,v)
        case i & 0xE000
        when 0xA000, 0xB000
          addr = i - EXTERNAL_RAM_START_ADDR
          @external_ram[addr] = v
        else
          fail 'forbidden write to rom'
        end
      end
    end
  end
end
