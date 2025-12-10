const std = @import("std");
const dbgPrint = std.debug.print;
const assert = std.debug.assert;

const input = @embedFile("inputs/day10.txt");

const ParseState = enum { Lights, Button, Joltages };
const Button = struct {
    begin: usize,
    end: usize,
};

const LightState = struct {
    lights: [10]u8, // Input only has <10 lights for any machine
    presses: usize,
    previous_press: usize,
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
    var line_it = std.mem.splitScalar(u8, input, '\n');
    var target_lights = try std.array_list.Managed(u8).initCapacity(gpa, 10);
    defer target_lights.deinit();
    var buttons_backing = std.array_list.Managed(u8).init(gpa);
    defer buttons_backing.deinit();
    var buttons = std.array_list.Managed(Button).init(gpa);
    defer buttons.deinit();
    var states = std.array_list.Managed(LightState).init(gpa);
    defer states.deinit();
    var seen_lights = std.AutoHashMap([10]u8, void).init(gpa);
    defer seen_lights.deinit();
    var press_sum: usize = 0;
    while (line_it.next()) |line| {
        target_lights.clearRetainingCapacity();
        buttons_backing.clearRetainingCapacity();
        buttons.clearRetainingCapacity();
        try buttons.append(Button{ .begin = 0, .end = 0 });

        dbgPrint("{s}\n", .{line});
        assert(line[0] == '[');
        var parse_state = ParseState.Lights;
        var i: usize = 1;
        line_loop: while (i < line.len) : (i += 1) {
            const c = line[i];
            switch (parse_state) {
                ParseState.Lights => {
                    switch (c) {
                        '#', '.' => target_lights.appendAssumeCapacity(c),
                        ']' => {
                            parse_state = ParseState.Button;
                            i += 1;
                            assert(line[i] == ' ');
                            i += 1;
                            assert(line[i] == '(');
                        },
                        else => unreachable,
                    }
                },
                ParseState.Button => {
                    switch (c) {
                        '0'...'9' => {
                            try buttons_backing.append(c - '0');
                            buttons.items[buttons.items.len - 1].end += 1;
                        },
                        ',' => {},
                        ')' => {
                            i += 1;
                            assert(line[i] == ' ');
                            i += 1;
                            if (line[i] == '{') {
                                parse_state = ParseState.Joltages;
                            } else {
                                assert(line[i] == '(');
                                try buttons.append(Button{
                                    .begin = buttons_backing.items.len,
                                    .end = buttons_backing.items.len,
                                });
                            }
                        },
                        else => unreachable,
                    }
                },
                ParseState.Joltages => break :line_loop,
            }
        }
        // dbgPrint("{s} {any} {any}\n", .{ target_lights.items, buttons_backing.items, buttons.items });

        seen_lights.clearRetainingCapacity();
        states.clearRetainingCapacity();
        try states.append(LightState{
            .lights = [_]u8{'.'} ** 10,
            .presses = 0,
            .previous_press = 10,
        });
        try seen_lights.put(states.items[0].lights, {});
        while (true) {
            const source_state = states.orderedRemove(0);
            if (std.mem.eql(u8, target_lights.items, source_state.lights[0..target_lights.items.len])) {
                dbgPrint("{d} needed\n", .{source_state.presses});
                press_sum += source_state.presses;
                break;
            }

            for (buttons.items, 0..) |button, bi| {
                if (bi == source_state.previous_press)
                    continue;
                var state = source_state;
                state.previous_press = bi;
                state.presses += 1;
                for (button.begin..button.end) |lbi| {
                    const li = buttons_backing.items[lbi];
                    const light = &state.lights[li];
                    if (light.* == '#') {
                        light.* = '.';
                    } else {
                        light.* = '#';
                    }
                }
                if (seen_lights.contains(state.lights))
                    continue;
                try states.append(state);
                try seen_lights.put(state.lights, {});
            }
        }
    }
    try stdout.print("fewest presses for all {d}", .{press_sum});

    try stdout.flush();
}
