# Tanso

A simple Pokemon Showdown Team Manager written in Zig.

## Building

To build Tanso, you will need to have [Zig](https://ziglang.org/) installed.
Additionally, you will need pnpm installed.

You can build Tanso by running the following command in the project directory:

```bash
./bootstrap.sh
zig build --release-fast
```
This will build the project and create an executable file named `tanso`.

## Running

To run Tanso, you will need to have [Bun](https://bun.sh/) installed.

You will also need to install the Tanso userscript.
Install Tampermonkey for either [Chrome](https://chromewebstore.google.com/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo) or [Firefox](https://addons.mozilla.org/en-US/firefox/addon/tampermonkey/)
Once Tampermonkey is installed, navigate to this [link](https://github.com/malaow3/tanso/raw/refs/heads/main/userscript/build/tanso.user.js) to install the script

You can run Tanso by running the following command in the project directory:

```bash
./zig-out/bin/tanso <command>
```

The following commands are available:

- `--help`: Displays the help message.

- `config`: Displays the configuration options.
    - `read <value>`: Displays the teams.
    - `set <key> <value>`: Sets the value of the specified key.
    - `list`: Displays a list of all the config values.

- `load`: Loads the teams from the DB to be selected to be loaded into Pokemon Showdown.
By default, your teams in Showdown will not be overwritten. To overwrite your existing teams, use the `--overwrite` flag.
 
- `save`: Saves the teams from Pokemon Showdown to the DB.

## How it works

Tanso communicates with Pokemon Showdown using websockets and a userscript.
Initially, I wanted to read and write directly to and from the Google Chrome local storage
but there are some issues with that approach (Chrome can't be open, writing to the LevelDB format is cumbersome, etc.).
In the future, maybe I'll add support for that; I'll also have to see how Firefox handles local storage.

## Future features
Truthfully, I'm not sure if I'll continue working on this. I mostly did this as a way to learn Zig (of which I have some conflicting opinions).
If I find that I use this tool extensively, I'll probably add more features.

I would like to add the following features if my interest permits:
- [ ] Improve download/onboarding process
- [ ] Edit the database
- [ ] Directly read and write to the LevelDB format for Chrome
- [ ] Directly read and write to the Firefox local storage
