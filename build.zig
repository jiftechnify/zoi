const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const tests = b.addTest("qoi.zig");
    addDeps(tests);
    tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&tests.step);

    const exe_qoiconv = b.addExecutable("qoiconv", "src/qoiconv.zig");
    exe_qoiconv.addPackagePath("zigimg", "libs/zigimg/zigimg.zig");
    exe_qoiconv.setTarget(target);
    exe_qoiconv.setBuildMode(mode);
    exe_qoiconv.install();

    const run_qoiconv = exe_qoiconv.run();
    run_qoiconv.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_qoiconv.addArgs(args);
    }

    const run_qoiconv_step = b.step("qoiconv", "Run qoiconv");
    run_qoiconv_step.dependOn(&run_qoiconv.step);

    const wasm = b.addSharedLibrary("qoi", "src/wasm.zig", .unversioned);
    wasm.rdynamic = true;
    wasm.setTarget(std.zig.CrossTarget{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
        .abi = .none,
    });
    wasm.setBuildMode(mode);
    wasm.install();
}

// adds common dependencies to given LibExeObjStep.
fn addDeps(step: *std.build.LibExeObjStep) void {
    step.addPackagePath("zigimg", "libs/zigimg/zigimg.zig");
    step.linkLibC();
    step.addIncludePath("libs/c_qoi");
}
