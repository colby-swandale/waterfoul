require 'waterfoul/apu/length_counter'
require 'waterfoul/apu/volume_envelope'
require 'waterfoul/apu/frequency_sweep'
require 'waterfoul/apu/pulse_channel'
require 'waterfoul/apu/wave_channel'
require 'waterfoul/apu/noise_channel'

module Waterfoul
  # Audio Processing Unit (APU) for the Game Boy.
  #
  # The APU generates audio using 4 channels:
  # - Channel 1: Pulse with sweep
  # - Channel 2: Pulse without sweep
  # - Channel 3: Wave (custom waveform)
  # - Channel 4: Noise (LFSR)
  #
  # Audio is mixed and output at 44100 Hz through SDL2.
  class APU
    # Game Boy clock rate (T-cycles per second)
    GB_CLOCK_RATE = 4_194_304

    # Audio sample rate
    SAMPLE_RATE = 44_100

    # T-cycles per audio sample
    CYCLES_PER_SAMPLE = GB_CLOCK_RATE.to_f / SAMPLE_RATE

    # Frame sequencer rate (512 Hz, clocked every 8192 T-cycles)
    FRAME_SEQUENCER_CYCLES = 8192

    # Audio buffer size (number of samples)
    BUFFER_SIZE = 1024

    # Pre-allocated buffer capacity (stereo samples, so 2x for L+R)
    BUFFER_CAPACITY = 4096

    # Register addresses
    NR10 = 0xFF10  # CH1 Sweep
    NR11 = 0xFF11  # CH1 Length/Duty
    NR12 = 0xFF12  # CH1 Volume Envelope
    NR13 = 0xFF13  # CH1 Frequency Low
    NR14 = 0xFF14  # CH1 Frequency High/Trigger

    NR21 = 0xFF16  # CH2 Length/Duty
    NR22 = 0xFF17  # CH2 Volume Envelope
    NR23 = 0xFF18  # CH2 Frequency Low
    NR24 = 0xFF19  # CH2 Frequency High/Trigger

    NR30 = 0xFF1A  # CH3 DAC Enable
    NR31 = 0xFF1B  # CH3 Length
    NR32 = 0xFF1C  # CH3 Volume
    NR33 = 0xFF1D  # CH3 Frequency Low
    NR34 = 0xFF1E  # CH3 Frequency High/Trigger

    NR41 = 0xFF20  # CH4 Length
    NR42 = 0xFF21  # CH4 Volume Envelope
    NR43 = 0xFF22  # CH4 Polynomial Counter
    NR44 = 0xFF23  # CH4 Trigger

    NR50 = 0xFF24  # Master Volume
    NR51 = 0xFF25  # Panning
    NR52 = 0xFF26  # Master Enable

    WAVE_RAM_START = 0xFF30
    WAVE_RAM_END = 0xFF3F

    attr_reader :channel1, :channel2, :channel3, :channel4, :audio_output

    def initialize(audio_output = nil)
      @channel1 = APU::PulseChannel.new(has_sweep: true)
      @channel2 = APU::PulseChannel.new(has_sweep: false)
      @channel3 = APU::WaveChannel.new
      @channel4 = APU::NoiseChannel.new

      @audio_output = audio_output

      # Master control registers
      @nr50 = 0x77  # Default: volume 7 on both channels
      @nr51 = 0xF3  # Default: CH1+CH2 to both, CH3+CH4 to left
      @nr52 = 0xF1  # Default: APU on, CH1 enabled

      # Timing
      @frame_sequencer_step = 0
      @frame_sequencer_counter = 0
      @sample_counter = 0.0

      # Audio buffer (pre-allocated to avoid GC pressure)
      @sample_buffer = Array.new(BUFFER_CAPACITY, 0)
      @buffer_index = 0
      @enabled = true

      # High-pass filter state (removes DC offset)
      @hp_left = 0.0
      @hp_right = 0.0
      @capacitor_left = 0.0
      @capacitor_right = 0.0
    end

    # Tick the APU by the given number of T-cycles.
    # @param cycles [Integer] Number of T-cycles to advance
    def tick(cycles)
      return unless @enabled
      return if cycles == 0

      # Batch frame sequencer counter updates
      @frame_sequencer_counter += cycles
      while @frame_sequencer_counter >= FRAME_SEQUENCER_CYCLES
        @frame_sequencer_counter -= FRAME_SEQUENCER_CYCLES
        clock_frame_sequencer
      end

      # Batch sample counter updates
      @sample_counter += cycles
      while @sample_counter >= CYCLES_PER_SAMPLE
        @sample_counter -= CYCLES_PER_SAMPLE
        generate_sample
      end

      # Tick channels (use while loop to avoid block allocation)
      i = 0
      while i < cycles
        @channel1.tick
        @channel2.tick
        @channel3.tick
        @channel4.tick
        i += 1
      end
    end

    # Read an APU register.
    # @param address [Integer] Register address (0xFF10-0xFF3F)
    # @return [Integer] Register value
    def read_register(address)
      case address
      when NR10 then @channel1.read_nr0
      when NR11 then @channel1.read_nr1
      when NR12 then @channel1.read_nr2
      when NR13 then @channel1.read_nr3
      when NR14 then @channel1.read_nr4
      when 0xFF15 then 0xFF  # Unused

      when NR21 then @channel2.read_nr1
      when NR22 then @channel2.read_nr2
      when NR23 then @channel2.read_nr3
      when NR24 then @channel2.read_nr4
      when 0xFF1F then 0xFF  # Unused

      when NR30 then @channel3.read_nr30
      when NR31 then @channel3.read_nr31
      when NR32 then @channel3.read_nr32
      when NR33 then @channel3.read_nr33
      when NR34 then @channel3.read_nr34

      when NR41 then @channel4.read_nr41
      when NR42 then @channel4.read_nr42
      when NR43 then @channel4.read_nr43
      when NR44 then @channel4.read_nr44

      when NR50 then @nr50
      when NR51 then @nr51
      when NR52 then read_nr52

      when WAVE_RAM_START..WAVE_RAM_END
        @channel3.read_wave_ram(address)

      else
        0xFF
      end
    end

    # Write to an APU register.
    # @param address [Integer] Register address (0xFF10-0xFF3F)
    # @param value [Integer] Value to write
    def write_register(address, value)
      # Wave RAM is always writable
      if address >= WAVE_RAM_START && address <= WAVE_RAM_END
        @channel3.write_wave_ram(address, value)
        return
      end

      # NR52 power control is always writable
      if address == NR52
        write_nr52(value)
        return
      end

      # Other registers are ignored when APU is off
      return unless @enabled

      case address
      when NR10 then @channel1.write_nr0(value)
      when NR11 then @channel1.write_nr1(value)
      when NR12 then @channel1.write_nr2(value)
      when NR13 then @channel1.write_nr3(value)
      when NR14 then @channel1.write_nr4(value)

      when NR21 then @channel2.write_nr1(value)
      when NR22 then @channel2.write_nr2(value)
      when NR23 then @channel2.write_nr3(value)
      when NR24 then @channel2.write_nr4(value)

      when NR30 then @channel3.write_nr30(value)
      when NR31 then @channel3.write_nr31(value)
      when NR32 then @channel3.write_nr32(value)
      when NR33 then @channel3.write_nr33(value)
      when NR34 then @channel3.write_nr34(value)

      when NR41 then @channel4.write_nr41(value)
      when NR42 then @channel4.write_nr42(value)
      when NR43 then @channel4.write_nr43(value)
      when NR44 then @channel4.write_nr44(value)

      when NR50 then @nr50 = value
      when NR51 then @nr51 = value
      end
    end

    # Check if samples are ready to be played.
    # @return [Boolean] true if buffer has enough samples
    def samples_ready?
      @buffer_index >= BUFFER_SIZE
    end

    # Get and clear the sample buffer.
    # @return [Array<Integer>] Stereo samples (interleaved L/R)
    def flush_samples
      samples = @sample_buffer[0, @buffer_index]
      @buffer_index = 0
      samples
    end

    # Queue audio to SDL output if ready.
    def queue_audio
      return unless @audio_output
      return unless samples_ready?

      @audio_output.queue_audio(flush_samples)
    end

    # Reset the APU.
    def reset
      @channel1.reset
      @channel2.reset
      @channel3.reset
      @channel4.reset

      @nr50 = 0x77
      @nr51 = 0xF3
      @nr52 = 0xF1

      @frame_sequencer_step = 0
      @frame_sequencer_counter = 0
      @sample_counter = 0.0
      @buffer_index = 0
      @enabled = true

      # Reset high-pass filter
      @hp_left = 0.0
      @hp_right = 0.0
      @capacitor_left = 0.0
      @capacitor_right = 0.0
    end

    private

    def clock_frame_sequencer
      case @frame_sequencer_step
      when 0
        clock_length_counters
      when 2
        clock_length_counters
        @channel1.clock_sweep
      when 4
        clock_length_counters
      when 6
        clock_length_counters
        @channel1.clock_sweep
      when 7
        clock_envelopes
      end

      @frame_sequencer_step = (@frame_sequencer_step + 1) & 7
    end

    def clock_length_counters
      @channel1.clock_length
      @channel2.clock_length
      @channel3.clock_length
      @channel4.clock_length
    end

    def clock_envelopes
      @channel1.clock_envelope
      @channel2.clock_envelope
      @channel4.clock_envelope
    end

    def generate_sample
      return unless @enabled

      # Get channel outputs (0-15) and center each around 7.5
      # Only apply centering if channel is actively producing sound
      # (both enabled AND DAC on). Otherwise contribute silence (0).
      ch1 = (@channel1.enabled && @channel1.dac_enabled?) ? @channel1.output - 7.5 : 0
      ch2 = (@channel2.enabled && @channel2.dac_enabled?) ? @channel2.output - 7.5 : 0
      ch3 = (@channel3.enabled && @channel3.dac_enabled?) ? @channel3.output - 7.5 : 0
      ch4 = (@channel4.enabled && @channel4.dac_enabled?) ? @channel4.output - 7.5 : 0

      # Mix for left channel (range: -30 to +30 with all 4 channels)
      left = 0.0
      left += ch1 if (@nr51 & 0x10) != 0
      left += ch2 if (@nr51 & 0x20) != 0
      left += ch3 if (@nr51 & 0x40) != 0
      left += ch4 if (@nr51 & 0x80) != 0

      # Mix for right channel
      right = 0.0
      right += ch1 if (@nr51 & 0x01) != 0
      right += ch2 if (@nr51 & 0x02) != 0
      right += ch3 if (@nr51 & 0x04) != 0
      right += ch4 if (@nr51 & 0x08) != 0

      # Apply master volume (0-7, stored as 1-8 for multiplication)
      left_vol = ((@nr50 >> 4) & 0x07) + 1
      right_vol = (@nr50 & 0x07) + 1

      left = (left * left_vol) / 8.0
      right = (right * right_vol) / 8.0

      # Apply high-pass filter to remove DC offset (like real hardware capacitor)
      # Formula: output = input - capacitor; capacitor += (input - capacitor) * charge_factor
      # Charge factor ~0.999958 at 44100Hz gives ~90Hz cutoff
      charge_factor = 0.999958
      @capacitor_left += (left - @capacitor_left) * (1.0 - charge_factor)
      @capacitor_right += (right - @capacitor_right) * (1.0 - charge_factor)
      left = left - @capacitor_left
      right = right - @capacitor_right

      # Convert to signed 16-bit samples (-32768 to 32767)
      # Scale factor increased for better audibility
      # Max amplitude is ~30, scale to use more of 16-bit range
      left_sample = (left * 2048).to_i.clamp(-32768, 32767)
      right_sample = (right * 2048).to_i.clamp(-32768, 32767)

      # Use index-based writing to avoid array growth allocations
      @sample_buffer[@buffer_index] = left_sample
      @sample_buffer[@buffer_index + 1] = right_sample
      @buffer_index += 2
    end

    def read_nr52
      status = @enabled ? 0x80 : 0x00
      status |= 0x70  # Unused bits read as 1
      status |= 0x01 if @channel1.enabled
      status |= 0x02 if @channel2.enabled
      status |= 0x04 if @channel3.enabled
      status |= 0x08 if @channel4.enabled
      status
    end

    def write_nr52(value)
      was_enabled = @enabled
      @enabled = (value & 0x80) != 0

      power_off unless @enabled && was_enabled
    end

    def power_off
      @channel1.reset
      @channel2.reset
      @channel3.reset
      @channel4.reset

      @nr50 = 0
      @nr51 = 0
      @frame_sequencer_step = 0
    end
  end
end
