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

const Direction = enum {
    N, S, E, W, Stay,
};

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
    bounds: Bounds,

    pub fn set(self: *Map, pos: Pos, val: NT) void {
        if (pos.x >= 0 and pos.x < self.width and pos.y >= 0 and pos.y < self.height) {
            const idx = (pos.y * self.width) + pos.x;
            self.data[@intCast(idx)] = val;
        }
    }

    pub fn get(self: *Map, pos: Pos) NT {
        if (pos.x >= 0 and pos.x < self.width and pos.y >= 0 and pos.y < self.height) {
            const idx = (pos.y * self.width) + pos.x;
            return self.data[@intCast(idx)];
        }
        return .Unknown; // Return Unknown if out of bounds
    }
};

// Update the map by first setting the new state based on the new_state and direction you came from.
// The take the next element from the regex and process it.
// Returns the next position in the regex to continue at.
fn traverse(map: *Map, current_pos: Pos, regex: []const u8, regex_idx: usize, new_state: NT, direction: Direction) !usize {
    // std.debug.print("pos {d}, {d}\n", .{current_pos.x, current_pos.y});
    if (regex_idx == regex.len) {
        return regex_idx; // Already processed the regex
    }

    // move in the direction specified to set the new state
    var new_pos: Pos = undefined;
    switch (direction) {
        .N => new_pos = .{ current_pos.x, current_pos.y - 1 },
        .S => new_pos = .{ current_pos.x, current_pos.y + 1 },
        .W => new_pos = .{ current_pos.x - 1, current_pos.y },
        .E => new_pos = .{ current_pos.x + 1, current_pos.y },
        .Stay => new_pos = .{ current_pos.x, current_pos.y - 1 },
    }
    
    // Update bounds
    if (new_pos.x < map.bounds.left) map.bounds.left = new_pos.x;
    if (new_pos.x > map.bounds.right) map.bounds.right = new_pos.x;
    if (new_pos.y < map.bounds.top) map.bounds.top = new_pos.y;
    if (new_pos.y > map.bounds.bottom) map.bounds.bottom = new_pos.y;

    // Verify bounds
    if (new_pos.x < 0 or new_pos.x >= map.width 
        or new_pos.y < 0 or new_pos.y >= map.height) {
        const bounds = map.bounds;
        std.debug.print("Bounds: left={d}, right={d}, top={d}, bottom={d}\n", .{bounds.left, bounds.right, bounds.top, bounds.bottom});
        return ZigError.OutOfBounds;
    }

    map.set(new_pos, new_state);

    switch (regex[regex_idx]) {
        '^' => return traverse(map, current_pos, regex, regex_idx + 1, .Room, .Stay),
        '$' => return regex_idx + 1,
        'N' => {

        },
        else => return traverse(map, current_pos, regex, regex_idx + 1, .Room, .Stay), // TODO error here instead
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

    const middle_x = grid_width / 2;
    const middle_y = grid_height / 2;

    const bounds: Bounds = .{ .left = middle_x, .right = middle_x, .top = middle_y, .bottom = middle_y };
    var map = Map{ .data = map_data, .width = grid_width, .height = grid_height, .bounds = bounds };

    const start: Pos = .{ .x = middle_x, .y = middle_y };
    std.debug.print("start pos {d},{d}\n", .{start.x, start.y});

    const end_idx = try traverse(&map, start, file_contents, 0, .Room, .Stay);
    std.debug.print("Finished at regex index {d}\n", .{end_idx});
    std.debug.print("Bounds: left={d}, right={d}, top={d}, bottom={d}\n", .{bounds.left, bounds.right, bounds.top, bounds.bottom});
}

