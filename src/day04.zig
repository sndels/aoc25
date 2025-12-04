const std = @import("std");
const dbgPrint = std.debug.print;
const assert = std.debug.assert;

const input = @embedFile("inputs/day04.txt");

pub fn main() !void {
    var gpa_backing = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_backing.deinit();
    const gpa = gpa_backing.allocator();

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);
    assert(args.len == 2);
    const part = try std.fmt.parseUnsigned(u32, args[1], 10);
    assert(part == 1 or part == 2);

    // Day code here
    var grid_width: usize = 0;
    var grid_cells = std.array_list.Managed(u8).init(gpa);
    defer grid_cells.deinit();
    var tmp_grid_cells = std.array_list.Managed(u8).init(gpa);
    defer tmp_grid_cells.deinit();
    var line_it = std.mem.splitScalar(u8, input, '\n');
    while (line_it.next()) |line| {
        if (grid_width == 0) {
            grid_width = line.len;
        } else {
            assert(grid_width == line.len);
        }
        try grid_cells.appendSlice(line);
    }
    try tmp_grid_cells.resize(grid_cells.items.len);
    assert(grid_width > 0);
    const grid_height: usize = @divTrunc(grid_cells.items.len, grid_width);

    var accessable_rolls: i32 = 0;
    while (true) {
        const previous_sum = accessable_rolls;
        for (0..grid_height) |y| {
            for (0..grid_width) |x| {
                if (grid_cells.items[y * grid_width + x] == '@') {
                    var adjacent_roll_count: i32 = 0;
                    const j_min = @as(usize, @intCast(@max(0, @as(i32, @intCast(y)) - 1)));
                    for (j_min..@min(y + 2, grid_height)) |j| {
                        const i_min = @as(usize, @intCast(@max(0, @as(i32, @intCast(x)) - 1)));
                        for (i_min..@min(x + 2, grid_width)) |i| {
                            if (grid_cells.items[j * grid_width + i] == '@')
                                adjacent_roll_count += 1;
                        }
                    }
                    // 5 because we'll count the cell itself too
                    if (adjacent_roll_count < 5) {
                        accessable_rolls += 1;
                        tmp_grid_cells.items[y * grid_width + x] = '.';
                        dbgPrint("x", .{});
                    } else {
                        tmp_grid_cells.items[y * grid_width + x] = '@';
                        dbgPrint("@", .{});
                    }
                } else {
                    tmp_grid_cells.items[y * grid_width + x] = '.';
                    dbgPrint(".", .{});
                }
            }
            dbgPrint("\n", .{});
        }
        if (part == 1) {
            break;
        } else if (previous_sum == accessable_rolls) {
            break;
        }
        grid_cells.clearRetainingCapacity();
        grid_cells.appendSliceAssumeCapacity(tmp_grid_cells.items);
    }

    // dbgPrint("This is a dbg_print that self flushes\n", .{});
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writerStreaming(&stdout_buffer);
    var stdout = &stdout_writer.interface;

    // Print result here
    try stdout.print("accessible rolls {d}\n", .{accessable_rolls});
    try stdout.flush();
}
