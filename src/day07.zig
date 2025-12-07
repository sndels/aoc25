const std = @import("std");
const dbgPrint = std.debug.print;
const assert = std.debug.assert;

const input = @embedFile("inputs/day07.txt");

const Beam = struct {
    pos: usize,
    timelines: usize,
};

pub fn findBeam(beams: []Beam, pos: usize) ?usize {
    for (beams, 0..) |beam, i| {
        if (beam.pos == pos)
            return i;
    }
    return null;
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
    var line_it = std.mem.splitScalar(
        u8,
        input,
        '\n',
    );
    var beams = std.array_list.Managed(Beam).init(gpa);
    defer beams.deinit();
    if (line_it.next()) |line| {
        dbgPrint("{s}\n", .{line});
        const start = std.mem.indexOfScalar(u8, line, 'S');
        try beams.append(Beam{ .pos = start.?, .timelines = 1 });
    }
    var split_count: i64 = 0;
    while (line_it.next()) |line| {
        for (0..line.len) |ci| {
            const c = line[ci];
            if (findBeam(beams.items, ci)) |bi| {
                if (c == '^') {
                    const beam = beams.swapRemove(bi);
                    assert(ci > 0);
                    assert(ci < line.len - 1);

                    if (findBeam(beams.items, ci - 1)) |bii| {
                        beams.items[bii].timelines += beam.timelines;
                    } else {
                        try beams.append(Beam{ .pos = ci - 1, .timelines = beam.timelines });
                    }
                    if (findBeam(beams.items, ci + 1)) |bii| {
                        beams.items[bii].timelines += beam.timelines;
                    } else {
                        try beams.append(Beam{ .pos = ci + 1, .timelines = beam.timelines });
                    }
                    split_count += 1;
                }
            }
        }
        for (0..line.len) |ci| {
            if (findBeam(beams.items, ci) != null) {
                dbgPrint("|", .{});
            } else {
                dbgPrint("{c}", .{line[ci]});
            }
        }
        dbgPrint("\n", .{});
    }
    if (part == 1) {
        try stdout.print("split count {d}", .{split_count});
    } else {
        var timeline_count: usize = 0;
        for (beams.items) |beam| {
            timeline_count += beam.timelines;
        }
        try stdout.print("timeline count {d}", .{timeline_count});
    }

    try stdout.flush();
}
