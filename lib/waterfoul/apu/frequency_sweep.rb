module Waterfoul
  class APU
    # Frequency sweep component for Channel 1.
    #
    # The frequency sweep periodically adjusts the channel's frequency up or down.
    # When clocked by the frame sequencer (at 128 Hz), it calculates a new frequency
    # based on the current frequency, shift amount, and direction.
    class FrequencySweep
      attr_reader :shadow_frequency

      def initialize
        @period = 0
        @direction = 0      # 0 = increase, 1 = decrease
        @shift = 0
        @shadow_frequency = 0
        @timer = 0
        @enabled = false
        @negate_used = false
      end

      # Configure the sweep from NR10 register.
      # @param value [Integer] NR10 register value
      #   Bits 6-4: Period
      #   Bit 3: Direction (0 = increase, 1 = decrease)
      #   Bits 2-0: Shift amount
      def set_register(value)
        @period = (value >> 4) & 0x07
        @direction = (value >> 3) & 0x01
        @shift = value & 0x07
      end

      # Clock the frequency sweep (called at 128 Hz by frame sequencer).
      # @return [Integer, nil] New frequency if changed, nil otherwise
      # @raise [Symbol] :overflow if frequency overflows (channel should be disabled)
      def clock
        return nil unless @enabled

        @timer -= 1 if @timer > 0

        return nil unless @timer == 0

        @timer = @period
        @timer = 8 if @period == 0

        return nil if @period == 0

        new_freq = calculate_frequency
        throw :overflow if new_freq > 2047

        if @shift > 0
          @shadow_frequency = new_freq
          # Check for overflow with new frequency
          throw :overflow if calculate_frequency > 2047
          return new_freq
        end

        nil
      end

      # Trigger the sweep (called when NR14 bit 7 is written).
      # @param frequency [Integer] Current channel frequency
      # @return [Boolean] true if channel should be disabled (overflow)
      def trigger(frequency)
        @shadow_frequency = frequency
        @timer = @period
        @timer = 8 if @period == 0
        @enabled = @period > 0 || @shift > 0
        @negate_used = false

        if @shift > 0
          new_freq = calculate_frequency
          return true if new_freq > 2047
        end

        false
      end

      # Check if negate mode was used then switched off.
      # This causes channel to be disabled (obscure hardware behavior).
      # @param new_direction [Integer] New direction value
      # @return [Boolean] true if channel should be disabled
      def check_negate_to_positive(new_direction)
        @negate_used && new_direction == 0
      end

      # Reset the sweep.
      def reset
        @period = 0
        @direction = 0
        @shift = 0
        @shadow_frequency = 0
        @timer = 0
        @enabled = false
        @negate_used = false
      end

      private

      def calculate_frequency
        delta = @shadow_frequency >> @shift

        if @direction == 1
          @negate_used = true
          @shadow_frequency - delta
        else
          @shadow_frequency + delta
        end
      end
    end
  end
end
