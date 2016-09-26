module Waterfoul
  module MBC
    class ROM
      EXTERNAL_RAM_SIZE = 0x1FFF

      attr_reader :ram

      def initialize(program)
        @ram = Array.new EXTERNAL_RAM_SIZE, 0
        @program = program
      end

      def [](i)
        case i
        when 0xA000...0xC000
          @ram[i - 0xA000]
        else
          @program[i]
        end
      end

      def []=(i,v)
        case i
        when 0xA000...0xC000
          @ram[i - 0xA000] = v
        end
      end
    end
  end
end
