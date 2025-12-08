const std = @import("std");
const dbgPrint = std.debug.print;
const assert = std.debug.assert;

const input = @embedFile("inputs/day08.txt");

const Position = @Vector(3, i64);

const JunctionPair = struct {
    a: usize,
    b: usize,
    distance: f64,
};

fn compareDistances(context: void, a: JunctionPair, b: JunctionPair) std.math.Order {
    _ = context;
    return std.math.order(a.distance, b.distance);
}

fn contains(pairs: []JunctionPair, i: usize) bool {
    for (pairs) |pair| {
        if (pair.a == i or pair.b == i)
            return true;
    }
    return false;
}

fn len(v: Position) f64 {
    return std.math.sqrt(@as(f64, (@floatFromInt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]))));
}

fn connect(pair: JunctionPair, junctions: []Position, circuits: []usize, highest_circuit: *usize) void {
    dbgPrint("Connect {any} - {any}\n", .{ junctions[pair.a], junctions[pair.b] });
    const ca = &circuits[pair.a];
    const cb = &circuits[pair.b];
    if (ca.* != 0) {
        if (cb.* != 0) {
            const old_c = cb.*;
            for (circuits) |*c| {
                if (c.* == old_c) {
                    c.* = ca.*;
                }
            }
        } else {
            cb.* = ca.*;
        }
    } else if (cb.* != 0) {
        ca.* = cb.*;
    } else {
        highest_circuit.* += 1;
        ca.* = highest_circuit.*;
        cb.* = highest_circuit.*;
    }
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
    var junctions = std.array_list.Managed(Position).init(gpa);
    defer junctions.deinit();
    var line_it = std.mem.splitScalar(u8, input, '\n');
    while (line_it.next()) |line| {
        var vector_it = std.mem.splitScalar(u8, line, ',');
        var position: Position = .{ 0, 0, 0 };
        var i: usize = 0;
        while (vector_it.next()) |component| : (i += 1) {
            const c = try std.fmt.parseInt(i64, component, 10);
            assert(i < 4);
            position[i] = c;
        }
        try junctions.append(position);
    }

    var closest_pairs = std.PriorityQueue(JunctionPair, void, compareDistances).init(gpa, {});
    defer closest_pairs.deinit();
    for (0..junctions.items.len) |i| {
        var pair = JunctionPair{
            .a = i,
            .b = 0,
            .distance = std.math.floatMax(f32),
        };

        const ap = junctions.items[i];
        for (i + 1..junctions.items.len) |j| {
            const bp = junctions.items[j];
            const d = len(bp - ap);
            pair.b = j;
            pair.distance = d;
            try closest_pairs.add(pair);
        }
    }

    var circuits = std.array_list.Managed(usize).init(gpa);
    defer circuits.deinit();
    try circuits.appendNTimes(0, junctions.items.len);
    var highest_circuit: usize = 0;
    for (0..1000) |_| {
        if (closest_pairs.count() == 0)
            break;

        const pair = closest_pairs.remove();
        connect(pair, junctions.items, circuits.items, &highest_circuit);
    }
    if (part == 1) {
        var circuit_sizes = std.array_list.Managed(usize).init(gpa);
        defer circuit_sizes.deinit();
        for (0..highest_circuit + 1) |i| {
            const count = std.mem.count(
                usize,
                circuits.items,
                &[_]usize{i},
            );
            try circuit_sizes.append(count);
        }
        circuit_sizes.items[0] = 0; // These are the unconnected junctions
        std.mem.sort(usize, circuit_sizes.items, {}, comptime std.sort.desc(usize));
        var res: usize = 1;
        for (circuit_sizes.items[0..3]) |s| {
            res *= s;
        }
        try stdout.print("{d}", .{res});
    } else {
        var x_prod: i64 = 0;
        while (std.mem.count(usize, circuits.items, &[_]usize{circuits.items[0]}) != circuits.items.len) {
            const pair = closest_pairs.remove();
            connect(pair, junctions.items, circuits.items, &highest_circuit);
            const ap = junctions.items[pair.a];
            const bp = junctions.items[pair.b];
            x_prod = ap[0] * bp[0];
        }
        try stdout.print("{d}", .{x_prod});
    }
    try stdout.flush();
}
