#!/usr/bin/env bash
# Rename MP3 files using their metadata: "## - Title.mp3"
# e.g. "03 - Moondance.mp3"
# Works in the current directory (one album at a time).

shopt -s nullglob

for f in *.mp3; do
    [ -e "$f" ] || continue

    # Extract metadata fields (quietly)
    track=$(ffprobe -v quiet -show_entries format_tags=track \
        -of default=noprint_wrappers=1:nokey=1 "$f")
    title=$(ffprobe -v quiet -show_entries format_tags=title \
        -of default=noprint_wrappers=1:nokey=1 "$f")

    # Handle empty tags gracefully
    track=${track:-00}
    title=${title:-$(basename "${f%.mp3}")}

    # If track tag is like "3/12", take only "3"
    track=${track%%/*}

    # Zero-pad to two digits (if already padded, treat as base 10)
    printf -v track "%02d" $((10#$track)) 2>/dev/null || track="00"

    # Sanitize title (remove or replace problematic chars)
    clean_title=$(echo "$title" | tr '/\\:*?"<>|' '-' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')

    # Construct new filename
    newname="${track} - ${clean_title}.mp3"

    # Skip if identical
    if [[ "$f" == "$newname" ]]; then
        echo "Skipping: $f (already named)"
        continue
    fi

    # Handle duplicate target names (like multiple "Moondance")
    if [[ -e "$newname" ]]; then
        i=1
        while [[ -e "${track} - ${clean_title} ($i).mp3" ]]; do
            ((i++))
        done
        newname="${track} - ${clean_title} ($i).mp3"
    fi

    echo "Renaming: $f → $newname"
    mv -n -- "$f" "$newname"
done

echo "✅ Done renaming files in $(pwd)"

