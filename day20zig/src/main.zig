const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const testing = std.testing;

const ZigError = error{
    NoFileSupplied,
    OutOfMemory,
    FileNotFound,
    OutOfBounds,
};

fn getInputFileNameArg(allocator: std.mem.Allocator) ZigError![]const u8 {
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
        const min_map_x = self.bounds.left - 1;
        const max_map_x = self.bounds.right + 1;
        const min_map_y = self.bounds.top - 1;
        const max_map_y = self.bounds.bottom + 1;

        var y = min_map_y;
        while (y <= max_map_y) : (y += 1) {
            var x = min_map_x;
            while (x <= max_map_x) : (x += 1) {
                const tile = self.get(.{ .x = x, .y = y });
                const char: u8 = switch (tile) {
                    .Room => '.',
                    .Door => '-',
                    .Unknown => '#',
                    .Wall => '#',
                };
                std.debug.print("{c}", .{char});
            }
            std.debug.print("\n", .{});
        }
    }

    pub fn dijkstra_max(self: *Map, allocator: std.mem.Allocator, start: Pos) !usize {
        
        // 1. Structure for Priority Queue
        const State = struct {
            pos: Pos,
            cost: usize,
        };

        // 2. Comparison function for Min-Heap (Dijkstra)
        const Compare = struct {
            fn lessThan(context: void, a: State, b: State) std.math.Order {
                _ = context;
                return std.math.order(a.cost, b.cost);
            }
        };

        // 3. Initialize Distance Map (keep track of costs + visited)
        // We use a flat array matching map dimensions for speed.
        const total_size = @as(usize, @intCast(self.width * self.height));
        var dist_map = try allocator.alloc(usize, total_size);
        defer allocator.free(dist_map);
        
        // Initialize with max integer (Infinity)
        @memset(dist_map, std.math.maxInt(usize));

        // 4. Initialize Priority Queue
        var pq = std.PriorityQueue(State, void, Compare.lessThan).init(allocator, {});
        defer pq.deinit();

        // 5. Setup Start Node
        // Calculate index for start position
        const start_idx = @as(usize, @intCast((start.y * self.width) + start.x));
        dist_map[start_idx] = 0;
        try pq.add(.{ .pos = start, .cost = 0 });

        var max_distance: usize = 0;

        // 6. The Loop
        while (pq.removeOrNull()) |current| {
            
            // Optimization: If we found a shorter way to this node already, skip
            const curr_idx = @as(usize, @intCast((current.pos.y * self.width) + current.pos.x));
            if (current.cost > dist_map[curr_idx]) continue;

            // Update global max distance if this is a Room
            // In this problem, we usually only care about distance to Rooms, not Doors
            if (self.get(current.pos) == .Room) {
                if (current.cost > max_distance) max_distance = current.cost;
            }

            // Check Neighbors (N, S, E, W)
            const neighbors = [_]Pos{
                .{ .x = current.pos.x, .y = current.pos.y - 1 }, // N
                .{ .x = current.pos.x, .y = current.pos.y + 1 }, // S
                .{ .x = current.pos.x + 1, .y = current.pos.y }, // E
                .{ .x = current.pos.x - 1, .y = current.pos.y }, // W
            };

            for (neighbors) |n_pos| {
                const tile = self.get(n_pos);

                // Valid movement: Can walk into Doors or Rooms
                if (tile == .Door or tile == .Room) {
                    const new_cost = current.cost + 1;
                    const n_idx = @as(usize, @intCast((n_pos.y * self.width) + n_pos.x));

                    if (new_cost < dist_map[n_idx]) {
                        dist_map[n_idx] = new_cost;
                        try pq.add(.{ .pos = n_pos, .cost = new_cost });
                    }
                }
            }
        }

        // Return max_distance / 2 because the grid steps are Room -> Door -> Room.
        // That counts as 2 array steps, but logically it is 1 "door passed".
        return max_distance / 2;
    }

    pub fn unknown_to_wall(self: *Map) void {
        const min_map_x = self.bounds.left;
        const max_map_x = self.bounds.right;
        const min_map_y = self.bounds.top;
        const max_map_y = self.bounds.bottom;

        var y = min_map_y;
        while (y <= max_map_y) : (y += 1) {
            var x = min_map_x;
            while (x <= max_map_x) : (x += 1) {
                const tile = self.get(.{ .x = x, .y = y });
                if (tile == .Unknown) {
                    self.set(.{ .x = x, .y = y }, .Wall);
                }
            }
        }
    }
};

const Options = struct {
    starts: ArrayList(usize),
    end: usize,

    pub fn deinit(self: *Options, allocator: Allocator) void {
        return self.starts.deinit(allocator);
    }
};

fn calculate_options(allocator: Allocator, regex: []const u8, regex_start: usize) ZigError!Options {
    var starts = try ArrayList(usize).initCapacity(allocator, 32);
    var end_idx: usize = 0;
    var depth: usize = 0;
    var i = regex_start;

    // Note that we start looking at the '('
    try starts.append(allocator, i + 1);

    while (i < regex.len) {
        const char = regex[i];
        switch (char) {
            '(' => {
                depth += 1;
            },
            '|' => {
                if (depth == 1) {
                    try starts.append(allocator, i + 1);
                }
            },
            ')' => {
                depth -= 1;
                if (depth == 0) {
                    end_idx = i;
                    break;
                }
            },
            else => {
                // Skip non related characters
            },
        }
        i += 1;
    }

    if (end_idx == 0) {
        return ZigError.OutOfBounds;
    }

    return Options{ .starts = starts, .end = end_idx };
}

const AutoHashMap = std.AutoHashMap;

fn expand(allocator: Allocator, map: *Map, start_pos: Pos, regex: []const u8) !void {
    // Track the expanding positions, to start with just the start position
    var current_positions = AutoHashMap(Pos, void).init(allocator);
    defer current_positions.deinit();
    try current_positions.put(start_pos, {});

    // Each frame remembers where each group started, and accumulates where branches end.
    const Frame = struct {
        starts: std.ArrayList(Pos), // Snapshot of positions when '(' was hit
        ends: std.ArrayList(Pos),   // Accumulator of positions where branches '|' ended
    };

    var stack = try ArrayList(Frame).initCapacity(allocator, 100);
    defer {
        for (stack.items) |*f| {
            f.starts.deinit(allocator);
            f.ends.deinit(allocator);
        }
        stack.deinit(allocator);
    }

    var i: usize = 0;
    while (i < regex.len) : (i += 1) {
        const char = regex[i];

        switch (char) {
            '^', '$' => continue,
            'N', 'S', 'E', 'W' => {
                // Move ALL current positions in this direction
                var next_positions = AutoHashMap(Pos, void).init(allocator);
                // don't defer deinit here because we swap it with current_positions later

                var it = current_positions.keyIterator();
                while (it.next()) |pos_ptr| {
                    var pos = pos_ptr.*;
                    
                    var dx: i64 = 0;
                    var dy: i64 = 0;
                    switch (char) {
                        'N' => dy = -1,
                        'S' => dy = 1,
                        'E' => dx = 1,
                        'W' => dx = -1,
                        else => unreachable,
                    }

                    pos.x += dx;
                    pos.y += dy;
                    try map.update_bounds(pos);
                    map.set(pos, .Door);

                    pos.x += dx;
                    pos.y += dy;
                    try map.update_bounds(pos);
                    map.set(pos, .Room);

                    try next_positions.put(pos, {});
                }
                
                current_positions.deinit();
                current_positions = next_positions;
            },
            '(' => {
                // Start of a group. Push state.
                // Save current "starts" so we can reset to them at every '|'
                var starts_list = try ArrayList(Pos).initCapacity(allocator, 1000);
                var it = current_positions.keyIterator();
                while (it.next()) |p| try starts_list.append(allocator, p.*);

                try stack.append(allocator, .{
                    .starts = starts_list,
                    .ends = try ArrayList(Pos).initCapacity(allocator, 1000),
                });
            },
            '|' => {
                // End of a branch option. 
                // 1. Save where we are now into 'ends' accumulator
                var frame = &stack.items[stack.items.len - 1];
                var it = current_positions.keyIterator();
                while (it.next()) |p| try frame.ends.append(allocator, p.*);

                // 2. Reset current positions to the group 'starts' for the next option
                current_positions.clearRetainingCapacity();
                for (frame.starts.items) |p| {
                    try current_positions.put(p, {});
                }
            },
            ')' => {
                // End of the group.
                var frame = &stack.items[stack.items.len - 1];

                // 1. The current path is also a valid endpoint, add it to 'ends'
                var it = current_positions.keyIterator();
                while (it.next()) |p| try frame.ends.append(allocator, p.*);

                // 2. Our new current positions are ALL the accumulated endpoints
                current_positions.clearRetainingCapacity();
                for (frame.ends.items) |p| {
                    try current_positions.put(p, {});
                }

                // 3. Cleanup stack
                frame.starts.deinit(allocator);
                frame.ends.deinit(allocator);
                _ = stack.pop();
            },
            else => {},
        }
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    // Note the arena allocator is convenient here because we don't free
    // anything until the end, it simplifies the freeing.
    const allocator = arena.allocator();
    const input_file_name = getInputFileNameArg(allocator) catch {
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
    const grid_width = 250;
    const grid_height = 250;

    const map_data = allocator.alloc(NT, grid_width * grid_height) catch return ZigError.OutOfMemory;
    defer allocator.free(map_data);

    @memset(map_data, .Unknown);

    const middle_x = @divTrunc(grid_width, 2);
    const middle_y = @divTrunc(grid_height, 2);

    const bounds: Bounds = .{ .left = middle_x, .right = middle_x, .top = middle_y, .bottom = middle_y };
    var map = Map{ .data = map_data, .width = grid_width, .height = grid_height, .bounds = bounds };

    const start: Pos = .{ .x = middle_x, .y = middle_y };
    std.debug.print("start pos {f}\n", .{start});

    map.set(start, .Room);
    try expand(allocator, &map, start, file_contents);
    std.debug.print("map.bounds: {f}\n", .{map.bounds});
    map.unknown_to_wall();
    map.draw_map();

    const furthest = try map.dijkstra_max(allocator, start);
    std.debug.print("furthest {d}\n", .{furthest});
}

test "calculate options" {
    const test1 = "^ENWWW(NEEE|SSE(EE|N))$";
    var result = try calculate_options(testing.allocator, test1, 6);
    defer result.deinit(testing.allocator);

    try testing.expectEqualSlices(usize, &[_]usize{ 7, 12 }, result.starts.items);
    try testing.expectEqual(21, result.end);
}

test "calculate options nested" {
    const test1 = "^ENWWW(NEEE(NN(NEEEE)EE)|SSE|NNN(EEE|WWW)EEE)$";
    var result = try calculate_options(testing.allocator, test1, 6);
    defer result.deinit(testing.allocator);

    try testing.expectEqualSlices(usize, &[_]usize{ 7, 25, 29 }, result.starts.items);
    try testing.expectEqual(44, result.end);
}

test "calculate options with empty pipe" {
    const test1 = "^ENW(NEEE|WEEEE|))$";
    var result = try calculate_options(testing.allocator, test1, 4);
    defer result.deinit(testing.allocator);

    try testing.expectEqualSlices(usize, &[_]usize{ 5, 10, 16 }, result.starts.items);
    try testing.expectEqual(16, result.end);
}
