const std = @import("std");
const dbgPrint = std.debug.print;
const assert = std.debug.assert;

const input = @embedFile("inputs/day02.txt");

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
    var line_it = std.mem.splitScalar(u8, input, ',');
    var total_invalid_sum: u64 = 0;
    var scratch: [1024]u8 = undefined;
    while (line_it.next()) |line| {
        dbgPrint("{s}\n", .{line});
        var begin: u64 = 0;
        var end: u64 = 0;
        var range_it = std.mem.splitScalar(u8, line, '-');
        while (range_it.next()) |endpoint| {
            if (begin == 0) {
                begin = try std.fmt.parseInt(u64, endpoint, 10);
            } else {
                assert(end == 0);
                end = try std.fmt.parseInt(u64, endpoint, 10);
            }
        }
        assert(begin != 0);
        assert(end != 0);
        assert(begin <= end);

        var invalid_sum: u64 = 0;
        for (begin..(end + 1)) |id| {
            // dbgPrint("id {d} ", .{id});
            const is = try std.fmt.bufPrint(&scratch, "{d}", .{id});
            if (part == 1) {
                if (is.len % 2 == 0) {
                    const n = is.len / 2;
                    const front = is[0..n];
                    const back = is[n..];
                    if (std.mem.eql(u8, front, back)) {
                        // dbgPrint("invalid\n", .{});
                        invalid_sum += id;
                    } else {
                        // dbgPrint("\n", .{});
                    }
                }
            } else {
                for (1..(is.len / 2 + 1)) |n| {
                    var slices_it = std.mem.window(u8, is, n, n);
                    if (slices_it.next()) |first| {
                        var all_slices_equal = true;
                        while (slices_it.next()) |slice| {
                            all_slices_equal &= std.mem.eql(u8, slice, first);
                            if (!all_slices_equal)
                                break;
                        }
                        if (all_slices_equal) {
                            // dbgPrint("invalid", .{});
                            invalid_sum += id;
                            break;
                        }
                    }
                }
            }
            // dbgPrint("\n", .{});
        }
        total_invalid_sum += invalid_sum;
    }

    // dbgPrint("This is a dbg_print that self flushes\n", .{});
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writerStreaming(&stdout_buffer);
    var stdout = &stdout_writer.interface;

    // Print result here
    try stdout.print("total invalid sum {d}\n", .{total_invalid_sum});
    try stdout.flush();
}
