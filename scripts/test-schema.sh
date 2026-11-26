#!/usr/bin/env bash
# What the schema must reject, and what it derives. Each case copies the repository to a
# temporary directory, adds one file and evaluates the catalog. Run from the repository root.
set -euo pipefail

root=$PWD
status=0

# run <name> <expect: pass|fail> <file> <content>
run() {
	local name=$1 expect=$2 file=$3 content=$4 tmp got
	tmp=$(mktemp -d)
	cp -r "$root/cue.mod" "$root/schema" "$root/teams" "$root/catalog.cue" "$tmp/"
	mkdir -p "$(dirname "$tmp/$file")"
	printf '%s\n' "$content" >"$tmp/$file"
	if (cd "$tmp" && cue export -e catalog --out json >"$tmp/out.json" 2>"$tmp/err.txt"); then got=pass; else got=fail; fi
	if [[ "$got" != "$expect" ]]; then
		echo "FAIL $name: expected $expect, got $got"
		cat "$tmp/err.txt"
		status=1
	else
		echo "ok   $name ($expect)"
	fi
	if [[ "$got" == pass && -n "${CHECK:-}" ]]; then
		jq -e "$CHECK" "$tmp/out.json" >/dev/null || {
			echo "FAIL $name: $CHECK"
			status=1
		}
	fi
	rm -rf "$tmp"
}

run "app of a team without tenant namespaces" fail teams/platform/tool.cue \
	'package platform
apps: tool: description: "x"'

run "one app in two teams" fail teams/platform/notes-api.cue \
	'package platform
team: tenant: true
apps: "notes-api": description: "x"'

run "app without a description" fail teams/notes/bare.cue \
	'package notes
apps: bare: {}'

run "unknown tier" fail teams/notes/tier.cue \
	'package notes
apps: "notes-api": tier: "tier-0"'

run "unknown environment" fail teams/notes/envs.cue \
	'package notes
apps: "notes-api": envs: ["staging", "qa"]'

run "a system setting in the catalog (quotas belong to platform-components)" fail teams/notes/quota.cue \
	'package notes
team: quota: staging: pods: "10"'

run "unknown lifecycle" fail teams/notes/lifecycle.cue \
	'package notes
apps: "notes-api": lifecycle: "retired"'

CHECK='.apps["notes-api"].envs == ["staging", "prod"]' \
	run "an app without previews" pass teams/notes/envs.cue \
	'package notes
apps: "notes-api": envs: ["staging", "prod"]'

exit "$status"
