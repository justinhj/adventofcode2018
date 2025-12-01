const std = @import("std");
const Allocator = std.mem.Allocator;

const ZigError = error{
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

const Direction = enum {
    N,
    S,
    E,
    W,
    Stay,
};

const Pos = struct {
    x: i64,
    y: i64,

    pub fn format(self: *const Pos, wr: *std.io.Writer) std.io.Writer.Error!void {
        try wr.print("{d},{d}", .{ self.x, self.y });
    }
};

const Bounds = struct {
    left: i64,
    right: i64,
    top: i64,
    bottom: i64,

    pub fn format(self: *const Bounds, wr: *std.io.Writer) std.io.Writer.Error!void {
        try wr.print("{d},{d} => {d},{d}", .{ self.left, self.top, self.right, self.bottom });
    }
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
    bounds: Bounds,

    pub fn set(self: *Map, pos: Pos, val: NT) void {
        if (pos.x >= 0 and pos.x < self.width and pos.y >= 0 and pos.y < self.height) {
            const idx = (pos.y * self.width) + pos.x;
            self.data[@intCast(idx)] = val;
        }
    }

    pub fn get(self: *const Map, pos: Pos) NT {
        if (pos.x >= 0 and pos.x < self.width and pos.y >= 0 and pos.y < self.height) {
            const idx = (pos.y * self.width) + pos.x;
            return self.data[@intCast(idx)];
        }
        return .Unknown; // Return Unknown if out of bounds
    }

    pub fn update_bounds(self: *Map, pos: Pos) ZigError!void {
        if (pos.x < self.bounds.left) self.bounds.left = pos.x;
        if (pos.x > self.bounds.right) self.bounds.right = pos.x;
        if (pos.y < self.bounds.top) self.bounds.top = pos.y;
        if (pos.y > self.bounds.bottom) self.bounds.bottom = pos.y;

        // Verify bounds
        if (pos.x < 0 or pos.x >= self.width or pos.y < 0 or pos.y >= self.height) {
            return ZigError.OutOfBounds;
        }
    }

    pub fn draw_map(self: *const Map) void {
        const min_map_x = self.bounds.left;
        const max_map_x = self.bounds.right;
        const min_map_y = self.bounds.top;
        const max_map_y = self.bounds.bottom;

        // Use a while loop to handle the i64 range cleanly
        var y = min_map_y;
        while (y <= max_map_y) : (y += 1) {
            var x = min_map_x;
            while (x <= max_map_x) : (x += 1) {

                // Retrieve data directly to respect *const Map signature
                // (Your helper 'get' requires *Map)
                var tile = NT.Unknown;
                if (x >= 0 and x < self.width and y >= 0 and y < self.height) {
                    const idx = (y * self.width) + x;
                    tile = self.data[@intCast(idx)];
                }

                const char: u8 = switch (tile) {
                    .Room => '.',
                    .Door => '-', // Per instructions
                    // Render Unknown/Wall as hashes to visualize the structure clearly
                    .Wall, .Unknown => '#',
                };

                std.debug.print("{c}", .{char});
            }
            // Newline at the end of the row
            std.debug.print("\n", .{});
        }
    }
};

// Update the map by first setting the new state based on the new_state and direction you came from.
// The take the next element from the regex and process it.
// Returns the next position in the regex to continue at.
fn traverse(map: *Map, current_pos: Pos, regex: []const u8, regex_idx: usize, direction: Direction) !usize {
    if (regex_idx == regex.len) {
        return regex_idx; // Reached the end
    }

    var new_pos: Pos = current_pos;
    // When not staying we must make a door and then a new room.
    if (direction != .Stay) {
        // move in the direction specified to set the new state
        switch (direction) {
            .N => new_pos.y -= 1,
            .S => new_pos.y += 1,
            .W => new_pos.x -= 1,
            .E => new_pos.x += 1,
            .Stay => new_pos = .{ .x = current_pos.x, .y = current_pos.y },
        }
        try map.update_bounds(new_pos);
        map.set(new_pos, .Door);
    }

    // Now make new room

    switch (direction) {
        .N => new_pos.y -= 1,
        .S => new_pos.y += 1,
        .W => new_pos.x -= 1,
        .E => new_pos.x += 1,
        .Stay => new_pos = .{ .x = current_pos.x, .y = current_pos.y },
    }
    try map.update_bounds(new_pos);
    map.set(new_pos, .Room);

    // Now get the next step.

    var continue_idx: usize = undefined;
    switch (regex[regex_idx]) {
        '^' => continue_idx = try traverse(map, new_pos, regex, regex_idx + 1, .Stay),
        '$' => continue_idx = regex_idx + 1,
        'N' => continue_idx = try traverse(map, new_pos, regex, regex_idx + 1, .N),
        'S' => continue_idx = try traverse(map, new_pos, regex, regex_idx + 1, .S),
        'W' => continue_idx = try traverse(map, new_pos, regex, regex_idx + 1, .W),
        'E' => continue_idx = try traverse(map, new_pos, regex, regex_idx + 1, .E),
        else => unreachable,
    }
    return continue_idx;
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

    const open_flags = std.fs.File.OpenFlags{ .mode = .read_only };
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

    const middle_x = @divTrunc(grid_width, 2);
    const middle_y = @divTrunc(grid_height, 2);

    const bounds: Bounds = .{ .left = middle_x, .right = middle_x, .top = middle_y, .bottom = middle_y };
    var map = Map{ .data = map_data, .width = grid_width, .height = grid_height, .bounds = bounds };

    const start: Pos = .{ .x = middle_x, .y = middle_y };
    std.debug.print("start pos {f}\n", .{start});

    const end_idx = try traverse(&map, start, file_contents, 0, .Stay);
    std.debug.print("Finished at regex index {d}\n", .{end_idx});
    std.debug.print("map.bounds: {f}\n", .{map.bounds});
    map.draw_map();
}
