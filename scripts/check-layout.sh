#!/usr/bin/env bash
# The directories under teams/ and the teams in catalog.cue agree, and each team directory holds
# team.cue plus one <app>.cue per app of that team, and .github/CODEOWNERS gives each team its
# directory, before the team.cue rule (the last match wins). Run from the repository root.
set -euo pipefail

catalog=$(cue export -e catalog --out json)
status=0
owners_team_cue=$(grep -nF '/teams/*/team.cue' .github/CODEOWNERS | cut -d: -f1)
[[ -n "$owners_team_cue" ]] || { echo ".github/CODEOWNERS: no '/teams/*/team.cue' rule"; exit 1; }

dirs=$(find teams -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
teams=$(jq -r '.teams | keys[]' <<<"$catalog" | sort)
if [[ "$dirs" != "$teams" ]]; then
	echo "teams/ directories and catalog.cue disagree (directories < > catalog):"
	diff <(echo "$dirs") <(echo "$teams") || true
	status=1
fi

for t in $dirs; do
	if [[ ! -f "teams/$t/team.cue" ]]; then
		echo "teams/$t: no team.cue"
		status=1
	fi
	files=$(find "teams/$t" -maxdepth 1 -name '*.cue' ! -name team.cue -printf '%f\n' | sed 's/\.cue$//' | sort)
	apps=$(jq -r --arg t "$t" '.apps | to_entries[] | select(.value.team == $t) | .key' <<<"$catalog" | sort)
	if [[ "$files" != "$apps" ]]; then
		echo "teams/$t: one <app>.cue per app (files < > apps):"
		diff <(echo "$files") <(echo "$apps") || true
		status=1
	fi
	line=$(grep -nE "^/teams/${t}/[[:space:]]+@homelab-selfuryon/${t}\$" .github/CODEOWNERS | cut -d: -f1 || true)
	if [[ -z "$line" ]]; then
		echo ".github/CODEOWNERS: no '/teams/$t/ @homelab-selfuryon/$t' line"
		status=1
	elif [[ "$line" -gt "$owners_team_cue" ]]; then
		echo ".github/CODEOWNERS: '/teams/$t/' must come before '/teams/*/team.cue'"
		status=1
	fi
done

if [[ $status -eq 0 ]]; then
	echo "layout ok: $(wc -w <<<"$dirs") teams, $(jq '.apps | length' <<<"$catalog") apps"
fi
exit "$status"
