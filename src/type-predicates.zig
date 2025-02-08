const std = @import("std");
const testing = std.testing;

pub const Predicate = struct {
    name: []const u8,
    func: fn (type) bool,

    pub fn init(predicate: anytype) @This() {
        const info = @typeInfo(@TypeOf(predicate));
        if (info != .Fn) {
            @compileError("Predicate must be a function");
        }
        const return_type = info.Fn.return_type.?;
        if (return_type != bool) {
            @compileError("Predicate must return bool");
        }
        const params = info.Fn.params;
        if (params.len != 1 or params[0].type != type) {
            @compileError("Predicate must take exactly one type argument");
        }
        return .{ .name = @typeName(@TypeOf(predicate)), .func = predicate };
    }
};

pub fn If(predicate: Predicate, comptime T: type, comptime Ret: type) type {
    return if (predicate.func(T))
        Ret
    else
        @compileError("Predicate '" ++ predicate.name ++ "' not satisfied by '" ++ @typeName(T) ++ "'");
}

test "if predicate" {
    const maxInt = std.math.maxInt;

    const Test = struct {
        fn fooable(T: type) bool {
            return @hasField(T, "foo");
        }

        const IsFooable = Predicate.init(fooable);

        const Foo = struct {
            foo: u8,
        };

        const Bar = struct {
            bar: u8,
            foo: usize,
        };

        fn f(foo: Foo) If(IsFooable, Foo, u8) {
            return foo.foo;
        }

        fn g(bar: Bar) If(IsFooable, Bar, u8) {
            return @truncate(bar.foo);
        }
    };

    const foo = Test.Foo{ .foo = 42 };
    const bar = Test.Bar{ .bar = 42, .foo = maxInt(usize) };

    try testing.expectEqual(Test.f(foo), 42);
    try testing.expectEqual(Test.g(bar), 255);
}
