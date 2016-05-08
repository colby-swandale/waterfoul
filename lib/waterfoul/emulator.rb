module Waterfoul
  class Emulator
    def initialize(gamefile, options = {})
      # read the rom into host memory
      rom = read_rom(gamefile).bytes
      # initialize emulated CPU, GPU & Sound components
      cartridge = Cartridge.new rom
      # initialize emulated memory management unit
      $mmu = MMU.new cartridge
      cpu = CPU.new
      @cpu = options[:skip_boot] ? SkipBoot.set_state(cpu) : cpu
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

    def read_rom(rom)
      File.binread rom
    end
  end
end
