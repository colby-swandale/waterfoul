module Waterfoul
  module MBC
    class ROM
      EXTERNAL_RAM_SIZE = 0x1FFF

      def initialize(program)
        @external_ram = Array.new EXTERNAL_RAM_SIZE, 0
        @program = program
      end

      def [](i)
        case i
        when 0xA000...0xC000
          @external_ram[i - 0xA000]
        else
          @program[i]
        end
      end

      def []=(i,v)
        case i
        when 0xA000...0xC000
          @external_ram[i - 0xA000] = v
        end
      end
    end
  end
end
