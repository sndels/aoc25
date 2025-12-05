const std = @import("std");
const dbgPrint = std.debug.print;
const assert = std.debug.assert;

const input = @embedFile("inputs/day05.txt");

const Range = struct { first: u64, last: u64 };

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
    var ranges = std.array_list.Managed(Range).init(gpa);
    defer ranges.deinit();
    var line_it = std.mem.splitScalar(u8, input, '\n');
    while (line_it.next()) |line| {
        if (line.len == 0)
            break;
        var range = Range{ .first = 0, .last = 0 };
        var range_it = std.mem.splitScalar(u8, line, '-');
        while (range_it.next()) |i| {
            if (range.first == 0) {
                range.first = try std.fmt.parseInt(u64, i, 10);
            } else {
                assert(range.last == 0);
                range.last = try std.fmt.parseInt(u64, i, 10);
            }
        }
        try ranges.append(range);
    }
    if (part == 1) {
        var fresh_count: u64 = 0;
        while (line_it.next()) |line| {
            const id = try std.fmt.parseInt(u64, line, 10);
            for (ranges.items) |range| {
                if (range.first <= id and id <= range.last) {
                    fresh_count += 1;
                    break;
                }
            }
        }
        try stdout.print("{d} fresh ingredients available\n", .{fresh_count});
    } else {
        std.mem.sort(Range, ranges.items, {}, struct {
            pub fn call(context: void, lhs: Range, rhs: Range) bool {
                return std.sort.asc(u64)(context, lhs.first, rhs.first);
            }
        }.call);
        var i: usize = 0;
        while (i < ranges.items.len) {
            var r0 = &ranges.items[i];
            var changed = true;
            while (changed) {
                changed = false;
                const j = i + 1;
                while (j < ranges.items.len) {
                    const r1 = ranges.items[j];
                    if (r1.first > r0.last)
                        break;
                    changed = true;
                    if (r1.last > r0.last) {
                        r0.last = r1.last;
                    }
                    _ = ranges.orderedRemove(j);
                }
            }
            i += 1;
        }
        var unique_ids: u64 = 0;
        for (ranges.items) |range| {
            unique_ids += range.last - range.first + 1;
        }
        try stdout.print("{d} fresh ingredient IDs in ID ranges\n", .{unique_ids});
    }

    try stdout.flush();
}
