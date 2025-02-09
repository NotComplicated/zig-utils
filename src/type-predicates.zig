const std = @import("std");

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
