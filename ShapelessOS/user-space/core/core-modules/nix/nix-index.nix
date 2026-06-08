{ config, pkgs, lib, ... }:
{
  # # ===========================================================================
  # # NIX-INDEX
  # # ===========================================================================
  # programs.nix-index = {
  #   enable = true;
  #   enableZshIntegration  = true;
  #   enableBashIntegration = true;
  # };
  #
  # # ===========================================================================
  # # NUSHELL: command-not-found handler
  # # ===========================================================================
  # programs.nushell.extraConfig = lib.mkAfter ''
  #   def command_not_found [cmd: string] {
  #     let suggestions = (
  #       nix-locate --whole-name --type x --type s --top-level $"/bin/($cmd)"
  #       | lines
  #     )
  #     if ($suggestions | length) > 0 {
  #       print $"Command '($cmd)' not found. Available in:"
  #       $suggestions | first 5 | each { |pkg| print $"  ($pkg)" }
  #       print "Run with: nix shell nixpkgs#<package>"
  #     } else {
  #       print $"Command '($cmd)' not found."
  #     }
  #   }
  # '';
  #
  # # ===========================================================================
  # # PACKAGES + WRAPPER SCRIPTS
  # # ===========================================================================
  # home.packages = with pkgs; [
  #   nix-index
  #
  #   (writeShellScriptBin "nix-find" ''
  #     if [ $# -eq 0 ]; then
  #       echo "Usage: nix-find <path>"
  #       echo "Example: nix-find bin/ffmpeg"
  #       exit 1
  #     fi
  #     nix-locate "$@"
  #   '')
  #
  #   (writeShellScriptBin "nix-whatprovides" ''
  #     if [ $# -eq 0 ]; then
  #       echo "Usage: nix-whatprovides <command>"
  #       exit 1
  #     fi
  #     nix-locate --whole-name --type x "/bin/$1"
  #   '')
  #
  #   (writeShellScriptBin "nix-search-fast" ''
  #     if [ -t 0 ] && command -v fzf >/dev/null 2>&1; then
  #       nix search nixpkgs "$@" --json \
  #         | jq -r 'keys[]' \
  #         | fzf --preview 'nix eval nixpkgs#{}.meta.description --raw 2>/dev/null'
  #     else
  #       nix search nixpkgs "$@"
  #     fi
  #   '')
  #
  #   # This was using a bash array with ${args[@]} which Nix eats as
  #   # interpolation. Rewritten to use a plain string instead.
  #   (writeShellScriptBin "nix-shell-here" ''
  #     if [ $# -eq 0 ]; then
  #       echo "Usage: nix-shell-here <package> [package...]"
  #       echo "Example: nix-shell-here nodejs python3 git"
  #       exit 1
  #     fi
  #     args=""
  #     for pkg in "$@"; do
  #       args="$args nixpkgs#$pkg"
  #     done
  #     nix shell $args
  #   '')
  #
  #   (writeShellScriptBin "nix-deps" ''
  #     if [ $# -eq 0 ]; then
  #       echo "Usage: nix-deps <package>"
  #       exit 1
  #     fi
  #     store_path=$(nix-build -f '<nixpkgs>' -A "$1" --no-out-link 2>/dev/null)
  #     if [ -n "$store_path" ]; then
  #       nix-store --query --tree "$store_path"
  #     else
  #       echo "Could not resolve '$1'"
  #     fi
  #   '')
  #
  #   (writeShellScriptBin "nix-size-tree" ''
  #     if [ $# -eq 0 ]; then
  #       echo "Usage: nix-size-tree <package>"
  #       exit 1
  #     fi
  #     store_path=$(nix-build -f '<nixpkgs>' -A "$1" --no-out-link 2>/dev/null)
  #     if [ -n "$store_path" ]; then
  #       nix path-info -Shr "$store_path"
  #     else
  #       nix path-info -Shr "nixpkgs#$1"
  #     fi
  #   '')
  # ];
  #
  # # ===========================================================================
  # # ALIASES
  # # ===========================================================================
  # home.shellAliases = {
  #   nf    = "nix-find";
  #   nwp   = "nix-whatprovides";
  #   nsf   = "nix-search-fast";
  #   nsh   = "nix-shell-here";
  #   ndeps = "nix-deps";
  #   nsize = "nix-size-tree";
  #
  #   "nix-i"    = "nix shell nixpkgs#";
  #   "nix-b"    = "nix build nixpkgs#";
  #   "nix-r"    = "nix run nixpkgs#";
  #   "nix-info" = "nix eval --json nixpkgs#";
  #   "nix-desc" = "nix eval --raw nixpkgs#.meta.description";
  #   "nix-ver"  = "nix eval nixpkgs#.version";
  #
  #   "nix-refs"      = "nix-store --query --references";
  #   "nix-referrers" = "nix-store --query --referrers";
  #   "nix-roots"     = "nix-store --gc --print-roots";
  # };
  #
  # # ===========================================================================
  # # NIX-INDEX DATABASE UPDATE (weekly timer)
  # # ===========================================================================
  # systemd.user.services.nix-index-update = {
  #   Unit.Description = "Update nix-index database";
  #   Service = {
  #     Type = "oneshot";
  #     ExecStart = toString (pkgs.writeShellScript "nix-index-update" ''
  #       mkdir -p "$HOME/.cache/nix-index"
  #       curl -sL \
  #         https://github.com/Mic92/nix-index-database/releases/latest/download/index-x86_64-linux \
  #         -o "$HOME/.cache/nix-index/files"
  #     '');
  #   };
  # };
  #
  # systemd.user.timers.nix-index-update = {
  #   Unit.Description = "Update nix-index database weekly";
  #   Timer = {
  #     OnCalendar = "weekly";
  #     Persistent = true;
  #   };
  #   Install.WantedBy = [ "timers.target" ];
  # };
}
