module Waterfoul
  module MBC
    class MBC5
      EXTERNAL_RAM_SIZE = 0x20000  # 128KB max (16 banks of 8KB)

      def initialize(program, has_rumble: false)
        @game_program = program
        @rom_bank_low = 1      # Lower 8 bits of ROM bank number
        @rom_bank_high = 0     # 9th bit of ROM bank number
        @ram_bank = 0
        @ram_enabled = false
        @ram = Array.new EXTERNAL_RAM_SIZE, 0
        @has_rumble = has_rumble
        @rumble_active = false
      end

      def rom_bank
        @rom_bank_low | (@rom_bank_high << 8)
      end

      def [](i)
        case i
        when 0x0...0x4000 # ROM Bank 0
          @game_program[i]
        when 0x4000...0x8000 # ROM Bank 1-511
          addr = i - 0x4000
          offset = rom_bank * 0x4000
          @game_program[offset + addr] || 0xFF
        when 0xA000...0xC000 # External RAM
          if @ram_enabled
            addr = i - 0xA000
            offset = @ram_bank * 0x2000
            @ram[offset + addr] || 0xFF
          else
            0xFF
          end
        else
          0xFF
        end
      end

      def []=(i, v)
        case i
        when 0x0000...0x2000 # RAM Enable
          @ram_enabled = (v & 0x0F) == 0x0A
        when 0x2000...0x3000 # ROM Bank Number (lower 8 bits)
          @rom_bank_low = v
        when 0x3000...0x4000 # ROM Bank Number (9th bit)
          @rom_bank_high = v & 0x01
        when 0x4000...0x6000 # RAM Bank Number
          if @has_rumble
            # Rumble cartridges: bits 0-2 = RAM bank, bit 3 = rumble motor
            @ram_bank = v & 0x07
            @rumble_active = (v & 0x08) != 0
          else
            # Non-rumble: bits 0-3 = RAM bank (0-15)
            @ram_bank = v & 0x0F
          end
        when 0xA000...0xC000 # External RAM
          if @ram_enabled
            addr = i - 0xA000
            offset = @ram_bank * 0x2000
            @ram[offset + addr] = v
          end
        end
      end
    end
  end
end
