module Waterfoul
  module IO
    class LCDStatus
      MODE_FLAGS = { 0x0 => :H_BLANK, 0x1 => :V_BLANK, 0x10 => :OAM_READ, 0x11 => :LCD_TRANSFER }

      def initialize
        @state = 0
      end

      def set_state(byte)
        @state = byte
      end

      def mode_flag
        case (@state & 0x3)
        when 0b0
          :H_BLANK
        when 0b1
          :V_BLANK
        when 0b10
          :OAM_READ
        when 0b11
          :LCD_TRANSFER
        else
          byebug
        end
      end
    end
  end
end
