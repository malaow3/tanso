const std = @import("std");
const data = @import("data.zig");
const builtin = @import("builtin");
const config = @import("config.zig");

var bun_process: std.process.Child = undefined;

pub fn init() !void {
    var child: std.process.Child = undefined;
    if (comptime builtin.os.tag != .windows) {
        child = std.process.Child.init(&[_][]const u8{ "bun", "run", "teamPack/dist/index.js" }, std.heap.page_allocator);
    }
    if (comptime builtin.os.tag == .windows) {
        child = std.process.Child.init(&[_][]const u8{ "bun.exe", "run", "teamPack/dist/index.js" }, std.heap.page_allocator);
    }
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;
    child.stdin_behavior = .Pipe;
    try child.spawn();

    // Wait for the process to write to stderr
    var stderr_buf: [1024]u8 = undefined;
    const stderr = child.stderr.?;
    var stderr_reader = stderr.reader();
    while (true) {
        const stderr_data = stderr_reader.read(&stderr_buf) catch |err| {
            if (err == error.WouldBlock) {
                break; // No more data available for now
            }
            return err; // Propagate other errors
        };
        if (stderr_data != 0) {
            break;
        }
    }
    stderr.close();
    child.stderr_behavior = .Inherit;

    bun_process = child;
}

pub fn runBun(db_path: []const u8) ![]data.Team {
    // Read the data from the file.
    const start = std.time.milliTimestamp();
    // const file = try std.fs.cwd().openFile("test.txt", .{});
    const file = try std.fs.cwd().openFile(db_path, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    var buf = try std.heap.page_allocator.alloc(u8, file_size);
    defer std.heap.page_allocator.free(buf);

    const br = try file.readAll(buf);
    const file_data = buf[0..br];
    // Remove the last newline
    const trimmed_data = if (file_data[file_data.len - 1] == '\n') file_data[0 .. file_data.len - 1] else file_data;

    // Replace all newlines with "\\n".
    var new_data = try std.ArrayList(u8).initCapacity(std.heap.page_allocator, trimmed_data.len * 2);
    defer new_data.deinit();

    for (file_data) |byte| {
        if (byte == '\n') {
            try new_data.appendSlice("\\n");
        } else {
            try new_data.append(byte);
        }
    }
    // Convert the new data to a string
    const new_data_str = try new_data.toOwnedSlice();
    const end = std.time.milliTimestamp();
    std.debug.print("File read and processed in {}ms\r\n", .{end - start});

    // Write to stdin
    var proc_stdin = bun_process.stdin.?;
    try proc_stdin.writeAll(new_data_str);
    proc_stdin.close();

    // Read from stdout.
    var stdout_buf: [1024]u8 = undefined;
    var stdout_reader = bun_process.stdout.?.reader();

    var data_buffer = std.ArrayList(u8).init(std.heap.page_allocator);
    defer data_buffer.deinit();

    while (true) {
        const bytes_read = try stdout_reader.read(&stdout_buf);
        if (bytes_read == 0) {
            break;
        }

        if (std.mem.eql(u8, stdout_buf[0..bytes_read], "END_OF_OUTPUT")) {
            break;
        }

        // Append the read data to the ArrayList
        try data_buffer.appendSlice(stdout_buf[0..bytes_read]);
    }

    // If the data_buffer has "\nEND_OF_OUTPUT" in it, remove it.
    if (std.mem.indexOf(u8, data_buffer.items, "\nEND_OF_OUTPUT") != null) {
        const end_of_output_index = std.mem.indexOf(u8, data_buffer.items, "\nEND_OF_OUTPUT").?;
        data_buffer.items = data_buffer.items[0..end_of_output_index];
    }

    // Parse the stdout JSON content to the teams type.
    const data_slice = try data_buffer.toOwnedSlice();

    const json_value = try std.json.parseFromSlice(std.json.Value, std.heap.page_allocator, data_slice, .{});
    const teams = try data.parseTeams(json_value.value.array);
    return teams;
}

pub fn writeToClipboard(clip_data: []const u8) !void {
    if (comptime builtin.os.tag == .macos) {
        var pbcopy = std.process.Child.init(&[_][]const u8{"/usr/bin/pbcopy"}, std.heap.page_allocator);
        pbcopy.stdin_behavior = .Pipe;
        try pbcopy.spawn();

        // Write the data to the clipboard
        const stdin = pbcopy.stdin.?;
        try stdin.writeAll(clip_data);
        stdin.close();
        return;
    }

    var is_wsl = false;
    if (comptime builtin.os.tag == .linux) {
        if (isWSL()) {
            is_wsl = true;
        } else {
            // Use xclip to write to the clipboard
            var xclip = std.process.Child.init(&[_][]const u8{ "xclip", "-selection", "clipboard" }, std.heap.page_allocator);
            xclip.stdin_behavior = .Pipe;
            try xclip.spawn();

            // Write the data to the clipboard
            const stdin = xclip.stdin.?;
            try stdin.writeAll(clip_data);
            stdin.close();
            return;
        }
    }
    if (is_wsl) {
        // Use clip.exe to write to the clipboard
        var clip = std.process.Child.init(&[_][]const u8{"clip.exe"}, std.heap.page_allocator);
        clip.stdin_behavior = .Pipe;
        try clip.spawn();

        // Write the data to the clipboard
        const stdin = clip.stdin.?;
        try stdin.writeAll(clip_data);
        stdin.close();
        return;
    } else if (builtin.os.tag == .windows) {
        var clip = std.process.Child.init(&[_][]const u8{"clip.exe"}, std.heap.page_allocator);
        clip.stdin_behavior = .Pipe;
        try clip.spawn();

        const stdin = clip.stdin.?;
        try stdin.writeAll(clip_data);
        stdin.close();
        return;
    } else {
        std.debug.print("Unsupported operating system", .{});
        std.process.exit(1);
    }
}

pub fn isWSL() bool {
    const proc_version = std.fs.cwd().readFileAlloc(std.heap.page_allocator, "/proc/version", std.math.maxInt(usize)) catch {
        return false;
    };

    defer std.heap.page_allocator.free(proc_version);
    if (std.mem.indexOf(u8, proc_version, "microsoft") != null) {
        return true;
    }
    return false;
}

test "writeToClipboard" {
    // Write "test" and the current time to the clipboard
    const c = @cImport({
        @cInclude("time.h");
    });
    var result: [20]u8 = undefined;
    const now = c.time(null);
    const ts = c.localtime(&now);
    // Format the current time as a string
    _ = c.strftime(&result, result.len, "%Y-%m-%d %H:%M:%S", ts);

    const str = try std.fmt.allocPrint(std.heap.page_allocator, "test-{s}", .{result[0..]});

    try writeToClipboard(str);
}
