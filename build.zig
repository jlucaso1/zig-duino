const std = @import("std");

pub fn build(b: *std.Build) void {
    const microzig = @import("microzig");
    const MicroBuild = microzig.MicroBuild(.{ .avr = true });
    const mz_dep = b.dependency("microzig", .{});
    if (MicroBuild.init(b, mz_dep)) |mb| {
        const fw = mb.add_firmware(.{
            .name = "blink_avr",
            .target = mb.ports.avr.boards.arduino.nano,
            .optimize = .ReleaseSmall,
            .root_source_file = b.path("src/firmware.zig"),
            .bundle_compiler_rt = false,
        });

        mb.install_firmware(fw, .{ .format = .hex });

        const fw_step = b.step("firmware", "Build AVR firmware (.hex)");
        const install_fw = mb.add_install_firmware(fw, .{ .format = .hex });
        fw_step.dependOn(&install_fw.step);

        const flash_step = b.step("flash", "Build + flash firmware with avrdude");

        const flash_port = b.option([]const u8, "flash-port", "Serial port (e.g. /dev/ttyUSB0)") orelse "/dev/ttyUSB0";
        const flash_baud = b.option(u32, "flash-baud", "Serial baud for bootloader (115200 or 57600)") orelse 115200;
        const flash_prog = b.option([]const u8, "flash-programmer", "avrdude programmer id") orelse "arduino";
        const flash_mcu = b.option([]const u8, "flash-mcu", "target MCU id for avrdude") orelse "m328p";
        const avrdude_bin = b.option([]const u8, "avrdude-bin", "path to avrdude binary") orelse "avrdude";

        const alloc = b.allocator;
        const baud_str = std.fmt.allocPrint(alloc, "{d}", .{flash_baud}) catch @panic("OOM");

        const hex_rel = "firmware/blink_avr.hex";
        const hex_path = b.getInstallPath(.prefix, hex_rel);
        const flash_u = std.fmt.allocPrint(alloc, "flash:w:{s}:i", .{hex_path}) catch @panic("OOM");

        const cmd = b.addSystemCommand(&.{
            avrdude_bin,
            "-c",
            flash_prog,
            "-p",
            flash_mcu,
            "-P",
            flash_port,
            "-b",
            baud_str,
            "-D",
            "-U",
            flash_u,
        });
        cmd.step.dependOn(&install_fw.step);
        flash_step.dependOn(&cmd.step);
    }
}
