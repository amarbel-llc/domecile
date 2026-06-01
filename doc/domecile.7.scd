domecile(7)

# NAME

domecile - personal fork of nix-community/home-manager

# DESCRIPTION

*domecile* is a personal fork of nix-community/home-manager maintained at
amarbel-llc/domecile. It tracks upstream's *release-26.05* branch and adds
opt-in extensions that have not yet been upstreamed.

The fork is consumed by the eng flake as its *home-manager* input in place of
the upstream module.

# DIFFERENCES FROM UPSTREAM

## programs.man.man-db: manualPages and skipPackages options

Upstream home-manager's man-db module builds the whatis cache by passing
*config.home.packages* directly to a *buildEnv*, so any package bump — even
one with no man pages — invalidates the cache and forces a full *mandb*
re-parse.

domecile adds two options to *programs.man.man-db* that mirror the treatment
NixOS/nixpkgs#136915 gave to *nixos/modules/misc/man-db.nix*:

*skipPackages*
	A list of packages to exclude from the cache's *buildEnv*. Useful as a
	quick win to exclude frequently-changing, man-page-less packages and avoid
	unnecessary cache rebuilds.

*manualPages*
	An overridable *path* option whose default is the same *buildEnv* as
	before, filtered by *skipPackages*. Advanced users can supply a
	content-addressed derivation so the cache only rebuilds when man-page
	_content_ changes rather than whenever any package in *home.packages*
	changes.

Default behaviour is unchanged: with an empty *skipPackages* list the
*manualPages* default produces the same derivation as the upstream module.

This change is a backwards-compatible superset of upstream's behaviour and is
a candidate for upstreaming to nix-community/home-manager.

# BRANCH POLICY

The fork's *master* branch tracks upstream's *release-26.05* branch. Fork
commits are layered on top; they are never merged back into *master* from
upstream's *master* (which tracks the next release cycle).

To pull upstream changes:

```
git fetch upstream
git rebase upstream/release-26.05
```

# SEE ALSO

*home-manager*(1), *home-manager-configuration.nix*(5),
*nix-community/home-manager* upstream at https://github.com/nix-community/home-manager
