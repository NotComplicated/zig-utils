const std = @import("std");
const heap = std.heap;
const fs = std.fs;
const mem = std.mem;

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var dir = try fs.openDirAbsolute(try fs.realpathAlloc(alloc, "src"), .{ .iterate = true });
    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind == .file and mem.eql(u8, fs.path.extension(entry.name), "zig")) {
            const sub_path = try fs.path.join(alloc, &.{ "src", entry.name });
            const lib = b.addStaticLibrary(.{
                .name = fs.path.stem(entry.name),
                // In this case the main source file is merely a path, however, in more
                // complicated build scripts, this could be a generated file.
                .root_source_file = .{ .src_path = .{ .sub_path = sub_path, .owner = b } },
                .target = target,
                .optimize = optimize,
            });

            // This declares intent for the library to be installed into the standard
            // location when the user invokes the "install" step (the default step when
            // running `zig build`).
            b.installArtifact(lib);
        }
    }

    // // Creates a step for unit testing. This only builds the test executable
    // // but does not run it.
    // const main_tests = b.addTest(.{
    //     .root_source_file = .{ .src_path = .{ .sub_path = main, .owner = b } },
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const run_main_tests = b.addRunArtifact(main_tests);

    // // This creates a build step. It will be visible in the `zig build --help` menu,
    // // and can be selected like this: `zig build test`
    // // This will evaluate the `test` step rather than the default, which is "install".
    // const test_step = b.step("test", "Run library tests");
    // test_step.dependOn(&run_main_tests.step);
}
