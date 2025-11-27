#!/usr/bin/env bash
set -e

if [ $# -ne 4 ]; then
    echo "Usage: $0 <version> <cpu|gpu> <linux|windows> <arch>"
    exit 1
fi

VERSION=$1
FLAVOR=$2
OS=$3
ARCH=$4

DEPS_DIR="../deps"
META_FILE="${DEPS_DIR}/.tf_meta"

mkdir -p "$DEPS_DIR"

# Compute the metadata string
META_CONTENT=$(printf "version=%s\nflavor=%s\nos=%s\narch=%s\n" \
    "$VERSION" "$FLAVOR" "$OS" "$ARCH")

# If metadata exists and matches → skip download
if [ -f "$META_FILE" ]; then
    if [ "$META_CONTENT" = "$(cat "$META_FILE")" ]; then
        echo "TensorFlow C API already downloaded with these settings. Skipping."
        exit 0
    fi
fi

# Determine extension
EXT="tar.gz"
if [ "$OS" = "windows" ]; then
    EXT="zip"
fi

FILENAME="libtensorflow-${FLAVOR}-${OS}-${ARCH}.${EXT}"
URL="https://storage.googleapis.com/tensorflow/versions/${VERSION}/${FILENAME}"

echo "Downloading TensorFlow C API from:"
echo "  $URL"

curl -L --fail -o "${DEPS_DIR}/${FILENAME}" "$URL"

echo "Extracting..."
if [ "$EXT" = "tar.gz" ]; then
    tar -xzf "${DEPS_DIR}/${FILENAME}" -C "$DEPS_DIR"
else
    unzip -o "${DEPS_DIR}/${FILENAME}" -d "$DEPS_DIR"
fi

# Write metadata after successful extraction
printf "%s" "$META_CONTENT" > "$META_FILE"

echo "Done! TensorFlow C API extracted to $DEPS_DIR/"

