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

const Map = struct {
    data: []NT,
    width: i64,
    height: i64,

    pub fn set(self: *Map, x: i64, y: i64, val: NT) void {
        if (x >= 0 and x < self.width and y >= 0 and y < self.height) {
            const idx = (y * self.width) + x;
            self.data[@intCast(idx)] = val;
        }
    }

    pub fn get(self: *Map, x: i64, y: i64) NT {
        if (x >= 0 and x < self.width and y >= 0 and y < self.height) {
            const idx = (y * self.width) + x;
            return self.data[@intCast(idx)];
        }
        return .Unknown; // Return Unknown if out of bounds
    }
};

// Update the map until you reach the end of the regex or exceed the initial array size
// during the traversal.
// Returns the new regex_idx after processing
fn traverse(map: *Map, bounds: *Bounds, current_pos: Pos, regex: []const u8, regex_idx: usize) !usize {
    std.debug.print("pos {d}, {d}\n", .{current_pos.x, current_pos.y});
    
    // Update bounds
    if (current_pos.x < bounds.left) bounds.left = current_pos.x;
    if (current_pos.x > bounds.right) bounds.right = current_pos.x;
    if (current_pos.y < bounds.top) bounds.top = current_pos.y;
    if (current_pos.y > bounds.bottom) bounds.bottom = current_pos.y;

    map.set(current_pos.x, current_pos.y, .Room);

    switch (regex[regex_idx]) {
        '^' => return traverse(map, bounds, current_pos, regex, regex_idx + 1),
        '$' => return regex_idx,
        else => return traverse(map, bounds, current_pos, regex, regex_idx + 1),
    }
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

    const map_data = allocator.alloc(NT, grid_width * grid_height) catch return ZigError.OutOfMemory;
    defer allocator.free(map_data);

    @memset(map_data, .Unknown);

    var map = Map{ .data = map_data, .width = grid_width, .height = grid_height };

    const middle_x = grid_width / 2;
    const middle_y = grid_height / 2;

    const start: Pos = .{ .x = middle_x, .y = middle_y };
    std.debug.print("start pos {d},{d}\n", .{start.x, start.y});

    var bounds: Bounds = .{ .left = middle_x, .right = middle_x, .top = middle_y, .bottom = middle_y };  
    const end_idx = try traverse(&map, &bounds, start, file_contents, 0);
    std.debug.print("Finished at regex index {d}\n", .{end_idx});
    std.debug.print("Bounds: left={d}, right={d}, top={d}, bottom={d}\n", .{bounds.left, bounds.right, bounds.top, bounds.bottom});

}

