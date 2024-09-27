/// This file isn't used, maybe I'll use it again if i try directly modifying chrome cookies
const std = @import("std");
const log = std.log.scoped(.main);
const c = @cImport({
    @cInclude("lcdb.h");
    @cInclude("lcdb_c.h");
});
const builtin = @import("builtin");

var separator: u8 = '/';

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Check if Chrome is running
    if (try isProcessRunning("chrome")) {
        log.err("Chrome is currently running. Please close Chrome and try again.", .{});
        return error.ChromeRunning;
    }

    // Open the db
    var base_db_path: []const u8 = undefined;
    switch (builtin.os.tag) {
        .windows => {
            base_db_path = "C:\\Users\\myuser\\AppData\\Local\\Google\\Chrome\\User Data\\Default\\Local Storage\\leveldb";
            separator = '\\';
        },
        .linux => {
            // Check if we are on WSL by reading /proc/version
            const proc_version = try std.fs.cwd().readFileAlloc(allocator, "/proc/version", std.math.maxInt(usize));
            defer allocator.free(proc_version);
            if (std.mem.indexOf(u8, proc_version, "microsoft") != null) {
                base_db_path = "/mnt/c/Users/myuser/AppData/Local/Google/Chrome/User Data/Default/Local Storage/leveldb";
            } else {
                base_db_path = "/home/myuser/AppData/Local/Google/Chrome/User Data/Default/Local Storage/leveldb";
            }
        },
        else => {
            log.err("Unsupported operating system", .{});
            return error.UnsupportedOperatingSystem;
        },
    }
    log.info("Database path: {s}", .{base_db_path});

    // Backup the database
    const db_path_ = try backupDatabase(allocator, base_db_path);
    defer allocator.free(db_path_);
    log.info("Database backed up to: {s}", .{db_path_});

    const opts = c.leveldb_options_create();
    defer c.leveldb_options_destroy(opts);
    var errptr: ?[*:0]u8 = null;

    const db_path = try std.fmt.allocPrint(allocator, "{s}\x00", .{db_path_});

    // Repair the database if it exists
    c.leveldb_repair_db(opts, db_path.ptr, &errptr);
    if (errptr != null) {
        log.err("Failed to repair database. Error: {s}", .{errptr.?});
        c.leveldb_free(errptr);
        return error.DatabaseRepairFailed;
    }
    std.debug.print("Database repair completed successfully\n", .{});

    const dbptr = c.leveldb_open(opts, db_path.ptr, &errptr);
    if (errptr != null) {
        log.err("Failed to open database. Error: {s}", .{errptr.?});
        c.leveldb_free(errptr);
        return error.DatabaseOpenFailed;
    }
    defer c.leveldb_close(dbptr);
    std.debug.print("Database opened successfully\n", .{});

    std.debug.assert(dbptr != null);
    const db = dbptr.?;

    // Read and print all keys and values
    log.info("Current database contents:", .{});
    try printAllKeysAndValues(db);
    return;

    // Find the correct key for Pokemon Showdown teams
    // const key = try findPokemonShowdownKey(db.?, allocator);
    // if (key == null) {
    //     log.err("Could not find Pokemon Showdown key", .{});
    //     return error.KeyNotFound;
    // }
    // defer allocator.free(key.?);
    //
    // // Read the current value
    // const roptions = c.leveldb_readoptions_create();
    // defer c.leveldb_readoptions_destroy(roptions);
    // var value_len: usize = undefined;
    // const value = c.leveldb_get(db, roptions, key.?.ptr, key.?.len, &value_len, &dberr);
    // defer if (value != null) c.leveldb_free(value);
    //
    // if (dberr != null) {
    //     log.err("Error getting value for key: {s}", .{dberr.?});
    //     c.leveldb_free(dberr);
    //     return error.FailedToGetValue;
    // }
    //
    // if (value != null) {
    //     log.info("Current value: {s}", .{value[0..value_len]});
    // } else {
    //     log.info("No value found for key", .{});
    //     return error.NoValueFound;
    // }
    //
    // // Modify the value
    // var new_value = std.ArrayList(u8).init(allocator);
    // defer new_value.deinit();
    // try new_value.appendSlice(value[0..value_len]);
    // const new_str = try std.fmt.allocPrint(allocator, "\ngen9]Untitled 1|Gholdengo||leftovers|goodasgold||||||||", .{});
    // var utf16_buf = try allocator.alloc(u16, new_str.len * 2); // Allocate buffer for UTF-16
    // defer allocator.free(utf16_buf);
    // const utf16_len = try std.unicode.utf8ToUtf16Le(utf16_buf, new_str);
    // try new_value.appendSlice(std.mem.sliceAsBytes(utf16_buf[0..utf16_len]));
    //
    // // Print the new value
    // log.info("New value: {s}", .{new_value.items});
    //
    // // Write the new value
    // const woptions = c.leveldb_writeoptions_create();
    // defer c.leveldb_writeoptions_destroy(woptions);
    // c.leveldb_put(db, woptions, key.?.ptr, key.?.len, new_value.items.ptr, new_value.items.len, &dberr);
    // if (dberr != null) {
    //     log.err("Error setting value for key: {s}", .{dberr.?});
    //     c.leveldb_free(dberr);
    //     return error.FailedToSetValue;
    // }
    //
    // // Verify the write operation
    // const verify_value = c.leveldb_get(db, roptions, key.?.ptr, key.?.len, &value_len, &dberr);
    // defer if (verify_value != null) c.leveldb_free(verify_value);
    //
    // if (dberr != null) {
    //     log.err("Error verifying value for key: {s}", .{dberr.?});
    //     c.leveldb_free(dberr);
    //     return error.FailedToVerifyValue;
    // }
    //
    // if (verify_value != null and value_len == new_value.items.len and std.mem.eql(u8, verify_value[0..value_len], new_value.items)) {
    //     log.info("Value successfully updated and verified.", .{});
    //     log.info("New value: {s}", .{verify_value[0..value_len]});
    // } else {
    //     log.err("Failed to verify the updated value.", .{});
    //     return error.VerificationFailed;
    // }
    //
    // // Print all keys and values again to verify changes
    // // log.info("Updated database contents:", .{});
    // // try printAllKeysAndValues(db.?);
    //
    // // Copy the database one more time.
    // _ = try backupDatabase(allocator, base_db_path);
    // // Move the db_path to the base path.
    // try copyDirectory(allocator, db_path, base_db_path);
}

fn findPokemonShowdownKey(db: *c.leveldb_t, allocator: std.mem.Allocator) !?[]const u8 {
    const roptions = c.leveldb_readoptions_create();
    defer c.leveldb_readoptions_destroy(roptions);
    const iter = c.leveldb_create_iterator(db, roptions);
    defer c.leveldb_iter_destroy(iter);

    c.leveldb_iter_seek_to_first(iter);
    while (c.leveldb_iter_valid(iter) != 0) {
        var key_len: usize = undefined;
        const key_ptr = c.leveldb_iter_key(iter, &key_len);
        const key = key_ptr[0..key_len];

        if (std.mem.indexOf(u8, key, "_https://play.pokemonshowdown.com") != null and
            std.mem.indexOf(u8, key, "showdown_teams") != null)
        {
            return try allocator.dupe(u8, key);
        }

        c.leveldb_iter_next(iter);
    }

    return null;
}

fn printAllKeysAndValues(db: *c.ldb_t) !void {
    const roptions = c.leveldb_readoptions_create();
    defer c.leveldb_readoptions_destroy(roptions);
    const iter = c.leveldb_create_iterator(db, roptions);
    if (iter == null) {
        log.err("Failed to create iterator", .{});
        return error.FailedToCreateIterator;
    }
    defer c.ldb_iter_destroy(iter);

    c.leveldb_iter_seek_to_first(iter);
    while (c.leveldb_iter_valid(iter) != 0) {
        var key_len: usize = undefined;
        const key = c.leveldb_iter_key(iter, &key_len);
        const key_str = key[0..key_len];

        var value_len: usize = undefined;
        const value = c.leveldb_iter_value(iter, &value_len);
        const value_str = value[0..value_len];

        log.info("Key: {any}", .{key_str});
        log.info("Value: {any}", .{value_str});
        log.info("---", .{});

        c.leveldb_iter_next(iter);
    }
}

fn isProcessRunning(process_name: []const u8) !bool {
    const powershell_cmd = try std.fmt.allocPrint(std.heap.page_allocator, "Get-Process -Name {s} -ErrorAction SilentlyContinue", .{process_name});
    defer std.heap.page_allocator.free(powershell_cmd);

    const result = try std.process.Child.run(.{
        .allocator = std.heap.page_allocator,
        .argv = &[_][]const u8{ "powershell.exe", "-Command", powershell_cmd },
    });
    defer std.heap.page_allocator.free(result.stdout);
    defer std.heap.page_allocator.free(result.stderr);

    // If the process is running, PowerShell will return information about it.
    // If not, it will return an empty string.
    return result.stdout.len > 0;
}

/// Backup the database to a new location with a timestamp appended
/// to the end of the filename.
///
/// Args:
///     allocator: The allocator to use for memory allocation.
///     db_path: The path to the database file.
/// Returns:
///     []const u8: The path to the backup file.
///     error: If an error occurs during the backup process.
fn backupDatabase(allocator: std.mem.Allocator, db_path: []const u8) ![]const u8 {
    // const timestamp = std.time.timestamp();
    const cwd = try std.fs.cwd().realpathAlloc(allocator, ".");
    // Make the tmp dir
    std.fs.makeDirAbsolute(try std.fmt.allocPrint(allocator, "{s}{c}tmp", .{ cwd, separator })) catch |err| {
        // If the tmp dir already exists, do nothing.
        switch (err) {
            error.PathAlreadyExists => {
                // Delete the existing tmp dir
                try std.fs.deleteTreeAbsolute(try std.fmt.allocPrint(allocator, "{s}{c}tmp", .{ cwd, separator }));
                // Recreate the tmp dir
                try std.fs.makeDirAbsolute(try std.fmt.allocPrint(allocator, "{s}{c}tmp", .{ cwd, separator }));
            },
            else => |e| return e,
        }
    };
    // Copy the contents of db_path to backup_path
    const backup_path = try std.fmt.allocPrint(allocator, "{s}{c}tmp", .{ cwd, separator });

    try copyDirectory(allocator, db_path, backup_path);
    return backup_path;
}

pub fn copyDirectory(allocator: std.mem.Allocator, src_path: []const u8, dest_path: []const u8) !void {
    var src_dir = try std.fs.openDirAbsolute(src_path, .{ .iterate = true });
    defer src_dir.close();

    try std.fs.cwd().makePath(dest_path);
    var dest_dir = try std.fs.cwd().openDir(dest_path, .{});
    defer dest_dir.close();

    var it = src_dir.iterate();
    while (try it.next()) |entry| {
        const src_full_path = try std.fs.path.join(allocator, &[_][]const u8{ src_path, entry.name });
        defer allocator.free(src_full_path);
        const dest_full_path = try std.fs.path.join(allocator, &[_][]const u8{ dest_path, entry.name });
        defer allocator.free(dest_full_path);

        switch (entry.kind) {
            .file => {
                // First try to just copy the file
                std.fs.copyFileAbsolute(src_full_path, dest_full_path, .{}) catch |err| {
                    log.err("Failed to copy file: {s}. Error: {s}", .{ src_full_path, @errorName(err) });
                    switch (err) {
                        error.PathAlreadyExists => {
                            // If the file already exists, delete it and try again
                            try std.fs.deleteFileAbsolute(dest_full_path);
                            std.fs.copyFileAbsolute(src_full_path, dest_full_path, .{}) catch |err2| {
                                log.err("Failed to copy file: {s}. Error: {s}", .{ src_full_path, @errorName(err2) });
                                return err2;
                            };
                        },
                        else => |e| return e,
                    }
                };

                // const src_file = try src_dir.openFile(entry.name, .{});
                // defer src_file.close();
                //
                // const dest_flags: std.fs.File.CreateFlags = .{
                //     .read = true,
                //     .truncate = true,
                //     .exclusive = false,
                // };
                //
                // const dest_file = try dest_dir.createFile(entry.name, dest_flags);
                // defer dest_file.close();
                //
                // dest_file.seekTo(0) catch |err| {
                //     log.err("Failed to seek to beginning of file: {s}. Error: {s}", .{ src_full_path, @errorName(err) });
                //     continue; // Skip this file and continue with the next one
                // };
                // const file_metadata = try src_file.stat();
                // const file_data = try src_file.readToEndAlloc(allocator, file_metadata.size);
                // try dest_file.writeAll(file_data);
            },
            .directory => {
                try copyDirectory(allocator, src_full_path, dest_full_path);
            },
            else => {
                std.debug.print("Unsupported file type for: {s}. Skipping.\n", .{src_full_path});
            },
        }
    }
}
