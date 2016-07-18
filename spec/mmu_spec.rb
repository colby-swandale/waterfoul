require 'spec_helper'

describe Waterfoul::MMU do
  subject { Waterfoul::MMU.new }

  describe 'DIV register' do
    before { subject.write_byte 0xFF04, 0x25, hardware_operation: true }
    it 'resets when written to' do
      subject.write_byte 0xFF04, 0x35
      expect(subject.read_byte(0xFF04)).to eq 0
    end
  end
end
