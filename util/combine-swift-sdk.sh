#!/bin/bash
# Combine per-arch portable Swift SDK artifactbundles (from make-swift-sdk.sh
# --portable) into a single bundle that cross-compiles for every arch:
#
#     swift sdk install swift-linux.artifactbundle
#     swift build --swift-sdk aarch64-unknown-linux-gnu   # or x86_64-...
#
# Each input bundle contributes its sysroot (renamed sysroot-<arch>) and its
# target triple; the combined bundle has one artifact with all triples.
#
# Usage:
#   util/combine-swift-sdk.sh <part1.artifactbundle> [<part2.artifactbundle> ...] --out DIR
set -eu

command -v jq >/dev/null || { echo "error: jq is required" >&2; exit 1; }

OUT="swift-linux.artifactbundle"
inputs=()
while [ $# -gt 0 ]; do
	case "$1" in
		--out) OUT="$2"; shift 2 ;;
		-h|--help) grep '^#' "$0" | sed 's/^# \?//'; exit 0 ;;
		*) inputs+=("$1"); shift ;;
	esac
done
[ ${#inputs[@]} -ge 1 ] || { echo "error: no input bundles" >&2; exit 1; }

ID="swift-linux"
rm -rf "$OUT"; mkdir -p "$OUT/$ID"
tmp="$(mktemp -d)"
version=""

for B in "${inputs[@]}"; do
	# The per-arch bundle has one subdir: swift-linux-<arch>/ (sysroot,
	# swift-sdk.json, toolset.json).
	iddir="$(find "$B" -mindepth 1 -maxdepth 1 -type d | head -1)"
	arch="$(basename "$iddir" | sed 's/^swift-linux-//')"
	version="$(jq -r '.artifacts[].version' "$B/info.json")"

	cp -a "$iddir/sysroot" "$OUT/$ID/sysroot-$arch"
	cp "$iddir/toolset.json" "$OUT/$ID/toolset-$arch.json"

	# The per-arch swift-sdk.json uses relative paths that all start with
	# "sysroot" and a toolset named toolset.json; re-point them to this arch's
	# copies before merging.
	sed -e "s#\"sysroot#\"sysroot-$arch#g" \
	    -e "s#\"toolset\.json\"#\"toolset-$arch.json\"#g" \
	    "$iddir/swift-sdk.json" > "$tmp/$arch.json"
done

# Merge every arch's targetTriples into one swift-sdk.json.
jq -s '{schemaVersion:"4.0", targetTriples: (map(.targetTriples) | add)}' \
	"$tmp"/*.json > "$OUT/$ID/swift-sdk.json"

cat > "$OUT/info.json" <<JSON
{
  "schemaVersion": "1.0",
  "artifacts": {
    "$ID": {
      "type": "swiftSDK",
      "version": "$version",
      "variants": [ { "path": "$ID" } ]
    }
  }
}
JSON

rm -rf "$tmp"
echo "combined bundle: $OUT"
echo "triples:"; jq -r '.targetTriples | keys[]' "$OUT/$ID/swift-sdk.json" | sed 's/^/  /'
