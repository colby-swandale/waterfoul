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
    end

    def run
      loop do
        @cpu.step
        @ppu.step @cpu.m
        @screen.render @ppu.framebuffer if @ppu.vblank?
      end
    end
  end
end
