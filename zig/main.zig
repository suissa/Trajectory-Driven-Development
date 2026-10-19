const std = @import("std");
const traject = @import("traject_runner.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const artifact = traject.runBuyProduct(.diverge);
    const json = try traject.serializeArtifact(allocator, artifact);
    defer allocator.free(json);

    // std.debug.print writes to stderr; CI redirects it to the artifact file.
    std.debug.print("{s}\n", .{json});
}
