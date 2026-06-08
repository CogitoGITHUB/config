{ config, pkgs, ... }:

{
  # Disable Pulseaudio
  services.pulseaudio.enable = false;

  # Real-time kit for audio priorities
  security.rtkit.enable = true;

  # PipeWire configuration
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
}
