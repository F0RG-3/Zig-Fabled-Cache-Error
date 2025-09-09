const std = @import("std");

pub fn build(b: *std.Build) void {

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib"); // main raylib module
    const raygui = raylib_dep.module("raygui"); // raygui module
    const ray_artifact = raylib_dep.artifact("raylib");

    const imports = [_]std.Build.Module.Import {
        .{.name = "raylib", .module = raylib},
        .{.name = "raygui", .module = raygui},
    };

    const exe = b.addExecutable(.{
        .name = "HexBoard",
        .use_lld = false,

        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,

            .imports = &imports,
        }),
    });

    exe.linkLibrary(ray_artifact);
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the App");
    run_step.dependOn(&run_cmd.step);
}