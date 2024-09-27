import type { PokemonSet } from "@pkmn/sim";
import * as TeamsImport from "../pokemon-showdown/dist/sim/teams.js";

const Teams = TeamsImport.Teams;

// biome-ignore lint/suspicious/noExplicitAny: we are okay with an any here.
function log(message: any) {
	console.error(`[Bun ${new Date().toISOString()}] ${message}`);
}

type Team = {
	format: string;
	name: string;
	mons: PokemonSet[];
	text: string;
};

log("Bun script started. Waiting for input...");

for await (const line of console) {
	log(`Received input: ${line.slice(0, 100)}...`);
	if (line === "QUIT") {
		log("Bun script exited.");
		break;
	}

	// Trim the end of line spaces.
	let current_team_name = undefined;
	try {
		const teams = line.split("\\n");
		log(`Processing ${teams.length} team(s)`);
		const results: Team[] = [];
		for (const team of teams) {
			if (team.length === 0) {
				continue;
			}
			// Split on the first "|" to get the format and team name
			const format_and_name = team.split("|")[0];
			const [format, name] = format_and_name.split("]");
			current_team_name = name;
			const teamWithoutFormatAndName = team.slice(format_and_name.length + 1);
			const result = Teams.unpack(teamWithoutFormatAndName);
			if (result === null) {
				throw new Error("Invalid team");
			}
			const readable = Teams.export(result);

			results.push({ format, name, mons: result, text: readable });
		}
		console.log(JSON.stringify(results));
		log("Finished processing. Sent results.");

		// biome-ignore lint/suspicious/noExplicitAny: we are okay with an any here.
	} catch (error: any) {
		log(`Error processing input: ${error.message}`);
		if (current_team_name) {
			log(`Failed to parse team: ${current_team_name}`);
		}
		console.log(JSON.stringify({ error: error.message }));
	}

	console.log("END_OF_OUTPUT");
	log("Waiting for next input...");
}

log("Bun script exited.");
