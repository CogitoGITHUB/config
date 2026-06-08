{ config, pkgs, ... }:

{
  # Timezone
  time.timeZone = "Europe/Bucharest";

  # Base locale
  i18n.defaultLocale = "en_US.UTF-8";

  # Regional overrides
  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "ro_RO.UTF-8";
    LC_IDENTIFICATION = "ro_RO.UTF-8";
    LC_MEASUREMENT    = "ro_RO.UTF-8";
    LC_MONETARY       = "ro_RO.UTF-8";
    LC_NAME           = "ro_RO.UTF-8";
    LC_NUMERIC        = "ro_RO.UTF-8";
    LC_PAPER          = "ro_RO.UTF-8";
    LC_TELEPHONE      = "ro_RO.UTF-8";
    LC_TIME           = "ro_RO.UTF-8";
  };
}
