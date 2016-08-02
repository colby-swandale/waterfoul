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
    POLL_RATE = 65536

    def initialize
      @modeclock = 0
      @current_key = 0
      $mmu.write_byte 0xFF00, 0x3F, hardware_operation: true
    end

    def step(cycles = 1)
      @modeclock =+ cycles
      event = SDL2::Event.poll
      if @modeclock >= POLL_RATE
        @modeclock -= POLL_RATE

        return unless @current_key > 0
        joypad_byte = $mmu.read_byte 0xFF00
        key_byte = 0x3F

        if joypad_byte & 0x10 == 0x00
          case @current_key
          when UP_INPUT_KEYCODE
            key_byte ^= 0x4
          when DOWN_INPUT_KEYCODE
            key_byte ^= 0x8
          when RIGHT_INPUT_KEYCODE
            key_byte ^= 0x1
          when LEFT_INPUT_KEYCODE
            key_byte ^= 0x2
          end
          p "bar!"
        elsif joypad_byte & 0x20 == 0x00
          case @current_key
          when A_INPUT_KEYCODE
            key_byte ^= 0x1
          when B_INPUT_KEYCODE
            key_byte ^= 0x2
          when START_INPUT_KEYCODE
            key_byte ^= 0x8
          when SELECT_INPUT_KEYCODE
            key_byte ^= 0x4
          end
          p "foo!"
        end

        $mmu.write_byte 0xFF00, (joypad_byte & key_byte), hardware_operation: true
        Interrupt.request_interrupt Interrupt::INTERRUPT_JOYPAD
      elsif event.kind_of? SDL2::Event::KeyDown
        @current_key = event.scancode
      end
    end
  end
end
