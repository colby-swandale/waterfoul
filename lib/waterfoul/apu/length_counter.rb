module Waterfoul
  class APU
    # Length counter component for APU channels.
    #
    # The length counter automatically disables the channel after a specified
    # duration. When clocked by the frame sequencer (at 256 Hz), it decrements
    # the counter and disables the channel when it reaches zero.
    class LengthCounter
      attr_reader :counter
      attr_accessor :enabled

      # @param max_length [Integer] Maximum length value (64 for pulse/noise, 256 for wave)
      def initialize(max_length = 64)
        @max_length = max_length
        @counter = 0
        @enabled = false
      end

      # Set the length from a register write.
      # Length is stored as (max - value), so writing 0 gives max length.
      # @param value [Integer] Value written to length register
      def set_length(value)
        @counter = @max_length - value
      end

      # Clock the length counter (called at 256 Hz by frame sequencer).
      # @return [Boolean] true if channel should be disabled
      def clock
        return false unless @enabled
        return false if @counter == 0

        @counter -= 1
        @counter == 0
      end

      # Trigger the channel (called when NRx4 bit 7 is written).
      # If counter is 0, reload with max length.
      def trigger
        @counter = @max_length if @counter == 0
      end

      # Reset the length counter.
      def reset
        @counter = 0
        @enabled = false
      end
    end
  end
end
