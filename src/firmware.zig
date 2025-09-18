const std = @import("std");
const microzig = @import("microzig");
const ws2812 = @import("ws2812.zig");

pub const panic = microzig.panic;

const LED_PIN = "PD6";
const LED_COUNT = 40;
const MATRIX_WIDTH: u8 = 5;
const MATRIX_HEIGHT: u8 = 8;
const CHAR_WIDTH: u8 = 5;

fn delay(comptime count: u32) void {
    var i: u32 = 0;
    while (i < count) : (i += 1) {
        asm volatile ("");
    }
}

const Shield = ws2812.Ws2812(LED_PIN, LED_COUNT);

const Font = struct {
    pub fn getChar(char: u8) [CHAR_WIDTH]u8 {
        return switch (char) {
            'E' => .{ 0x7F, 0x49, 0x49, 0x49, 0x41 },
            'U' => .{ 0x3F, 0x40, 0x40, 0x40, 0x3F },
            'T' => .{ 0x01, 0x01, 0x7F, 0x01, 0x01 },
            'A' => .{ 0x7F, 0x09, 0x09, 0x09, 0x7F },
            'M' => .{ 0x7F, 0x02, 0x04, 0x02, 0x7F },
            'O' => .{ 0x3E, 0x41, 0x41, 0x41, 0x3E },
            'Z' => .{ 0x61, 0x51, 0x49, 0x45, 0x43 },
            'I' => .{ 0x41, 0x41, 0x7F, 0x41, 0x41 },
            'G' => .{ 0x2E, 0x49, 0x49, 0x41, 0x3E },
            'L' => .{ 0x7F, 0x40, 0x40, 0x40, 0x40 },
            'V' => .{ 0x1F, 0x20, 0x40, 0x20, 0x1F },
            '<' => .{ 0x0E, 0x11, 0x21, 0x11, 0x0E },
            else => .{ 0x00, 0x00, 0x00, 0x00, 0x00 },
        };
    }
};

fn get_pixel_index(x: u8, y: u8) u16 {
    const x_u16 = @as(u16, x);
    const y_u16 = @as(u16, y);
    const height = @as(u16, MATRIX_HEIGHT);

    return x_u16 * height + (height - 1 - y_u16);
}

pub fn main() void {
    var shield: Shield = .{ .leds = undefined };
    shield.init();

    const TEXT_COLOR: ws2812.Color = .{ .g = 0, .r = 0, .b = 40 };
    const HEART_COLOR: ws2812.Color = .{ .g = 0, .r = 40, .b = 0 };
    const DELAY_COUNT = 2_000_000;
    const TEXT_TO_DISPLAY = "EU TE AMO < ";

    while (true) {
        inline for (TEXT_TO_DISPLAY) |character| {
            var current_color = TEXT_COLOR;
            if (character == '<') {
                current_color = HEART_COLOR;
            }

            shield.clear();
            const char_bitmap = Font.getChar(character);

            var x: u8 = 0;
            while (x < CHAR_WIDTH) : (x += 1) {
                const col_data = char_bitmap[x];

                var y: u8 = 0;
                while (y < MATRIX_HEIGHT) : (y += 1) {
                    if ((col_data >> @truncate(y)) & 1 != 0) {
                        const idx = get_pixel_index(x, y);
                        shield.setPixelColor(idx, current_color);
                    }
                }
            }

            shield.show();
            delay(DELAY_COUNT);
        }
    }
}
