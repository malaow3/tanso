const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "tanso",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const ws_module = b.dependency("websocket", .{ .target = target, .optimize = optimize }).module("websocket");
    exe.root_module.addImport("websocket", ws_module);
    const vaxis = b.dependency("vaxis", .{ .target = target, .optimize = optimize }).module("vaxis");
    exe.root_module.addImport("vaxis", vaxis);
    const yazap = b.dependency("yazap", .{}).module("yazap");
    exe.root_module.addImport("yazap", yazap);

    // exe.addIncludePath(b.path("lcdb/include"));
    // exe.addIncludePath(b.path("lcdb/src"));
    // exe.addIncludePath(b.path("lcdb/src/util"));
    // exe.addIncludePath(b.path("lcdb/src/table"));
    // addCFilesRecursively(b, exe, "lcdb/src") catch |err| {
    //     std.log.err("Failed to add C files recursively: {s}", .{@errorName(err)});
    //     return;
    // };
    // exe.linkLibC();

    b.installArtifact(exe);

    const exe_check = b.addExecutable(.{
        .name = "tanso",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_check.root_module.addImport("websocket", ws_module);
    exe_check.root_module.addImport("vaxis", vaxis);
    exe_check.root_module.addImport("yazap", yazap);
    const check = b.step("check", "Check if foo compiles");
    check.dependOn(&exe_check.step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

// This was used when I was trying out adding the lcdb C files to the build.
// Since I'm not using lcdb anymore, I commented it out.
// It's still here in case I want to add it back in the future.
//
//
// fn addCFilesRecursively(b: *std.Build, exe: *std.Build.Step.Compile, dir_path: []const u8) !void {
//     var dir = std.fs.cwd().openDir(dir_path, .{ .iterate = true }) catch |err| {
//         std.log.err("Failed to open directory '{s}': {s}", .{ dir_path, @errorName(err) });
//         return err;
//     };
//     defer dir.close();
//
//     var walker = dir.walk(b.allocator) catch |err| {
//         std.log.err("Failed to create directory walker for '{s}': {s}", .{ dir_path, @errorName(err) });
//         return err;
//     };
//     defer walker.deinit();
//
//     while (walker.next() catch |err| {
//         std.log.err("Error while walking directory '{s}': {s}", .{ dir_path, @errorName(err) });
//         return;
//     }) |entry| {
//         if (entry.kind == .file) {
//             const ext = std.fs.path.extension(entry.basename);
//             // If the file name is "dbutil.c", skip it
//             if (std.mem.eql(u8, ext, ".c") and std.mem.eql(u8, entry.basename, "dbutil.c")) {
//                 continue;
//             }
//             if (std.mem.eql(u8, ext, ".c")) {
//                 const full_path = std.fs.path.join(b.allocator, &[_][]const u8{ dir_path, entry.path }) catch |err| {
//                     std.log.err("Failed to join path for '{s}': {s}", .{ entry.path, @errorName(err) });
//                     continue;
//                 };
//                 exe.addCSourceFile(.{
//                     .file = b.path(full_path),
//                     .flags = &[_][]const u8{
//                         "-std=c99",
//                         "-D_GNU_SOURCE",
//                     },
//                 });
//                 // std.log.info("Added C file: {s}", .{full_path});
//             }
//         }
//     }
// }
