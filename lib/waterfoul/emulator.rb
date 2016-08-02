require 'sdl2'

module Waterfoul
  class Emulator
    def initialize(rom_filename, options = {})
      SDL2.init SDL2::INIT_EVERYTHING
      # read the rom into host memory
      rom = read_program(rom_filename).bytes
      # initialize emulated CPU, GPU & Sound components
      cartridge = Cartridge.new rom
      # initialize emulated memory management unit
      $mmu = MMU.new
      $mmu.cartridge = cartridge
      cpu = CPU.new
      @cpu = options.has_key?('skip_boot') ? SkipBoot.set_state(cpu) : cpu
      @gpu = GPU.new
      @input = Input.new
      @screen = Screen.new
      # @sound = Sound.new
    end

    def run
      loop do
        @cpu.step
        @gpu.step @cpu.m
        @screen.render @gpu.framebuffer if @gpu.vblank?
        @input.step @cpu.m
        # @sound.step
      end
    end

    private

    def read_program(rom)
      File.binread rom
    end
  end
end
