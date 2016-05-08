require 'spec_helper'

describe Waterfoul::CPU do

  describe 'CPU instruction timings' do
    before { $mmu = Waterfoul::MMU.new }

    ZERO_JUMP_INSTR = [:call_nz_a16, :call_nc_a16, :jp_nc_a16, :jp_nz_nn,
    :ret_nc, :ret_nz, :jr_nc_r8, :jr_nz_r8, :jp_nz_a16].freeze

    OPCODE_TIMINGS = [
      1, 3, 2, 2, 1, 1, 2, 1, 5, 2, 2, 2, 1, 1, 2, 1,
      1, 3, 2, 2, 1, 1, 2, 1, 3, 2, 2, 2, 1, 1, 2, 1,
      2, 3, 2, 2, 1, 1, 2, 1, 2, 2, 2, 2, 1, 1, 2, 1,
      2, 3, 2, 2, 3, 3, 3, 1, 2, 2, 2, 2, 1, 1, 2, 1,
      1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
      1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
      1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
      2, 2, 2, 2, 2, 2, 1, 2, 1, 1, 1, 1, 1, 1, 2, 1,
      1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
      1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
      1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
      1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
      2, 3, 3, 4, 3, 4, 2, 4, 2, 4, 3, 1, 3, 6, 2, 4,
      2, 3, 3, 0, 3, 4, 2, 4, 2, 4, 3, 0, 3, 0, 2, 4,
      3, 3, 2, 0, 0, 4, 2, 4, 4, 1, 4, 0, 0, 0, 2, 4,
      3, 3, 2, 1, 0, 4, 2, 4, 3, 2, 4, 1, 0, 0, 2, 4,
    ].freeze

    OPCODE_CONDITIONAL_TIMINGS = [
      1, 3, 2, 2, 1, 1, 2, 1, 5, 2, 2, 2, 1, 1, 2, 1,
      1, 3, 2, 2, 1, 1, 2, 1, 3, 2, 2, 2, 1, 1, 2, 1,
      3, 3, 2, 2, 1, 1, 2, 1, 3, 2, 2, 2, 1, 1, 2, 1,
      3, 3, 2, 2, 3, 3, 3, 1, 3, 2, 2, 2, 1, 1, 2, 1,
      1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
      1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
      1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
      2, 2, 2, 2, 2, 2, 1, 2, 1, 1, 1, 1, 1, 1, 2, 1,
      1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
      1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
      1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
      1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
      5, 3, 4, 4, 6, 4, 2, 4, 5, 4, 4, 1, 6, 6, 2, 4,
      5, 3, 4, 0, 6, 4, 2, 4, 5, 4, 4, 0, 6, 0, 2, 4,
      3, 3, 2, 0, 0, 4, 2, 4, 4, 1, 4, 0, 0, 0, 2, 4,
      3, 3, 2, 1, 0, 4, 2, 4, 3, 2, 4, 1, 0, 0, 2, 4,
    ].freeze

    Waterfoul::CPU::OPCODE.each_with_index do |instruction, index|
      next if instruction == :prefix_cb
      describe "\##{instruction}" do
        context "when flags reset" do
          if ZERO_JUMP_INSTR.include? instruction
            cpu = Waterfoul::CPU.new pc: 0xABAC, sp: 0xFFF0, f: 0xF0
          else
            cpu = Waterfoul::CPU.new pc: 0xABAC, sp: 0xFFF0, f: 0x00
          end

          # skip the test if the instruction is not implemnted
          next if instruction == :xx || instruction == :prefix_cb

          before { allow(cpu).to receive(:fetch_instruction).and_return(index) }
          it "sets clock cycle" do
            instruction_cycles = OPCODE_TIMINGS[index]
            cpu.perform_instruction index
            expect(cpu.m).to eq instruction_cycles
          end
        end

        context 'with all flags set' do
          if ZERO_JUMP_INSTR.include? instruction
            cpu = Waterfoul::CPU.new pc: 0xABAC, sp: 0xFFF0, f: 0x00
          else
            cpu = Waterfoul::CPU.new pc: 0xABAC, sp: 0xFFF0, f: 0xF0
          end

          next if instruction == :xx || instruction == :prefix_cb

          before { allow(cpu).to receive(:fetch_instruction).and_return(index) }
          it 'sets clock cycle' do
            instruction_cycles = OPCODE_CONDITIONAL_TIMINGS[index]
            cpu.perform_instruction index
            expect(cpu.m).to eq instruction_cycles
          end
        end
      end
    end
  end
end
