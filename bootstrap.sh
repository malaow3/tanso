#!/bin/bash

# Check if Zig is installed
if ! command -v zig &> /dev/null; then
    echo "Zig is not installed. Please install Zig and add it to your PATH."
    echo "See https://ziglang.org/learn/getting-started/#installing-zig"
    echo "Optionally, if you have Python on your machine, you can run 'pip install ziglang'"
    echo "Then run this script again."
    exit 1
fi

if ! command -v bun &> /dev/null; then
    echo "Bun is not installed. Please install Bun and add it to your PATH."
    echo "See https://bun.sh/docs/installation for instructions."
    echo "Then run this script again."
    exit 1
fi

# Get the git submodules
git submodule init
git submodule update

# Build the pokemon-showdown code
pushd pokemon-showdown
# Remove the lockfile b/c it doesn't work with Bun...
if [ -f package-lock.json ]; then
    rm package-lock.json
fi
pnpm install
pnpm run build
popd

pushd teamPack
bun build index.ts --bundle --outfile=dist/index.js --target=node
popd

