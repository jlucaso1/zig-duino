# zig-duino

A tiny Zig workspace that builds both a host-side CLI and an AVR firmware using MicroZig. The firmware targets common Arduino Uno/Nano clones based on the ATmega328P and toggles the on-board LED (D13 / PB5).

## Overview

- Host app: `zig-out/bin/zig_duino` (a simple CLI built for your machine).
- Firmware: `zig-out/firmware/blink_avr.hex` (for ATmega328P boards; LED on PB5/D13).
- Toolchain: Zig 0.15.x + MicroZig for AVR.

## Prerequisites

- Zig 0.15.1 (check with `zig version`).
- avrdude (for flashing). On Arch Linux: `sudo pacman -S avrdude`.
- Serial access to `/dev/ttyUSB0`:
  - Quick path: prefix commands with `sudo`.
  - Recommended: add your user to the `uucp` group and re-login:
    ```sh
    sudo usermod -aG uucp "$USER"
    # log out/in or reboot for group to take effect
    ```
  - Alternatively, grant a temporary ACL:
    ```sh
    sudo setfacl -m u:$USER:rw /dev/ttyUSB0
    ```

Optional:

- PlatformIO CLI (handy for listing ports):
  ```sh
  pipx install platformio
  pio device list
  ```

## Build

Fetch dependencies (MicroZig) and build everything:

```sh
zig build --fetch
zig build
```

For AVR firmware, ensure `ReleaseSmall` optimizations when building:

```sh
zig build -Doptimize=ReleaseSmall
```

Artifacts:

- Host CLI: `zig-out/bin/zig_duino`
- Firmware HEX: `zig-out/firmware/blink_avr.hex`

## Flashing the Board

1. Identify the serial port. Typical on Linux with CH340: `/dev/ttyUSB0`.
2. Probe the MCU signature and bootloader baud with avrdude (Uno/Nano clones use 57600 or 115200):

   ```sh
   # Try 115200 first
   avrdude -c arduino -p m328p -P /dev/ttyUSB0 -b 115200 -v
   # If that fails, try 57600
   avrdude -c arduino -p m328p -P /dev/ttyUSB0 -b 57600 -v
   ```

   Expected signature for ATmega328P: `0x1E 0x95 0x0F`.

3. Flash the firmware (two options):
   - Using avrdude directly:
     ```sh
     avrdude -c arduino -p m328p -P /dev/ttyUSB0 -b 115200 -D \
       -U flash:w:zig-out/firmware/blink_avr.hex:i
     ```
   - Using the build-integrated flash step:
     ```sh
     zig build -Doptimize=ReleaseSmall flash \
       -Dflash-port=/dev/ttyUSB0 \
       -Dflash-baud=115200 \
       -Dflash-programmer=arduino \
       -Davrdude-bin=avrdude \
       -Dflash-mcu=m328p
     ```
     If you lack permissions on the serial device, prefix direct avrdude with `sudo` or fix permissions per Prerequisites.

## Project Layout

- `build.zig`: Builds the host app and configures MicroZig AVR firmware target.
- `build.zig.zon`: Zig dependency manifest (pulls MicroZig).
- `src/main.zig`: Host executable entry point.
- `src/root.zig`: Library for host app.
- `src/firmware.zig`: AVR blink firmware using MicroZig HAL (PB5/D13 toggle).
- `zig-out/`: Build outputs. Firmware HEX in `zig-out/firmware/`.

## Current State

- Board detected as an Arduino-compatible with CH340 USB-serial.
- AVR target assumed ATmega328P (Arduino Nano/Uno clone) @ 16 MHz.
- Firmware builds and flashes successfully using avrdude at 115200 baud.
- Output file present: `zig-out/firmware/blink_avr.hex`.

## Troubleshooting

- **Permission denied on `/dev/ttyUSB0`**:
  - Add user to `uucp` group or use `sudo`/ACL as shown above.
- **`avrdude` sync errors**:
  - Toggle baud between 115200 and 57600.
  - Press the reset button on the board just as the upload begins.
  - Ensure you’re using `-c arduino -p m328p` for ATmega328P bootloaders.
- **Build errors regarding `compiler_rt` or odd integer sizes**:
  - Use `-Doptimize=ReleaseSmall` and avoid pulling in heavy helpers.
  - This project disables bundling `compiler_rt` for the AVR firmware via build.zig.
- **Firmware hangs after refactoring `comptime` logic or only show white colors**:
  - **Problem**: When refactoring repetitive logic from `main` into a helper function (e.g., a function that draws a character and then calls a `comptime` delay), the program may hang after the first iteration on real hardware. This can happen with AVR targets under `ReleaseSmall` optimization, as the compiler's behavior with nested `comptime` arguments can be unpredictable.
  - **Solution**: A more robust pattern is to perform the logic directly inside an `inline for` loop within your main loop. This allows you to eliminate code duplication in the source while ensuring the compiler unrolls the operations in a simple, predictable way, avoiding complex function call chains that might confuse the optimizer.

## Next Steps

- Adjust the LED pin or board target in `src/firmware.zig` / `build.zig` if using a different AVR.
- Add a serial "hello" example using `USART` via MicroZig HAL.
- Create a `flash` build step that invokes avrdude automatically.

---

Maintained with Zig + MicroZig. Have fun hacking your Arduino-compatible in Zig!
