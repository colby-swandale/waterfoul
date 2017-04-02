module Waterfoul
  class Timer
    DIV_INC_TIME = 256 # cycles

    def initialize
      @div_cycles = 0
      @tima_cycles = 0
      @tima = TIMA.new
    end

    def tick(cycles = 0)
      @div_cycles += cycles
      # incremnt DIV register if its time to
      inc_div_register if @div_cycles >= DIV_INC_TIME
      # update TIMA register
      @tima.update
      # dont bother if TIMA is not running
      if @tima.running?
        # increment TIMA and DIV register
        @tima_cycles += cycles
        frequency = @tima.frequency
        if @tima_cycles >= frequency
          inc_tima_register
          @tima_cycles -= frequency
        end
      end
    end

    def inc_tima_register
      tima = $mmu.read_memory_byte 0xFF05
      if tima == 0xFF
        tima = $mmu.read_memory_byte 0xFF06
        Interrupt.request_interrupt(Interrupt::INTERRUPT_TIMER)
      else
        tima += 1
      end

      $mmu.write_byte 0xFF05, tima, hardware_operation: true
    end

    def inc_div_register
      div = $mmu.read_memory_byte 0xFF04
      div = (div + 1) & 0xFF
      $mmu.write_byte 0xFF04, div, hardware_operation: true
      @div_cycles -= DIV_INC_TIME
    end
  end

  class TIMA
    def initialize
      @register = 0
    end

    def update
      @register = $mmu.read_memory_byte 0xFF07
    end

    def running?
      @register & 0x4 == 0x4
    end

    def frequency
      case @register & 0x3
      when 0x0
        1024
      when 0x1
        16
      when 0x2
        64
      when 0x3
        256
      end
    end
  end
end
