module Waterfoul
  class APU
    # Wave channel (Channel 3).
    #
    # Plays a custom 32-sample waveform stored in Wave RAM (0xFF30-0xFF3F).
    # Each byte stores two 4-bit samples.
    class WaveChannel
      WAVE_RAM_START = 0xFF30
      WAVE_RAM_END = 0xFF3F

      # Volume shift values for each level (0=mute, 1=100%, 2=50%, 3=25%)
      VOLUME_SHIFTS = [4, 0, 1, 2].freeze

      attr_reader :enabled
      attr_accessor :length_counter

      def initialize
        @length_counter = LengthCounter.new(256)

        @enabled = false
        @dac_enabled = false
        @volume_code = 0
        @frequency = 0
        @timer = 0
        @position = 0
        @sample_buffer = 0
        @sample_dirty = true  # Lazy sample extraction

        # Wave RAM (16 bytes = 32 samples)
        @wave_ram = Array.new(16, 0)
      end

      # Tick the channel by one T-cycle.
      def tick
        return unless @enabled

        @timer -= 1
        return unless @timer <= 0

        @timer = (2048 - @frequency) * 2
        @position = (@position + 1) & 0x1F
        @sample_dirty = true  # Mark for lazy extraction in output()
      end

      # Get the current output sample (0-15).
      # @return [Integer] Current amplitude
      def output
        return 0 unless @enabled
        return 0 unless @dac_enabled

        # Lazy sample extraction - only compute when needed
        if @sample_dirty
          byte_index = @position >> 1
          sample = @wave_ram[byte_index]
          @sample_buffer = if (@position & 1) == 0
                             (sample >> 4) & 0x0F
                           else
                             sample & 0x0F
                           end
          @sample_dirty = false
        end

        @sample_buffer >> VOLUME_SHIFTS[@volume_code]
      end

      # Check if this channel's DAC is enabled.
      # @return [Boolean] true if DAC is producing signal
      def dac_enabled?
        @dac_enabled
      end

      # Clock the length counter (256 Hz).
      def clock_length
        disable if @length_counter.clock
      end

      # Write to NR30 register (DAC enable).
      # @param value [Integer] Register value
      def write_nr30(value)
        @dac_enabled = (value & 0x80) != 0
        disable unless @dac_enabled
      end

      # Write to NR31 register (Length).
      # @param value [Integer] Register value
      def write_nr31(value)
        @length_counter.set_length(value)
      end

      # Write to NR32 register (Volume).
      # @param value [Integer] Register value
      def write_nr32(value)
        @volume_code = (value >> 5) & 0x03
      end

      # Write to NR33 register (Frequency low).
      # @param value [Integer] Register value
      def write_nr33(value)
        @frequency = (@frequency & 0x700) | value
      end

      # Write to NR34 register (Trigger/Length enable/Frequency high).
      # @param value [Integer] Register value
      def write_nr34(value)
        @frequency = (@frequency & 0xFF) | ((value & 0x07) << 8)
        @length_counter.enabled = (value & 0x40) != 0

        trigger if (value & 0x80) != 0
      end

      # Write to Wave RAM.
      # @param address [Integer] Address (0xFF30-0xFF3F)
      # @param value [Integer] Value to write
      def write_wave_ram(address, value)
        index = address - WAVE_RAM_START
        @wave_ram[index] = value
      end

      # Read from Wave RAM.
      # @param address [Integer] Address (0xFF30-0xFF3F)
      # @return [Integer] Value at address
      def read_wave_ram(address)
        index = address - WAVE_RAM_START

        if @enabled
          # When channel is on, reading returns the current sample byte
          @wave_ram[@position >> 1]
        else
          @wave_ram[index]
        end
      end

      # Read NR30 register.
      # @return [Integer] Register value
      def read_nr30
        0x7F | (@dac_enabled ? 0x80 : 0)
      end

      # Read NR31 register.
      # @return [Integer] Always 0xFF (write-only)
      def read_nr31
        0xFF
      end

      # Read NR32 register.
      # @return [Integer] Register value
      def read_nr32
        0x9F | (@volume_code << 5)
      end

      # Read NR33 register.
      # @return [Integer] Always 0xFF (write-only)
      def read_nr33
        0xFF
      end

      # Read NR34 register.
      # @return [Integer] Register value (only length enable readable)
      def read_nr34
        0xBF | (@length_counter.enabled ? 0x40 : 0)
      end

      # Disable the channel.
      def disable
        @enabled = false
      end

      # Reset the channel.
      def reset
        @enabled = false
        @dac_enabled = false
        @volume_code = 0
        @frequency = 0
        @timer = 0
        @position = 0
        @sample_buffer = 0
        @sample_dirty = true
        @length_counter.reset
        # Wave RAM is not cleared on reset
      end

      private

      def trigger
        @enabled = true if @dac_enabled
        @length_counter.trigger
        @timer = (2048 - @frequency) * 2
        @position = 0
      end
    end
  end
end
