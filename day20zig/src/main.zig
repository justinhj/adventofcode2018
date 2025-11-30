const std = @import("std");
const Allocator = std.mem.Allocator;

const ZigError = error {
    NoFileSupplied,
    OutOfMemory,
    FileNotFound,
    OutOfBounds,
};

fn getInputFileName(allocator: std.mem.Allocator) ZigError![]const u8 {
    var it = try std.process.argsWithAllocator(allocator);
    defer it.deinit();
    _ = it.next(); // skip the executable (first arg)
    const filename = it.next() orelse return ZigError.NoFileSupplied;
    return filename;
}

const Pos = struct {
    x: i64,
    y: i64,
};

const Bounds = struct {
    left: i64,
    right: i64,
    top: i64,
    bottom: i64,
};

const NT = enum {
    Unknown,
    Wall,
    Room,
    Door,
};

// Update the map until you reach the end of the regex or exceed the initial array size
// during the traversal.
fn traverse(map_pos: Pos, regex_pos: usize, regex: []const u8, bounds: Bounds) ZigError.OutOfBounds!Bounds {
    std.debug.print("pos {d}, {d}\n", .{map_pos.x, map_pos.y});
    switch (regex[regex_pos]) {
        '^' => traverse(regex_pos + 1, map_pos, regex),
        '$' => return,
        else => traverse(regex_pos + 1, map_pos, regex),
    }
    return bounds;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    // Note the arena allocator is convenient here because we don't free
    // anything until the end, it simplifies the freeing.
    const allocator = arena.allocator();
    const input_file_name = getInputFileName(allocator) catch {
        std.debug.print("Please pass a file path to the input.\n", .{});
        return;
    }; 
    std.debug.print("Processing file {s}.\n", .{input_file_name});

    const open_flags = std.fs.File.OpenFlags {.mode = .read_only};
    const file = std.fs.cwd().openFile(input_file_name, open_flags) catch {
        return ZigError.FileNotFound;
    };
    defer file.close();

    const max_file_size = 100 * 1024; // 100 kb
    const file_contents = try file.readToEndAlloc(allocator, max_file_size);
    defer allocator.free(file_contents);

    std.debug.print("Loaded input. {d} bytes.\n", .{file_contents.len});

    // TODO would parse here normally but we can simply parse and generate the map
    // in one go...

    // Create a large grid and we will start in the centre. 
    const grid_width = 1000;
    const grid_height = 1000;

    const map = allocator.alloc(NT, grid_width * grid_height) catch return ZigError.OutOfMemory;
    defer allocator.free(map);

    @memset(map, .Unknown);

    const middle_x = grid_width / 2;
    const middle_y = grid_height / 2;

    const start: Pos = .{ .x = middle_x, .y = middle_y };
    std.debug.print("start pos {d},{d}\n", .{start.x, start.y});

    const bounds: Bounds = .{ .left = middle_x, .right = middle_x, .top = middle_y, .bottom = middle_y };  
    const result = traverse(start, 0, file_contents, bounds);
    if (result) |b| {
        std.debug.print("bounds! {d}\n", .{b.left});
    } else {

        std.debug.print("Out of bounds!");
    }

}

