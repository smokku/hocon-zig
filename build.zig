const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("hocon", "src/hocon.zig");
    lib.setBuildMode(mode);
    lib.install();

    const json_parser_tests = b.addTest("src/tests_json.zig");
    json_parser_tests.setBuildMode(mode);
    const hocon_parser_tests = b.addTest("src/tests_hocon.zig");
    hocon_parser_tests.setBuildMode(mode);

    const serializer_tests = b.addTest("src/tests_serializer.zig");
    serializer_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&json_parser_tests.step);
    test_step.dependOn(&hocon_parser_tests.step);
    test_step.dependOn(&serializer_tests.step);
}
