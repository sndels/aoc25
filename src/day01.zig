const std = @import("std");
const dbgPrint = std.debug.print;
const assert = std.debug.assert;

const input = @embedFile("inputs/day01.txt");

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
    var it = std.mem.splitScalar(u8, input, '\n');
    var dial_counter: u64 = std.math.maxInt(u64) / 2;
    dial_counter -= dial_counter % 100;
    dial_counter += 50;
    var zero_counter: u64 = 0;
    dbgPrint("dial_counter: {d}\n", .{dial_counter});
    dbgPrint("dial: {d}\n", .{dial_counter % 100});
    while (it.next()) |line| {
        dbgPrint("{s}\n", .{line});
        const amount = try std.fmt.parseInt(u64, line[1..], 10);
        if (part == 1) {
            switch (line[0]) {
                'L' => dial_counter -= amount,
                'R' => dial_counter += amount,
                else => unreachable,
            }
            if (dial_counter % 100 == 0)
                zero_counter += 1;
        } else {
            const dial = dial_counter % 100;
            switch (line[0]) {
                'L' => {
                    if (dial <= amount) {
                        const rem_amount = amount - dial;
                        if (dial > 0)
                            zero_counter += 1;
                        zero_counter += rem_amount / 100;
                    }
                    dial_counter -= amount;
                },
                'R' => {
                    if (100 - dial <= amount) {
                        const rem_amount = amount - (100 - dial);
                        zero_counter += 1 + (rem_amount / 100);
                    }
                    dial_counter += amount;
                },
                else => unreachable,
            }
        }
        dbgPrint("dial_counter: {d}\n", .{dial_counter});
        dbgPrint("dial: {d}\n", .{dial_counter % 100});
        dbgPrint("zero_counter: {d}\n", .{zero_counter});
    }

    // dbgPrint("This is a dbg_print that self flushes\n", .{});
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writerStreaming(&stdout_buffer);
    var stdout = &stdout_writer.interface;

    // Print result here
    try stdout.print("zero count {d}", .{zero_counter});
    try stdout.flush();
}
