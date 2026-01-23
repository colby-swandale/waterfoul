module Waterfoul
  class APU
    # Pulse channel (Square wave) for Channels 1 and 2.
    #
    # Generates a square wave with selectable duty cycle (12.5%, 25%, 50%, 75%).
    # Channel 1 has frequency sweep capability, Channel 2 does not.
    class PulseChannel
      # Duty cycle waveforms (8 samples each)
      DUTY_WAVEFORMS = [
        [0, 0, 0, 0, 0, 0, 0, 1],  # 12.5%
        [0, 0, 0, 0, 0, 0, 1, 1],  # 25%
        [0, 0, 0, 0, 1, 1, 1, 1],  # 50%
        [1, 1, 1, 1, 1, 1, 0, 0]   # 75%
      ].freeze

      attr_reader :enabled
      attr_accessor :length_counter, :volume_envelope, :frequency_sweep

      # @param has_sweep [Boolean] Whether this channel has frequency sweep (CH1 only)
      def initialize(has_sweep: false)
        @has_sweep = has_sweep

        @length_counter = LengthCounter.new(64)
        @volume_envelope = VolumeEnvelope.new
        @frequency_sweep = FrequencySweep.new if has_sweep

        @enabled = false
        @duty = 0
        @frequency = 0
        @period = 8192  # (2048 - 0) * 4, cached for performance
        @timer = 0
        @duty_position = 0
      end

      # Tick the channel by multiple T-cycles (batched for performance).
      # @param cycles [Integer] Number of T-cycles to advance
      def tick(cycles = 1)
        return unless @enabled

        @timer -= cycles
        return if @timer > 0

        # Timer expired - calculate how many duty advances
        # Handle multiple underflows if cycles > period
        if @period > 0
          while @timer <= 0
            @timer += @period
            @duty_position = (@duty_position + 1) & 0x07
          end
        else
          @timer = 0
        end
      end

      # Get the current output sample (0-15).
      # @return [Integer] Current amplitude (0 or current volume)
      def output
        return 0 unless @enabled
        return 0 unless @volume_envelope.dac_enabled?

        DUTY_WAVEFORMS[@duty][@duty_position] * @volume_envelope.volume
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

      # Clock the frequency sweep (128 Hz, CH1 only).
      def clock_sweep
        return unless @has_sweep

        result = catch(:overflow) do
          new_freq = @frequency_sweep.clock
          if new_freq
            @frequency = new_freq
            @period = (2048 - @frequency) * 4
          end
          nil
        end

        disable if result == :overflow
      end

      # Write to NRx0 register (Sweep, CH1 only).
      # @param value [Integer] Register value
      def write_nr0(value)
        return unless @has_sweep

        old_direction = (@frequency_sweep.instance_variable_get(:@direction))
        @frequency_sweep.set_register(value)
        new_direction = (value >> 3) & 0x01

        disable if @frequency_sweep.check_negate_to_positive(new_direction) && old_direction == 1
      end

      # Write to NRx1 register (Length/Duty).
      # @param value [Integer] Register value
      def write_nr1(value)
        @duty = (value >> 6) & 0x03
        @length_counter.set_length(value & 0x3F)
      end

      # Write to NRx2 register (Volume Envelope).
      # @param value [Integer] Register value
      def write_nr2(value)
        @volume_envelope.set_register(value)
        disable unless @volume_envelope.dac_enabled?
      end

      # Write to NRx3 register (Frequency low).
      # @param value [Integer] Register value
      def write_nr3(value)
        @frequency = (@frequency & 0x700) | value
        @period = (2048 - @frequency) * 4
      end

      # Write to NRx4 register (Trigger/Length enable/Frequency high).
      # @param value [Integer] Register value
      def write_nr4(value)
        @frequency = (@frequency & 0xFF) | ((value & 0x07) << 8)
        @period = (2048 - @frequency) * 4
        @length_counter.enabled = (value & 0x40) != 0

        trigger if (value & 0x80) != 0
      end

      # Read NRx0 register.
      # @return [Integer] Register value with unused bits set
      def read_nr0
        return 0xFF unless @has_sweep

        sweep = @frequency_sweep
        period = sweep.instance_variable_get(:@period)
        direction = sweep.instance_variable_get(:@direction)
        shift = sweep.instance_variable_get(:@shift)

        0x80 | (period << 4) | (direction << 3) | shift
      end

      # Read NRx1 register.
      # @return [Integer] Register value (only duty bits readable)
      def read_nr1
        0x3F | (@duty << 6)
      end

      # Read NRx2 register.
      # @return [Integer] Register value
      def read_nr2
        envelope = @volume_envelope
        initial = envelope.instance_variable_get(:@initial_volume)
        direction = envelope.instance_variable_get(:@direction)
        period = envelope.instance_variable_get(:@period)

        (initial << 4) | (direction << 3) | period
      end

      # Read NRx3 register.
      # @return [Integer] Always 0xFF (write-only)
      def read_nr3
        0xFF
      end

      # Read NRx4 register.
      # @return [Integer] Register value (only length enable readable)
      def read_nr4
        0xBF | (@length_counter.enabled ? 0x40 : 0)
      end

      # Disable the channel.
      def disable
        @enabled = false
      end

      # Reset the channel.
      def reset
        @enabled = false
        @duty = 0
        @frequency = 0
        @period = 8192
        @timer = 0
        @duty_position = 0
        @length_counter.reset
        @volume_envelope.reset
        @frequency_sweep&.reset
      end

      private

      def trigger
        @enabled = true
        @length_counter.trigger
        @volume_envelope.trigger
        @timer = @period

        if @has_sweep
          overflow = @frequency_sweep.trigger(@frequency)
          disable if overflow
        end

        disable unless @volume_envelope.dac_enabled?
      end
    end
  end
end
