##!/bin/bash

## Get the directory of this script
#DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#SRC_DIR="$DIR/src"

## Check whether the src folder exists
#if [ ! -d "$SRC_DIR" ]; then
#    echo "Error: src folder does not exist."
#    exit 1
#fi

## On invocation, we build the first time
#bun run build

## Watch for changes in the src folder
#fswatch -o --event Updated "$SRC_DIR" | xargs -I{} bun run build && python -m http.server 8080

## If we get here, something went wrong
#exit 1

#!/bin/bash

# Get the directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

SRC_DIR="$DIR/src"
DIST_DIR="$DIR/dist"  # Assuming your built files go to a 'dist' directory

# Check whether the src folder exists
if [ ! -d "$SRC_DIR" ]; then
    echo "Error: src folder does not exist."
    exit 1
fi

# Function to build and serve
build_and_serve() {
    echo "Building..."
    bun run build
    
    # echo "Starting server..."
    # bunx live-server "$DIST_DIR" --port=60711 &
    # SERVER_PID=$!
}

# Function to kill the server
# kill_server() {
#     if [ ! -z "$SERVER_PID" ]; then
#         echo "Stopping server..."
#         kill $SERVER_PID
#     fi
# }

# Trap to ensure we kill the server on script exit
trap kill_server EXIT

# Initial build and serve
build_and_serve

# Watch for changes in the src folder
echo "Watching for changes..."
fswatch -o --event Updated "$SRC_DIR" | while read file
do
    echo "Change detected. Rebuilding..."
    # kill_server
    build_and_serve
done

# If we get here, something went wrong
exit 1
