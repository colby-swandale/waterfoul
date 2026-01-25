module Waterfoul
  module MBC
    class MBC3
      EXTERNAL_RAM_SIZE = 0x8000  # 32KB max (4 banks of 8KB)

      # RTC register indices
      RTC_SECONDS = 0x08
      RTC_MINUTES = 0x09
      RTC_HOURS   = 0x0A
      RTC_DAY_LOW = 0x0B
      RTC_DAY_HIGH = 0x0C

      attr_reader :rom_bank

      def initialize(program, has_rtc: false)
        @game_program = program
        @rom_bank = 1
        @ram_bank = 0
        @ram_enabled = false
        @ram = Array.new EXTERNAL_RAM_SIZE, 0

        # RTC support
        @has_rtc = has_rtc
        @rtc_select = nil  # nil = RAM mode, 0x08-0x0C = RTC register
        @rtc_latch_pending = false
        @rtc_latched = false

        # RTC registers (active values that tick)
        @rtc_seconds = 0
        @rtc_minutes = 0
        @rtc_hours = 0
        @rtc_days = 0        # 9-bit day counter (0-511)
        @rtc_halt = false
        @rtc_carry = false

        # Latched RTC values (snapshot for reading)
        @rtc_latched_seconds = 0
        @rtc_latched_minutes = 0
        @rtc_latched_hours = 0
        @rtc_latched_days = 0
        @rtc_latched_halt = false
        @rtc_latched_carry = false

        # For RTC timing
        @rtc_last_update = Time.now.to_f
      end

      def [](i)
        case i
        when 0x0000...0x4000 # ROM Bank 0
          @game_program[i]
        when 0x4000...0x8000 # ROM Bank 01-7F
          addr = i - 0x4000
          offset = @rom_bank * 0x4000
          @game_program[offset + addr] || 0xFF
        when 0xA000...0xC000 # External RAM or RTC
          return 0xFF unless @ram_enabled

          if @rtc_select && @has_rtc
            read_rtc_register(@rtc_select)
          else
            addr = i - 0xA000
            offset = @ram_bank * 0x2000
            @ram[offset + addr] || 0xFF
          end
        else
          0xFF
        end
      end

      def []=(i, v)
        case i
        when 0x0000...0x2000 # RAM and Timer Enable
          @ram_enabled = (v & 0x0F) == 0x0A
        when 0x2000...0x4000 # ROM Bank Number
          @rom_bank = v & 0x7F
          @rom_bank = 1 if @rom_bank == 0  # Bank 0 maps to bank 1
        when 0x4000...0x6000 # RAM Bank / RTC Register Select
          if v <= 0x03
            # RAM bank select
            @ram_bank = v & 0x03
            @rtc_select = nil
          elsif v >= 0x08 && v <= 0x0C && @has_rtc
            # RTC register select
            @rtc_select = v
          end
        when 0x6000...0x8000 # Latch Clock Data
          if @has_rtc
            if v == 0x00
              @rtc_latch_pending = true
            elsif v == 0x01 && @rtc_latch_pending
              latch_rtc
              @rtc_latch_pending = false
            else
              @rtc_latch_pending = false
            end
          end
        when 0xA000...0xC000 # External RAM or RTC Write
          return unless @ram_enabled

          if @rtc_select && @has_rtc
            write_rtc_register(@rtc_select, v)
          else
            addr = i - 0xA000
            offset = @ram_bank * 0x2000
            @ram[offset + addr] = v
          end
        end
      end

      # Update RTC based on real elapsed time (call periodically)
      def update_rtc
        return unless @has_rtc && !@rtc_halt

        now = Time.now.to_f
        elapsed_seconds = (now - @rtc_last_update).to_i

        if elapsed_seconds > 0
          @rtc_last_update = now
          advance_rtc(elapsed_seconds)
        end
      end

      private

      def advance_rtc(seconds)
        return if @rtc_halt

        @rtc_seconds += seconds

        # Handle overflow cascade
        if @rtc_seconds >= 60
          minutes_to_add = @rtc_seconds / 60
          @rtc_seconds = @rtc_seconds % 60
          @rtc_minutes += minutes_to_add
        end

        if @rtc_minutes >= 60
          hours_to_add = @rtc_minutes / 60
          @rtc_minutes = @rtc_minutes % 60
          @rtc_hours += hours_to_add
        end

        if @rtc_hours >= 24
          days_to_add = @rtc_hours / 24
          @rtc_hours = @rtc_hours % 24
          @rtc_days += days_to_add
        end

        # Day counter is 9 bits (0-511), set carry on overflow
        if @rtc_days > 511
          @rtc_days = @rtc_days % 512
          @rtc_carry = true
        end
      end

      def latch_rtc
        update_rtc  # Ensure RTC is current before latching

        @rtc_latched_seconds = @rtc_seconds
        @rtc_latched_minutes = @rtc_minutes
        @rtc_latched_hours = @rtc_hours
        @rtc_latched_days = @rtc_days
        @rtc_latched_halt = @rtc_halt
        @rtc_latched_carry = @rtc_carry
        @rtc_latched = true
      end

      def read_rtc_register(reg)
        # Read from latched values
        case reg
        when RTC_SECONDS
          @rtc_latched_seconds
        when RTC_MINUTES
          @rtc_latched_minutes
        when RTC_HOURS
          @rtc_latched_hours
        when RTC_DAY_LOW
          @rtc_latched_days & 0xFF
        when RTC_DAY_HIGH
          value = 0
          value |= 0x01 if (@rtc_latched_days & 0x100) != 0  # Day counter bit 8
          value |= 0x40 if @rtc_latched_halt                  # Halt flag
          value |= 0x80 if @rtc_latched_carry                 # Carry flag
          value
        else
          0xFF
        end
      end

      def write_rtc_register(reg, value)
        case reg
        when RTC_SECONDS
          @rtc_seconds = value & 0x3F  # 0-59
        when RTC_MINUTES
          @rtc_minutes = value & 0x3F  # 0-59
        when RTC_HOURS
          @rtc_hours = value & 0x1F    # 0-23
        when RTC_DAY_LOW
          @rtc_days = (@rtc_days & 0x100) | value
        when RTC_DAY_HIGH
          @rtc_days = (@rtc_days & 0xFF) | ((value & 0x01) << 8)
          @rtc_halt = (value & 0x40) != 0
          @rtc_carry = (value & 0x80) != 0
        end

        # Reset timing reference when RTC is written
        @rtc_last_update = Time.now.to_f
      end
    end
  end
end
