module Waterfoul
  module MBC
    class MBC1 < ROM
      EXTERNAL_RAM_SIZE = 0x2000

      attr_accessor :ram_enabled, :mode, :rom_bank, :ram_bank

      def initialize(program)
        @rom_bank = 1
        @ram_bank = 1
        @mode = 0
        @ram_enabled = false
        @game_program = program
        @ram = Array.new EXTERNAL_RAM_SIZE, 0
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
          fail 'trying to read invalid ram' unless @ram_enabled
          addr = i - 0xA000
          if @mode == 0
            @ram[addr]
          else
            offset = @rom_ram_bank_number * 0x8000
            @ram[offset + addr]
          end
        end
      end

      def []=(i,v)
        case i
        when 0x0...0x2000
          @ram_enabled = (v & 0xA == 0xA ? true : false)
        when 0x2000...0x4000
          if @mode == 1
            @rom_bank = (v & 0x1F) | (@rom_bank & 0xE0)
          else
            @rom_bank = v & 0x1F
          end
        when 0x4000...0x6000
          v = v & 0x3
          if @mode == 1
            @ram_bank = v
          else
            @rom_bank = (@rom_bank & 0x1F) | (v << 5)
            @rom_bank += 1 if [0x0, 0x20, 0x40, 0x60].include? @rom_bank
          end
        when 0x6000...0x8000
          @mode = v & 0x1
        when 0xA000...0xC000
          return unless @ram_enabled
          addr = i - 0xA000
          if @mode == 0
            @ram[addr] = v
          else
            offset = @ram_bank * 0x8000
            @ram[offset + addr] = v
          end
        end
      end
    end
  end
end
