# catalog

Teams and apps of the `homelab-selfuryon` org, declared once: the facts every repository must agree
on — which teams and apps exist, who owns what, how critical an app is (`tier`), where it is in its
life (`lifecycle`), which environments it has and where it runs. From them the other repositories
build what a team or an app gets by default — the GitHub team, repositories and environments, OpenBao
roles, namespaces and quotas, Argo CD objects, `CODEOWNERS` lines — and set there whatever one team or
app needs beyond that (a bigger quota, another GitHub permission). Settings of one system never live
here. Decision and contract: `meta/decisions.md` (2026-11-26), `meta/delivery.md` ("Catalog"), card
`meta/catalog.md`.

## Layout

```
schema/schema.cue        #Team, #App, defaults
teams/<team>/team.cue    the team: description (tenant: false for a team without namespaces)
teams/<team>/<app>.cue   one file per app: description, tier, lifecycle, environments
catalog.cue              imports every team directory
views.cue                what each repository receives: only the fields it reads
ext_tool.cue             cue cmd generate -> out/catalog.json, out/<repository>.json (views)
scripts/                 check-layout.sh, test-schema.sh
```

## A new team

1. `teams/<team>/team.cue`:

   ```cue
   package <team>

   team: description: "What the team does"
   ```

2. One import in `catalog.cue` and a line in `_teams`.
3. A `/teams/<team>/` line in `.github/CODEOWNERS`, above the `team.cue` rule (`check-layout.sh` checks
   it). The team gets `push` here with the GitHub team (platform-terraform), so it opens its own PRs.

## A new app

`teams/<team>/<app>.cue`; everything but the description has a default:

```cue
package <team>

apps: "<app>": {
	description: "What the app does"
	tier:        "tier-3"             // tier-1 | tier-2 | tier-3
	envs: ["preview", "staging", "prod"] // previews only with "preview"
}
```

Its quotas, GitHub permission and the like are not set here: a team that needs more than the default
gets it in the repository of that system (`platform-components` `teams/<team>.cue`,
`platform-terraform` `github/locals.tf`).

## Commands

```sh
devenv shell -- cue cmd generate     # out/catalog.json + out/<repository>.json (git-ignored)
devenv shell -- cue export -e 'views.gitops'   # one view
devenv test                          # treefmt, cue vet, generate, layout, schema tests, shellcheck
```

## After merge

CI on `main` (`.github/workflows/ci.yaml`, job `sync`) sends each repository that reads the catalog
its view (`views.cue`: only the fields it reads, at the same paths as in `out/catalog.json`), one PR
each from the branch `catalog/sync`, and does not wait for any of them. A change outside a
repository's view opens no PR there (a new app's tier goes to `platform-terraform` only):

| Repository            | File                 | Merge                                                                |
| --------------------- | -------------------- | -------------------------------------------------------------------- |
| `platform-terraform`  | `catalog.json`       | first, then `tofu apply` in `github/` and `openbao/`                 |
| `platform-components` | `teams/catalog.json` | after the apply                                                      |
| `gitops`              | `catalog.json`       | after the apply; also `{}` version files and CODEOWNERS (its `sync`) |

The token comes from octo-sts (identity `catalog-sync`, policy in each repository's
`.github/chainguard/`). A newer catalog updates the open PR; a manual run of the workflow on `main`
resends the file.
