const std = @import("std");
const dbgPrint = std.debug.print;
const assert = std.debug.assert;

const input = @embedFile("inputs/day03.txt");

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
    var line_it = std.mem.splitScalar(u8, input, '\n');
    var joltage_sum: i64 = 0;
    var bs = try std.array_list.Managed(u8).initCapacity(gpa, 12);
    defer bs.deinit();
    while (line_it.next()) |line| {
        dbgPrint("{s}", .{line});
        bs.clearRetainingCapacity();
        if (part == 1) {
            try bs.appendNTimes(0, 2);
            for (line) |c| {
                const ci = c - '0';
                const prev_joltage = bs.items[0] * 10 + bs.items[1];
                const joltage0 = bs.items[0] * 10 + ci;
                const joltage1 = bs.items[1] * 10 + ci;
                if (joltage0 > joltage1) {
                    if (joltage0 > prev_joltage) {
                        bs.items[1] = ci;
                    }
                } else if (joltage1 > prev_joltage) {
                    bs.items[0] = bs.items[1];
                    bs.items[1] = ci;
                }
            }
            dbgPrint(" - {d}{d}\n", .{ bs.items[0], bs.items[1] });
            joltage_sum += bs.items[0] * 10 + bs.items[1];
        } else {
            try bs.appendNTimes(0, 12);
            var max_joltage: i64 = 0;
            for (line) |c| {
                const ci = c - '0';
                var skip_i: usize = 0;
                var max_skip_i: usize = 0;
                while (skip_i < 13) {
                    var mul: i64 = 100000000000;
                    var joltage: i64 = if (skip_i == 12) 0 else ci;
                    for (bs.items, 0..) |b, i| {
                        if (i == skip_i) {
                            continue;
                        }

                        joltage += b * mul;
                        mul = @divTrunc(mul, 10);
                    }
                    if (joltage >= max_joltage) {
                        max_joltage = joltage;
                        max_skip_i = skip_i;
                    }
                    skip_i += 1;
                }
                if (max_skip_i <= 11) {
                    _ = bs.orderedRemove(max_skip_i);
                    bs.appendAssumeCapacity(ci);
                }
            }
            dbgPrint(" - {d}\n", .{max_joltage});
            joltage_sum += max_joltage;
        }
    }

    // dbgPrint("This is a dbg_print that self flushes\n", .{});
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writerStreaming(&stdout_buffer);
    var stdout = &stdout_writer.interface;

    // Print result here
    try stdout.print("total joltage {d}\n", .{joltage_sum});
    try stdout.flush();
}
