const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const meta = std.meta;

const type_predicates = @import("type-predicates.zig");
const Predicate = type_predicates.Predicate;
const If = type_predicates.If;

fn isIterator(T: type) bool {
    var I = T;
    if (@typeInfo(I) == .pointer) {
        I = meta.Child(I);
    }
    if (!meta.hasMethod(I, "next")) return false;
    const info = @typeInfo(@TypeOf(@field(I, "next")));
    if (@typeInfo(info.@"fn".return_type.?) != .optional) return false;
    if (info.@"fn".params.len != 1) return false;
    if (info.@"fn".params[0].type != *I) return false;
    return true;
}
const IsIterator = Predicate.init(isIterator);

fn GetItem(T: type) If(IsIterator, T, type) {
    var I = T;
    if (@typeInfo(I) == .pointer) {
        I = meta.Child(I);
    }
    return meta.Child(@typeInfo(@TypeOf(@field(I, "next"))).@"fn".return_type.?);
}

pub fn Map(I: type, Ctx: type, func: anytype) type {
    const Item = GetItem(I);
    const info = @typeInfo(@TypeOf(func));
    if (info != .@"fn") {
        @compileError("Map function must be a function");
    }
    if (info.@"fn".params.len != 2 or info.@"fn".params[0].type != Ctx or info.@"fn".params[1].type != Item) {
        @compileError("Map function must take a context and an item of the iterator type");
    }

    return struct {
        iter: I,
        ctx: Ctx,

        const Self = @This();

        usingnamespace Iter(Self);

        pub fn next(self: *Self) ?info.@"fn".return_type.? {
            return if (self.iter.next()) |item|
                func(self.ctx, item)
            else
                null;
        }
    };
}

pub fn map(iter: anytype, ctx: anytype, func: anytype) Map(@TypeOf(iter), @TypeOf(ctx), func) {
    return .{
        .iter = iter,
        .ctx = ctx,
    };
}

pub fn Iter(Sub: type) type {
    return struct {
        pub fn map(self: *Sub, ctx: anytype, func: anytype) Map(@TypeOf(self), @TypeOf(ctx), func) {
            return @import("itertools.zig").map(self, ctx, func);
        }
    };
}

pub fn IntoIter(T: type) If(IsIterator, T, type) {
    return struct {
        pub fn next(self: *T) ?GetItem(T) {
            return self.next();
        }
    };
}

test "map" {
    const Len = struct {
        fn len(_: void, s: []const u8) usize {
            return s.len;
        }
    };
    var mapped_split = map(mem.splitScalar(u8, "a bb ccc", ' '), {}, Len.len);

    try testing.expectEqual(1, mapped_split.next().?);
    try testing.expectEqual(2, mapped_split.next().?);
    try testing.expectEqual(3, mapped_split.next().?);
    try testing.expectEqual(null, mapped_split.next());

    const Range = struct {
        from: usize,
        to: usize,

        const Self = @This();

        usingnamespace Iter(Self);

        pub fn next(self: *Self) ?usize {
            self.from += 1;
            return if (self.from > self.to) null else self.from - 1;
        }
    };

    const Add = struct {
        fn add(a: usize, b: usize) usize {
            return a + b;
        }
    };

    var range = Range{ .from = 0, .to = 3 };
    var mapped_range = range.map(@as(usize, 1), Add.add);

    try testing.expectEqual(1, mapped_range.next().?);
    try testing.expectEqual(2, mapped_range.next().?);
    try testing.expectEqual(3, mapped_range.next().?);
    try testing.expectEqual(null, mapped_range.next());

    range = Range{ .from = 0, .to = 4 };
    mapped_range = range.map(@as(usize, 5), Add.add);
    var double_mapped_range = mapped_range.map(@as(usize, 10), Add.add);

    try testing.expectEqual(15, double_mapped_range.next().?);
    try testing.expectEqual(16, double_mapped_range.next().?);
    try testing.expectEqual(17, double_mapped_range.next().?);
    try testing.expectEqual(18, double_mapped_range.next().?);
    try testing.expectEqual(null, double_mapped_range.next());
}
