module Waterfoul
  # The Emulator is the abstraction of the emulator as a whole, it initializes
  # each component and performs the tick.
  class Emulator
    def initialize(rom_filename, options = {})
      # read the given file as binary and break it down into an array of bytes
      rom = File.binread(rom_filename).bytes
      # initialize emulated CPU, GPU & Scren components
      @cartridge = Cartridge.new rom
      $mmu = MMU.new(@cartridge)
      @cpu = CPU.new
      @cpu = SkipBoot.set_state(@cpu) if options.has_key?('skip_boot')
      @ppu = PPU.new
      @screen = Screen.new

      # Initialize audio
      @audio_output = AudioOutput.new
      @audio_output.init
      $apu = APU.new(@audio_output)
    end

    def run
      loop do
        @cpu.step
        cycles = @cpu.m
        @ppu.step cycles
        $apu.tick(cycles) if $apu
        Input.tick(cycles)
        @screen.render @ppu.framebuffer if @ppu.vblank?
        $apu.queue_audio if $apu
      end
    end

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
