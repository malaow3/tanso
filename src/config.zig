const std = @import("std");
const builtin = @import("builtin");
const fs = std.fs;
const meta = std.meta;
const Allocator = std.mem.Allocator;
const utils = @import("utils.zig");

pub const Config = struct {
    browser_path: []const u8,
    db_path: []const u8,

    pub fn init() !Config {
        const home_dir = try get_home_dir();
        const default_db = std.fmt.allocPrint(std.heap.page_allocator, "{s}{s}", .{ home_dir, ".tanso.db" }) catch unreachable;

        var default_browser_path: []const u8 = undefined;
        if (comptime builtin.os.tag == .windows) {
            default_browser_path = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
        }
        if (comptime builtin.os.tag == .linux) {
            if (utils.isWSL()) {
                default_browser_path = "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe";
            } else {
                // I don't use Linux, this is just what I saw online.
                default_browser_path = "/usr/bin/google-chrome-stable";
            }
        } else if (comptime builtin.os.tag == .macos) {
            default_browser_path = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
        }

        return .{
            .browser_path = default_browser_path,
            .db_path = default_db,
        };
    }

    pub fn saveConfig(self: Config) !void {
        const config_path = try getConfigPath();

        const file = try fs.cwd().createFile(config_path, .{});
        defer file.close();

        const SerializableConfig = struct {
            browser_path: []const u8,
            db_path: []const u8,
        };

        const serializable = SerializableConfig{
            .browser_path = self.browser_path,
            .db_path = self.db_path,
        };

        try std.json.stringify(serializable, .{}, file.writer());
    }
};

pub fn setConfigValue(cfg: *Config, key: []const u8, value: []const u8) !void {
    if (std.mem.eql(u8, key, "browser_path")) {
        const duped_value = try std.heap.page_allocator.dupe(u8, value);
        if (cfg.browser_path.len > 0) {
            std.heap.page_allocator.free(cfg.browser_path);
        }
        cfg.browser_path = duped_value;
    } else if (std.mem.eql(u8, key, "db_path")) {
        const duped_value = try std.heap.page_allocator.dupe(u8, value);
        if (cfg.db_path.len > 0) {
            std.heap.page_allocator.free(cfg.db_path);
        }
        cfg.db_path = duped_value;
    } else {
        return error.FieldNotFound;
    }

    try cfg.saveConfig();
}

pub fn loadConfig() !Config {
    const config_path = try getConfigPath();

    const file = fs.cwd().openFile(config_path, .{}) catch |err| {
        if (err == error.FileNotFound) {
            var config = try Config.init();
            try config.saveConfig();
            return config;
        }
        return err;
    };
    defer file.close();

    const file_size = try file.getEndPos();
    const file_contents = try file.readToEndAlloc(std.heap.page_allocator, file_size);

    const SerializableConfig = struct {
        browser_path: []const u8,
        db_path: []const u8,
    };

    var parsed = try std.json.parseFromSlice(SerializableConfig, std.heap.page_allocator, file_contents, .{});
    defer parsed.deinit();

    return Config{
        .browser_path = try std.heap.page_allocator.dupe(u8, parsed.value.browser_path),
        .db_path = try std.heap.page_allocator.dupe(u8, parsed.value.db_path),
    };
}

pub fn getConfigPath() ![]const u8 {
    const home_dir = try get_home_dir();
    return try fs.path.join(std.heap.page_allocator, &[_][]const u8{ home_dir, ".tanso.json" });
}

fn get_home_dir() ![]const u8 {
    var env_map = try std.process.getEnvMap(std.heap.page_allocator);
    defer env_map.deinit();
    var home_dir: []const u8 = undefined;
    if (builtin.os.tag == .windows) {
        home_dir = env_map.get("USERPROFILE") orelse return error.HomeNotFound;
    } else if (builtin.os.tag == .linux) {
        home_dir = env_map.get("HOME") orelse return error.HomeNotFound;
    } else if (builtin.os.tag == .macos) {
        home_dir = env_map.get("HOME") orelse return error.HomeNotFound;
    } else {
        return error.UnsupportedOperatingSystem;
    }
    home_dir = try std.mem.concat(std.heap.page_allocator, u8, &[_][]const u8{ home_dir, "/" });
    return home_dir;
}
