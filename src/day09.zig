const std = @import("std");
const dbgPrint = std.debug.print;
const assert = std.debug.assert;

const input = @embedFile("inputs/day09.txt");

const Position = @Vector(3, i64);

const Tile = struct {
    x: i64,
    y: i64,
};

fn setTile(floor: []u8, width: i64, tile: Tile, c: u8) void {
    floor[@as(usize, @intCast(tile.y * width + tile.x))] = c;
}

fn handleTile(floor: []u8, width: i64, tile: Tile, previous_tile: Tile) void {
    if (tile.x == previous_tile.x) {
        var j = @min(previous_tile.y, tile.y) + 1;
        const end = @max(previous_tile.y, tile.y);
        while (j < end) : (j += 1)
            setTile(floor, width, Tile{ .x = tile.x, .y = j }, 'X');
    } else if (tile.y == previous_tile.y) {
        var i = @min(previous_tile.x, tile.x) + 1;
        const end = @max(previous_tile.x, tile.x);
        while (i < end) : (i += 1)
            setTile(floor, width, Tile{ .x = i, .y = tile.y }, 'X');
    } else {
        unreachable;
    }
    setTile(floor, width, tile, '#');
}

fn intersect(c0: Tile, c1: Tile, t0: Tile, t1: Tile) bool {
    // TODO:
    // Intersect corners instead to get winding and no false positive when going
    // ..|XXX
    // --#-->?
    // XXXXXXX
    if (c0.x == c1.x) {
        if (t0.x == t1.x) {
            return false;
        } else {
            const ty = t0.y;
            if (c1.y > c0.y) {
                if (c0.y >= ty)
                    return false;
                if (c1.y <= ty)
                    return false;
            }
            if (c1.y < c0.y) {
                if (c0.y <= ty)
                    return false;
                if (c1.y >= ty)
                    return false;
            }
            const cx = c0.x;
            const tlx = @min(t0.x, t1.x);
            const thx = @max(t0.x, t1.x);
            return tlx <= cx and cx <= thx;
        }
    }

    if (t0.y == t1.y)
        return false;
    const tx = t0.x;
    if (c1.x > c0.x) {
        if (c0.x >= tx)
            return false;
        if (c1.x <= tx)
            return false;
    }
    if (c1.x < c0.x) {
        if (c0.x <= tx)
            return false;
        if (c1.x >= tx)
            return false;
    }
    const cy = c0.y;
    const tly = @min(t0.y, t1.y);
    const thy = @max(t0.y, t1.y);
    return tly <= cy and cy <= thy;
}

fn anyIntersect(tiles: []Tile, t0: Tile, t1: Tile) bool {
    var prev_tile = tiles[tiles.len - 1];
    for (tiles) |tile| {
        if (intersect(t0, t1, prev_tile, tile))
            return true;
        prev_tile = tile;
    }
    return false;
}

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

    if (part == 1) {
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
    } else {
        var largest_area: i64 = 0;
        for (0..tiles.items.len) |i| {
            const t0 = tiles.items[i];
            mid: for ((i + 1)..tiles.items.len) |j| {
                const t1 = tiles.items[j];
                dbgPrint("\n{any} -> {any}", .{ t0, t1 });
                const tl = Tile{ .x = @min(t0.x, t1.x), .y = @min(t0.y, t1.y) };
                const tr = Tile{ .x = @max(t0.x, t1.x), .y = @min(t0.y, t1.y) };
                const bl = Tile{ .x = @min(t0.x, t1.x), .y = @max(t0.y, t1.y) };
                const br = Tile{ .x = @max(t0.x, t1.x), .y = @max(t0.y, t1.y) };

                if (anyIntersect(tiles.items, tl, tr))
                    continue :mid;
                if (anyIntersect(tiles.items, tr, br))
                    continue :mid;
                if (anyIntersect(tiles.items, br, bl))
                    continue :mid;
                if (anyIntersect(tiles.items, bl, tl))
                    continue :mid;

                const area = (br.x - tl.x + 1) * (br.y - tl.y + 1);
                dbgPrint(" = {d}", .{area});
                if (area > largest_area)
                    largest_area = area;
            }
        }
        try stdout.print("\nlargest area {d}", .{largest_area});
    }
    try stdout.flush();
}
