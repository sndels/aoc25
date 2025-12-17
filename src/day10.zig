const std = @import("std");
const dbgPrint = std.debug.print;
const assert = std.debug.assert;

const input = @embedFile("inputs/day10.txt");

const ParseState = enum { Lights, Button, Joltages };
const Button = struct {
    begin: usize,
    end: usize,
};

const MachineState = struct {
    indicators: [10]i32, // Input only has <10 lights/joltages for any machineh
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
    var target_indicators = try std.array_list.Managed(i32).initCapacity(gpa, 10);
    defer target_indicators.deinit();
    var buttons_backing = std.array_list.Managed(u8).init(gpa);
    defer buttons_backing.deinit();
    var buttons = std.array_list.Managed(Button).init(gpa);
    defer buttons.deinit();
    var machine_states = std.array_list.Managed(MachineState).init(gpa);
    defer machine_states.deinit();
    var seen_states = std.AutoHashMap([10]i32, void).init(gpa);
    defer seen_states.deinit();
    var press_sum: usize = 0;
    while (line_it.next()) |line| {
        target_indicators.clearRetainingCapacity();
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
                        '#' => {
                            if (part == 1) {
                                target_indicators.appendAssumeCapacity(1);
                            }
                        },
                        '.' => {
                            if (part == 1) {
                                target_indicators.appendAssumeCapacity(0);
                            }
                        },
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
                ParseState.Joltages => {
                    if (part == 2) {
                        const end = if (std.mem.indexOfScalar(u8, line[i..], '}')) |ei| ei else 0;
                        assert(end > 0);
                        var joltage_it = std.mem.splitScalar(u8, line[i..(i + end)], ',');
                        while (joltage_it.next()) |joltage| {
                            target_indicators.appendAssumeCapacity(try std.fmt.parseInt(i32, joltage, 10));
                        }
                    }
                    break :line_loop;
                },
            }
        }
        dbgPrint("{any} {any} {any}\n", .{ target_indicators.items, buttons_backing.items, buttons.items });

        seen_states.clearRetainingCapacity();
        machine_states.clearRetainingCapacity();
        try machine_states.append(MachineState{
            .indicators = [_]i32{0} ** 10,
            .presses = 0,
            .previous_press = 10,
        });
        try seen_states.put(machine_states.items[0].indicators, {});
        state_loop: while (true) {
            const source_state = machine_states.orderedRemove(0);
            if (std.mem.eql(i32, target_indicators.items, source_state.indicators[0..target_indicators.items.len])) {
                dbgPrint("{d} needed\n", .{source_state.presses});
                press_sum += source_state.presses;
                break;
            }

            if (part == 2) {
                for (0..target_indicators.items.len) |ti| {
                    if (target_indicators.items[ti] < source_state.indicators[ti])
                        continue :state_loop;
                }
            }

            button_loop: for (buttons.items, 0..) |button, bi| {
                if (bi == source_state.previous_press)
                    continue;
                var state = source_state;
                state.previous_press = bi;
                state.presses += 1;
                for (button.begin..button.end) |lbi| {
                    const li = buttons_backing.items[lbi];
                    const indicator = &state.indicators[li];
                    if (indicator.* == target_indicators.items[li])
                        continue :button_loop;
                    if (part == 1) {
                        if (indicator.* == 0) {
                            indicator.* = 1;
                        } else {
                            indicator.* = 0;
                        }
                    } else {
                        // TODO:
                        // Really need to do multiple presses at once or something when the joltages are in the hundreds.
                        indicator.* += 1;
                    }
                }
                if (seen_states.contains(state.indicators))
                    continue;
                try machine_states.append(state);
                try seen_states.put(state.indicators, {});
            }
        }
    }
    try stdout.print("fewest presses for all {d}", .{press_sum});

    try stdout.flush();
}
