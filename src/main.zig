const std = @import("std");
const JsonDb = @import("./root.zig").JsonDb;

const Entry = struct {
    title: []const u8,
};

const Data = [256]Entry;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var data: Data = undefined;
    data[0] = Entry{ .title = "Deneme" };
    const db = try JsonDb(Data).init("./deneme.json", allocator, data);

    defer db.deinit();

    defer std.debug.print("Hi from jsondb!\n", .{});
}
