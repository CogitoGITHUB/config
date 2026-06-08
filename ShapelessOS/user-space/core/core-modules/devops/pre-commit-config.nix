{ config, pkgs, lib, ... }:
{
  # # ===========================================================================
  # # PRE-COMMIT
  # # ===========================================================================
  # # The global template at ~/.pre-commit-config.yaml is a bit of a footgun —
  # # pre-commit looks for the config in the repo root, not in $HOME.
  # # Moved it to a proper templates location. Use pc-init to copy it into a repo.
  # home.file.".config/pre-commit/templates/nixos.yaml".text = ''
  #   repos:
  #     - repo: https://github.com/pre-commit/pre-commit-hooks
  #       rev: v4.5.0
  #       hooks:
  #         - id: trailing-whitespace
  #           exclude: "\.patch$"
  #         - id: end-of-file-fixer
  #           exclude: "\.patch$"
  #         - id: check-json
  #         - id: check-toml
  #         - id: check-yaml
  #           args: [--allow-multiple-documents]
  #         - id: check-added-large-files
  #           args: [--maxkb=500]
  #         - id: check-case-conflict
  #         - id: check-executables-have-shebangs
  #         - id: check-shebang-scripts-are-executable
  #         - id: check-merge-conflict
  #         - id: detect-private-key
  #         - id: forbid-new-submodules
  #
  #     - repo: https://github.com/nix-community/nixpkgs-fmt
  #       rev: v1.3.0
  #       hooks:
  #         - id: nixpkgs-fmt
  #
  #     - repo: local
  #       hooks:
  #         - id: statix
  #           name: statix (nix linter)
  #           entry: statix check
  #           language: system
  #           files: "\.nix$"
  #           pass_filenames: false
  #
  #         - id: deadnix
  #           name: deadnix (dead code)
  #           entry: deadnix --edit
  #           language: system
  #           files: "\.nix$"
  #
  #         - id: shellcheck
  #           name: shellcheck
  #           entry: shellcheck --severity=warning
  #           language: system
  #           files: "\.sh$"
  #
  #         # pre-push only — these are slow
  #         - id: nix-flake-check
  #           name: nix flake check
  #           entry: nix flake check
  #           language: system
  #           pass_filenames: false
  #           always_run: true
  #           stages: [pre-push]
  #
  #         - id: nixos-rebuild-dry-run
  #           name: nixos-rebuild dry-run
  #           entry: doas nixos-rebuild dry-build --flake .
  #           language: system
  #           pass_filenames: false
  #           always_run: true
  #           stages: [pre-push]
  # '';
  #
  # home.file.".config/pre-commit/templates/nix-project.yaml".text = ''
  #   repos:
  #     - repo: https://github.com/pre-commit/pre-commit-hooks
  #       rev: v4.5.0
  #       hooks:
  #         - id: trailing-whitespace
  #         - id: end-of-file-fixer
  #         - id: check-added-large-files
  #           args: [--maxkb=500]
  #
  #     - repo: https://github.com/nix-community/nixpkgs-fmt
  #       rev: v1.3.0
  #       hooks:
  #         - id: nixpkgs-fmt
  #
  #     - repo: local
  #       hooks:
  #         - id: statix
  #           name: statix
  #           entry: statix check
  #           language: system
  #           files: "\.nix$"
  #           pass_filenames: false
  #
  #         - id: nix-build
  #           name: nix build check
  #           entry: nix build --no-link
  #           language: system
  #           pass_filenames: false
  #           always_run: true
  #           stages: [pre-push]
  # '';
  #
  # home.file.".config/pre-commit/templates/python.yaml".text = ''
  #   repos:
  #     - repo: https://github.com/pre-commit/pre-commit-hooks
  #       rev: v4.5.0
  #       hooks:
  #         - id: trailing-whitespace
  #         - id: end-of-file-fixer
  #         - id: check-yaml
  #         - id: check-added-large-files
  #
  #     - repo: https://github.com/psf/black
  #       rev: 23.12.1
  #       hooks:
  #         - id: black
  #           language_version: python3
  #
  #     - repo: https://github.com/pycqa/isort
  #       rev: 5.13.2
  #       hooks:
  #         - id: isort
  #           args: ["--profile", "black"]
  #
  #     - repo: https://github.com/pycqa/flake8
  #       rev: 6.1.0
  #       hooks:
  #         - id: flake8
  #           args: [--max-line-length=88, --extend-ignore=E203]
  #
  #     - repo: https://github.com/pre-commit/mirrors-mypy
  #       rev: v1.7.1
  #       hooks:
  #         - id: mypy
  #           additional_dependencies: [types-all]
  # '';
  #
  # home.file.".config/pre-commit/templates/rust.yaml".text = ''
  #   repos:
  #     - repo: https://github.com/pre-commit/pre-commit-hooks
  #       rev: v4.5.0
  #       hooks:
  #         - id: trailing-whitespace
  #         - id: end-of-file-fixer
  #
  #     - repo: https://github.com/doublify/pre-commit-rust
  #       rev: v1.0
  #       hooks:
  #         - id: fmt
  #         - id: cargo-check
  #         - id: clippy
  # '';
  #
  # # ===========================================================================
  # # PACKAGES
  # # ===========================================================================
  # home.packages = with pkgs; [
  #   pre-commit
  #   statix
  #   deadnix
  #   shellcheck
  #   shfmt
  #
  #   (writeShellScriptBin "pc-init" ''
  #     if [ ! -d .git ]; then
  #       echo "Not a git repository"
  #       exit 1
  #     fi
  #
  #     TEMPLATE_DIR="$HOME/.config/pre-commit/templates"
  #
  #     if [ ! -f .pre-commit-config.yaml ]; then
  #       echo "Available templates:"
  #       ls "$TEMPLATE_DIR"/*.yaml 2>/dev/null | while read f; do
  #         echo "  $(basename "$f" .yaml)"
  #       done
  #       echo ""
  #       echo "Usage: pc-init <template>"
  #       echo "Example: pc-init nixos"
  #       exit 1
  #     fi
  #
  #     # If a template name was given and no config exists yet, copy it
  #     if [ -n "$1" ] && [ ! -f .pre-commit-config.yaml ]; then
  #       local src="$TEMPLATE_DIR/$1.yaml"
  #       if [ -f "$src" ]; then
  #         cp "$src" .pre-commit-config.yaml
  #         echo "Copied $1 template"
  #       else
  #         echo "Template '$1' not found in $TEMPLATE_DIR"
  #         exit 1
  #       fi
  #     fi
  #
  #     pre-commit install
  #     pre-commit install --hook-type pre-push
  #     pre-commit install-hooks
  #     echo "Done. Run 'pre-commit run --all-files' to test."
  #   '')
  #
  #   (writeShellScriptBin "pc-check" ''
  #     pre-commit run --all-files
  #   '')
  #
  #   (writeShellScriptBin "pc-update" ''
  #     pre-commit autoupdate
  #   '')
  # ];
  #
  # ===========================================================================
  # ALIASES
  # ===========================================================================
  # home.shellAliases = {
  #   pci  = "pc-init";
  #   pcc  = "pc-check";
  #   pcu  = "pc-update";
  #   pcr  = "pre-commit run";
  #   pcra = "pre-commit run --all-files";
  # };
}
