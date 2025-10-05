{ config, pkgs, inputs, ... }:

{ imports = [ ./hardware-configuration.nix ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-0f4afb55-ff8a-4750-a4e4-0731f389af1a".device = "/dev/disk/by-uuid/0f4afb55-ff8a-4750-a4e4-0731f389af1a";

  # Networking
  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true; # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;

  # Time and Locale
  time.timeZone = "Europe/Bucharest";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ro_RO.UTF-8";
    LC_IDENTIFICATION = "ro_RO.UTF-8";
    LC_MEASUREMENT = "ro_RO.UTF-8";
    LC_MONETARY = "ro_RO.UTF-8";
    LC_NAME = "ro_RO.UTF-8";
    LC_NUMERIC = "ro_RO.UTF-8";
    LC_PAPER = "ro_RO.UTF-8";
    LC_TELEPHONE = "ro_RO.UTF-8";
    LC_TIME = "ro_RO.UTF-8";
  };

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
  ];

  # Nix Settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # X11 Keymap
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Users
  users.users.asdf = {
    isNormalUser = true;
    description = "asdf";
    extraGroups = [ "networkmanager" "wheel" "input"];
    shell = pkgs.nushell;
    packages = with pkgs; [];
  };

  # Automatic Login
  services.getty.autologinUser = "asdf";

  # Hyprland Configuration (Used for both enabling and setting up exec-once)
  programs.hyprland = {
    enable = true;
  };
  
  programs.steam.enable = true;

  # System Packages (Consolidated and Caelestia Shell added)
  environment.systemPackages = with pkgs; [
    ffmpeg
    python3
    python3Packages.mutagen
    mpd
    mpdcron
    tree
    cava
    rmpc
    spotify
    spotify-cli-linux
    neovim
    fastfetch
    evtest
    git
    gh
    starship
    kitty
    zellij
    firefox
    pyprland
    waybar
    tofi
    hyprpaper
    hypridle
    hyprlock
    hyprsunset
    hyprsysteminfo
    wl-clipboard
    swww
    atuin
    fzf
    zoxide
    obs-studio
    obs-cli
    texliveTeTeX
    blender
    mpv
    mpvpaper
    yt-dlp
  ];

  # Kanata
  services.kanata = {
    enable = true;
    keyboards = {
      internalKeyboard = {
        devices = [
          "/dev/input/event0"
        ];
        extraDefCfg = "process-unmapped-keys yes";
        config = ''
          (defsrc
            caps a s d f j k l ;
          )
          (defvar
            tap-time 150
            hold-time 200
          )
          (defalias
            caps (tap-hold 100 100 esc lctl)
            a (tap-hold $tap-time $hold-time a lmet)
            s (tap-hold $tap-time $hold-time s lalt)
            d (tap-hold $tap-time $hold-time d lsft)
            f (tap-hold $tap-time $hold-time f lctl)
            j (tap-hold $tap-time $hold-time j rctl)
            k (tap-hold $tap-time $hold-time k rsft)
            l (tap-hold $tap-time $hold-time l ralt)
            ; (tap-hold $tap-time $hold-time ; rmet)
          )

          (deflayer base
            @caps @a @s @d @f @j @k @l @;
          )
        '';
      };
    };
  };

  # Other Services
  services.openssh.enable = true;

  # This value determines the NixOS release...
  system.stateVersion = "25.05";
}

