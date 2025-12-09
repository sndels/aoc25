const std = @import("std");
const dbgPrint = std.debug.print;
const assert = std.debug.assert;

const input = @embedFile("inputs/day09.txt");

const Position = @Vector(3, i64);

const Tile = struct {
    x: i64,
    y: i64,
};

pub fn main() !void {
    var gpa_backing = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_backing.deinit();
    const gpa = gpa_backing.allocator();

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);
    assert(args.len == 2);
    const part = try std.fmt.parseUnsigned(u32, args[1], 10);
    assert(part == 1 or part == 2);

    // dbgPrint("This is a dbg_print that self flushes\n", .{});
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writerStreaming(&stdout_buffer);
    var stdout = &stdout_writer.interface;

    // Day code here
    var tiles = std.array_list.Managed(Tile).init(gpa);
    defer tiles.deinit();
    var line_it = std.mem.splitScalar(u8, input, '\n');
    while (line_it.next()) |line| {
        var vector_it = std.mem.splitScalar(u8, line, ',');
        var tile = Tile{ .x = 0, .y = 0 };
        if (vector_it.next()) |x| {
            tile.x = try std.fmt.parseInt(i64, x, 10);
        }
        if (vector_it.next()) |y| {
            tile.y = try std.fmt.parseInt(i64, y, 10);
        }
        try tiles.append(tile);
    }

    var largest_area: u64 = 0;
    for (0..tiles.items.len) |i| {
        const t0 = tiles.items[i];
        for (i..tiles.items.len) |j| {
            const t1 = tiles.items[j];
            const area = @abs(t0.x - t1.x + 1) * @abs(t0.y - t1.y + 1);
            dbgPrint("{any} -> {any} = {d}\n", .{ t0, t1, area });
            if (area > largest_area)
                largest_area = area;
        }
    }

    try stdout.print("largest area {d}", .{largest_area});
    try stdout.flush();
}
