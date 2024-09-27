import { defineConfig } from "@rsbuild/core";
// import { pluginBabel } from "@rsbuild/plugin-babel";
// import { pluginSolid } from "@rsbuild/plugin-solid";

export default defineConfig({
	plugins: [
		// pluginBabel({
		// 	include: /\.(?:jsx|tsx)$/,
		// }),
		// pluginSolid(),
	],

	output: {
		filenameHash: false,
		filename: {
			js: "[name].js",
		},
	},
	source: {
		entry: {
			main: "./src/main.ts",
		},
	},
	tools: {
		htmlPlugin: false,
	},

	performance: {
		chunkSplit: {
			strategy: "all-in-one",
		},
	},
});
