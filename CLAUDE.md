# CLAUDE.md

The org's teams and apps in CUE, generated into one `out/catalog.json` that `platform-terraform`,
`platform-components` and `gitops` read. Read `meta/delivery.md` ("Catalog") first: the shape of
`catalog.json` is a contract with those repositories; change it there in the same session.

## Layout

```
schema/        #Catalog, #Team, #App, defaults
teams/         one <team>.cue per team (the team and its apps), package teams
catalog.cue    builds `catalog` from the teams package
views.cue      views.<repository>: the fields each reader reads (same paths as catalog)
ext_tool.cue   cue cmd generate -> out/catalog.json + out/<repository>.json
.github/       workflows/ci.yaml (tests; on main, job `sync` opens the `catalog/sync` PRs)
scripts/       check-layout.sh (a file per team, its own team only; CODEOWNERS), test-schema.sh (rejections)
```

## Commands

```
devenv shell -- cue fmt ./...
devenv shell -- cue vet -c ./...
devenv shell -- cue cmd generate
devenv test                          # what CI runs
```

## Conventions

- Only facts every repository must agree on (teams, apps, ownership, tier, lifecycle, envs,
  cluster). A setting of one system (quotas, GitHub permission, roles) belongs in that system's
  repository, as a default plus what one team needs (meta decisions.md, 2026-11-26).
- A team file holds data only; types and defaults live in `schema/`. Values a team must be
  able to set differently are defaults (`*v | T`) in the schema.
- Adding a team: `teams/<team>.cue` and a `CODEOWNERS` line. `check-layout.sh` checks that a file
  holds only its own team (CODEOWNERS is per file, so a team must not add apps to another).
- A new rule the schema enforces gets a case in `scripts/test-schema.sh`.
- A repository receives its view, never the whole catalog. A field it starts to read goes into
  `views.cue` first; a new reader gets a view, a `sync` matrix entry and `catalog-sync.sts.yaml` in
  its `.github/chainguard/`.
- Changing what `catalog.json` carries changes what the other repositories receive: render or plan
  them before and after (no diff unless intended).
- Public repository: no secrets, no e-mail addresses, no member lists.
- Conventional Commits (`!` for breaking changes), signed commits.
