#!/usr/bin/env bash
# Converts all .m4a files in current directory (and subdirs) to MP3
# and organizes output as Artist/Album/track.mp3

shopt -s globstar nullglob

for f in **/*.m4a; do
    [ -e "$f" ] || continue  # skip if no files

    # Extract tags using ffprobe
    artist=$(ffprobe -v quiet -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 "$f")
    album=$(ffprobe -v quiet -show_entries format_tags=album  -of default=noprint_wrappers=1:nokey=1 "$f")
    title=$(ffprobe -v quiet -show_entries format_tags=title  -of default=noprint_wrappers=1:nokey=1 "$f")

    # Provide fallbacks if tags missing
    artist=${artist:-Unknown_Artist}
    album=${album:-Unknown_Album}
    title=${title:-$(basename "${f%.m4a}")}

    # Sanitize directory names
    safe_artist=$(echo "$artist" | tr '/\\' '_' )
    safe_album=$(echo "$album" | tr '/\\' '_' )

    # Output path
    outdir="${safe_artist}/${safe_album}"
    mkdir -p "$outdir"

    # Output filename
    outfile="${outdir}/${title}.mp3"

    echo "Converting: $f → $outfile"
    ffmpeg -y -i "$f" -codec:a libmp3lame -qscale:a 2 "$outfile"
done

echo "✅ All conversions complete."

