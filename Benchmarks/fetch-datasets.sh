#!/bin/sh
# Downloads three real-roaring-datasets, one mostly array, bitset and run containers; `all` fetches the nine CRoaring
# vendors in benchmarks/realdata.
set -eu
cd "$(dirname "$0")"
base=https://github.com/RoaringBitmap/real-roaring-datasets/raw/929d8088817840f43ffaa8592b49373b5a2d43b2
mkdir -p datasets
names="census1881 weather_sept_85 wikileaks-noquotes"
if [ "${1:-}" = all ]; then
    names="$names census-income census-income_srt census1881_srt uscensus2000 weather_sept_85_srt wikileaks-noquotes_srt"
fi
for name in $names; do
    [ -f "datasets/$name/complete" ] && continue
    curl -sSfL -o "datasets/$name.zip" "$base/$name.zip"
    rm -rf "datasets/$name"
    unzip -q -d "datasets/$name" "datasets/$name.zip"
    touch "datasets/$name/complete"
    rm "datasets/$name.zip"
done
