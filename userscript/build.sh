#!/bin/bash

bun run build:internal;
mkdir -p build;
cp dist/static/js/main.js build/tanso.user.js;

# cp -r icons build;

# Prepend userscript metadata to the file.
{
	echo "// ==UserScript=="
	echo "// @name			Tanso"
	echo "// @version		1.0.0"
	echo "// @description	Import and Export teams to & from Showdown!"
	echo "// @author		malaow3"
	echo "// @match			https://play.pokemonshowdown.com/*"
	echo "// @grant			unsafeWindow"
    echo "// ==/UserScript=="
	echo ""
	cat build/tanso.user.js
} > build/tmp-tanso.user.js

mv build/tmp-tanso.user.js build/tanso.user.js
