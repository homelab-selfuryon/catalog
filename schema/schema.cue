// Package schema types the catalog: the facts about the org that every repository must agree on —
// which teams and apps exist, who owns what, how critical an app is and where it runs. How a system
// implements a fact (GitHub permissions, quotas, roles) is that system's, in its own repository
// (meta decisions.md, 2026-11-26). A team file says only how it differs from the defaults;
// `catalog.json` carries every value resolved.
package schema

#Catalog: {
	teams: [string]~(N,_): #Team & {name: N}
	apps: [string]~(N,_):  #App & {name: N}

	// An app belongs to a team that exists and gets tenant namespaces.
	_appTeams: {for a, s in apps {(a): teams[s.team].tenant & true}}
}

#Team: {
	// Not `system`: its Argo CD Applications namespace would be Argo CD's own (argocd-system).
	name!:        =~"^[a-z][a-z0-9]{1,20}$" & !="system"
	description!: string & !=""

	// A product team runs apps in its own namespaces (`<team>-staging`, `<team>-prod`,
	// `<team>-pr-<n>`); the platform team runs none.
	tenant: *true | bool
}

#Envs: ["preview", "staging", "prod"]

#App: {
	// Also the name of its repository, image and Argo CD Applications.
	name!:        =~"^[a-z][a-z0-9-]{1,40}$"
	team!:        string
	description!: string & !=""
	// How much the org depends on the app; systems derive their rules from it.
	tier: *"tier-3" | "tier-2" | "tier-1"
	// Where the app is in its life.
	lifecycle: *"active" | "experimental" | "deprecated"
	// The environments the app has: `preview` (one per pull request), `staging`, `prod`. Every
	// repository honours the same list (environments, OpenBao roles, Applications).
	envs: *#Envs | [...or(#Envs)]
	// The cluster it runs in (gitops checks that it exists).
	cluster: *"alpha-01" | =~"^[a-z][a-z0-9-]{1,40}$"
}
