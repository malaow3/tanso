const std = @import("std");
const json = std.json;

pub const Team = struct {
    name: []const u8,
    format: ?[]const u8,
    mons: ?[]Pokemon,
    text: ?[]const u8,

    pub fn init() Team {
        return Team{
            .name = "",
            .format = null,
            .mons = null,
            .text = null,
        };
    }
};

const Pokemon = struct {
    name: ?[]const u8,
    species: []const u8,
    gender: ?[]const u8,
    shiny: ?bool,
    level: ?u8,
    teraType: ?[]const u8,
    ability: ?[]const u8,
    item: ?[]const u8,
    evs: ?Stats,
    ivs: ?Stats,
    nature: ?[]const u8,
    moves: ?[][]const u8,
};

const Stats = struct {
    hp: u8,
    atk: u8,
    def: u8,
    spa: u8,
    spd: u8,
    spe: u8,
};

pub fn parseTeams(value: std.ArrayList(json.Value)) ![]Team {
    var teams = try std.heap.page_allocator.alloc(Team, value.items.len);
    for (value.items, 0..) |item, i| {
        teams[i] = try parseTeam(item);
    }
    return teams;
}

fn parseTeam(value: json.Value) !Team {
    const obj = value.object;

    const name = if (obj.get("name")) |name_val| name_val.string else "";
    const format = if (obj.get("format")) |format_val| format_val.string else "";
    const mons = if (obj.get("mons")) |mons_val| try parseMons(mons_val) else null;
    const text = if (obj.get("text")) |text_val| text_val.string else null;

    return Team{ .name = name, .format = format, .mons = mons, .text = text };
}

fn parseMons(value: json.Value) ![]Pokemon {
    const array = value.array;
    var mons = try std.heap.page_allocator.alloc(Pokemon, array.items.len);
    for (array.items, 0..) |item, i| {
        mons[i] = try parsePokemon(item);
    }
    return mons;
}

fn parsePokemon(value: json.Value) !Pokemon {
    const obj = value.object;
    return Pokemon{
        .name = if (obj.get("name")) |name| name.string else "",
        .species = obj.get("species").?.string,
        .gender = if (obj.get("gender")) |gender| gender.string else null,
        .shiny = if (obj.get("shiny")) |shiny| shiny.bool else null,
        .level = if (obj.get("level")) |level| @intCast(level.integer) else null,
        .teraType = if (obj.get("teraType")) |teraType| teraType.string else null,
        .ability = if (obj.get("ability")) |ability| ability.string else null,
        .item = if (obj.get("item")) |item| item.string else null,
        .evs = if (obj.get("evs")) |evs| try parseStats(evs) else null,
        .ivs = if (obj.get("ivs")) |ivs| try parseStats(ivs) else null,
        .nature = if (obj.get("nature")) |nature| nature.string else null,
        .moves = if (obj.get("moves")) |moves| try parseMoves(moves) else null,
    };
}

fn parseStats(value: json.Value) !Stats {
    const obj = value.object;
    return Stats{
        .hp = @intCast(obj.get("hp").?.integer),
        .atk = @intCast(obj.get("atk").?.integer),
        .def = @intCast(obj.get("def").?.integer),
        .spa = @intCast(obj.get("spa").?.integer),
        .spd = @intCast(obj.get("spd").?.integer),
        .spe = @intCast(obj.get("spe").?.integer),
    };
}

fn parseMoves(value: json.Value) ![][]const u8 {
    const array = value.array;
    var moves = try std.heap.page_allocator.alloc([]const u8, array.items.len);
    for (array.items, 0..) |item, i| {
        moves[i] = item.string;
    }
    return moves;
}
