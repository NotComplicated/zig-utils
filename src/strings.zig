const std = @import("std");
const unicode = std.unicode;
const testing = std.testing;
const mem = std.mem;

const itertools = @import("itertools.zig");
const Iter = itertools.Iter;

const StrErr = error{
    InvalidUtf8,
};

const Str = struct {
    bytes: []const u8,

    const Self = @This();

    pub fn initUnchecked(bytes: []const u8) Self {
        return .{ .bytes = bytes };
    }

    pub fn init(bytes: []const u8) StrErr!Self {
        return if (unicode.utf8ValidateSlice(bytes)) initUnchecked(bytes) else error.InvalidUtf8;
    }

    pub inline fn initComptime(comptime bytes: []const u8) Self {
        return comptime if (init(bytes)) |r| r else |_| @compileError("Invalid UTF-8");
    }

    pub fn chars(self: Self) BytesIter {
        return .{ .iter = unicode.Utf8View.initUnchecked(self.bytes).iterator() };
    }

    pub fn eql(self: Self, other: Self) bool {
        return mem.eql(u8, self.bytes, other.bytes);
    }
};

pub const BytesIter = struct {
    iter: unicode.Utf8Iterator,

    const Self = @This();

    usingnamespace Iter(Self);

    pub fn next(self: *Self) ?Str {
        return if (self.iter.nextCodepointSlice()) |c| Str.initUnchecked(c) else null;
    }
};

test "Str" {
    const str = try Str.init("Hello, world!");
    var chars = str.chars();

    try testing.expect(Str.initComptime("H").eql(chars.next().?));
    try testing.expect(Str.initComptime("e").eql(chars.next().?));
    try testing.expect(Str.initComptime("l").eql(chars.next().?));
    try testing.expect(Str.initComptime("l").eql(chars.next().?));

    var no_o = chars.filter({}, func: {
        break :func struct {
            fn f(_: void, c: Str) bool {
                return !c.eql(Str.initComptime("o"));
            }
        }.f;
    });

    try testing.expect(Str.initComptime(",").eql(no_o.next().?));
}
