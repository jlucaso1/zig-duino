const std = @import("std");
const microzig = @import("microzig");
const hal = microzig.hal;

fn delay_us(us: u16) void {
    var i: u16 = 0;
    while (i < us) : (i += 1) {
        asm volatile (
            \\ nop
            \\ nop
            \\ nop
            \\ nop
        );
    }
}

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
};

pub fn Ws2812(comptime pin_name: []const u8, comptime led_count: u16) type {
    return struct {
        const Self = @This();
        const LedPin = hal.parse_pin(pin_name);
        const led_buffer_size = led_count * 3;

        const port_io_addr: u5 = 3 * @intFromEnum(LedPin.port) + 0x02;
        const pin_bit: u3 = LedPin.pin;

        leds: [led_buffer_size]u8,

        pub fn init(self: *Self) void {
            var i: usize = 0;
            while (i < self.leds.len) : (i += 1) {
                self.leds[i] = 0;
            }

            hal.gpio.set_output(LedPin);
            hal.gpio.write(LedPin, .low);
        }

        pub fn setPixelColor(self: *Self, index: u16, color: Color) void {
            if (index >= led_count) return;
            const i = index * 3;
            self.leds[i] = color.g;
            self.leds[i + 1] = color.r;
            self.leds[i + 2] = color.b;
        }

        pub fn show(self: *Self) void {
            const ptr_addr = @intFromPtr(&self.leds);

            const ptr_lo_byte: u8 = @truncate(ptr_addr);
            const ptr_hi_byte: u8 = @truncate(ptr_addr >> 8);
            const len_lo_byte: u8 = @truncate(led_buffer_size);
            const len_hi_byte: u8 = @truncate(led_buffer_size >> 8);

            asm volatile ("cli" ::: .{ .memory = true });

            asm volatile (
                \\ LDI  r28, %[len_hi]
                \\ LDI  r29, %[len_lo]
                \\ MOV  r30, %[ptr_lo]
                \\ MOV  r31, %[ptr_hi]
                \\
                \\ loop:
                \\   LD   r24, Z+        ; Load the next byte from the buffer
                \\   LDI  r25, 8         ; Reset the bit counter
                \\
                \\ bitloop:
                \\   SBI  %[port], %[pin] ; (2 cycles) Set pin HIGH
                \\   LSL  r24            ; (1 cycle)  Shift the next bit into the Carry flag
                \\   NOP                  ; (1 cycle)  Extend the high pulse
                \\   NOP                  ; (1 cycle)
                \\   BRCS is_one          ; (1/2 cycles) Branch if the bit was a 1
                \\
                \\ is_zero:               ; --- Path for a '0' bit ---
                \\   CBI  %[port], %[pin] ; (2 cycles) Set pin LOW. Total HIGH time for '0' is ~437.5ns
                \\   NOP                  ;
                \\   NOP                  ;
                \\   NOP                  ;
                \\   NOP                  ;
                \\   RJMP end_of_bit      ; Jump to the end of the bit
                \\
                \\ is_one:                ; --- Path for a '1' bit ---
                \\   NOP                  ; Extend HIGH time for '1'. Total HIGH time for '1' is ~812.5ns
                \\   NOP                  ;
                \\   NOP                  ;
                \\   NOP                  ;
                \\   NOP                  ;
                \\   CBI  %[port], %[pin] ; (2 cycles) Set pin LOW
                \\
                \\ end_of_bit:
                \\   DEC  r25            ; Decrement bit counter
                \\   BRNE bitloop         ; Loop if there are more bits in this byte
                \\
                \\   SBIW r28, 1          ; Decrement byte counter
                \\   BRNE loop            ; Loop if there are more bytes to send
                :
                : [len_hi] "M" (len_hi_byte),
                  [len_lo] "M" (len_lo_byte),
                  [ptr_lo] "r" (ptr_lo_byte),
                  [ptr_hi] "r" (ptr_hi_byte),
                  [port] "I" (port_io_addr),
                  [pin] "I" (pin_bit),
                : .{ .r24 = true, .r25 = true, .r28 = true, .r29 = true, .r30 = true, .r31 = true, .memory = true });

            asm volatile ("sei" ::: .{ .memory = true });

            delay_us(100);
        }
    };
}
