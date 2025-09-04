{ lib, pkgs, kernel ? pkgs.linuxPackages_latest.kernel, ... }:

let
  bcachefs-kernel-src = pkgs.fetchgit {
    name = "linux-kernel-bcachefs";
    url = "https://evilpiepirate.org/git/bcachefs.git";

    # To get the latest commit hash and sha256 from the master branch, run:
    # $ nix-shell -p nix-prefetch-git --run 'nix-prefetch-git --url https://evilpiepirate.org/git/bcachefs.git --rev refs/heads/master'
    rev = "bafa1cd3390cc97b6dc87090c63e8cf025ded178";
    hash = "sha256-XO8E7zB5EKCarQufYp7SAJ5FSPzhSGGZjpXb7AgQa1Y=";
  };
  makefileContents = builtins.readFile (bcachefs-kernel-src + "/Makefile");

  # Helper function to extract a value for a given key from the Makefile text.
  getMakefileVar = key:
    let
      # Find the line starting with the key, e.g., "VERSION = 6"
      line = lib.findFirst (line: lib.hasPrefix "${key} = " line) null (lib.splitString "\n" makefileContents);
      # Throw an error if the key isn't found in the Makefile
      _ = if line == null then throw "Could not find '${key}' in kernel Makefile" else true;
      # Extract the value part of the line (the part after "= ")
      value = lib.removePrefix "${key} = " line;
    in value;

  # Extract all the version components from the Makefile.
  version_major = getMakefileVar "VERSION";
  version_patch = getMakefileVar "PATCHLEVEL";
  version_sub = getMakefileVar "SUBLEVEL";
  version_extra = getMakefileVar "EXTRAVERSION";

  # Construct the base version string, e.g., "6.17.0-rc3"
  baseVersion = "${version_major}.${version_patch}.${version_sub}${version_extra}";
  versionString = "${baseVersion}-bcachefs-git-${lib.sources.shortRev bcachefs-kernel-src.rev}";
in
{
  boot.kernelPackages = let
    linux_bcachefs_pkg = { fetchgit, buildLinux, ... } @ args:

      buildLinux (args // rec {
        version = versionString;
        modDirVersion = baseVersion;

        src = bcachefs-kernel-src;
        kernelPatches = [];
        nativeBuildInputs = kernel.nativeBuildInputs ++ [ pkgs.rustfmt ];

        extraConfig = ''
          BCACHEFS_FS y
        '';

        # extraMeta.branch = "master";
      } // (args.argsOverride or {}));
    linux_bcachefs = pkgs.callPackage linux_bcachefs_pkg{};
  in
    pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_bcachefs);
}
