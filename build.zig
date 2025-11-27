const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const version = b.option([]const u8, "tf-version", "TensorFlow version") orelse "2.16.2";
    const flavor = b.option([]const u8, "tf-flavor", "cpu or gpu") orelse "cpu";

    const os = switch (builtin.target.os.tag) {
        .linux => "linux",
        .windows => "windows",
        .macos => "darwin",
        else => @panic("OS not supported!"),
    };

    const arch = switch (builtin.target.cpu.arch) {
        .arm => "arm64",
        .x86_64 => "x86_64",
        else => @panic("CPU architecture not supported!"),
    };

    const run_get_tf = b.addSystemCommand(&.{
        "bash",
        b.path("src/fetch_tf.sh").src_path.sub_path,
        version,
        flavor,
        os,
        arch,
    });

    const root_file = b.addSystemCommand(&.{
        "bash",
        "-c",
        "zig translate-c deps/include/tensorflow/c/c_api.h -Ideps/include -lc > src/root.zig",
    });
    root_file.step.dependOn(&run_get_tf.step);

    const module = b.addModule("tf", .{
        .root_source_file = b.path("src/root.zig"),
        .optimize = optimize,
        .target = target,
    });

    const lib = b.addLibrary(.{
        .name = "ztf",
        .root_module = module,
    });
    lib.step.dependOn(&root_file.step);

    lib.addIncludePath(b.path("deps/include"));
    lib.addLibraryPath(b.path("deps/lib"));

    lib.linkLibC();
    lib.linkSystemLibrary("tensorflow");

    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "example",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/example.zig"),
            .target = b.graph.host,
        }),
    });

    exe.root_module.addImport("tf", module);
    exe.linkLibC();
    exe.linkLibrary(lib);

    exe.addLibraryPath(b.path("deps/lib"));
    exe.linkSystemLibrary("tensorflow");

    exe.step.dependOn(&root_file.step);

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
