require 'spec_helper'

describe Waterfoul::CPU do

  describe 'CPU instruction timings' do
    before { $mmu = Waterfoul::MMU.new }
    subject { Waterfoul::CPU.new }
    before { subject.set_register :pc, 0x100 }
    before { subject.set_register :sp, 0x200 }

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

    ZERO_JUMP_INSTR = [:call_nz_a16, :call_nc_a16, :jp_nc_a16, :jp_nz_nn,
      :ret_nc, :ret_nz, :jr_nc_r8, :jr_nz_r8, :jp_nz_a16].freeze

    describe 'instruction timings' do
      Waterfoul::CPU::OPCODE.each_with_index do |instruction, index|
        next if instruction == :prefix_cb || instruction == :xx

        describe instruction do
          context 'with all status flag bits reset' do
            before { subject.set_register :f, 0xF0 } if ZERO_JUMP_INSTR.include?(instruction)
            it 'sets the correct instruction timing' do
              instruction_cycles = OPCODE_TIMINGS[index]
              subject.perform_instruction index
              expect(subject.m).to eq (instruction_cycles * 4)
            end
          end

          context 'with all status flag bits set' do
            before { subject.set_register :f, 0xF0 } unless ZERO_JUMP_INSTR.include?(instruction)
            it 'sets the correct instruction timing' do
              instruction_cycles = OPCODE_CONDITIONAL_TIMINGS[index]
              subject.perform_instruction index
              expect(subject.m).to eq (instruction_cycles * 4)
            end
          end
        end
      end
    end
  end
end
