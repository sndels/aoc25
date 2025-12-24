const std = @import("std");
const dbgPrint = std.debug.print;
const assert = std.debug.assert;

const input = @embedFile("inputs/day11.txt");

const Device = struct {
    name: [3]u8,
    connections: std.array_list.Managed(usize),
};

fn deviceIndex(devices: []Device, name: [3]u8) ?usize {
    for (devices, 0..) |device, i| {
        // TODO:
        // Is there a std lib function like std.mem.eql but for pointers and size?
        if (name[0] == device.name[0] and name[1] == device.name[1] and name[2] == device.name[2]) {
            return i;
        }
    }
    return null;
}

fn countSimplePaths(devices: []Device, device_index: usize, out_index: usize) usize {
    assert(device_index != out_index);
    const device = &devices[device_index];
    var found_paths: usize = 0;
    for (device.connections.items) |ci| {
        if (ci == out_index) {
            found_paths += 1;
        } else {
            found_paths += countSimplePaths(devices, ci, out_index);
        }
    }
    return found_paths;
}

fn recurCountDacFftPaths(
    devices: []Device,
    tail_path_counts: []usize,
    device_index: usize,
    dac_index: usize,
    fft_index: usize,
    out_index: usize,
    dac_visited: bool,
    fft_visited: bool,
) usize {
    // TODO:
    // Memoization doesn't work here. Four cases
    //  - dac_visited and fft_visited
    //    - add all tail paths
    //  - dac_visited
    //    - add tail paths that have fft
    //  - fft_visited
    //    - add tail paths that have dac
    //  - neither dac nor fft
    //    - add tail paths that have dac and fft
    const tail_count = tail_path_counts[device_index];
    if (tail_count < devices.len)
        return tail_count;

    dbgPrint("dac {any} fft {any}\n", .{ dac_visited, fft_visited });
    const device = &devices[device_index];
    var found_paths: usize = 0;
    for (device.connections.items) |ci| {
        if (ci == out_index) {
            if (dac_visited and fft_visited)
                found_paths += 1;
            continue;
        }

        var new_dac_visited = dac_visited;
        var new_fft_visited = fft_visited;
        if (ci == dac_index) {
            dbgPrint("dac\n", .{});
            new_dac_visited = true;
        } else if (ci == fft_index) {
            dbgPrint("fft\n", .{});
            new_fft_visited = true;
        }
        found_paths += recurCountDacFftPaths(
            devices,
            tail_path_counts,
            ci,
            dac_index,
            fft_index,
            out_index,
            new_dac_visited,
            new_fft_visited,
        );
    }
    tail_path_counts[device_index] = found_paths;
    return found_paths;
}

fn countDacFftPaths(gpa: std.mem.Allocator, devices: []Device, device_index: usize, out_index: usize) !usize {
    const dac_index = deviceIndex(devices, .{ 'd', 'a', 'c' }) orelse unreachable;
    const fft_index = deviceIndex(devices, .{ 'f', 'f', 't' }) orelse unreachable;
    var tail_path_counts = std.array_list.Managed(usize).init(gpa);
    defer tail_path_counts.deinit();
    try tail_path_counts.appendNTimes(devices.len, devices.len);
    return recurCountDacFftPaths(devices, tail_path_counts.items, device_index, dac_index, fft_index, out_index, false, false);
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
    var devices = std.array_list.Managed(Device).init(gpa);
    defer {
        for (devices.items) |device| {
            device.connections.deinit();
        }
        devices.deinit();
    }
    var line_it = std.mem.splitScalar(u8, input, '\n');
    while (line_it.next()) |line| {
        const device = Device{
            .name = .{ line[0], line[1], line[2] },
            .connections = std.array_list.Managed(usize).init(gpa),
        };
        try devices.append(device);
    }
    {
        const device = Device{
            .name = .{ 'o', 'u', 't' },
            .connections = std.array_list.Managed(usize).init(gpa),
        };
        try devices.append(device);
    }

    line_it = std.mem.splitScalar(u8, input, '\n');
    while (line_it.next()) |line| {
        dbgPrint("{s}\n", .{line});
        const device_name = [_]u8{ line[0], line[1], line[2] };
        const device_index = deviceIndex(devices.items, device_name) orelse unreachable;
        const device = &devices.items[device_index];
        var connection_it = std.mem.splitScalar(u8, line[5..], ' ');
        while (connection_it.next()) |connection| {
            dbgPrint("{s}\n", .{connection});
            assert(connection.len == 3);
            const connection_name = [_]u8{ connection[0], connection[1], connection[2] };
            const connection_index = deviceIndex(devices.items, connection_name) orelse unreachable;
            try device.connections.append(connection_index);
        }
    }
    dbgPrint("\n\n", .{});
    for (devices.items) |device| {
        dbgPrint("{s}:", .{device.name});
        for (device.connections.items) |ci| {
            dbgPrint(" {s}", .{devices.items[ci].name});
        }
        dbgPrint("\n", .{});
    }

    const out_index = devices.items.len - 1;
    assert(std.mem.eql(u8, &devices.items[out_index].name, &.{ 'o', 'u', 't' }));

    if (part == 1) {
        const you_index = deviceIndex(devices.items, .{ 'y', 'o', 'u' }) orelse unreachable;
        const found_paths = countSimplePaths(devices.items, you_index, out_index);
        try stdout.print("found paths from you to out {d}\n", .{found_paths});
    } else {
        const svr_index = deviceIndex(devices.items, .{ 's', 'v', 'r' }) orelse unreachable;
        const found_paths = try countDacFftPaths(gpa, devices.items, svr_index, out_index);
        try stdout.print("found paths from svr to out with dac and fft {d}\n", .{found_paths});
    }

    try stdout.flush();
}
