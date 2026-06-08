{ config, pkgs, ... }:

{
  # Ensure the uinput group exists
  users.groups.uinput = {};

  # Kanata service configuration
  services.kanata = {
    enable = true;

    keyboards = {
      internalKeyboard = {
        extraDefCfg = "process-unmapped-keys yes";
        config = ''
          (defsrc
           caps a o e u h t n s
          )
          (defvar
           tap-time 150
           hold-time 200
          )
          (defalias
           caps (tap-hold 100 100 esc lctl)
           a (tap-hold $tap-time $hold-time a lmet)
           o (tap-hold $tap-time $hold-time o lalt)
           e (tap-hold $tap-time $hold-time e lsft)
           u (tap-hold $tap-time $hold-time u lctl)
           h (tap-hold $tap-time $hold-time h rctl)
           t (tap-hold $tap-time $hold-time t rsft)
           n (tap-hold $tap-time $hold-time n ralt)
           s (tap-hold $tap-time $hold-time s rmet)
          )
          (deflayer base
           @caps @a @o @e @u @h @t @n @s
          )
        '';
      };
    };
  };
}

