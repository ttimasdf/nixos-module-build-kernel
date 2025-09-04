# nixos-module-build-kernel: bcachefs.nix

This module provides a straightforward way to build and install a custom Linux kernel for NixOS directly from the official `bcachefs` development git repository. It is designed to be a "drop-in" solution for users who want to run the latest, cutting-edge version of the bcachefs filesystem.

## Purpose

The primary goal of this module is to simplify the process of using the `bcachefs` filesystem on NixOS. Instead of manually patching an existing kernel or managing complex overlays, this module automates the entire process:

  * **Fetches Source Directly**: It pulls the kernel source code from the official `bcachefs` git repository (`evilpiepirate.org/git/bcachefs.git`).
  * **Dynamic Versioning**: The module intelligently parses the kernel's `Makefile` to automatically determine the correct version string (e.g., `6.17.0-rc3-bcachefs-git-bafa1cd`). This ensures that tools like `uname -r` report a meaningful version.
  * **Enables Bcachefs**: It automatically sets the necessary kernel configuration option (`CONFIG_BCACHEFS_FS=y`) to build `bcachefs` support directly into the kernel.
  * **Complete Kernel Packages**: It uses `pkgs.linuxPackagesFor` to build not just the kernel, but the entire set of associated packages (`kernel`, `headers`, `broadcom-sta`, etc.), ensuring a fully functional system.

## Usage

To use this module, follow these steps:

1.  **Save the File**: Save the provided code as `bcachefs.nix` somewhere in your NixOS configuration directory. For example: `/etc/nixos/kernel/bcachefs.nix`.

2.  **Import the Module**: Import the new file into your main `configuration.nix`.

    ```nix
    # /etc/nixos/configuration.nix

    { config, pkgs, ... }:

    {
      imports =
        [
          ./hardware-configuration.nix
          ./kernel/bcachefs.nix  # <-- Add this line
        ];

      # ... your other configuration options
    }
    ```

3.  **Rebuild Your System**: Run your standard NixOS rebuild command.

      * **If using flakes:**
        ```sh
        sudo nixos-rebuild switch --flake .#yourHostname
        ```
      * **If not using flakes:**
        ```sh
        sudo nixos-rebuild switch
        ```

After rebooting, your system will be running the custom-built `bcachefs` kernel.

## Updating the Kernel

The module is pinned to a specific git commit hash to ensure reproducibility. To update to the latest version of the `bcachefs` kernel, you need to update the `rev` and `hash` values in `bcachefs.nix`.

1.  **Get the Latest Commit Info**: Run the following command in your terminal. This will fetch the latest commit hash and its corresponding SHA256 hash from the `master` branch of the repository.

    ```sh
    nix-shell -p nix-prefetch-git --run 'nix-prefetch-git --url https://evilpiepirate.org/git/bcachefs.git --rev refs/heads/master'
    ```

2.  **Update `bcachefs.nix`**: The command will output a JSON snippet. Copy the `rev` and `hash` values from the output and replace the old ones in your `bcachefs.nix` file.

    For example, if the command outputs:

    ```json
    {
      "url": "https://evilpiepirate.org/git/bcachefs.git",
      "rev": "f00b4r...c0ffee",
      "date": "2025-09-05T12:00:00+00:00",
      "path": "/nix/store/...",
      "sha256": "sha256-n3wH4shValu3...n3wH4shValu3",
      "hash": "sha256-n3wH4shValu3...n3wH4shValu3",
      "fetchLFS": false,
      "fetchSubmodules": false,
      "deepClone": false,
      "leaveDotGit": false
    }
    ```

    You would update these lines in `bcachefs.nix`:

    ```nix
    # bcachefs.nix

    ...
      bcachefs-kernel-src = pkgs.fetchgit {
        name = "linux-kernel-bcachefs";
        url = "https://evilpiepirate.org/git/bcachefs.git";

        # To get the latest commit hash...
        rev = "f00b4r...c0ffee"; # <-- updated
        hash = "sha256-n3wH4shValu3...n3wH4shValu3"; # <-- updated
      };
    ...
    ```

3.  **Rebuild**: Rebuild your NixOS system again to compile and install the new kernel version.
