const std = @import("std");
const aarch64 = std.Target.aarch64;

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .aarch64,
        .cpu_model = .{ .explicit = &aarch64.cpu.cortex_a76 },
        .cpu_features_sub = aarch64.featureSet(&.{ .neon, .fullfp16 }),
        .os_tag = .freestanding,
        .abi = .none,
    });

    const optimize = b.standardOptimizeOption(.{});

    const kernel_obj = b.addExecutable(.{
        .name = "kernel",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    kernel_obj.setLinkerScript(b.path("linker.ld"));
    kernel_obj.addAssemblyFile(b.path("src/start.s"));
    b.installArtifact(kernel_obj);

    const kernel_bin = b.addObjCopy(kernel_obj.getEmittedBin(), .{
        .basename = "kernel",
        .format = .bin,
    });
    const install_bin = b.addInstallBinFile(kernel_bin.getOutput(), "kernel.bin");
    b.getInstallStep().dependOn(&install_bin.step);
}
