# Waterfoul
Waterfoul is a Gameboy emulator written in Ruby-lang. It is just a casual excersize by myself to learn the internals
of the device and how it works.

## Requirements
The [sdl2](https://www.libsdl.org/download-2.0.php) library is currenty used to render pixels. Most platforms have packages avaliable, else see the [here](https://wiki.libsdl.org/Installation). This library is required and needs to be installed before you can run the emulator.

## Can it play roms?
No. But a lot of work is being put into making a compatable emulator. The device does boot the internal program succesfully and is running emulator testing programs sucesfully (barggs).

## Testing
If you wish to run the test suite, download the source code (make sure to run `bundle instlall`) and run `bundle exec rspec`
