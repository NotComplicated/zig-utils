const std = @import("std");
const testing = std.testing;

pub const type_predicates = @import("type-predicates.zig");

test "if predicate" {
    const maxInt = std.math.maxInt;

    const Test = struct {
        const Predicate = type_predicates.Predicate;
        const If = type_predicates.If;

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
    const bar = Test.Bar{ .bar = undefined, .foo = maxInt(usize) };

    try testing.expectEqual(Test.f(foo), 42);
    try testing.expectEqual(Test.g(bar), 255);
}
