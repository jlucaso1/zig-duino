const microzig = @import("microzig");
const ws2812 = @import("ws2812.zig");

pub const panic = microzig.panic;

const LED_PIN = "PD6"; // D6 on the Arduino Uno/Nano/RGBDuino
const LED_COUNT = 40; // 5x8 grid

const Shield = ws2812.Ws2812(LED_PIN, LED_COUNT);

// We pass a large number to it to create a visible pause.
fn delay(comptime count: u32) void {
    var i: u32 = 0;
    while (i < count) : (i += 1) {
        // This empty volatile assembly statement prevents the compiler
        // from optimizing away the entire loop.
        asm volatile ("");
    }
}

// Helper to wipe a color across the shield with a pixel delay.
fn wipe(shield_ptr: *Shield, color: ws2812.Color, comptime pixel_delay: u32) void {
    var idx: u16 = 0;
    while (idx < LED_COUNT) : (idx += 1) {
        shield_ptr.setPixelColor(idx, color);
        shield_ptr.show();
        delay(pixel_delay);
    }
}

pub fn main() void {
    var shield: Shield = undefined;
    shield.init();

    const RED: ws2812.Color = .{ .r = 50, .g = 0, .b = 0 };
    const GREEN: ws2812.Color = .{ .r = 0, .g = 50, .b = 0 };
    const BLUE: ws2812.Color = .{ .r = 0, .g = 0, .b = 50 };

    while (true) {
        wipe(&shield, RED, 40000);
        delay(800000);

        wipe(&shield, GREEN, 40000);
        delay(800000);

        wipe(&shield, BLUE, 40000);
        delay(800000);

        shield.clear();
        shield.show();
        delay(800000);
    }
}
