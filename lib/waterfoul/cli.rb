require "thor"

module Waterfoul
  class CLI < Thor
    desc 'start ROM', 'start the emulator'
    option :gbc, type: :boolean, desc: 'Enable Game Boy Color mode'
    option :stackprof, type: :boolean, desc: 'Enable CPU profiling with stackprof'
    option :profile_frames, type: :numeric, desc: 'Stop after N frames (for profiling)'
    def start(rom_file)
      emu = Waterfoul::Emulator.new rom_file, options

      if options[:stackprof]
        require 'stackprof'
        output_file = 'stackprof.dump'

        puts "StackProf profiling enabled. Results will be saved to #{output_file}"
        if options[:profile_frames]
          puts "Will stop after #{options[:profile_frames]} frames"
        else
          puts "Press Ctrl+C to stop and save profile"
        end

        # Handle Ctrl+C to save profile
        trap('INT') do
          puts "\nStopping profiler..."
          StackProf.stop
          results = StackProf.results
          File.write(output_file, Marshal.dump(results))
          puts "Profile saved to #{output_file}"
          puts "View with: stackprof #{output_file} --text --limit 30"
          exit(0)
        end

        StackProf.start(mode: :cpu, interval: 1000, raw: true)
        begin
          if options[:profile_frames]
            emu.run_frames(options[:profile_frames])
          else
            emu.run
          end
        ensure
          StackProf.stop
          results = StackProf.results
          if results
            File.write(output_file, Marshal.dump(results))
            puts "\nProfile saved to #{output_file}"
            puts "View with: stackprof #{output_file} --text --limit 30"
          end
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

