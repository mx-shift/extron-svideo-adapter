#!/usr/bin/env bash
# Check the design and generate release outputs:
#   output/<project>-<version>-schematic.pdf
#   output/<project>-<version>-oshpark.zip   (Gerbers + Excellon drill for OSH Park)
#   output/erc.rpt, output/drc.rpt
#
# Usage: scripts/build.sh
#   KICAD_CLI  kicad-cli command (default: kicad-cli; for the Flatpak use
#              "flatpak run --command=kicad-cli org.kicad.KiCad")
#   VERSION    string used in output names (default: tag name or short commit
#              hash in GitHub Actions, otherwise `git describe`)
#   OUT        output directory (default: output)
set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT=extron-svideo-adapter
read -r -a KICAD_CLI <<< "${KICAD_CLI:-kicad-cli}"
OUT=${OUT:-output}
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
mkdir -p "$OUT/gerbers"

echo "== ERC"
"${KICAD_CLI[@]}" sch erc --severity-error --exit-code-violations \
    -o "$OUT/erc.rpt" "$PROJECT.kicad_sch"

echo "== DRC"
"${KICAD_CLI[@]}" pcb drc --schematic-parity --severity-error --exit-code-violations \
    -o "$OUT/drc.rpt" "$PROJECT.kicad_pcb"

echo "== Schematic PDF"
"${KICAD_CLI[@]}" sch export pdf \
    -o "$OUT/$PROJECT-$VERSION-schematic.pdf" "$PROJECT.kicad_sch"

# Layers and settings per https://docs.oshpark.com/design-tools/kicad/generating-kicad-gerbers/
echo "== Gerbers"
"${KICAD_CLI[@]}" pcb export gerbers --check-zones \
    --layers F.Cu,B.Cu,F.Mask,B.Mask,F.Silkscreen,B.Silkscreen,Edge.Cuts \
    -o "$OUT/gerbers/" "$PROJECT.kicad_pcb"

echo "== Drill"
"${KICAD_CLI[@]}" pcb export drill --format excellon \
    --excellon-units in --excellon-zeros-format decimal \
    --excellon-oval-format alternate --drill-origin absolute \
    -o "$OUT/gerbers/" "$PROJECT.kicad_pcb"

echo "== Package"
(cd "$OUT/gerbers" && python3 -m zipfile -c "../$PROJECT-$VERSION-oshpark.zip" ./*)

ls -l "$OUT"
