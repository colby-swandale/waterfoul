# Waterfoul
Waterfoul is a Gameboy emulator written in Ruby-lang. It is just a casual excersize by myself to learn the internals
of the device and how it works.

## Requirements
The [sdl2](https://www.libsdl.org/download-2.0.php) library is currenty used to render pixels. Most platforms have packages avaliable, else see [here](https://wiki.libsdl.org/Installation). This library is required and needs to be installed before you can run the emulator.

## Can it play roms?
Yes! but the list of roms that i know work is very limited to just Tetris, Super Mario Land and Pokemon Red. But a lot of work is being put into making other games compatable. The device does run the internal boot program succesfully and is passing test programs sucesfully (barggs).

## Testing
If you wish to run the test suite, download the source code (make sure to run `bundle install`) and run `bundle exec rspec`

## How do i run the emulator?
If you wish to see the emulator in action, download a rom online which typically have a .gb extension and place it onto your local file system. To start the emulator:

`bundle exec exe/waterfoul start <path to rom>`

Make sure to bundle install first.

The boot program will be executed by default, if you wish to skip it add `--skip-boot` as an option.
