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
            'Z' => .{ 0x61, 0x51, 0x49, 0x45, 0x43 },
            'I' => .{ 0x41, 0x41, 0x7F, 0x41, 0x41 },
            'G' => .{ 0x2E, 0x49, 0x49, 0x41, 0x3E },
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

    const TEXT_COLOR: ws2812.Color = .{ .r = 0, .g = 50, .b = 30 };
    const DELAY_COUNT = 2_000_000;
    const TEXT_TO_DISPLAY = "ZIG";

    while (true) {
        inline for (TEXT_TO_DISPLAY) |character| {
            drawGlyph(&shield, character, TEXT_COLOR);
            shield.show();
            delay(DELAY_COUNT);
            shield.clear();
        }
    }
}

fn drawGlyph(shield: *Shield, letter: u8, color: ws2812.Color) void {
    shield.clear();
    const char_bitmap = Font.getChar(letter);

    var x: u8 = 0;
    while (x < CHAR_WIDTH) : (x += 1) {
        const col_data = char_bitmap[x];

        var y: u8 = 0;
        while (y < MATRIX_HEIGHT) : (y += 1) {
            if ((col_data >> @truncate(y)) & 1 != 0) {
                const idx = get_pixel_index(x, y);
                shield.setPixelColor(idx, color);
            }
        }
    }
}
