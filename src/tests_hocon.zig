const std = @import("std");
const testing = std.testing;

const hocon = @import("hocon.zig");
const Parser = hocon.Parser;
const Error = hocon.Error;
const Token = hocon.Token;
const Type = hocon.Type;

const parse = @import("tests_json.zig").parse;
const serialize = @import("tests_serializer.zig").serialize;

test "for comments" {
    var js =
        \\{
        \\  "key": "value", // comment
        \\                  //another comment
        \\  "number": 2      #field comment
        \\  , #  object  comment
        \\}
    ;
    try parse(js, 9, 9, .{
        .{ Type.OBJECT, 0, 125, 5 },
        .{ Type.STRING, "key", 1 },
        .{ Type.STRING, "value", 0 },
        .{ Type.COMMENT, " comment" },
        .{ Type.COMMENT, "another comment" },
        .{ Type.STRING, "number", 2 },
        .{ Type.PRIMITIVE, "2" },
        .{ Type.COMMENT, "field comment" },
        .{ Type.COMMENT, "  object  comment" },
    }, false);

    const expected =
        \\{"key":"value","number":2}
    ;
    try serialize(9, expected, js);
}
