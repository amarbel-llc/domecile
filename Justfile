default: lint build test

[group("pre-build")]
lint: lint-fmt

# Read-only formatting check via treefmt.
[group("pre-build")]
lint-fmt:
  treefmt --ci

[group("build")]
build: build-doc

# Compile doc/*.scd man pages via nix.
[group("build")]
build-doc:
  nix build --no-link .#docs-domecile

[group("post-build")]
test: test-flake-check

# Validate flake outputs and run nix checks.
[group("post-build")]
test-flake-check:
  nix flake check

# List tests matching a pattern
[group("post-build")]
test-list *pattern:
  nix run .#tests -- -l {{pattern}}

# Run module tests matching a pattern
[group("post-build")]
test-modules *pattern:
  nix run .#tests -- {{pattern}}

# Run integration tests
[group("post-build")]
test-integration:
  nix run .#tests -- -t -l

# Format codebase with treefmt.
[group("codemod")]
codemod-fmt:
  treefmt

# Create a news entry for a module change.
[group("maintenance")]
create-news-entry:
  modules/misc/news/create-news-entry.sh
