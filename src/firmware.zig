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

pub fn main() void {
    var shield: Shield = undefined;
    shield.init();

    const red = ws2812.Color{ .r = 50, .g = 0, .b = 0 };
    const green = ws2812.Color{ .r = 0, .g = 50, .b = 0 };
    const blue = ws2812.Color{ .r = 0, .g = 0, .b = 50 };
    const off = ws2812.Color{ .r = 0, .g = 0, .b = 0 };

    while (true) {
        // --- Red Wipe ---
        var i: u16 = 0;
        while (i < LED_COUNT) : (i += 1) {
            shield.setPixelColor(i, red);
            shield.show();
            delay(40000); // Calibrated for visual delay
        }
        delay(800000);

        // --- Green Wipe ---
        i = 0;
        while (i < LED_COUNT) : (i += 1) {
            shield.setPixelColor(i, green);
            shield.show();
            delay(40000);
        }
        delay(800000);

        // --- Blue Wipe ---
        i = 0;
        while (i < LED_COUNT) : (i += 1) {
            shield.setPixelColor(i, blue);
            shield.show();
            delay(40000);
        }
        delay(800000);

        // --- Turn Off ---
        i = 0;
        while (i < LED_COUNT) : (i += 1) {
            shield.setPixelColor(i, off);
        }
        shield.show();
        delay(800000);
    }
}
