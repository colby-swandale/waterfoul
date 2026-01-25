module Waterfoul
  class Screen
    WINDOW_WIDTH = 480
    WINDOW_HEIGHT = 432

    SCREEN_WIDTH = 160
    SCREEN_HEIGHT = 144

    # SDL_Event union size (56 bytes)
    SDL_EVENT_SIZE = 56

    def initialize
      SDL.Init 0
      SDL.InitSubSystem SDL::INIT_VIDEO
      @buffer = FFI::MemoryPointer.new :uint32, SCREEN_WIDTH * SCREEN_HEIGHT
      @event = FFI::MemoryPointer.new :uint8, SDL_EVENT_SIZE
      @window = SDL.CreateWindow 'waterfoul', SDL::SDL_WINDOWPOS_UNDEFINED, SDL::SDL_WINDOWPOS_UNDEFINED, WINDOW_WIDTH, WINDOW_HEIGHT, SDL::SDL_WINDOW_RESIZABLE
      @renderer = SDL.CreateRenderer @window, -1, 0
      SDL.SetHint "SDL_HINT_RENDER_SCALE_QUALITY",  "2"
      SDL.RenderSetLogicalSize(@renderer, WINDOW_WIDTH, WINDOW_HEIGHT)
      @texture = SDL.CreateTexture @renderer, SDL::PIXELFORMAT_ARGB8888, 1, SCREEN_WIDTH, SCREEN_HEIGHT
      @last = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def render(framebuffer)
      process_events
      @buffer.write_array_of_uint32 framebuffer
      SDL.UpdateTexture @texture, nil, @buffer, SCREEN_WIDTH * 4
      SDL.RenderClear @renderer
      SDL.RenderCopy @renderer, @texture, nil, nil
      SDL.RenderPresent @renderer

      t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      fps = 1.0 / (t - @last)
      fps = fps.floor.to_s
      @last = t

      SDL.SetWindowTitle(@window, "waterfoul (#{fps} fps)")
    end

    private

    def process_events
      while SDL.PollEvent(@event) != 0
        event_type = @event.read_uint32

        case event_type
        when SDL::SDL_QUIT
          # Window close button clicked
          exit(0)
        when SDL::SDL_KEYDOWN
          # Check for Cmd+Q (macOS) or Ctrl+Q
          # Scancode is at offset 16 in SDL_KeyboardEvent
          scancode = @event.get_uint32(16)
          if scancode == SDL::SDL_SCANCODE_Q
            mod_state = SDL.GetModState
            if (mod_state & SDL::KMOD_GUI) != 0 || (mod_state & SDL::KMOD_CTRL) != 0
              exit(0)
            end
          end
        end
      end
    end
  end
end
