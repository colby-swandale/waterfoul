require "thor"

module Waterfoul
  class CLI < Thor
    desc 'start ROM', 'start the emulator'
    option :skip_boot
    option :stackprof, :type => :boolean
    def start(rom_file)
      emu = Waterfoul::Emulator.new rom_file, options

      if options.has_key?('stackprof')
        require 'stackprof'
        StackProf.start(mode: :cpu)
        begin
          emu.run
        ensure
          StackProf.stop
          StackProf.results('stackprof.dump')
        end
      else
        emu.run
      end
    end
  end
end

