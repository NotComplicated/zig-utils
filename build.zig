const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const main = b.path("src/main.zig");
    const name = "zig-utils";

    _ = b.addModule(name, .{
        .root_source_file = main,
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addStaticLibrary(.{
        .name = name,
        .root_source_file = main,
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);

    const test_step = b.step("test", "Run library tests");
    inline for (.{ "type-predicates", "itertools" }) |test_name| {
        const run_test = b.addRunArtifact(b.addTest(.{
            .name = test_name,
            .root_source_file = b.path("src/" ++ test_name ++ ".zig"),
            .target = target,
            .optimize = optimize,
        }));
        test_step.dependOn(&run_test.step);
    }
}
