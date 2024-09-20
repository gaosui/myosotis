const std = @import("std");

const uart_dr: *volatile u8 = @ptrFromInt(0x900_0000);

const UartWriter = struct {
    pub fn writeAll(_: UartWriter, content: []const u8) !void {
        for (content) |char| {
            uart_dr.* = char;
        }
    }

    pub fn writeBytesNTimes(self: UartWriter, fill: []const u8, padding: usize) !void {
        try self.writeAll(fill);
        _ = padding;
    }

    pub const Error = error{};
};

pub fn kprint(comptime fmt: []const u8, args: anytype) void {
    std.fmt.format(UartWriter{}, fmt, args) catch return;
}
