{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    literalMD
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.programs.man;
  cfgManDb = config.programs.man.man-db;

  # The manual pages the cache is generated from. When contentAddressed is
  # set, the configured manualPages (the default buildEnv *or* a user
  # override) is wrapped in a content-addressed copy so the cache's input
  # path is keyed on man-page content rather than the identity of the input
  # packages — unrelated home.packages bumps that leave /share/man
  # byte-identical then reuse the same store path, and mandb is not re-run.
  effectiveManualPages =
    if cfgManDb.contentAddressed then
      pkgs.runCommand "man-paths-ca"
        {
          __contentAddressed = true;
          outputHashMode = "recursive";
          outputHashAlgo = "sha256";
        }
        ''
          mkdir -p "$out/share/man"
          cp -rL ${cfgManDb.manualPages}/share/man/. "$out/share/man/"
        ''
    else
      cfgManDb.manualPages;
in
{
  options.programs.man.man-db = {
    enable = mkEnableOption "man-db as the man page viewer" // {
      default = true;
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Additional fields to be added to the end of the user manpath config file.";
      example = ''
        MANDATORY_MANPATH /usr/man
        SECTION 1 n l 8 3 0 2 3type 5 4 9 6 7
      '';
    };

    skipPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = ''
        Packages to *not* include when generating the man-db cache.
        Useful to avoid unnecessary cache rebuilds caused by packages that
        change frequently but whose man pages (if any) you do not need
        indexed for {command}`apropos`/{command}`man -k`.
      '';
    };

    manualPages = mkOption {
      type = types.path;
      default = pkgs.buildEnv {
        name = "man-paths";
        paths = lib.subtractLists cfgManDb.skipPackages config.home.packages;
        pathsToLink = [ "/share/man" ];
        extraOutputsToInstall = [ "man" ];
        ignoreCollisions = true;
      };
      defaultText = literalMD "all man pages in {option}`home.packages`";
      description = ''
        The manual pages to generate caches for when
        {option}`programs.man.generateCaches` is enabled. Must be a path to a
        directory with man pages under `/share/man`.

        Advanced users can override this with a content-addressed derivation
        so the cache only rebuilds when man-page *content* changes rather than
        whenever any package in {option}`home.packages` changes. See
        {option}`programs.man.man-db.contentAddressed` for a built-in way to
        do this without hand-rolling the wrapper.
      '';
    };

    contentAddressed = mkEnableOption "" // {
      description = ''
        Wrap {option}`programs.man.man-db.manualPages` in a content-addressed
        derivation so the man-db cache is keyed on man-page *content* rather
        than on the identity of the packages in {option}`home.packages`. With
        this enabled, an unrelated package bump that leaves the man pages
        byte-identical reuses the same cache store path, so the (slow) mandb
        whatis re-parse is skipped.

        Requires the `ca-derivations` experimental Nix feature to be enabled
        on every host that evaluates this configuration. Defaults to false so
        the module works on stock Nix; opt in only where `ca-derivations` is
        available.
      '';
    };
  };

  config = mkIf (cfg.enable && cfgManDb.enable) {
    warnings = lib.optional (
      cfgManDb.extraConfig != "" && !cfg.generateCaches
    ) "programs.man.man-db.extraConfig has no effect when programs.man.generateCaches is false";

    # This is mostly copy/pasted/adapted from NixOS' documentation.nix.
    home.file = mkIf (cfg.generateCaches && cfg.package != null) {
      ".manpath".text =
        let
          # Generate a database of all manpages in the configured manualPages
          # (content-addressed first when contentAddressed is set).
          manualCache =
            pkgs.runCommandLocal "man-cache"
              {
                nativeBuildInputs = [ cfg.package ];
              }
              ''
                # Generate a temporary man.conf so mandb knows where to
                # write cache files.
                echo "MANDB_MAP ${effectiveManualPages}/share/man $out" > man.conf
                # Run mandb to generate cache files:
                mandb -C man.conf --no-straycats --create \
                  ${effectiveManualPages}/share/man
              '';
        in
        ''
          MANDB_MAP ${config.home.profileDirectory}/share/man ${manualCache}
        ''
        + lib.optionalString (cfgManDb.extraConfig != "") "\n${cfgManDb.extraConfig}";
    };
  };
}
