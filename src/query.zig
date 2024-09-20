const fdt = @import("fdt.zig");
const kprint = @import("kprint.zig").kprint;

fn printCallback(node: fdt.Node) void {
    if (node.address) |addr| {
        kprint("===========Node {s}@0x{x}\n", .{ node.name, addr });
    } else {
        kprint("===========Node {s}\n", .{node.name});
    }
}

pub const device_queries = [_]fdt.DeviceQuery{
    fdt.DeviceQuery{
        .name = "pl011",
        .callback = printCallback,
    },
};
