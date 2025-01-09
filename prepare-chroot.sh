#!/bin/bash

set -e  # Exit on error

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 /path/to/binary /path/to/new/root"
    exit 1
fi

BINARY="$1"
NEW_ROOT="$2"

if [ ! -f "$BINARY" ]; then
    echo "Error: Binary $BINARY not found"
    exit 1
fi

if [ ! -d "$NEW_ROOT" ]; then
    echo "Creating new root directory: $NEW_ROOT"
    mkdir -p "$NEW_ROOT"
fi

# Create necessary directories
mkdir -p "$NEW_ROOT/bin"
mkdir -p "$NEW_ROOT/lib"
mkdir -p "$NEW_ROOT/lib64"
mkdir -p "$NEW_ROOT/lib/x86_64-linux-gnu"

# Copy the binary
echo "Copying $BINARY to $NEW_ROOT/bin/$(basename $BINARY)"
cp "$BINARY" "$NEW_ROOT/bin/"

# Function to copy a library
copy_lib() {
    local lib="$1"
    local real_lib=$(readlink -f "$lib")
    local lib_name=$(basename "$lib")
    local real_lib_name=$(basename "$real_lib")
    
    case "$lib" in
        /lib64/*)
            echo "Copying $real_lib to $NEW_ROOT/lib64/$lib_name"
            cp "$real_lib" "$NEW_ROOT/lib64/$lib_name"
            ;;
        /lib/x86_64-linux-gnu/*)
            echo "Copying $real_lib to $NEW_ROOT/lib/x86_64-linux-gnu/$lib_name"
            cp "$real_lib" "$NEW_ROOT/lib/x86_64-linux-gnu/$lib_name"
            ;;
        *)
            echo "Copying $real_lib to $NEW_ROOT/lib/$lib_name"
            cp "$real_lib" "$NEW_ROOT/lib/$lib_name"
            ;;
    esac
}

# Get and copy all dependencies
echo "Copying dependencies..."
ldd "$BINARY" | while read -r line; do
    if [[ $line == *"=>"* ]]; then
        # Extract the library path
        lib_path=$(echo "$line" | awk '{print $3}')
        if [ -n "$lib_path" ] && [ "$lib_path" != "not" ]; then
            copy_lib "$lib_path"
        fi
    elif [[ $line == */ld-linux* ]]; then
        # Handle cases like /lib64/ld-linux-x86-64.so.2
        lib_path=$(echo "$line" | awk '{print $1}')
        copy_lib "$lib_path"
    fi
done

echo "Done! You can now try: chroot $NEW_ROOT $BINARY_NAME"
