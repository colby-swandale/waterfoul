module Waterfoul
  class EmulatorError < StandardError; end
  # raised if read/write outside avaliable memory made
  class MemoryOutOfBounds < EmulatorError; end
  # raised if unimplemented OPCODE called
  class InstructionNotImplemented < EmulatorError; end
  # raised if an `xx` instruction is called anytime
  class InvalidInstruction < EmulatorError; end
end
