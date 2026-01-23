module Waterfoul
  class APU
    # Noise channel (Channel 4).
    #
    # Generates pseudo-random noise using a Linear Feedback Shift Register (LFSR).
    # Can operate in 15-bit or 7-bit mode, with configurable frequency.
    class NoiseChannel
      # Divisor table for noise frequency
      DIVISORS = [8, 16, 32, 48, 64, 80, 96, 112].freeze

      attr_reader :enabled
      attr_accessor :length_counter, :volume_envelope

      def initialize
        @length_counter = LengthCounter.new(64)
        @volume_envelope = VolumeEnvelope.new

        @enabled = false
        @clock_shift = 0
        @width_mode = false  # false = 15-bit, true = 7-bit
        @divisor_code = 0
        @period = 8  # DIVISORS[0] << 0, cached for performance
        @timer = 0
        @lfsr = 0x7FFF  # 15-bit LFSR, all 1s
      end

      # Tick the channel by multiple T-cycles (batched for performance).
      # @param cycles [Integer] Number of T-cycles to advance
      def tick(cycles = 1)
        return unless @enabled

        @timer -= cycles
        return if @timer > 0

        # Timer expired - clock LFSR for each expiration
        if @period > 0
          while @timer <= 0
            @timer += @period
            clock_lfsr
          end
        else
          @timer = 0
        end
      end

      # Get the current output sample (0-15).
      # @return [Integer] Current amplitude
      def output
        return 0 unless @enabled
        return 0 unless @volume_envelope.dac_enabled?

        # Output is inverted bit 0 of LFSR
        ((~@lfsr) & 1) * @volume_envelope.volume
      end

      # Check if this channel's DAC is enabled.
      # @return [Boolean] true if DAC is producing signal
      def dac_enabled?
        @volume_envelope.dac_enabled?
      end

      # Clock the length counter (256 Hz).
      def clock_length
        disable if @length_counter.clock
      end

      # Clock the volume envelope (64 Hz).
      def clock_envelope
        @volume_envelope.clock
      end

      # Write to NR41 register (Length).
      # @param value [Integer] Register value
      def write_nr41(value)
        @length_counter.set_length(value & 0x3F)
      end

      # Write to NR42 register (Volume Envelope).
      # @param value [Integer] Register value
      def write_nr42(value)
        @volume_envelope.set_register(value)
        disable unless @volume_envelope.dac_enabled?
      end

      # Write to NR43 register (Polynomial Counter).
      # @param value [Integer] Register value
      def write_nr43(value)
        @clock_shift = (value >> 4) & 0x0F
        @width_mode = (value & 0x08) != 0
        @divisor_code = value & 0x07
        @period = DIVISORS[@divisor_code] << @clock_shift
      end

      # Write to NR44 register (Trigger/Length enable).
      # @param value [Integer] Register value
      def write_nr44(value)
        @length_counter.enabled = (value & 0x40) != 0

        trigger if (value & 0x80) != 0
      end

      # Read NR41 register.
      # @return [Integer] Always 0xFF (write-only)
      def read_nr41
        0xFF
      end

      # Read NR42 register.
      # @return [Integer] Register value
      def read_nr42
        envelope = @volume_envelope
        initial = envelope.instance_variable_get(:@initial_volume)
        direction = envelope.instance_variable_get(:@direction)
        period = envelope.instance_variable_get(:@period)

        (initial << 4) | (direction << 3) | period
      end

      # Read NR43 register.
      # @return [Integer] Register value
      def read_nr43
        (@clock_shift << 4) | (@width_mode ? 0x08 : 0) | @divisor_code
      end

      # Read NR44 register.
      # @return [Integer] Register value (only length enable readable)
      def read_nr44
        0xBF | (@length_counter.enabled ? 0x40 : 0)
      end

      # Disable the channel.
      def disable
        @enabled = false
      end

      # Reset the channel.
      def reset
        @enabled = false
        @clock_shift = 0
        @width_mode = false
        @divisor_code = 0
        @period = 8
        @timer = 0
        @lfsr = 0x7FFF
        @length_counter.reset
        @volume_envelope.reset
      end

      private

      def trigger
        @enabled = true
        @length_counter.trigger
        @volume_envelope.trigger
        @timer = @period
        @lfsr = 0x7FFF

        disable unless @volume_envelope.dac_enabled?
      end

      def clock_lfsr
        # XOR bits 0 and 1
        xor_result = (@lfsr & 0x01) ^ ((@lfsr >> 1) & 0x01)

        # Shift right
        @lfsr >>= 1

        # Set bit 14 to XOR result
        @lfsr |= (xor_result << 14)

        # In 7-bit mode, also set bit 6
        if @width_mode
          @lfsr &= ~(1 << 6)
          @lfsr |= (xor_result << 6)
        end
      end
    end
  end
end
