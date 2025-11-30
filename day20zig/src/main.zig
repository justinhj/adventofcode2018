const std = @import("std");
const Allocator = std.mem.Allocator;

const ZigError = error {
    NoFileSupplied,
    OutOfMemory,
    FileNotFound,
};

fn getInputFileName(allocator: std.mem.Allocator) ZigError![]const u8 {
    var it = try std.process.argsWithAllocator(allocator);
    defer it.deinit();
    _ = it.next(); // skip the executable (first arg)
    const filename = it.next() orelse return ZigError.NoFileSupplied;
    return filename;
}

const NT = enum {
    Unknown,
    Wall,
    Room,
    Door,
};

// Graph node
const GN = struct {
    x: i64,
    y: i64,
    node_type: NT,

    n: ?*GN = null,
    s: ?*GN = null,
    e: ?*GN = null,
    w: ?*GN = null,

    pub fn init(allocator: Allocator) ZigError!*GN {
        const node = allocator.create(GN) catch return ZigError.OutOfMemory;
        node.* = GN{
                .x = 0,
                .y = 0,
                .node_type = .Room,
                .n = null,
                .s = null,
                .e = null,
                .w = null,
            };

        return node;
    }
};

// Build the graph recursively advancing the pos through the regex and growing the graph.
// Note we assume the input is perfect and simply panic if it is not.
fn bg(pos: usize, node: *GN, regex: []u8) void {
    std.debug.print("pos {d}\n", .{pos});
    switch (regex[pos]) {
        '^' => bg(pos + 1, node, regex),
        '$' => return,
        else => bg(pos + 1, node, regex),
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

    // Walk the regex and create a graph of nodes
    const node = try GN.init(allocator);
    bg(0, node, file_contents);

}

