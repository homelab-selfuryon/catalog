# Only what is specific to catalog. CUE, treefmt (nixfmt, prettier, cue fmt), the base git hooks and
# actionlint/zizmor/shellcheck/jq come from platform-kit/devenv/cue.nix (see devenv.yaml).
{ ... }:
{
  treefmt.config.settings.global.excludes = [ "out/**" ];

  git-hooks.hooks.actionlint.enable = true;

  # `devenv test` (after the base step `treefmt --fail-on-change`); CI runs it as is.
  enterTest = ''
    cue vet -c ./...
    cue cmd generate
    bash scripts/check-layout.sh
    bash scripts/test-schema.sh
    shellcheck scripts/*.sh
  '';
}
