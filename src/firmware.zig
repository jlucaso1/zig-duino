const microzig = @import("microzig");
const hal = microzig.hal;

pub const panic = microzig.panic;

const Led = hal.parse_pin("PD7");

fn delay(n: u32) void {
    var c = n;
    while (c != 0) : (c -= 1) {
        asm volatile ("nop");
    }
}

pub fn main() void {
    hal.gpio.set_output(Led);
    while (true) {
        hal.gpio.toggle(Led);
        delay(200_000);
    }
}
