const fdt = @import("fdt.zig");
const kprint = @import("kprint.zig").kprint;

fn printCallback(node: fdt.Node) void {
    if (node.address) |addr| {
        kprint("Node {s}@0x{x}\n", .{ node.name, addr });
    } else {
        kprint("Node {s}\n", .{node.name});
    }
}

export fn main() void {
    const fdt_header: *const fdt.Header = @ptrFromInt(0x4000_0000);
    const fdt_parser = fdt.Parser{
        .header = fdt_header,
        .callback = printCallback,
    };
    fdt_parser.parse();
    kprint("Hello World!\n", .{});

    // var mem_reserve_iter = dts.MemReservationIterator.create(fdt_header);
    // while (mem_reserve_iter.next()) |entry| {
    //     _ = entry.address;
    // }
}
