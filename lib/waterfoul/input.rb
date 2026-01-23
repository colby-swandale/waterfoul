module Waterfoul
  class Input
    # Cache keyboard state, update every N cycles or once per frame
    # SDL.PumpEvents is expensive - called on every 0xFF00 read
    # 8192 cycles = ~8-9 polls/frame (still very responsive for 60Hz games)
    POLL_INTERVAL = 8192

    SDL.InitSubSystem(SDL::INIT_KEYBOARD)

    @keyboard_state = nil
    @last_joyp = 0
    @cycles_since_poll = POLL_INTERVAL  # Start ready to poll

    class << self
      attr_accessor :keyboard_state, :last_joyp, :cycles_since_poll
    end

    def self.tick(cycles)
      @cycles_since_poll += cycles
    end

    def self.read_keyboard(joyp)
      # Only poll SDL when interval elapsed OR joyp selection changed
      if @cycles_since_poll >= POLL_INTERVAL || joyp != @last_joyp
        @cycles_since_poll = 0
        @last_joyp = joyp
        SDL.PumpEvents
        keyboard = SDL.GetKeyboardState(nil)
        @keyboard_state = keyboard.read_array_of_uint8(229)
      end

      # Use cached keyboard state
      compute_input(joyp, @keyboard_state)
    end

    def self.compute_input(joyp, keyboard_state)
      return (0xF0 & joyp) | 0xF if keyboard_state.nil?

      input = 0xF
      if joyp & 0x20 == 0x00
        # Button keys (allow multiple simultaneous)
        input ^= 0x8 if keyboard_state[SDL::SDL_SCANCODE_RETURN] == 1
        input ^= 0x4 if keyboard_state[SDL::SDL_SCANCODE_RSHIFT] == 1
        input ^= 0x1 if keyboard_state[SDL::SDL_SCANCODE_A] == 1
        input ^= 0x2 if keyboard_state[SDL::SDL_SCANCODE_Z] == 1
      elsif joyp & 0x10 == 0x0
        # D-pad keys (allow multiple simultaneous)
        input ^= 0x4 if keyboard_state[SDL::SDL_SCANCODE_UP] == 1
        input ^= 0x8 if keyboard_state[SDL::SDL_SCANCODE_DOWN] == 1
        input ^= 0x2 if keyboard_state[SDL::SDL_SCANCODE_LEFT] == 1
        input ^= 0x1 if keyboard_state[SDL::SDL_SCANCODE_RIGHT] == 1
      end

      (0xF0 & joyp) | input
    end
  end
end
