const std = @import("std");
const fs = std.fs;
const Allocator = std.mem.Allocator;

///
/// Helper function, opens and returns file content to a buffer.
///
fn read_file(f_name: []const u8, allocator: Allocator) ![]u8 {
    // get size of file for allocation
    const f_size = try file_size(f_name);

    const buffer = try allocator.alloc(u8, f_size);

    const exists = file_exists(f_name);
    if (!exists) {
        return error.FileNotFound;
    }

    var file = try std.fs.cwd().openFile(f_name, .{});
    defer file.close();

    _ = try file.readAll(buffer);

    return buffer;
}

///
/// Helper function, returns size of the file
///
pub fn file_size(f_name: []const u8) !u64 {
    const file = try std.fs.cwd().openFile(f_name, .{});
    defer file.close();

    const stats = try file.stat();
    return stats.size;
}

///
/// Helper function, returns true or false according to file exists.
///
fn file_exists(f_name: []const u8) bool {
    const stats = fs.cwd().statFile(f_name) catch {
        return false;
    };
    const kind = stats.kind;
    return kind == std.fs.File.Kind.file;
}

fn write_file(f_name: []const u8, buffer: []const u8) !void {
    // write only flag
    const flags = std.fs.File.OpenFlags{ .mode = .write_only };

    const file = try fs.cwd().openFile(f_name, flags);
    defer file.close();

    _ = try file.writeAll(buffer);
}

test "file test" {
    const allocator = std.testing.allocator;
    const f_name = ".file.test.file.tmp";

    // create test file
    _ = try fs.cwd().createFile(f_name, .{});

    // write contents
    const write_contents = "This is a test content!\nThe second line";
    _ = try write_file(f_name, write_contents);

    // read contents
    const read_contents = try read_file(f_name, allocator);
    defer allocator.free(read_contents);

    _ = try std.testing.expect(std.mem.eql(u8, write_contents, read_contents));
}
