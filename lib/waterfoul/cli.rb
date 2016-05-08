require "thor"
module Waterfoul
  class CLI < Thor
    desc 'start ROM', 'start the emulator'
    option :skip_boot
    def self.start(rom)
      emu = Waterfoul::Emulator.new rom.first, options
      emu.run
    end
  end
end

