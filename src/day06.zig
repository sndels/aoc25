const std = @import("std");
const dbgPrint = std.debug.print;
const assert = std.debug.assert;

const input = @embedFile("inputs/day06.txt");

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
    var operators = std.array_list.Managed(u8).init(gpa);
    defer operators.deinit();
    var operand_lines = std.array_list.Managed([]const u8).init(gpa);
    defer operand_lines.deinit();
    const max_operand_count = std.mem.count(u8, input, "\n");
    var line_it = std.mem.splitScalar(
        u8,
        input,
        '\n',
    );
    var line_len: usize = 0;
    while (line_it.next()) |line| {
        assert(line_len == 0 or line_len == line.len);
        line_len = line.len;
        if (line[0] == '+' or line[0] == '*') {
            var operator_it = std.mem.splitScalar(
                u8,
                line,
                ' ',
            );
            while (operator_it.next()) |op| {
                if (op.len == 0)
                    continue;
                assert(op.len == 1);
                // TODO:
                // How to instantiate generic functions (std.math.add(i64)) for a function pointer?
                if (op[0] == '*') {
                    try operators.append('*');
                } else if (op[0] == '+') {
                    try operators.append('+');
                } else {
                    unreachable;
                }
            }
        } else {
            try operand_lines.append(line);
        }
    }
    assert(operand_lines.items.len == max_operand_count);
    var accumulators = std.array_list.Managed(i64).init(gpa);
    defer accumulators.deinit();
    for (operators.items) |op| {
        if (op == '*') {
            try accumulators.append(1);
        } else if (op == '+') {
            try accumulators.append(0);
        } else {
            unreachable;
        }
    }
    if (part == 1) {
        for (operand_lines.items) |line| {
            var operand_it = std.mem.splitScalar(u8, line, ' ');
            var column: usize = 0;
            while (operand_it.next()) |operand| {
                if (operand.len == 0)
                    continue;

                const rhs = try std.fmt.parseInt(i64, operand, 10);
                assert(column < operators.items.len);
                assert(column < accumulators.items.len);
                const op = operators.items[column];
                const acc = &accumulators.items[column];
                if (op == '*') {
                    acc.* = acc.* * rhs;
                } else if (op == '+') {
                    acc.* = acc.* + rhs;
                } else {
                    unreachable;
                }
                column += 1;
            }
        }
    } else {
        var operands = std.array_list.Managed(i64).init(gpa);
        defer operands.deinit();
        var i: usize = 0;
        var acc: usize = 0;
        while (acc < accumulators.items.len) : (acc += 1) {
            for (0..max_operand_count) |_| {
                try operands.append(0);
            }

            // TODO:
            // Parse operand columns until all rows have a ' '
            // Then do the op and continue
            var c: usize = 0;
            var digit_found = true;
            while (digit_found and (i + c) < line_len) : (c += 1) {
                digit_found = false;
                for (0..max_operand_count) |j| {
                    const line = operand_lines.items[j];
                    const d = line[i + c];
                    if (d == ' ')
                        continue;

                    digit_found = true;
                    const operand = &operands.items[c];
                    if (operand.* != 0)
                        operand.* *= 10;
                    operand.* += d - '0';
                }
            }
            i += c;

            dbgPrint("{any} ", .{operands.items});
            const operator = operators.items[acc];
            const accumulator = &accumulators.items[acc];
            if (operator == '*') {
                for (operands.items) |operand| {
                    accumulator.* *= @max(operand, 1);
                }
            } else if (operator == '+') {
                for (operands.items) |operand| {
                    accumulator.* += operand;
                }
            } else {
                unreachable;
            }
            dbgPrint("{d}\n", .{accumulator.*});

            operands.clearRetainingCapacity();
        }
    }

    var grand_total: i64 = 0;
    for (accumulators.items) |acc| {
        grand_total += acc;
    }
    try stdout.print("grand total {d}", .{grand_total});

    try stdout.flush();
}
