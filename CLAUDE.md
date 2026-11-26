# CLAUDE.md

The org's teams and apps in CUE, generated into one `out/catalog.json` that `platform-terraform`,
`platform-components` and `gitops` read. Read `meta/delivery.md` ("Catalog") first: the shape of
`catalog.json` is a contract with those repositories; change it there in the same session.

## Layout

```
schema/        #Catalog, #Team, #App, #Sizes (quota sizes), defaults
teams/<team>/  team.cue + one <app>.cue per app, package <team>
catalog.cue    imports every team package (aliased t_<team>), builds `catalog`
ext_tool.cue   cue cmd generate -> out/catalog.json
.github/       workflows/ci.yaml (tests; on main, job `sync` opens the `catalog/sync` PRs)
scripts/       check-layout.sh (directories = imports, one file per app), test-schema.sh (rejections)
```

## Commands

```
devenv shell -- cue fmt ./...
devenv shell -- cue vet -c ./...
devenv shell -- cue cmd generate
devenv test                          # what CI runs
```

## Conventions

- A team directory holds data only; types and defaults live in `schema/`. Values a team must be
  able to override are defaults (`*v | T`) in the schema.
- Adding a team: a directory, an import in `catalog.cue` (alias `t_<team>`: a field named like an
  import shadows it) and a `CODEOWNERS` line. `check-layout.sh` checks directories and imports agree.
- A new rule the schema enforces gets a case in `scripts/test-schema.sh`.
- The `sync` job needs `catalog-sync.sts.yaml` in each target repository; a new reader of the
  catalog gets a matrix entry and that policy.
- Changing what `catalog.json` carries changes what the other repositories receive: render or plan
  them before and after (no diff unless intended).
- Public repository: no secrets, no e-mail addresses, no member lists.
- Conventional Commits (`!` for breaking changes), signed commits.
