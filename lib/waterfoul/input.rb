require 'sdl2'

module Waterfoul
  class Input

    UP_INPUT_KEYCODE = 82
    DOWN_INPUT_KEYCODE = 81
    LEFT_INPUT_KEYCODE = 80
    RIGHT_INPUT_KEYCODE = 79
    A_INPUT_KEYCODE = 4
    B_INPUT_KEYCODE = 5
    START_INPUT_KEYCODE = 40
    SELECT_INPUT_KEYCODE = 229
    POLL_RATE = 5000

    def initialize
      @modeclock = 0
      @current_keys = 0
      $mmu.write_byte 0xFF00, 0xFF, hardware_operation: true
    end

    def step(cycles = 1)
      @modeclock += cycles
      event = SDL2::Event.poll

      if @modeclock >= POLL_RATE
        @modeclock -= POLL_RATE

        input = $mmu.read_byte 0xFF00

        if input & 0x10 == 0x00
          case @current_key
          when UP_INPUT_KEYCODE
            input ^= 0x4
          when DOWN_INPUT_KEYCODE
            input ^= 0x8
          when RIGHT_INPUT_KEYCODE
            input ^= 0x1
          when LEFT_INPUT_KEYCODE
            input ^= 0x2
          end
          @current_key = 0
          $mmu.write_byte 0xFF0F, input
          Interrupt.request_interrupt(Interrupt::INTERRUPT_JOYPAD)
        elsif input & 0x20 == 0x0
          case @current_key
          when A_INPUT_KEYCODE
            input ^= 0x1
          when B_INPUT_KEYCODE
            input ^= 0x2
          when START_INPUT_KEYCODE
            input ^= 0x8
          when SELECT_INPUT_KEYCODE
            input ^= 0x4
          end
          @current_key = 0
          $mmu.write_byte 0xFF0F, input
          Interrupt.request_interrupt(Interrupt::INTERRUPT_JOYPAD)
        end
      elsif event.kind_of?(SDL2::Event::KeyDown)
        @current_key = event.scancode
        p @current_key
      end
    end
  end
end
