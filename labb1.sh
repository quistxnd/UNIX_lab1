#!/bin/sh

# Argument checking
if [ $# -ne 1 ]; then
    echo "Using: $0 <source_file>" >&2
    exit 1
fi

SRC=$1

if [ ! -f "$SRC" ]; then
    echo "File not found" >&2
    exit 2
fi

dirname=$(pwd)
# Looking for the line with Output:
OUTPUT=$(grep -m1 'Output:' "$SRC" | sed 's/.*Output:[ ]*//')

if [ -z "$OUTPUT" ]; then
    echo "No comment found Output:" >&2
    exit 3
fi

# create a temporary directory
TMPDIR=$(mktemp -d)
if [ ! -d "$TMPDIR" ]; then
    echo "Failed to create temporary directory" >&2
    exit 4
fi


cleanup() {
    rm -rf "$TMPDIR"
}
trap cleanup EXIT INT TERM

# Copying file from temporary directory
cp "$SRC" "$TMPDIR" || exit 5
cd "$TMPDIR" || exit 5

BASENAME=$(basename "$SRC")
RESULT=0


case "$SRC" in
    *.c)
        gcc "$BASENAME" -o "$OUTPUT" || RESULT=1
        ;;
    *.tex)
        pdflatex "$BASENAME" >/dev/null 2>&1
        if [ ! -f "$OUTPUT.pdf" ]; then
            RESULT=1
        fi
        ;;
    *)
        echo "Unsupported file type" >&2
        exit 6
        ;;
esac

if [ $RESULT -ne 0 ]; then
    echo "Ошибка сборки" >&2
    exit 7
fi


case "$SRC" in
    *.c)
        mv "$OUTPUT" $dirname
        ;;
    *.tex)
        mv "$OUTPUT.pdf" $dirname
        ;;
esac

echo "The assembly was successful!"
exit 0
