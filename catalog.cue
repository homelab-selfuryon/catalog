// Package catalog builds the catalog from teams/: one file per team, `teams/<team>.cue`, holding
// the team and its apps (scripts/check-layout.sh checks that each file holds only its own team).
package catalog

import (
	"github.com/homelab-selfuryon/catalog/schema"
	"github.com/homelab-selfuryon/catalog/teams"
)

// What a team file holds; the schema types the values.
#TeamFile: {
	team!: {...}
	apps: [string]: {...}
}

_teams: [string]: #TeamFile
_teams: teams

catalog: schema.#Catalog & {
	teams: {for k, t in _teams {(k): t.team}}
	apps:  {for k, t in _teams for a, s in t.apps {(a): s & {team: k}}}
}
