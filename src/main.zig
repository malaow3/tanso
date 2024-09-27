const utils = @import("utils.zig");
const config = @import("config.zig");
const data = @import("data.zig");
const state = @import("state.zig");
const events = @import("events.zig");
const websock = @import("ws.zig");
const yazap = @import("yazap");
const App = yazap.App;
const Arg = yazap.Arg;

const std = @import("std");
const builtin = @import("builtin");
const meta = std.meta;
const vaxis = @import("vaxis");
const TextInput = vaxis.widgets.TextInput;

const log = std.log.scoped(.main);

const major_version = 0;
const minor_version = 1;
const patch_version = 0;
var version_string: [25]u8 = undefined;

var teams: []state.Item = undefined;

fn loadTeams(loop: *vaxis.Loop(events.Event), db_path: []const u8) !void {
    const teams_data = try utils.runBun(db_path);
    teams = try std.heap.page_allocator.alloc(state.Item, teams_data.len);
    for (teams_data, 0..) |team, i| {
        teams[i] = .{
            .selected = false,
            .team = team,
            .index = i,
        };
    }
    loop.postEvent(.{ .teams_loaded = true });
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            log.err("memory leak", .{});
        }
    }

    const alloc = gpa.allocator();
    var app = App.init(std.heap.page_allocator, "tanso", "");
    defer app.deinit();

    var root = app.rootCommand();

    var configcmd = app.createCommand("config", "Read or set configuration values");
    var read = app.createCommand("read", "Read a single configuration value");
    const list = app.createCommand("list", "List all configuration values");
    try read.addArg(Arg.positional("KEY", "The value to read", null));
    var set = app.createCommand("set", "Set a configuration value");
    try set.addArg(Arg.positional("KEY", "The value to set", null));
    try set.addArg(Arg.positional("VALUE", "The value to set", null));
    try configcmd.addSubcommand(read);
    try configcmd.addSubcommand(list);
    try configcmd.addSubcommand(set);
    try root.addSubcommand(configcmd);

    var load = app.createCommand("load", "Load teams from the db into Pokemon Showdown");
    try load.addArg(Arg.booleanOption("overwrite", null, "Overwrite existing teams in Pokemon Showdown"));
    const save = app.createCommand("save", "Save teams from Pokemon Showdown into the db");
    try root.addSubcommand(load);
    try root.addSubcommand(save);

    var cfg = try config.loadConfig();

    const matches = try app.parseProcess();
    if (matches.subcommandMatches("config")) |config_matches| {
        if (config_matches.subcommandMatches("read")) |read_matches| {
            if (read_matches.getSingleValue("KEY")) |value| {
                // Check if the value matches a struct field.
                inline for (meta.fields(config.Config)) |field| {
                    if (std.mem.eql(u8, field.name, value)) {
                        std.debug.print("{s}: {s}\n", .{ field.name, @field(cfg, field.name) });
                    }
                }
                return;
            } else {
                std.debug.print("No value provided\n", .{});
                return;
            }
        } else if (config_matches.subcommandMatches("list")) |_| {
            inline for (meta.fields(config.Config)) |field| {
                std.debug.print("{s}: {s}\n", .{ field.name, @field(cfg, field.name) });
            }
            return;
        } else if (config_matches.subcommandMatches("set")) |set_matches| {
            if (set_matches.getSingleValue("KEY")) |key| {
                if (set_matches.getSingleValue("VALUE")) |value| {
                    try config.setConfigValue(&cfg, key, value);
                    try cfg.saveConfig();
                    return;
                } else {
                    std.debug.print("No value provided\n", .{});
                    return;
                }
            } else {
                std.debug.print("No key provided\n", .{});
                return;
            }
        }
    } else if (matches.subcommandMatches("load")) |load_matches| {
        const selected_teams = runTUI(alloc, cfg) catch |err| {
            switch (err) {
                error.UserCancelled => {
                    return;
                },
                else => {
                    std.debug.print("Error loading teams: {s}\n", .{@errorName(err)});
                    return;
                },
            }
        };
        if (selected_teams.len == 0) {
            std.debug.print("No teams selected\n", .{});
            return;
        }
        std.debug.print("Loading the following teams...\n", .{});
        for (selected_teams) |team| {
            std.debug.print("- {s}\n", .{team.team.name});
        }

        var overwrite = false;
        if (load_matches.containsArg("overwrite")) {
            std.debug.print("Overwriting existing teams in Pokemon Showdown...\n", .{});
            overwrite = true;
        }
        try websock.loadTeams(cfg.browser_path, selected_teams, overwrite);
    } else if (matches.subcommandMatches("save")) |_| {
        const fetched_teams = try websock.saveTeams(cfg.browser_path);
        // Save the fetched teams to a temp file.
        var temp_dir: []const u8 = undefined;
        if (builtin.os.tag == .windows) {
            temp_dir = try std.process.getEnvVarOwned(std.heap.page_allocator, "TEMP");
        } else if (builtin.os.tag == .linux) {
            temp_dir = "/tmp";
        } else if (builtin.os.tag == .macos) {
            temp_dir = try std.process.getEnvVarOwned(std.heap.page_allocator, "TMPDIR");
        } else {
            std.debug.print("Unsupported operating system\n", .{});
            return error.UnsupportedOperatingSystem;
        }
        const temp_file = try std.fmt.allocPrint(alloc, "{s}{c}tanso-teams.txt", .{ temp_dir, std.fs.path.sep });
        std.debug.print("Saving teams to {s}\n", .{temp_file});
        const temp_file_obj = try std.fs.cwd().createFile(temp_file, .{});
        defer alloc.free(temp_file);
        try temp_file_obj.writeAll(fetched_teams);
        defer std.fs.cwd().deleteFile(temp_file) catch {};
        temp_file_obj.close();

        const temp_cfg = config.Config{ .db_path = temp_file, .browser_path = "" };

        const selected_teams = runTUI(alloc, temp_cfg) catch |err| {
            switch (err) {
                error.UserCancelled => {
                    return;
                },
                else => {
                    std.debug.print("Error loading teams: {s}\n", .{@errorName(err)});
                    return;
                },
            }
        };

        var split_teams = std.mem.split(u8, fetched_teams, "\n");
        var split_teams_list = std.ArrayList([]const u8).init(std.heap.page_allocator);
        while (split_teams.next()) |line| {
            if (std.mem.eql(u8, line, "")) {
                continue;
            }
            try split_teams_list.append(line);
        }

        const db_file = try std.fs.cwd().openFile(cfg.db_path, .{ .mode = .read_write });
        defer db_file.close();

        const original_data = try db_file.readToEndAlloc(std.heap.page_allocator, std.math.maxInt(usize));
        defer std.heap.page_allocator.free(original_data);

        try db_file.seekTo(0);

        // Add the selected teams to the config.
        for (selected_teams) |team| {
            std.debug.print("Adding team {s} to config\n", .{team.team.name});
            // Get the line in the file that corresponds to the index of the team.
            var line = split_teams_list.items[team.index];
            // Split the line on the "["
            const server_id = std.mem.indexOf(u8, line, "[");
            if (server_id) |id| {
                // Split the line on the "["
                line = line[id + 1 ..];
            }
            // Add a newline at the end of line.
            const new_line = std.fmt.allocPrint(std.heap.page_allocator, "{s}\n", .{line}) catch unreachable;
            defer std.heap.page_allocator.free(new_line);

            // Add the line to the db
            try db_file.writeAll(new_line);
        }

        // Write the original data back to the file.
        try db_file.writeAll(original_data);
    }
}

fn runTUI(alloc: std.mem.Allocator, cfg: config.Config) ![]state.Item {
    try utils.init();
    _ = std.fmt.bufPrint(&version_string, "TANSO - v{}.{}.{} ", .{ major_version, minor_version, patch_version }) catch unreachable;

    var tty = try vaxis.Tty.init();
    defer tty.deinit();

    var vx = try vaxis.init(alloc, .{});
    defer vx.deinit(alloc, tty.anyWriter());

    var loop: vaxis.Loop(events.Event) = .{ .tty = &tty, .vaxis = &vx };
    try loop.init();

    try loop.start();
    defer loop.stop();

    _ = try std.Thread.spawn(.{}, loadTeams, .{
        &loop,
        cfg.db_path,
    });

    try vx.enterAltScreen(tty.anyWriter());
    try vx.queryTerminal(tty.anyWriter(), 25);

    var text_input = TextInput.init(alloc, &vx.unicode);
    defer text_input.deinit();

    var appstate = state.newState(&teams, alloc, &vx, &text_input, &tty);
    appstate.version_string = version_string;

    while (true) {
        const event = loop.nextEvent();
        switch (appstate.view) {
            .list => {
                const done = try events.handleListEvent(event, &appstate);
                switch (done) {
                    .done => {
                        break;
                    },
                    .cancel => {
                        return error.UserCancelled;
                    },
                    .keepgoing => {},
                }
            },
            .info => {
                switch (event) {
                    .key_press => |key| {
                        if (key.codepoint == 'c' and key.mods.ctrl) {
                            break;
                        } else if (key.matches('q', .{})) {
                            break;
                        } else if (key.matches('e', .{})) {
                            appstate.view = .list;
                            appstate.info_scroll_offset = 0;
                        } else if (key.matches('c', .{})) {
                            // Copy the selected team to the clipboard
                            try utils.writeToClipboard(appstate.items.ptr[appstate.selected_option].team.text.?);
                        } else if (key.matches('j', .{})) {
                            if (appstate.info_scroll_offset < appstate.total_info_lines) {
                                appstate.info_scroll_offset += 1;
                            }
                        } else if (key.matches('k', .{})) {
                            if (appstate.info_scroll_offset > 0) {
                                appstate.info_scroll_offset -= 1;
                            }
                        } else {}
                    },
                    .winsize => |ws| {
                        try vx.resize(alloc, tty.anyWriter(), ws);
                    },
                    .teams_loaded => |loaded| {
                        appstate.teams_loaded = loaded;
                    },
                }
            },
        }
        try appstate.redraw();
    }

    // Return the selected items.
    var return_teams = std.ArrayList(state.Item).init(std.heap.page_allocator);
    for (0..appstate.items.len) |i| {
        const item = appstate.items.ptr[i];
        if (item.selected) {
            try return_teams.append(item);
        }
    }
    return return_teams.toOwnedSlice();
}
