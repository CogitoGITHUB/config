{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    tree sops age pass ollama rofi cargo docker lazydocker docker-compose
    k3s kubectl helm k9s gemini-cli opencode ardour lmms hydrogen
    fluidsynth supercollider sox sonic-pi qemu waydroid waydroid-nftables
    waydroid-helper krita gimp inkscape blender emacs neovim gcc cmake
    libtool tree-sitter nodejs python3 python3Packages.mutagen zellij
    wezterm starship nushell qutebrowser nyxt zathura mpv mpvpaper yt-dlp
    ffmpeg mpd mpdcron cava rmpc git lazygit gh bat lsd htop fastfetch
    bluetui exiftool evtest wl-clipboard atuin fzf zoxide obs-studio obs-cli
    texlive.combined.scheme-full texlivePackages.latexmk ghostscript texinfo
    poppler zip wget lua-language-server pyright nodePackages.typescript-language-server
    texlab libnotify
  ];
}
