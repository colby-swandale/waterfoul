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

    SDL.InitSubSystem(SDL::INIT_KEYBOARD)

    def self.read_keyboard(joyp)
      SDL.PumpEvents # update keyboard state
      keyboard = SDL.GetKeyboardState(nil)
      keyboard_state = keyboard.read_array_of_uint8(229)

      input = 0xF
      if joyp & 0x20 == 0x00
        if keyboard_state[SDL::SDL_SCANCODE_RETURN] == 1
          input ^= 0x8
        elsif keyboard_state[SDL::SDL_SCANCODE_RSHIFT] == 1
          input ^= 0x4
        elsif keyboard_state[SDL::SDL_SCANCODE_A] == 1
          input ^= 0x1
        elsif keyboard_state[SDL::SDL_SCANCODE_Z] == 1
          input ^= 0x2
        end
      elsif joyp & 0x10 == 0x0
        if keyboard_state[SDL::SDL_SCANCODE_UP] == 1
          input ^= 0x4
        elsif keyboard_state[SDL::SDL_SCANCODE_DOWN] == 1
          input ^= 0x8
        elsif keyboard_state[SDL::SDL_SCANCODE_LEFT] == 1
          input ^= 0x2
        elsif keyboard_state[SDL::SDL_SCANCODE_RIGHT] == 1
          input ^= 0x1
        end
      end

      (0xF0 & joyp) | input
    end
  end
end
