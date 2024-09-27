const std = @import("std");
const data = @import("data.zig");
const vaxis = @import("vaxis");

pub const Item = struct {
    selected: bool,
    team: data.Team,
    index: usize,
};

const View = enum {
    list,
    info,
};

const offset_cols = 3;
const offset_rows = 1;

// The extra row offset is used to account for the version string and the navigation instructions.
const extra_row_offset = 9;

pub const State = struct {
    items: *[]Item,
    allocator: std.mem.Allocator,
    vx: *vaxis.Vaxis,
    input: *vaxis.widgets.TextInput,
    tty: *vaxis.Tty,
    version_string: [25]u8,
    selected_option: usize,
    pages: usize,
    page_size: ?usize,
    current_page: usize,
    info_scroll_offset: usize,
    max_lines: usize,
    max_width: ?usize,
    total_lines: usize,
    view: View,
    teams_loaded: bool = false,
    total_info_lines: usize,

    pub fn redraw(self: *State) !void {
        switch (self.view) {
            .list => try self.drawList(),
            .info => try self.drawInfo(),
        }
    }

    fn drawInfo(self: *State) !void {
        const win = self.vx.window();
        win.clear();
        self.input.draw(win);
        win.hideCursor();

        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();
        const aalloc = arena.allocator();

        var lines = std.ArrayList(vaxis.Segment).init(aalloc);
        defer lines.deinit();

        const team = self.items.ptr[self.selected_option];
        const text = team.team.text;
        self.max_lines = self.vx.window().height - 3;

        var top_line = team.team.name;
        if (team.team.format) |format| {
            top_line = try std.fmt.allocPrint(aalloc, "{s} | {s}", .{ team.team.name, format });
        }
        lines.append(.{ .text = top_line }) catch unreachable;
        lines.append(.{ .text = "" }) catch unreachable;

        // Get the lines
        if (text) |t| {
            var text_lines = std.mem.split(u8, t, "\n");
            var total_lines: usize = 0;
            while (text_lines.next()) |line| {
                if (total_lines >= self.info_scroll_offset and lines.items.len < self.max_lines) {
                    lines.append(.{ .text = line }) catch unreachable;
                }
                total_lines += 1;
            }
            if (self.info_scroll_offset > 0) {
                lines.append(.{ .text = "^ More above" }) catch unreachable;
            }
            if (total_lines > self.info_scroll_offset + self.max_lines) {
                lines.append(.{ .text = "v More below" }) catch unreachable;
            }
            self.total_info_lines = total_lines;
        }

        lines.append(.{ .text = "Use j/k to scroll, c to copy, e to go back" }) catch unreachable;

        for (lines.items, 0..) |line, idx| {
            _ = try win.printSegment(line, .{ .row_offset = idx, .col_offset = 0 });
        }
        try self.vx.render(self.tty.anyWriter());
    }

    fn drawList(self: *State) !void {
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();
        const aalloc = arena.allocator();

        const win = self.vx.window();
        win.clear();
        self.input.draw(win);
        win.hideCursor();

        var lines = std.ArrayList(vaxis.Segment).init(aalloc);
        defer lines.deinit();

        if (self.max_width == null) {
            if (self.vx.screen.width != 0) {
                if (self.vx.screen.width < 10) {
                    self.max_width = self.vx.screen.width;
                } else {
                    self.max_width = self.vx.screen.width - 10;
                }
            }
        } else if (self.max_width != null) {
            var value = self.vx.screen.width;
            if (self.vx.screen.width < 10) {
                value = self.vx.screen.width;
            } else {
                value = self.vx.screen.width - 10;
            }
            self.max_width = @min(value, self.max_width.?);
        }

        lines.append(.{ .text = &self.version_string, .style = .{
            .bg = vaxis.Color{ .index = 12 },
            .fg = vaxis.Color{ .index = 0 },
        } }) catch unreachable;

        if (self.teams_loaded) {
            const lines_num = try self.getMaxLines();
            if (self.page_size == null) {
                self.page_size = lines_num;
            } else {
                self.page_size = @max(lines_num, self.page_size.?);
            }
            self.pages = (self.items.len + self.page_size.? - 1) / self.page_size.?;
            const start = (self.current_page - 1) * self.page_size.?;

            const end = @min(start + self.page_size.?, self.items.len);
            for (start..end) |i| {
                const opt = self.items.ptr[i];
                var name = opt.team.name;
                // Truncate to the max width
                if (self.max_width != null and name.len > self.max_width.?) {
                    name = std.fmt.allocPrint(aalloc, "{s}...", .{name[0..self.max_width.?]}) catch unreachable;
                }
                const text = if (opt.selected) std.fmt.allocPrint(aalloc, "[x] {s}", .{name}) catch unreachable else std.fmt.allocPrint(aalloc, "[ ] {s}", .{name}) catch unreachable;
                const seg = vaxis.Segment{
                    .text = text,
                    .style = if (i == self.selected_option) .{ .reverse = true } else .{},
                };
                try lines.append(seg);
            }

            const direction_text = "Use j/k to scroll, h/l to switch pages, space to select";
            lines.append(.{ .text = "" }) catch unreachable;
            lines.append(.{ .text = direction_text }) catch unreachable;
            if (self.pages > 1) {
                const page_text = std.fmt.allocPrint(aalloc, "Page {d}/{d}", .{ self.current_page, self.pages }) catch unreachable;
                lines.append(.{ .text = page_text }) catch unreachable;
            }
        }

        for (lines.items, 0..) |line, idx| {
            _ = try win.printSegment(line, .{ .row_offset = idx + offset_rows, .col_offset = offset_cols });
        }

        try self.vx.render(self.tty.anyWriter());
    }

    pub fn resize(self: *State) usize {
        if (self.max_width == null) {
            if (self.vx.screen.width != 0) {
                if (self.vx.screen.width < 10) {
                    self.max_width = self.vx.screen.width;
                } else {
                    self.max_width = self.vx.screen.width - 10;
                }
            }
        } else if (self.max_width != null) {
            var value = self.vx.screen.width;
            if (self.vx.screen.width < 10) {
                value = self.vx.screen.width;
            } else {
                value = self.vx.screen.width - 10;
            }
            self.max_width = @min(value, self.max_width.?);
        }
        const lines_num = try self.getMaxLines();

        if (self.page_size == null) {
            self.page_size = lines_num;
        } else {
            self.page_size = @min(lines_num, self.page_size.?);
        }
        self.pages = (self.items.len + self.page_size.? - 1) / self.page_size.?;
        return lines_num;
    }

    fn getMaxLines(self: *State) !usize {
        var max_lines: usize = 10;
        const ts = self.vx.screen.height;
        if (ts == 0) {
            return max_lines;
        } else if (ts == std.math.maxInt(usize)) {
            return max_lines;
        }
        if (ts < max_lines) {
            return max_lines;
        } else {
            max_lines = ts - extra_row_offset;
        }

        return max_lines;
    }
};

pub fn newState(
    teams: *[]Item,
    allocator: std.mem.Allocator,
    vx: *vaxis.Vaxis,
    input: *vaxis.widgets.TextInput,
    tty: *vaxis.Tty,
) State {
    return State{
        .items = teams,
        .pages = 0,
        .page_size = null,
        .current_page = 1,
        .view = .list,
        .info_scroll_offset = 0,
        .max_lines = 0,
        .total_lines = 0,
        .allocator = allocator,
        .vx = vx,
        .input = input,
        .version_string = undefined,
        .tty = tty,
        .selected_option = vx.screen.width,
        .max_width = null,
        .total_info_lines = 0,
    };
}
