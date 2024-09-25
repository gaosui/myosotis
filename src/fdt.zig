const std = @import("std");
const mem = std.mem;
const kprint = @import("kprint.zig").kprint;

pub const Header = extern struct {
    magic: u32,
    totalsize: u32,
    off_dt_struct: u32,
    off_dt_strings: u32,
    off_mem_rsvmap: u32,
    version: u32,
    last_comp_version: u32,
    boot_cpuid_phys: u32,
    size_dt_strings: u32,
    size_dt_struct: u32,
};

pub const ReserveEntry = extern struct {
    address: u64,
    size: u64,
};

pub const PropHeader = extern struct {
    len: u32,
    nameoff: u32,
};

pub const Token = enum(u8) {
    begin_node = 0x1,
    end_node = 0x2,
    prop = 0x3,
    nop = 0x4,
    end = 0x9,
    _,
};

pub const Node = struct {
    name: [*:0]const u8,
    address: ?usize = null,
};

pub const Prop = struct {
    name: [*:0]const u8,
    value: []const u8,
};

pub const DeviceQuery = struct {
    name: []const u8,
    callback: *const fn (node: Node) void,
};

pub const Parser = struct {
    header: *const Header,
    callback: *const fn (node: Node) void,

    pub fn parse(self: Parser) void {
        // Safe because the structure block is 4-bytes aligned.
        const base: [*]const u32 = @ptrCast(self.header);
        const struct_begin = base + mem.bigToNative(u32, self.header.off_dt_struct) / 4;

        if (parseToken(struct_begin[0]) != .begin_node) {
            return;
        }

        _ = self.recursiveParse(struct_begin + 1);
    }

    fn recursiveParse(self: Parser, start: [*]const u32) [*]const u32 {
        const name_start: [*:0]const u8 = @ptrCast(start);
        const result = parseName(name_start);

        var pos = result.next;
        const node = Node{
            .name = name_start,
            .address = result.addr,
        };

        while (true) {
            const token = parseToken(pos[0]);
            pos += 1;

            switch (token) {
                .begin_node => {
                    pos = self.recursiveParse(pos);
                },
                .prop => {
                    const prop: *const PropHeader = @ptrCast(pos);
                    const value: [*]const u8 = @ptrCast(pos + 2); // 2 32-bit numbers
                    pos = alignForward32([*]const u8, value + mem.bigToNative(u32, prop.len));
                },
                .end_node => {
                    self.callback(node);
                    break;
                },
                .end => break,
                .nop => continue,
                _ => continue,
            }
        }

        return pos;
    }

    const ParseNameResult = struct {
        addr: ?usize = null,
        next: [*]const u32,
    };

    fn parseName(start: [*:0]const u8) ParseNameResult {
        var i: usize = 0;
        var addr_idx: ?usize = null;
        while (start[i] != 0) : (i += 1) {
            if (start[i] == '@') {
                addr_idx = i + 1;
            }
        }

        var result = ParseNameResult{ .next = alignForward32([*]const u8, start + i + 1) };

        if (addr_idx) |idx| {
            const addr = (start + idx)[0 .. i - idx];
            result.addr = std.fmt.parseInt(usize, addr, 16) catch unreachable;
        }
        return result;
    }

    fn alignForward32(comptime T: type, ptr: T) [*]const u32 {
        return @ptrFromInt(mem.alignForward(usize, @intFromPtr(ptr), 4));
    }

    fn parseToken(big: u32) Token {
        return @enumFromInt(mem.bigToNative(u32, big));
    }
};

pub const MemReservationIterator = struct {
    current: [*]const ReserveEntry,

    pub fn create(header: *const Header) MemReservationIterator {
        // Header is required to be 8-bytes aligned.
        const base: [*]align(8) const u8 = @ptrCast(header);
        return .{ .current = @ptrCast(base + mem.bigToNative(header.off_mem_rsvmap)) };
    }

    pub fn next(self: *MemReservationIterator) ?ReserveEntry {
        if (mem.bigToNative(self.current[0].address) == 0 and
            mem.bigToNative(self.current[0].size) == 0)
        {
            return null;
        } else {
            defer self.current += 1;
            return self.current[0];
        }
    }
};
