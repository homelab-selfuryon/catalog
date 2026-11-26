# catalog

Teams and apps of the `homelab-selfuryon` org, declared once. Everything a team or an app needs in
the other repositories — the GitHub team, repositories and environments, OpenBao roles, namespaces
and quotas, Argo CD registration, `CODEOWNERS` lines — is generated from here. Decision and contract:
`meta/decisions.md` (2026-11-26), `meta/delivery.md` ("Catalog"), card `meta/catalog.md`.

## Layout

```
schema/schema.cue        #Team, #App, quota sizes, defaults
teams/<team>/team.cue    the team: description, size, quota overrides, GitHub permission
teams/<team>/<app>.cue   one file per app: description, tier, lifecycle, environments
catalog.cue              imports every team directory
ext_tool.cue             cue cmd generate -> out/catalog.json (defaults resolved)
scripts/                 check-layout.sh, test-schema.sh
```

## A new team

1. `teams/<team>/team.cue`:

   ```cue
   package <team>

   team: {
   	description: "What the team does"
   	size:        "small" // small | medium | large; single quota values can be overridden
   }
   ```

2. One import in `catalog.cue` and a line in `_teams`.
3. A `/teams/<team>/` line in `.github/CODEOWNERS`.

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

## Commands

```sh
devenv shell -- cue cmd generate     # out/catalog.json (git-ignored)
devenv test                          # treefmt, cue vet, generate, layout, schema tests, shellcheck
```

## After merge

CI on `main` (`.github/workflows/ci.yaml`, job `sync`) sends the tested `catalog.json` to the
repositories that read it, one PR each from the branch `catalog/sync`, and does not wait for any of
them:

| Repository            | File                 | Merge                                                                |
| --------------------- | -------------------- | -------------------------------------------------------------------- |
| `platform-terraform`  | `catalog.json`       | first, then `tofu apply` in `github/` and `openbao/`                 |
| `platform-components` | `teams/catalog.json` | after the apply                                                      |
| `gitops`              | `catalog.json`       | after the apply; also `{}` version files and CODEOWNERS (its `sync`) |

The token comes from octo-sts (identity `catalog-sync`, policy in each repository's
`.github/chainguard/`). A newer catalog updates the open PR; a manual run of the workflow on `main`
resends the file.
