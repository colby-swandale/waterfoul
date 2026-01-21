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

    desc 'debug', 'Debug CPU instructions step-by-step'
    option :hex, type: :string, desc: 'Hex bytes to execute (e.g., "3E 42 06 10 80")'
    option :file, type: :string, desc: 'Binary file with instructions'
    option :memory, type: :string, desc: 'Memory range to display (e.g., C000-C0FF)'
    option :pc, type: :numeric, default: 0, desc: 'Starting PC address'
    option :sp, type: :numeric, default: 0xFFFE, desc: 'Starting SP address'
    def debug
      require 'waterfoul/debugger'

      bytes = parse_input_bytes
      if bytes.nil? || bytes.empty?
        puts "Error: No input provided. Use --hex or --file option."
        puts "Examples:"
        puts "  waterfoul debug --hex \"3E 42 06 10 80\""
        puts "  waterfoul debug --file test.bin"
        return
      end

      debugger = Waterfoul::Debugger.new(
        pc: options[:pc],
        sp: options[:sp],
        memory_range: options[:memory]
      )

      debugger.load_program(bytes, options[:pc])
      debugger.run
    end

    private

    def parse_input_bytes
      if options[:hex]
        # Parse hex string like "3E 42 06 10 80"
        options[:hex].split(/\s+/).map { |b| b.to_i(16) }
      elsif options[:file]
        # Read binary file
        if File.exist?(options[:file])
          File.binread(options[:file]).bytes
        else
          puts "Error: File not found: #{options[:file]}"
          nil
        end
      else
        nil
      end
    end
  end
end

