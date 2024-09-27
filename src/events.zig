const vaxis = @import("vaxis");
const State = @import("state.zig").State;

pub const Event = union(enum) {
    key_press: vaxis.Key,
    winsize: vaxis.Winsize,
    teams_loaded: bool,
};

const doneStatus = enum { done, cancel, keepgoing };

pub fn handleListEvent(event: Event, appstate: *State) !doneStatus {
    switch (event) {
        .key_press => |key| {
            if (key.codepoint == 'c' and key.mods.ctrl) {
                return doneStatus.cancel;
            } else if (key.matches('a', .{})) {
                // Select all
                // If all teams are already selected, deselect all.
                // Otherwise, select all teams.
                var all_selected = true;
                for (0..appstate.items.len) |i| {
                    const item = appstate.items.ptr[i];
                    if (!item.selected) {
                        all_selected = false;
                        break;
                    }
                }
                for (0..appstate.items.len) |i| {
                    if (all_selected) {
                        appstate.items.ptr[i].selected = false;
                    } else {
                        appstate.items.ptr[i].selected = true;
                    }
                }
            } else if (key.matches('j', .{})) {
                const start = (appstate.current_page - 1) * appstate.page_size.?;
                const end = @min(start + appstate.page_size.? - 1, appstate.items.len - 1);
                appstate.selected_option = @min(end, appstate.selected_option + 1);
            } else if (key.matches('J', .{})) {
                const start = (appstate.current_page - 1) * appstate.page_size.?;
                const end = @min(start + appstate.page_size.? - 1, appstate.items.len - 1);
                appstate.selected_option = @min(end, appstate.selected_option + 10);
            } else if (key.matches('k', .{})) {
                const start = (appstate.current_page - 1) * appstate.page_size.?;
                appstate.selected_option = @max(start, appstate.selected_option -| 1);
            } else if (key.matches('K', .{})) {
                const start = (appstate.current_page - 1) * appstate.page_size.?;
                appstate.selected_option = @max(start, appstate.selected_option -| 10);
            } else if (key.matches('h', .{})) {
                if (appstate.current_page > 1) {
                    appstate.current_page = appstate.current_page -| 1;
                    appstate.selected_option = (appstate.current_page - 1) * appstate.page_size.?;
                }
            } else if (key.matches('l', .{})) {
                if (appstate.current_page < appstate.pages) {
                    appstate.current_page += 1;
                    appstate.selected_option = (appstate.current_page - 1) * appstate.page_size.?;
                }
            } else if (key.matches(vaxis.Key.space, .{})) {
                const items = appstate.items;
                items.ptr[appstate.selected_option].selected = !items.ptr[appstate.selected_option].selected;
            } else if (key.matches('q', .{})) {
                return doneStatus.cancel;
            } else if (key.matches('e', .{})) {
                appstate.view = .info;
            } else if (key.matches('g', .{})) {
                appstate.selected_option = (appstate.current_page - 1) * appstate.page_size.?;
            } else if (key.matches('G', .{})) {
                const start = (appstate.current_page - 1) * appstate.page_size.?;
                const end = @min(start + appstate.page_size.? - 1, appstate.items.len - 1);
                appstate.selected_option = end;
            } else if (key.matches(vaxis.Key.enter, .{})) {
                return doneStatus.done;
            } else {}
        },
        .winsize => |ws| {
            _ = appstate.resize();
            try appstate.vx.resize(appstate.allocator, appstate.tty.anyWriter(), ws);
            appstate.redraw() catch {};
        },
        .teams_loaded => |loaded| {
            appstate.teams_loaded = loaded;
        },
    }
    return doneStatus.keepgoing;
}
