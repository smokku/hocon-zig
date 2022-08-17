const std = @import("std");
const testing = std.testing;

const hocon = @import("hocon.zig");
const serialize = hocon.serialize;

test "basic" {
    var p: hocon.Parser = undefined;
    p.init();
    var t: [10]hocon.Token = undefined;
    const js =
        \\{"one": "uno", "two": 2, "three": [false, 1, "2"]}
    ;
    const r = try p.parse(js, &t);
    try testing.expectEqual(@as(usize, 10), r);

    const s = try serialize(&t, js, testing.allocator);
    defer testing.allocator.destroy(s.ptr);

    const expected =
        \\{"one":"uno","two":2,"three":[false,1,"2"]}
    ;
    try testing.expectFmt(expected, "{s}", .{s});
}
