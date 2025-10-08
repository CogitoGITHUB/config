{ config, pkgs,  ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];
  nixpkgs.config.allowUnfree = true;
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
 #
  # Audio
  #
  services.pulseaudio.enable = false; # Use Pipewire, the modern sound subsystem

  security.rtkit.enable = true; # Enable RealtimeKit for audio purposes

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # Uncomment the following line if you want to use JACK applications
    # jack.enable = true;
  };


hardware.bluetooth = {
  enable = true;
  powerOnBoot = true;
  settings = {
    General = {
      # Shows battery charge of connected devices on supported
      # Bluetooth adapters. Defaults to 'false'.
      Experimental = true;
      # When enabled other devices can connect faster to us, however
      # the tradeoff is increased power consumption. Defaults to
      # 'false'.
      FastConnectable = true;
    };
    Policy = {
      # Enable all controllers when they are found. This includes
      # adapters present on start as well as adapters that are plugged
      # in later on. Defaults to 'true'.
      AutoEnable = true;
    };
  };
};


 
# Enable Power Management services
services.upower.enable = true;
services.power-profiles-daemon.enable = true;
 # Nix Settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Users
  users.users.asdf = {
    isNormalUser = true;
    description = "asdf";
    extraGroups = [ "networkmanager" "wheel" "input"];
    shell = pkgs.nushell;
    packages = with pkgs; [];
  };


  # Hyprland Configuration (Used for both enabling and setting up exec-once)
  programs.hyprland = {
    enable = true;
  };



  # Automatic Login
  services.getty.autologinUser = "asdf";

  programs.steam.enable = true;






environment.systemPackages = with pkgs; [
    qutebrowser
    htop
    bluetui
    exiftool
    superfile
    bat
    tmux
    zathura
    nb
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
    jujutsu
    lazyjj
    jj-fzf
    starship
    kitty
    firefox
    pyprland
    waybar
    wofi
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
    blender
    mpv
    mpvpaper
    yt-dlp
    texlive.combined.scheme-full       # full LaTeX distribution
  texlivePackages.latexmk             # latexmk from Texlive
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
            caps a s d f g h j k l ;
          )

          (defvar
            tap-time 150
            hold-time 200
          )
          (defalias
            caps (tap-hold 100 100 esc bspc)
            a (tap-hold $tap-time $hold-time a lmet)
            s (tap-hold $tap-time $hold-time s lalt)
            d (tap-hold $tap-time $hold-time d lsft)
            f (tap-hold $tap-time $hold-time f lctl)
	    g (tap-hold $tap-time $hold-time g ret)

	    h (tap-hold $tap-time $hold-time h spc)
            j (tap-hold $tap-time $hold-time j rctl)
            k (tap-hold $tap-time $hold-time k rsft)
            l (tap-hold $tap-time $hold-time l ralt)
            ; (tap-hold $tap-time $hold-time ; rmet)
          )

          (deflayer base
            @caps @a @s @d @f @g @h @j @k @l @;
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

