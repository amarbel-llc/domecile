# treefmt comes from the devShell and is invoked via `nix develop --command`,
# so recipes work from a bare shell and inside the spinclass merge hook, not
# only under an active direnv devshell.

default: lint build test

[group("pre-build")]
lint: lint-fmt

# read-only formatting check via treefmt
[group("pre-build")]
lint-fmt:
  nix develop --command treefmt --ci

[group("build")]
build: build-doc

# compile doc/*.scd man pages via nix
[group("build")]
build-doc:
  nix build --no-link .#docs-domecile

[group("post-build")]
test: test-flake-check

# validate flake outputs and run nix checks
[group("post-build")]
test-flake-check:
  nix flake check

# list tests matching a pattern
[group("post-build")]
test-list *pattern:
  nix run .#tests -- -l {{pattern}}

# run module tests matching a pattern
[group("post-build")]
test-modules *pattern:
  nix run .#tests -- {{pattern}}

# run integration tests
[group("post-build")]
test-integration:
  nix run .#tests -- -t -l

# format codebase with treefmt
[group("codemod")]
codemod-fmt:
  nix develop --command treefmt

# create a news entry for a module change
[group("maintenance")]
create-news-entry:
  modules/misc/news/create-news-entry.sh
