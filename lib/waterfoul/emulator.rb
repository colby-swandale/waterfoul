module Waterfoul
  # The Emulator is the abstraction of the emulator as a whole, it initializes
  # each component and performs the tick.
  class Emulator
    # Game Boy runs at ~59.7 FPS, use 60 FPS for simplicity
    TARGET_FPS = 60
    FRAME_TIME = 1.0 / TARGET_FPS

    def initialize(rom_filename, options = {})
      # read the given file as binary and break it down into an array of bytes
      rom = File.binread(rom_filename).bytes
      # initialize emulated CPU, GPU & Scren components
      @cartridge = Cartridge.new rom

      # Detect GBC mode: CLI flag must be set AND cartridge must be GBC compatible
      @gbc_mode = options.has_key?('gbc') && Cartridge.gbc_compatible?(rom)

      $mmu = MMU.new(@cartridge, gbc_mode: @gbc_mode)
      @cpu = CPU.new
      SkipBoot.set_state(@cpu, gbc_mode: @gbc_mode)
      @ppu = PPU.new(gbc_mode: @gbc_mode)
      @screen = Screen.new

      # Initialize audio
      @audio_output = AudioOutput.new
      @audio_output.init
      $apu = APU.new(@audio_output)

      # Frame timing for 60 FPS cap
      @last_frame_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def run
      # Handle Ctrl+C gracefully
      trap('INT') { exit(0) }

      loop do
        @cpu.step
        cycles = @cpu.m
        @ppu.step cycles
        $apu.tick(cycles) if $apu
        Input.tick(cycles)
        if @ppu.vblank?
          @screen.render @ppu.framebuffer
          limit_frame_rate
        end
        $apu.queue_audio if $apu
      end
    end

    private

    def limit_frame_rate
      current_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      elapsed = current_time - @last_frame_time
      sleep_time = FRAME_TIME - elapsed

      if sleep_time > 0
        sleep(sleep_time)
        @last_frame_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      else
        @last_frame_time = current_time
      end
    end

    public

    # Run for a specific number of frames (useful for profiling)
    def run_frames(frame_count)
      frames = 0
      while frames < frame_count
        @cpu.step
        cycles = @cpu.m
        @ppu.step cycles
        $apu.tick(cycles) if $apu
        Input.tick(cycles)
        if @ppu.vblank?
          @screen.render @ppu.framebuffer
          $apu.queue_audio if $apu
          frames += 1
          print "\rFrame #{frames}/#{frame_count}" if frames % 10 == 0
        end
      end
      puts "\nCompleted #{frame_count} frames"
    end
  end
end
