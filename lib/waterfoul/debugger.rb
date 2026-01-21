require 'waterfoul/debugger/disassembler'
require 'waterfoul/debugger/state_printer'

module Waterfoul
  class Debugger
    attr_reader :cpu, :mmu

    def initialize(options = {})
      @start_pc = options[:pc] || 0x0000
      @start_sp = options[:sp] || 0xFFFE
      @memory_range = options[:memory_range]
      @program_bytes = []
      @program_end = 0
      @total_cycles = 0
      @step_count = 0
    end

    def load_program(bytes, start_address = nil)
      start_address ||= @start_pc
      @program_bytes = bytes
      @program_end = start_address + bytes.length

      # Setup environment with program bytes pre-loaded into ROM
      setup_environment(bytes, start_address)

      # Set PC to start address
      @cpu.instance_variable_set(:@pc, start_address)
    end

    def run
      @printer = StatePrinter.new
      @disassembler = Disassembler.new

      @printer.print_initial_state(@cpu, @mmu, memory_range: @memory_range)

      loop do
        result = step
        break if result == :halt || result == :stop || result == :end
      end
    end

    def step
      return :end if @cpu.pc >= @program_end

      # Check for HALT/STOP before executing
      opcode = @mmu.read_byte(@cpu.pc)
      return handle_halt if opcode == 0x76  # HALT
      return handle_stop if opcode == 0x10  # STOP

      @step_count += 1

      # Get instruction info before executing
      instruction_bytes = fetch_instruction_bytes(@cpu.pc)
      instruction_info = @disassembler.decode(instruction_bytes)

      # Track memory changes
      memory_changes = track_memory_changes do
        @cpu.step
      end

      @total_cycles += @cpu.m

      @printer.print_state(
        @step_count,
        @cpu,
        @mmu,
        instruction_info,
        @cpu.m,
        memory_changes,
        memory_range: @memory_range
      )

      :continue
    end

    private

    def setup_environment(program_bytes = [], start_address = 0)
      # Create ROM data (32KB) with program bytes pre-loaded
      rom_data = Array.new(0x8000, 0)
      rom_data[Cartridge::CARTRIDGE_TYPE_MEM_LOC] = 0x00  # ROM only type

      # Load program bytes into ROM data at start_address
      program_bytes.each_with_index do |byte, i|
        addr = start_address + i
        rom_data[addr] = byte if addr < 0x8000
      end

      # Create cartridge with pre-loaded program
      cartridge = Cartridge.new(rom_data)

      # Create MMU and bypass boot ROM by setting cartridge directly
      @mmu = MMU.new(cartridge)
      @mmu.instance_variable_set(:@cartridge, cartridge)

      # Set global MMU (required by CPU)
      $mmu = @mmu

      # Create CPU
      @cpu = CPU.new

      # Set initial SP
      @cpu.instance_variable_set(:@sp, @start_sp)
    end

    def fetch_instruction_bytes(pc)
      opcode = @mmu.read_byte(pc)
      length = Disassembler.new.instruction_length(opcode)

      # For CB prefix, we need 2 bytes
      length = 2 if opcode == 0xCB

      bytes = []
      length.times do |i|
        bytes << @mmu.read_byte(pc + i)
      end
      bytes
    end

    def track_memory_changes
      # Capture memory state before execution (only track working RAM and HRAM regions)
      # We track: C000-DFFF (WRAM), FE00-FEFF (OAM), FF00-FFFF (IO/HRAM)
      prev_state = {}
      track_regions = [
        (0xC000..0xDFFF),  # Working RAM
        (0xFE00..0xFEFF),  # OAM
        (0xFF00..0xFFFF)   # IO + HRAM
      ]

      track_regions.each do |range|
        range.each do |addr|
          prev_state[addr] = @mmu.memory[addr]
        end
      end

      yield

      # Find changes
      changes = []
      prev_state.each do |addr, old_val|
        new_val = @mmu.memory[addr]
        changes << [addr, old_val, new_val] if old_val != new_val
      end
      changes
    end

    def handle_halt
      @step_count += 1
      instruction_info = { mnemonic: 'HALT', bytes: [0x76], length: 1 }

      @printer.print_state(
        @step_count,
        @cpu,
        @mmu,
        instruction_info,
        4,
        [],
        memory_range: @memory_range
      )
      @printer.print_halt_message
      :halt
    end

    def handle_stop
      @step_count += 1
      instruction_info = { mnemonic: 'STOP', bytes: [0x10, 0x00], length: 2 }

      @printer.print_state(
        @step_count,
        @cpu,
        @mmu,
        instruction_info,
        4,
        [],
        memory_range: @memory_range
      )
      @printer.print_stop_message
      :stop
    end
  end
end
