#!/usr/bin/env bash
# Check the case for collisions with the board and connectors, then export
# printable STLs:
#   <out>/extron-svideo-adapter-<version>-case-bottom.stl
#   <out>/extron-svideo-adapter-<version>-case-top.stl
#
# Usage: scripts/build-case.sh
#   OPENSCAD  openscad command (default: openscad)
#   VERSION   string used in output names (default: as scripts/build.sh)
#   OUT       output directory (default: output-case)
set -euo pipefail

cd "$(dirname "$0")/.."

NAME=extron-svideo-adapter
read -r -a OPENSCAD <<< "${OPENSCAD:-openscad}"
OUT=${OUT:-output-case}
if [[ -z ${VERSION:-} ]]; then
    if [[ ${GITHUB_REF_TYPE:-} == tag ]]; then
        VERSION=$GITHUB_REF_NAME
    elif [[ -n ${GITHUB_SHA:-} ]]; then
        VERSION=${GITHUB_SHA:0:7}
    else
        VERSION=$(git describe --tags --always --dirty 2>/dev/null || echo dev)
    fi
fi

rm -rf "$OUT"
mkdir -p "$OUT"

echo "== Collision check"
# The "check" part is the intersection of the case with the board and
# connector envelopes. OpenSCAD writes no file when it is empty.
"${OPENSCAD[@]}" -D 'part="check"' -o "$OUT/check.stl" case/case.scad >/dev/null 2>&1 || true
if [[ -e $OUT/check.stl ]]; then
    echo "error: case intersects the board or connectors (see $OUT/check.stl)" >&2
    exit 1
fi
echo "no collisions"

for part in bottom top; do
    echo "== $part shell"
    "${OPENSCAD[@]}" -D "part=\"$part\"" \
        -o "$OUT/$NAME-$VERSION-case-$part.stl" case/case.scad
done

ls -l "$OUT"
