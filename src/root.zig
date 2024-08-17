const std = @import("std");
const json = std.json;
const futil = @import("./utils//file.zig");
const Allocator = std.mem.Allocator;
const testing = std.testing;

///
/// Json db is a simple
///
pub fn JsonDb(comptime T: type) type {
    return struct {
        data: T,
        f_name: []const u8,
        allocator: Allocator,

        const Self = @This();

        ///
        /// Inits the Db takes path of file
        ///
        pub fn init(f_name: []const u8, allocator: Allocator, data: T) !*Self {
            const self: *Self = try allocator.create(Self);

            self.allocator = allocator;
            self.f_name = f_name;
            self.data = data;

            self.read() catch |err| {
                if (err == error.FileNotFound) {
                    _ = try self.save(); // write and read if file not created
                }
            };
            return self;
        }
        pub fn deinit(self: *Self) void {
            self.allocator.destroy(self);
        }
        ///
        /// Reads and loads the data from jsonfile
        ///
        pub fn read(self: *Self) !void {

            // read contents from file
            const contents = try futil.read_file(self.f_name, self.allocator);
            defer self.allocator.free(contents);

            const value: json.Parsed(T) = try std.json.parseFromSlice(T, self.allocator, contents, .{ .allocate = .alloc_always });
            defer self.allocator.free(value);
            self.data = value.value;
        }
        ///
        /// Writes data to json file, it may write as strict for minimizing
        ///
        pub fn write(self: *Self, minify: bool, options: ?json.StringifyOptions) !void {
            if (!futil.file_exists(self.f_name)) {
                _ = try std.fs.cwd().createFile(self.f_name, std.fs.File.CreateFlags{});
            }
            var opt = options orelse json.StringifyOptions{};
            if (minify) {
                opt.whitespace = .minified;
            }
            const buffer = try json.stringifyAlloc(self.allocator, self.data, json.StringifyOptions{ .whitespace = .minified });
            defer self.allocator.free(buffer);
            _ = try futil.write_file(self.f_name, buffer);
        }

        ///
        /// Just a wrapper function for saving and reading the date
        ///
        pub fn save(self: *Self) !void {
            _ = try self.write(false, null);
            _ = try self.read();
        }
    };
}

test "jsondb" {
    const allocator = std.testing.allocator;
    const Data = struct { test_field: []u8, age: u8 };
    const str = "Test string 1";
    const str2 = "Test string after change";
    const string = try allocator.alloc(u8, 256);
    defer allocator.free(string);
    @memcpy(string[0..str.len], str[0..str.len]);

    const data = Data{ .age = 20, .test_field = string };

    var db: *JsonDb(Data) = try JsonDb(Data).init("./jsondb.json", allocator, data);
    defer db.deinit();

    db.data.age = 42;
    @memcpy(string[0..str2.len], str2[0..str2.len]);

    _ = try db.save();
}
