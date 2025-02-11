const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("zig-utils", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run library tests");
    inline for (.{ "type-predicates", "itertools", "strings" }) |name| {
        const run_test = b.addRunArtifact(b.addTest(.{
            .name = name,
            .root_source_file = b.path("src/" ++ name ++ ".zig"),
            .target = target,
            .optimize = optimize,
        }));
        test_step.dependOn(&run_test.step);
    }
}
