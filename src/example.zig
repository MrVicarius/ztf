const std = @import("std");
const tf = @import("tf");

pub fn main() !void {
    std.debug.print("TF version detected: {s}\n", .{tf.TF_Version()});
}
