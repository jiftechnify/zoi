const std = @import("std");

pub const testing = struct {
    // workaround for an issue of `expectEqual`.
    //
    // When a comptime-known value is passed as `expected`, the compiler complains that
    // `actual` value must be comptime-known, although `actual` value is generally runtime-known.
    // So we are forced to cast `expected` to a type of runtime-known value, which is cumbersome.
    //
    // To resolve this issue, we can define wrapper of `expectEqual` which casts `expected` to the type of `actual` automatically.
    //
    // cf. https://github.com/ziglang/zig/issues/4437#issuecomment-683309291
    pub fn expectEqual(expected: anytype, actual: anytype) !void {
        try std.testing.expectEqual(@as(@TypeOf(actual), expected), actual);
    }
};

const expectEqual = testing.expectEqual;

/// Checks if given `i8` value fits in the range of type `T`.
///
/// `T` must be a signed integer type.
pub fn fitsIn(comptime T: type, n: i8) bool {
    switch (@typeInfo(T)) {
        .Int => |i| {
            switch (i.signedness) {
                .signed => {
                    if (i.bits > 8) {
                        @compileError("T's number of bits should be less than or equal to 8");
                    }
                    return std.math.minInt(T) <= n and n <= std.math.maxInt(T);
                },
                .unsigned => @compileError("T should be signed integer type"),
            }
        },
        else => @compileError("T should be signed integer type"),
    }
}

test "fitsIn" {
    const tt = [_]struct { T: type, n: i8, exp: bool }{
        .{ .T = i2, .n = -3, .exp = false },
        .{ .T = i2, .n = -2, .exp = true },
        .{ .T = i2, .n = -1, .exp = true },
        .{ .T = i2, .n = 0, .exp = true },
        .{ .T = i2, .n = 1, .exp = true },
        .{ .T = i2, .n = 2, .exp = false },

        .{ .T = i4, .n = 7, .exp = true },
        .{ .T = i4, .n = -8, .exp = true },
        .{ .T = i4, .n = 8, .exp = false },

        .{ .T = i6, .n = 31, .exp = true },
        .{ .T = i6, .n = -32, .exp = true },
        .{ .T = i6, .n = 32, .exp = false },
    };

    inline for (tt) |t| {
        try expectEqual(t.exp, fitsIn(t.T, t.n));
    }
}

/// Add `bias` to `n` and convert it to `u8` by bit-preserving cast.
pub fn addBias(n: i8, bias: i8) u8 {
    return @bitCast(u8, n +% bias);
}

test "addBias" {
    const tt = [_]struct { n: i8, bias: i8, exp: u8 }{
        .{ .n = -2, .bias = 2, .exp = 0 },
        .{ .n = -1, .bias = 2, .exp = 1 },
        .{ .n = 0, .bias = 2, .exp = 2 },
        .{ .n = 1, .bias = 2, .exp = 3 },

        .{ .n = -8, .bias = 8, .exp = 0 },
        .{ .n = 0, .bias = 8, .exp = 8 },
        .{ .n = 7, .bias = 8, .exp = 15 },

        .{ .n = -32, .bias = 32, .exp = 0 },
        .{ .n = 0, .bias = 32, .exp = 32 },
        .{ .n = 31, .bias = 32, .exp = 63 },
    };

    for (tt) |t| {
        try expectEqual(t.exp, addBias(t.n, t.bias));
    }
}