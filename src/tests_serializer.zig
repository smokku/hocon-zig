const std = @import("std");
const testing = std.testing;

const hocon = @import("hocon.zig");

pub fn serialize(numtokens: usize, expected: []const u8, actual: []const u8) !void {
    var p: hocon.Parser = undefined;
    p.init();

    var t = try testing.allocator.alloc(hocon.Token, numtokens);
    defer testing.allocator.free(t);

    const r = try p.parse(actual, t);
    try testing.expectEqual(numtokens, r);

    const s = try hocon.serialize(t, actual, testing.allocator);
    defer testing.allocator.destroy(s.ptr);

    try testing.expectFmt(expected, "{s}", .{s});
}

test "basic" {
    const js =
        \\{"one": "uno", "two": 2, "three": [false, 1, "2"]}
    ;
    const expected =
        \\{"one":"uno","two":2,"three":[false,1,"2"]}
    ;
    try serialize(10, expected, js);
}
