const std = @import("std");
const testing = std.testing;

const hocon = @import("hocon.zig");
const Parser = hocon.Parser;
const Error = hocon.Error;
const Token = hocon.Token;
const Type = hocon.Type;

pub fn parse(json: []const u8, status: Error!usize, comptime numtok: usize, comptime result: anytype) anyerror!void {
    var tokens: [numtok]Token = undefined;
    var p: Parser = undefined;

    p.init();
    const r = p.parse(json, &tokens);
    // if (r) |c| std.debug.print("{any}\n", .{tokens[0..c]}) else |_| {}
    try testing.expectEqual(status, r);

    if (status) |count| {
        try testing.expectEqual(count, try r);
    } else |err| {
        try testing.expectError(err, r catch |e| e);
    }

    inline for (result) |res, index| {
        const tk = &tokens[index];
        const typ = res[0];
        try testing.expectEqual(typ, tk.typ);
        switch (typ) {
            Type.UNDEFINED => unreachable,
            Type.OBJECT, Type.ARRAY => {
                if (res[1] != -1 and res[2] != -1) {
                    try testing.expectEqual(@as(isize, res[1]), tk.start);
                    try testing.expectEqual(@as(isize, res[2]), tk.end);
                }
                try testing.expectEqual(@as(usize, res[3]), tk.size);
            },
            Type.STRING, Type.PRIMITIVE, Type.COMMENT => {
                const value = json[@intCast(usize, tk.start)..@intCast(usize, tk.end)];
                try testing.expectFmt(res[1], "{s}", .{value});
                if (typ == Type.STRING)
                    try testing.expectEqual(@as(usize, res[2]), tk.size);
            },
        }
    }
}

test "for a empty JSON objects/arrays" {
    try parse("{}", 1, 1, .{.{ Type.OBJECT, 0, 2, 0 }});
    try parse("[]", 1, 1, .{.{ Type.ARRAY, 0, 2, 0 }});
    try parse("[{},{}]", 3, 3, .{ .{ Type.ARRAY, 0, 7, 2 }, .{ Type.OBJECT, 1, 3, 0 }, .{ Type.OBJECT, 4, 6, 0 } });
}

test "for a JSON objects" {
    try parse("{\"a\":0}", 3, 3, .{ .{ Type.OBJECT, 0, 7, 1 }, .{ Type.STRING, "a", 1 }, .{ Type.PRIMITIVE, "0" } });
    try parse("{\"a\":[]}", 3, 3, .{ .{ Type.OBJECT, 0, 8, 1 }, .{ Type.STRING, "a", 1 }, .{ Type.ARRAY, 5, 7, 0 } });
    try parse("{\"a\":{},\"b\":{}}", 5, 5, .{ .{ Type.OBJECT, 0, 15, 2 }, .{ Type.STRING, "a", 1 }, .{ Type.OBJECT, -1, -1, 0 }, .{ Type.STRING, "b", 1 }, .{ Type.OBJECT, -1, -1, 0 } });
    try parse("{\n \"Day\": 26,\n \"Month\": 9,\n \"Year\": 12\n }", 7, 7, .{ .{ Type.OBJECT, -1, -1, 3 }, .{ Type.STRING, "Day", 1 }, .{ Type.PRIMITIVE, "26" }, .{ Type.STRING, "Month", 1 }, .{ Type.PRIMITIVE, "9" }, .{ Type.STRING, "Year", 1 }, .{ Type.PRIMITIVE, "12" } });
    try parse("{\"a\": 0, \"b\": \"c\"}", 5, 5, .{ .{ Type.OBJECT, -1, -1, 2 }, .{ Type.STRING, "a", 1 }, .{ Type.PRIMITIVE, "0" }, .{ Type.STRING, "b", 1 }, .{ Type.STRING, "c", 0 } });

    try parse("{\"a\"\n0}", Error.INVAL, 3, .{});
    try parse("{\"a\", 0}", Error.INVAL, 3, .{});
    try parse("{\"a\": {2}}", Error.INVAL, 3, .{});
    try parse("{\"a\": {2: 3}}", Error.INVAL, 3, .{});
    try parse("{\"a\": {\"a\": 2 3}}", Error.INVAL, 5, .{});
    // FIXME:
    //try parse("{\"a\"}", Error.INVAL, 2, .{});
    //try parse("{\"a\": 1, \"b\"}", Error.INVAL, 4, .{});
    //try parse("{\"a\",\"b\":1}", Error.INVAL, 4, .{});
    //try parse("{\"a\":1,}", Error.INVAL, 4, .{});
    //try parse("{\"a\":\"b\":\"c\"}", Error.INVAL, 4, .{});
    //try parse("{,}", Error.INVAL, 4, .{});
}

test "for a JSON arrays" {
    // FIXME:
    //try parse("[10}", Error.INVAL, 3, .{});
    //try parse("[1,,3]", Error.INVAL, 3);
    try parse("[10]", 2, 2, .{ .{ Type.ARRAY, -1, -1, 1 }, .{ Type.PRIMITIVE, "10" } });
    try parse("{\"a\": 1]", Error.INVAL, 3, .{});
    // FIXME:
    //try parse("[\"a\": 1]", Error.INVAL, 3, .{});
}

test "test primitive JSON data types" {
    try parse("{\"boolVar\" : true }", 3, 3, .{ .{ Type.OBJECT, -1, -1, 1 }, .{ Type.STRING, "boolVar", 1 }, .{ Type.PRIMITIVE, "true" } });
    try parse("{\"boolVar\" : false }", 3, 3, .{ .{ Type.OBJECT, -1, -1, 1 }, .{ Type.STRING, "boolVar", 1 }, .{ Type.PRIMITIVE, "false" } });
    try parse("{\"nullVar\" : null }", 3, 3, .{ .{ Type.OBJECT, -1, -1, 1 }, .{ Type.STRING, "nullVar", 1 }, .{ Type.PRIMITIVE, "null" } });
    try parse("{\"intVar\" : 12}", 3, 3, .{ .{ Type.OBJECT, -1, -1, 1 }, .{ Type.STRING, "intVar", 1 }, .{ Type.PRIMITIVE, "12" } });
    try parse("{\"floatVar\" : 12.345}", 3, 3, .{ .{ Type.OBJECT, -1, -1, 1 }, .{ Type.STRING, "floatVar", 1 }, .{ Type.PRIMITIVE, "12.345" } });
}

test "test string JSON data types" {
    try parse("{\"strVar\" : \"hello world\"}", 3, 3, .{ .{ Type.OBJECT, -1, -1, 1 }, .{ Type.STRING, "strVar", 1 }, .{ Type.STRING, "hello world", 0 } });
    try parse("{\"strVar\" : \"escapes: \\/\\r\\n\\t\\b\\f\\\"\\\\\"}", 3, 3, .{ .{ Type.OBJECT, -1, -1, 1 }, .{ Type.STRING, "strVar", 1 }, .{ Type.STRING, "escapes: \\/\\r\\n\\t\\b\\f\\\"\\\\", 0 } });
    try parse("{\"strVar\": \"\"}", 3, 3, .{ .{ Type.OBJECT, -1, -1, 1 }, .{ Type.STRING, "strVar", 1 }, .{ Type.STRING, "", 0 } });
    try parse("{\"a\":\"\\uAbcD\"}", 3, 3, .{ .{ Type.OBJECT, -1, -1, 1 }, .{ Type.STRING, "a", 1 }, .{ Type.STRING, "\\uAbcD", 0 } });
    try parse("{\"a\":\"str\\u0000\"}", 3, 3, .{ .{ Type.OBJECT, -1, -1, 1 }, .{ Type.STRING, "a", 1 }, .{ Type.STRING, "str\\u0000", 0 } });
    try parse("{\"a\":\"\\uFFFFstr\"}", 3, 3, .{ .{ Type.OBJECT, -1, -1, 1 }, .{ Type.STRING, "a", 1 }, .{ Type.STRING, "\\uFFFFstr", 0 } });
    try parse("{\"a\":[\"\\u0280\"]}", 4, 4, .{ .{ Type.OBJECT, -1, -1, 1 }, .{ Type.STRING, "a", 1 }, .{ Type.ARRAY, -1, -1, 1 }, .{ Type.STRING, "\\u0280", 0 } });

    try parse("{\"a\":\"str\\uFFGFstr\"}", Error.INVAL, 3, .{});
    try parse("{\"a\":\"str\\u@FfF\"}", Error.INVAL, 3, .{});
    try parse("{{\"a\":[\"\\u028\"]}", Error.INVAL, 4, .{});
}

test "test partial JSON string parsing" {
    const js = "{\"x\": \"va\\\\ue\", \"y\": \"value y\"}";

    comptime var i = 1;
    inline while (i <= js.len) : (i += 1) {
        if (i != js.len) {
            try parse(js[0..i], Error.PART, 5, .{});
        } else {
            try parse(js[0..i], 5, 5, .{ .{ Type.OBJECT, -1, -1, 2 }, .{ Type.STRING, "x", 1 }, .{ Type.STRING, "va\\\\ue", 0 }, .{ Type.STRING, "y", 1 }, .{ Type.STRING, "value y", 0 } });
        }
    }
}

test "test partial array reading" {
    const js = "[ 1, true, [123, \"hello\"]]";

    comptime var i = 1;
    inline while (i <= js.len) : (i += 1) {
        if (i != js.len) {
            try parse(js[0..i], Error.PART, 6, .{});
        } else {
            try parse(js[0..i], 6, 6, .{ .{ Type.ARRAY, -1, -1, 3 }, .{ Type.PRIMITIVE, "1" }, .{ Type.PRIMITIVE, "true" }, .{ Type.ARRAY, -1, -1, 2 }, .{ Type.PRIMITIVE, "123" }, .{ Type.STRING, "hello", 0 } });
        }
    }
}

test "test array reading with a smaller number of tokens" {
    const js = "  [ 1, true, [123, \"hello\"]]";

    comptime var i = 0;
    inline while (i < 10) : (i += 1) {
        if (i < 6) {
            try parse(js, Error.NOMEM, i, .{});
        } else {
            try parse(js, 6, i, .{ .{ Type.ARRAY, -1, -1, 3 }, .{ Type.PRIMITIVE, "1" }, .{ Type.PRIMITIVE, "true" }, .{ Type.ARRAY, -1, -1, 2 }, .{ Type.PRIMITIVE, "123" }, .{ Type.STRING, "hello", 0 } });
        }
    }
}

test "test unquoted keys (like in JavaScript)" {
    const js = "key1: \"value\"\nkey2 : 123";

    try parse(js, 4, 4, .{ .{ Type.PRIMITIVE, "key1" }, .{ Type.STRING, "value", 0 }, .{ Type.PRIMITIVE, "key2" }, .{ Type.PRIMITIVE, "123" } });
}

test "test issue #22" {
    const js =
        \\{ "height":10, "layers":[ { "data":[6,6], "height":10,
        \\ "name":"Calque de Tile 1", "opacity":1, "type":"tilelayer",
        \\ "visible":true, "width":10, "x":0, "y":0 }],
        \\ "orientation":"orthogonal", "properties": { }, "tileheight":32,
        \\ "tilesets":[ { "firstgid":1, "image":"..\\/images\\/tiles.png",
        \\ "imageheight":64, "imagewidth":160, "margin":0,
        \\ "name":"Tiles",
        \\ "properties":{}, "spacing":0, "tileheight":32, "tilewidth":32
        \\ }],
        \\ "tilewidth":32, "version":1, "width":10 }
    ;
    try parse(js, 61, 128, .{});
}

test "test issue #27" {
    const js =
        "{ \"name\" : \"Jack\", \"age\" : 27 } { \"name\" : \"Anna\", ";

    try parse(js, Error.PART, 8, .{});
}

test "test tokens count estimation" {
    var p: Parser = undefined;
    var js: []const u8 = undefined;

    js = "{}";
    p.init();
    try parse(js, 1, 10, .{});

    js = "[]";
    p.init();
    try parse(js, 1, 10, .{});

    js = "[[]]";
    p.init();
    try parse(js, 2, 10, .{});

    js = "[[], []]";
    p.init();
    try parse(js, 3, 10, .{});

    js = "[[], []]";
    p.init();
    try parse(js, 3, 10, .{});

    js = "[[], [[]], [[], []]]";
    p.init();
    try parse(js, 7, 10, .{});

    js = "[\"a\", [[], []]]";
    p.init();
    try parse(js, 5, 10, .{});

    js = "[[], \"[], [[]]\", [[]]]";
    p.init();
    try parse(js, 5, 10, .{});

    js = "[1, 2, 3]";
    p.init();
    try parse(js, 4, 10, .{});

    js = "[1, 2, [3, \"a\"], null]";
    p.init();
    try parse(js, 7, 10, .{});
}

test "for non-strict mode" {
    var js: []const u8 = "a: 0garbage";
    try parse(js, 2, 2, .{ .{ Type.PRIMITIVE, "a" }, .{ Type.PRIMITIVE, "0garbage" } });

    js = "Day : 26\nMonth : Sep\n\nYear: 12";
    try parse(js, 6, 6, .{ .{ Type.PRIMITIVE, "Day" }, .{ Type.PRIMITIVE, "26" }, .{ Type.PRIMITIVE, "Month" }, .{ Type.PRIMITIVE, "Sep" }, .{ Type.PRIMITIVE, "Year" }, .{ Type.PRIMITIVE, "12" } });

    // nested {s don't cause a parse error.
    js = "\"key {1\": 1234";
    try parse(js, 2, 2, .{ .{ Type.STRING, "key {1", 1 }, .{ Type.PRIMITIVE, "1234" } });
}

test "for unmatched brackets" {
    var js: []const u8 = "\"key 1\": 1234}";
    try parse(js, Error.INVAL, 2, .{});
    js = "{\"key 1\": 1234";
    try parse(js, Error.PART, 3, .{});
    js = "{\"key 1\": 1234}}";
    try parse(js, Error.INVAL, 3, .{});
    js = "\"key 1\"}: 1234";
    try parse(js, Error.INVAL, 3, .{});
    js = "{\"key {1\": 1234}";
    try parse(js, 3, 3, .{ .{ Type.OBJECT, 0, 16, 1 }, .{ Type.STRING, "key {1", 1 }, .{ Type.PRIMITIVE, "1234" } });
    js = "{\"key 1\":{\"key 2\": 1234}";
    try parse(js, Error.PART, 5, .{});
}

test "for key type" {
    var js: []const u8 = "{\"key\": 1}";
    try parse(js, 3, 3, .{ .{ Type.OBJECT, 0, 10, 1 }, .{ Type.STRING, "key", 1 }, .{ Type.PRIMITIVE, "1" } });
    js = "{true: 1}";
    try parse(js, Error.INVAL, 3, .{});
    js = "{1: 1}";
    try parse(js, Error.INVAL, 3, .{});
    js = "{{\"key\": 1}: 2}";
    try parse(js, Error.INVAL, 5, .{});
    js = "{[1,2]: 2}";
    try parse(js, Error.INVAL, 5, .{});
}
