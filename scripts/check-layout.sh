#!/usr/bin/env bash
# Each team is one file, teams/<team>.cue, that holds only its own team (a file must not add apps
# to another team), and .github/CODEOWNERS gives each team its file. Run from the repository root.
set -euo pipefail

status=0
n=0
shopt -s nullglob
for f in teams/*.cue; do
	t=$(basename "$f" .cue)
	n=$((n + 1))
	keys=$(cue export "$f" --out json | jq -r 'keys | join(" ")')
	if [[ "$keys" != "$t" ]]; then
		echo "$f: must hold the team '$t' only, holds: ${keys:-nothing}"
		status=1
	fi
	if ! grep -qE "^/teams/${t}\.cue[[:space:]]+@homelab-selfuryon/${t}\$" .github/CODEOWNERS; then
		echo ".github/CODEOWNERS: no '/teams/$t.cue @homelab-selfuryon/$t' line"
		status=1
	fi
done
extra=$(find teams -mindepth 1 ! -name '*.cue' -printf '%p\n')
if [[ -n "$extra" ]]; then
	echo "teams/ holds one <team>.cue per team, nothing else:"
	echo "$extra"
	status=1
fi

if [[ $status -eq 0 ]]; then
	echo "layout ok: $n teams, $(cue export -e 'len(catalog.apps)') apps"
fi
exit "$status"
