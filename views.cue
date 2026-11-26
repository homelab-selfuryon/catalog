package catalog

// What each repository receives: only the fields it reads, at the same paths as in `catalog`, so
// a view is a subset of out/catalog.json. `cue cmd generate` writes each to out/<repository>.json
// and CI sends it there (job `sync`). A field a repository starts to read is added here first;
// a change that touches no view field opens no PR in that repository.
views: {
	// github/ (teams, repositories with their properties and environments) and openbao/ (roles per
	// app and environment).
	"platform-terraform": {
		teams: {for n, t in catalog.teams {(n): description: t.description}}
		apps: {for n, a in catalog.apps {
			(n): {team: a.team, description: a.description, tier: a.tier, lifecycle: a.lifecycle, envs: a.envs}
		}}
	}

	// teams/catalog.cue: every tenant team becomes a team with the platform's defaults.
	"platform-components": {
		teams: {for n, t in catalog.teams if t.tenant {(n): tenant: true}}
	}

	// registry.cue (Argo CD objects for the environments in `envs`) and gitops_checks.py (version
	// files, CODEOWNERS).
	gitops: {
		apps: {for n, a in catalog.apps {(n): {team: a.team, envs: a.envs, cluster: a.cluster}}}
	}
}
