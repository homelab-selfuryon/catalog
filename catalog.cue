// Package catalog collects every team directory into one catalog. Adding a team means a directory
// under teams/ and one import here (scripts/check-layout.sh makes sure the two agree).
package catalog

import (
	"github.com/homelab-selfuryon/catalog/schema"

	t_notes "github.com/homelab-selfuryon/catalog/teams/notes"
	t_platform "github.com/homelab-selfuryon/catalog/teams/platform"
)

// Keyed by the directory name.
_teams: {
	notes:    {team: t_notes.team, apps: t_notes.apps}
	platform: {team: t_platform.team, apps: t_platform.apps}
}

catalog: schema.#Catalog & {
	teams: {for k, t in _teams {(k): t.team}}
	apps:  {for k, t in _teams for a, s in t.apps {(a): s & {team: k}}}
}
