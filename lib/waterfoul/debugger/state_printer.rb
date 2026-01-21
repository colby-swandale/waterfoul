module Waterfoul
  class Debugger
    class StatePrinter
      def initialize
        @disassembler = Disassembler.new
      end

      def print_state(step_num, cpu, mmu, instruction_info, cycles, memory_changes, memory_range: nil)
        output = []

        # Header with instruction info
        bytes_str = @disassembler.format_bytes(instruction_info[:bytes])
        output << "Step #{step_num}: #{instruction_info[:mnemonic]}  (#{bytes_str})"
        output << "\u2500" * 50

        # Registers section
        output << "Registers:"
        output << format_8bit_registers(cpu)
        output << format_16bit_registers(cpu)
        output << format_pc_sp(cpu)
        output << ""

        # Flags and cycles
        output << format_flags_and_cycles(cpu, cycles)
        output << ""

        # Memory changes
        output << format_memory_changes(memory_changes)

        # Optional memory range display
        if memory_range
          output << ""
          output << format_memory_range(mmu, memory_range)
        end

        output << ""
        puts output.join("\n")
      end

      def print_initial_state(cpu, mmu, memory_range: nil)
        output = []
        output << "Initial State"
        output << "\u2500" * 50

        output << "Registers:"
        output << format_8bit_registers(cpu)
        output << format_16bit_registers(cpu)
        output << format_pc_sp(cpu)
        output << ""

        output << format_flags_and_cycles(cpu, 0)

        if memory_range
          output << ""
          output << format_memory_range(mmu, memory_range)
        end

        output << ""
        puts output.join("\n")
      end

      def print_halt_message
        puts "\u2500" * 50
        puts "CPU HALTED"
        puts "\u2500" * 50
      end

      def print_stop_message
        puts "\u2500" * 50
        puts "CPU STOPPED"
        puts "\u2500" * 50
      end

      def print_end_of_program
        puts "\u2500" * 50
        puts "End of program reached"
        puts "\u2500" * 50
      end

      private

      def format_8bit_registers(cpu)
        format(
          "  A: %02X   B: %02X   C: %02X   D: %02X   E: %02X   H: %02X   L: %02X   F: %02X",
          cpu.a, cpu.b, cpu.c, cpu.d, cpu.e, cpu.h, cpu.l, cpu.f
        )
      end

      def format_16bit_registers(cpu)
        af = (cpu.a << 8) | cpu.f
        bc = (cpu.b << 8) | cpu.c
        de = (cpu.d << 8) | cpu.e
        hl = (cpu.h << 8) | cpu.l
        format("  AF: %04X   BC: %04X   DE: %04X   HL: %04X", af, bc, de, hl)
      end

      def format_pc_sp(cpu)
        format("  SP: %04X   PC: %04X", cpu.sp, cpu.pc)
      end

      def format_flags_and_cycles(cpu, cycles)
        z = (cpu.f & Z_FLAG) != 0 ? 1 : 0
        n = (cpu.f & N_FLAG) != 0 ? 1 : 0
        h = (cpu.f & H_FLAG) != 0 ? 1 : 0
        c = (cpu.f & C_FLAG) != 0 ? 1 : 0
        format("Flags: Z:%d N:%d H:%d C:%d    Cycles: %d", z, n, h, c, cycles)
      end

      def format_memory_changes(changes)
        if changes.empty?
          "Memory Changes: (none)"
        else
          lines = ["Memory Changes:"]
          changes.each do |addr, old_val, new_val|
            lines << format("  $%04X: %02X -> %02X", addr, old_val, new_val)
          end
          lines.join("\n")
        end
      end

      def format_memory_range(mmu, range_str)
        # Parse range like "C000-C0FF"
        match = range_str.match(/([0-9A-Fa-f]+)-([0-9A-Fa-f]+)/)
        return "Invalid memory range: #{range_str}" unless match

        start_addr = match[1].to_i(16)
        end_addr = match[2].to_i(16)

        lines = [format("Memory [$%04X - $%04X]:", start_addr, end_addr)]

        (start_addr..end_addr).each_slice(16) do |addrs|
          addr = addrs.first
          bytes = addrs.map { |a| format('%02X', mmu.read_byte(a)) }
          ascii = addrs.map { |a| printable_char(mmu.read_byte(a)) }
          lines << format("  %04X: %-48s %s", addr, bytes.join(' '), ascii.join)
        end

        lines.join("\n")
      end

      def printable_char(byte)
        (byte >= 0x20 && byte < 0x7F) ? byte.chr : '.'
      end
    end
  end
end
