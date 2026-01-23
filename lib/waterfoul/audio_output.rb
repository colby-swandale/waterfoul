module Waterfoul
  # SDL2 audio output wrapper for the APU.
  #
  # Handles initialization of SDL2 audio subsystem and queuing of
  # audio samples for playback.
  class AudioOutput
    # Audio sample rate (Hz)
    SAMPLE_RATE = 44_100

    # Number of audio channels (stereo)
    CHANNELS = 2

    # Buffer size in samples (per channel)
    BUFFER_SAMPLES = 1024

    # Maximum queued audio size (in bytes) before dropping samples
    MAX_QUEUE_SIZE = SAMPLE_RATE * CHANNELS * 2 * 2  # ~2 seconds of audio

    attr_reader :device_id

    def initialize
      @device_id = 0
      @initialized = false
    end

    # Initialize SDL2 audio.
    # @return [Boolean] true if initialization succeeded
    def init
      return true if @initialized

      # Initialize SDL audio subsystem
      result = SDL.InitSubSystem(SDL::INIT_AUDIO)
      if result < 0
        warn "Failed to initialize SDL audio: #{SDL.GetError()}"
        return false
      end

      # Set up desired audio specification
      desired = SDL::AudioSpec.new
      desired[:freq] = SAMPLE_RATE
      desired[:format] = SDL::AUDIO_S16
      desired[:channels] = CHANNELS
      desired[:samples] = BUFFER_SAMPLES
      desired[:callback] = nil  # Using queue mode
      desired[:userdata] = nil

      obtained = SDL::AudioSpec.new

      # Open audio device
      @device_id = SDL.OpenAudioDevice(nil, 0, desired, obtained, 0)
      if @device_id == 0
        warn "Failed to open audio device: #{SDL.GetError()}"
        return false
      end

      # Unpause audio (SDL opens devices paused by default)
      SDL.PauseAudioDevice(@device_id, 0)

      @initialized = true
      true
    end

    # Queue audio samples for playback.
    # @param samples [Array<Integer>] Interleaved stereo samples (16-bit signed)
    def queue_audio(samples)
      return unless @initialized
      return if samples.empty?

      # Check if we have too much audio queued (prevent lag)
      queued_size = SDL.GetQueuedAudioSize(@device_id)
      if queued_size > MAX_QUEUE_SIZE
        # Drop this buffer to catch up
        return
      end

      # Convert Ruby array to packed binary data
      packed = samples.pack('s*')

      # Create FFI pointer for the data
      ptr = FFI::MemoryPointer.new(:int16, samples.size)
      ptr.put_bytes(0, packed)

      # Queue the audio
      SDL.QueueAudio(@device_id, ptr, packed.bytesize)
    end

    # Get the amount of queued audio in bytes.
    # @return [Integer] Bytes of audio queued
    def queued_size
      return 0 unless @initialized

      SDL.GetQueuedAudioSize(@device_id)
    end

    # Clear all queued audio.
    def clear
      return unless @initialized

      SDL.ClearQueuedAudio(@device_id)
    end

    # Pause audio playback.
    def pause
      return unless @initialized

      SDL.PauseAudioDevice(@device_id, 1)
    end

    # Resume audio playback.
    def resume
      return unless @initialized

      SDL.PauseAudioDevice(@device_id, 0)
    end

    # Close the audio device and clean up.
    def close
      return unless @initialized

      SDL.CloseAudioDevice(@device_id)
      @device_id = 0
      @initialized = false
    end

    # Check if audio is initialized.
    # @return [Boolean] true if initialized
    def initialized?
      @initialized
    end
  end
end
