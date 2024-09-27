const std = @import("std");
const thread = std.Thread;
const config = @import("config.zig");
const state = @import("state.zig");
const data = @import("data.zig");

const websocket = @import("websocket");
const Conn = websocket.Conn;
const Message = websocket.Message;
const Handshake = websocket.Handshake;

fn spawn(browser_path: []const u8) void {
    const allocator = std.heap.page_allocator;

    _ = std.process.Child.run(.{ .allocator = allocator, .argv = &[_][]const u8{ browser_path, "https://play.pokemonshowdown.com" } }) catch {
        std.debug.print("Failed to run child process", .{});
    };
}

fn startupWebsocketServer(allocator: std.mem.Allocator, context: *Context) !void {
    try websocket.listen(Handler, allocator, context, .{
        .port = 11025,
        .max_headers = 10,
        .address = "127.0.0.1",
    });
}

const Mode = enum {
    fetch,
    load,
    load_overwrite,
};

fn wsinit(
    browser_path: []const u8,
    teams: ?[]state.Item,
    mode: Mode,
) !Context {
    const allocator = std.heap.page_allocator;
    var context = Context{
        .allocator = allocator, //
        .mut = thread.Mutex{}, //
        .fetched = false, //
        .loaded = false, //
        .connected = false, //
        .teams = teams, //
        .should_close = false, //
        .packed_teams = "", //
        .should_fetch = mode == .fetch, //
        .overwrite = mode == .load_overwrite,
    };

    const t = try thread.spawn(.{}, startupWebsocketServer, .{ allocator, &context });

    t.detach();
    var msg_printed = false;
    std.time.sleep(3 * std.time.ns_per_s);
    while (!context.connected) {
        if (!msg_printed) {
            std.debug.print("Websocket server not connected\n", .{});
            if (!std.mem.containsAtLeast(u8, browser_path, 1, "chrome") and !std.mem.containsAtLeast(u8, browser_path, 1, "firefox")) {
                std.debug.print("Please launch your browser and navigate to https://play.pokemonshowdown.com", .{});
            } else {
                const t2 = try thread.spawn(.{}, spawn, .{
                    browser_path,
                });
                t2.detach();
                context.mut.lock();
                context.should_close = true;
                context.mut.unlock();
            }
        }
        msg_printed = true;
        // Sleep for 200ns
        std.time.sleep(200);
    }

    return context;
}

pub fn loadTeams(browser_path: []const u8, teams: []state.Item, overwrite: bool) !void {
    const mode = if (overwrite) Mode.load_overwrite else Mode.load;
    var ctx = try wsinit(browser_path, teams, mode);
    var loaded = false;
    while (!loaded) {
        std.time.sleep(250);
        ctx.mut.lock();
        loaded = ctx.loaded;
        ctx.mut.unlock();
    }
}

pub fn saveTeams(browser_path: []const u8) ![]const u8 {
    var ctx = try wsinit(browser_path, null, .fetch);
    var fetched = false;
    while (!fetched) {
        std.time.sleep(250);
        ctx.mut.lock();
        fetched = ctx.fetched;
        ctx.mut.unlock();
    }

    ctx.mut.lock();
    return ctx.packed_teams;
}

const Context = struct {
    allocator: std.mem.Allocator,
    mut: thread.Mutex,
    fetched: bool,
    loaded: bool,
    connected: bool,
    teams: ?[]state.Item,
    packed_teams: []const u8,
    should_close: bool,
    should_fetch: bool,
    overwrite: bool,
};

const Handler = struct {
    conn: *Conn,
    context: *Context,

    pub fn init(h: Handshake, conn: *Conn, context: *Context) !Handler {
        // `h` contains the initial websocket "handshake" request
        // It can be used to apply application-specific logic to verify / allow
        // the connection (e.g. valid url, query string parameters, or headers)

        _ = h; // we're not using this in our simple case

        std.debug.print("Connected to websocket\n", .{});

        return Handler{
            .conn = conn,
            .context = context,
        };
    }

    // optional hook that, if present, will be called after initialization is complete
    pub fn afterInit(_: *Handler) !void {}

    pub fn handle(self: *Handler, message: Message) !void {
        var arena = std.heap.ArenaAllocator.init(self.context.allocator);
        defer arena.deinit();

        // Set the connected flag to true
        self.context.connected = true;

        const msgdata = message.data;

        // Parse the JSON message
        const ReceiveMessage = struct {
            action: []const u8,
            data: []const u8,
        };

        const parsed = std.json.parseFromSlice(ReceiveMessage, self.context.allocator, msgdata, .{}) catch std.json.Parsed(ReceiveMessage){
            .value = ReceiveMessage{ .action = "", .data = "" },
            .arena = &arena,
        };

        // Get the action key
        const action = parsed.value.action;
        const RespMessage = struct { action: []const u8, data: ?[]data.Team };

        // If the action is "fetch_teams", set the fetched flag to true.
        if (std.mem.eql(u8, action, "fetch_teams")) {
            self.context.mut.lock();
            self.context.fetched = true;
            self.context.packed_teams = parsed.value.data;
            self.context.mut.unlock();
            if (self.context.should_close) {
                // Send close window message
                const msg = RespMessage{ .action = "close_window", .data = null };
                const size = @bitSizeOf(RespMessage);

                // Stringify the JSON object
                var buf: [size]u8 = undefined;
                var fba = std.heap.FixedBufferAllocator.init(&buf);
                var string = std.ArrayList(u8).init(fba.allocator());
                try std.json.stringify(msg, .{}, string.writer());
                try self.conn.write(string.items);
            }
        }

        self.context.mut.lock();
        if (!self.context.fetched and self.context.should_fetch) {
            // const msg = RespMessage{ .action = "close_window" };
            const rmsg = RespMessage{ .action = "fetch_teams", .data = null };
            const size = @bitSizeOf(RespMessage);

            // Stringify the JSON object
            var buf: [size]u8 = undefined;
            var fba = std.heap.FixedBufferAllocator.init(&buf);
            var string = std.ArrayList(u8).init(fba.allocator());
            try std.json.stringify(rmsg, .{}, string.writer());
            try self.conn.write(string.items);
        }
        self.context.mut.unlock();

        if (std.mem.eql(u8, action, "load_teams")) {
            self.context.mut.lock();
            self.context.loaded = true;
            self.context.mut.unlock();

            if (self.context.should_close) {
                // Send close window message
                const msg = RespMessage{ .action = "close_window", .data = null };
                const size = @bitSizeOf(RespMessage);

                // Stringify the JSON object
                var buf: [size]u8 = undefined;
                var fba = std.heap.FixedBufferAllocator.init(&buf);
                var string = std.ArrayList(u8).init(fba.allocator());
                try std.json.stringify(msg, .{}, string.writer());
                try self.conn.write(string.items);
            }
        }

        self.context.mut.lock();
        if (!self.context.loaded and !self.context.should_fetch) {
            if (self.context.teams) |items| {
                std.debug.print("Sending {d} teams to load...\n", .{items.len});
                var teams = std.ArrayList(data.Team).init(arena.allocator());
                for (0..items.len) |i| {
                    const item = items[i].team;
                    teams.append(item) catch {
                        std.debug.print("Failed to append team {d} to the list\n", .{i});
                        continue;
                    };
                }

                const teams_slice = teams.items;

                const send_action = if (self.context.overwrite) "load_teams_overwrite" else "load_teams";
                const rmsg = RespMessage{
                    .action = send_action,
                    .data = teams_slice,
                };

                // Stringify the JSON object
                var string = std.ArrayList(u8).init(std.heap.page_allocator);
                try std.json.stringify(rmsg, .{}, string.writer());
                try self.conn.write(string.items);
            }
        }
        self.context.mut.unlock();
    }

    // called whenever the connection is closed, can do some cleanup in here
    pub fn close(_: *Handler) void {}
};
