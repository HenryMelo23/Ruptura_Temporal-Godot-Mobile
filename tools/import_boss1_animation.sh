#!/usr/bin/env bash
# Normalize reviewed, isolated sprites into independent frames with clear borders.
set -euo pipefail
source_image="$1"
output_dir="$2"
prefix="$3"
frame_count="${4:-4}"
layout="${5:-isolated}"
scratch_dir="$(mktemp -d)"
trap 'find "$scratch_dir" -type f -delete; rmdir "$scratch_dir"' EXIT
mkdir -p "$output_dir"
# Generated sheets need not match their requested dimensions/grid. Detect each
# complete silhouette instead of slicing through an extended claw at midpoint.
if [[ "$layout" == grid3x2 ]]; then
  # Reviewed six-cell sheets may contain disconnected death fragments.
  read -r width height < <(magick identify -format '%w %h\n' "$source_image")
  boxes=()
  row_split="${6:-$((height/2))}"
  for ((i=0; i<frame_count; i++)); do
    if (( i < 3 )); then row_y=0; row_height=$row_split; else row_y=$row_split; row_height=$((height-row_split)); fi
    boxes+=("$((width/3))x${row_height}+$(((i%3)*width/3))+${row_y}")
  done
else
  columns=2
  [[ "$layout" == isolated3x2 ]] && columns=3
  mapfile -t boxes < <(magick "$source_image" -alpha extract -threshold 1% -define connected-components:verbose=true -connected-components 8 null: | awk '$4 > 5000 && $5 == "srgb(255,255,255)" {split($2,b,"+"); print b[3], b[2], $2}' | sort -nk1 | awk -v n="$columns" '{print int((NR-1)/n),$2,$3}' | sort -nk1 -nk2 | awk '{print $3}')
  if (( ${#boxes[@]} != columns*2 )); then
    echo 'Unexpected number of complete isolated silhouettes' >&2
    exit 1
  fi
fi
for ((i=0; i<frame_count; i++)); do
  magick "$source_image" -crop "${boxes[i]}" +repage -trim +repage "$scratch_dir/$i.png"
done
for ((i=0; i<frame_count; i++)); do
  printf -v name '%s_%02d.png' "$prefix" "$((i+1))"
  read -r fw fh < <(magick identify -format '%w %h' "$scratch_dir/$i.png")
  frame_extent=$((fw > fh ? fw : fh))
  scale=$(awk -v extent="$frame_extent" 'BEGIN {printf "%.8f%%", 23200/extent}')
  magick "$scratch_dir/$i.png" -filter point -resize "$scale" -background none -gravity south -extent 256x244 -gravity north -extent 256x256 "$output_dir/$name"
done
