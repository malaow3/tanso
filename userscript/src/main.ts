import { type PokemonSet, Sets } from "@pkmn/sets";
const PREFIX = "TANSO";
const VERSION = "0.0.1";
const PORT = 11025;

// biome-ignore lint/suspicious/noExplicitAny: We are just logging, so any is fine.
function log(message: any) {
	console.log(`${PREFIX}: ${message}`);
}

// biome-ignore lint/suspicious/noExplicitAny: We are just logging, so any is fine.
function elog(object: any) {
	console.error(`${PREFIX}: ${object}`);
}

let socket: WebSocket | null = null;
const RECONNECT_INTERVAL = 100; // 100 ms - very aggressive reconnection

function closeWindow() {
	log("Attempting to close the window");
	if (window.close) {
		window.close();
	} else {
		log("Unable to close the window automatically");
		alert("Please close this window manually.");
	}
}

async function connect(silent = false) {
	if (socket && socket.readyState !== WebSocket.CLOSED) {
		return; // Already connected or connecting
	}

	socket = new WebSocket(`ws://127.0.0.1:${PORT}`);

	socket.onopen = () => {
		log("[open] connection established");
		socket?.send("[CLIENT] CONNECTION");
	};

	socket.onmessage = async (event) => {
		log("[message] data received");
		log(event.data);
		try {
			const msgObj = JSON.parse(event.data);
			if (msgObj.action === "close_window") {
				closeWindow();
			}

			if (msgObj.action === "fetch_teams") {
				const teams = localStorage.getItem("showdown_teams");
				if (teams) {
					socket?.send(JSON.stringify({ action: "fetch_teams", data: teams }));
				}

				// If the window is not active, close it.
				if (!window.document.hasFocus()) {
					closeWindow();
				}
			}

			if (
				msgObj.action === "load_teams" ||
				msgObj.action === "load_teams_overwrite"
			) {
				let teams = localStorage.getItem("showdown_teams");
				const data_object = msgObj.data;
				// biome-ignore lint/suspicious/noExplicitAny: I don't care enough to map this to an explicit type
				const load_teams = [];
				for (const team of data_object) {
					let sets = "";
					for (let i = 0; i < team.mons.length; i++) {
						const mon = team.mons[i];

						const json_str = JSON.stringify(mon);
						let s = Sets.fromJSON(json_str);
						if (s === undefined) {
							elog(`Failed to parse set: ${JSON.stringify(mon)}`);
							continue;
						}
						s = s as PokemonSet;
						if (i !== 0) {
							console.log(s);
							sets = `${sets}]${Sets.pack(s)}`;
						} else {
							sets = `${Sets.pack(s)}`;
						}
					}
					if (team.format !== null) {
						load_teams.push(`${team.format}]${team.name}|${sets}`);
					} else {
						load_teams.push(`${team.name}|${sets}`);
					}
					log(`Formatted team: ${team.name}`);
				}
				log("Formatted all teams");
				let add_string = "";
				for (const team of load_teams) {
					add_string = `${add_string}\n${team}`;
				}

				if (teams && msgObj.action !== "load_teams_overwrite") {
					// Append the teams to the local storage
					teams = `${add_string}\n${teams}`;
				} else {
					teams = add_string;
				}

				if (msgObj.action === "load_teams_overwrite") {
					localStorage.removeItem("showdown_teams");
					localStorage.setItem("showdown_teams", add_string);
				} else if (teams !== null) {
					log("Setting teams");
					localStorage.setItem("showdown_teams", teams);
				}

				socket?.send(JSON.stringify({ action: "load_teams", data: "" }));
			}
		} catch (e) {
			log(e);
		}
	};

	socket.onclose = () => {
		if (!silent) {
			log("[close] connection closed");
		}
		socket = null;
		setTimeout(() => connect(true), RECONNECT_INTERVAL);
	};

	socket.onerror = () => {
		if (!silent) {
			log("[error] connection error - Is the desktop app running?");
		}
		socket?.close(); // Explicitly close the socket on error
	};
}

async function main() {
	log(`Starting TANSO Userscript v${VERSION}`);
	// Initial connection attempt
	connect();

	// Continuously check and attempt to reconnect
	setInterval(() => {
		if (!socket || socket.readyState === WebSocket.CLOSED) {
			connect(true);
		}
	}, RECONNECT_INTERVAL);
}

main();
