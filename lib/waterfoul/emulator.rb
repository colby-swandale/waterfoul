require 'pp'
module Waterfoul
  class Emulator
    def initialize(rom_filename, options = {})
      # read the rom into host memory
      rom = read_program(rom_filename).bytes
      # initialize emulated CPU, GPU & Sound components
      cartridge = Cartridge.new rom
      # initialize emulated memory management unit
      $mmu = MMU.new cartridge
      cpu = CPU.new
      @cpu = options.has_key?('skip_boot') ? SkipBoot.set_state(cpu) : cpu
      @gpu = GPU.new
      @screen = Screen.new
      # @sound = Sound.new
    end

    def run
      loop do
        @cpu.step
        vblank = @gpu.step(@cpu.m)
        @screen.render(@gpu.framebuffer) if vblank
        # @sound.step
      end
    end

    private

    def read_program(rom)
      File.binread rom
    end
  end
end
