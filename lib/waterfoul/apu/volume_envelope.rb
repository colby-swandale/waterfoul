module Waterfoul
  class APU
    # Volume envelope component for APU channels.
    #
    # The volume envelope provides automatic volume fade in/out for channels 1, 2, and 4.
    # When clocked by the frame sequencer (at 64 Hz), it adjusts the volume up or down
    # by 1 every N clocks where N is the period.
    class VolumeEnvelope
      attr_reader :volume

      def initialize
        @initial_volume = 0
        @direction = 0      # 0 = decrease, 1 = increase
        @period = 0
        @volume = 0
        @timer = 0
      end

      # Configure the envelope from NRx2 register.
      # @param value [Integer] NRx2 register value
      #   Bits 7-4: Initial volume
      #   Bit 3: Direction (0 = down, 1 = up)
      #   Bits 2-0: Period (0 = disabled)
      def set_register(value)
        @initial_volume = (value >> 4) & 0x0F
        @direction = (value >> 3) & 0x01
        @period = value & 0x07
      end

      # Clock the volume envelope (called at 64 Hz by frame sequencer).
      def clock
        return if @period == 0

        @timer -= 1 if @timer > 0

        return unless @timer == 0

        @timer = @period

        if @direction == 1 && @volume < 15
          @volume += 1
        elsif @direction == 0 && @volume > 0
          @volume -= 1
        end
      end

      # Trigger the envelope (called when NRx4 bit 7 is written).
      def trigger
        @volume = @initial_volume
        @timer = @period
        @timer = 8 if @timer == 0
      end

      # Check if DAC is enabled (volume or direction bits set).
      # @return [Boolean] true if DAC is enabled
      def dac_enabled?
        @initial_volume > 0 || @direction == 1
      end

      # Reset the envelope.
      def reset
        @initial_volume = 0
        @direction = 0
        @period = 0
        @volume = 0
        @timer = 0
      end
    end
  end
end
