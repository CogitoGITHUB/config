{ config, pkgs, lib, ... }:
let
  dashboardsDir = "/etc/grafana-dashboards";
in
{
  #######
  # Grafana
  #######
  services.grafana = {
    enable = true;

    declarativePlugins = with pkgs.grafanaPlugins; [
      yesoreyeram-infinity-datasource
      grafana-piechart-panel
    ];

    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
        domain = "localhost";
      };

      security = {
        admin_user = "admin";
        admin_password = "admin";
      };

      users = {
        allow_sign_up = false;
        auto_assign_org = true;
        auto_assign_org_role = "Admin";
      };

      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
      };

      log = {
        mode = "console";
        level = "info";
      };
    };

    provision = {
      enable = true;

      dashboards.settings.providers = [
        {
          name = "local-dashboards";
          type = "file";
          disableDeletion = true;
          editable = true;
          options = {
            path = dashboardsDir;
            foldersFromFilesStructure = true;
          };
        }
      ];

      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://127.0.0.1:9090";
          isDefault = true;
          editable = false;
        }

        {
          name = "Loki";
          type = "loki";
          url = "http://127.0.0.1:3100";
          editable = false;
        }

        {
          name = "Infinity";
          type = "yesoreyeram-infinity-datasource";
          editable = false;
        }
      ];
    };
  };

  #######
  # Prometheus (metrics)
  #######
  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9090;

    scrapeConfigs = [
      {
        job_name = "prometheus";
        static_configs = [
          { targets = [ "127.0.0.1:9090" ]; }
        ];
      }

      {
        job_name = "node";
        static_configs = [
          { targets = [ "127.0.0.1:9100" ]; }
        ];
      }
    ];
  };

  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "127.0.0.1";
  };

  #######
  # Loki (logs)
  #######
  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;

      server = {
        http_listen_address = "127.0.0.1";
        http_listen_port = 3100;
        grpc_listen_port = 9096;
      };

      common = {
        path_prefix = "/var/lib/loki";
        storage = {
          filesystem = {
            chunks_directory = "/var/lib/loki/chunks";
            rules_directory = "/var/lib/loki/rules";
          };
        };
        replication_factor = 1;
        ring.kvstore.store = "inmemory";
      };

      schema_config.configs = [
        {
          from = "2023-01-01";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index.prefix = "index_";
          index.period = "24h";
        }
      ];
    };
  };

  #######
  # Promtail (log shipper)
  #######
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_address = "127.0.0.1";
        http_listen_port = 9080;
      };

      positions.filename = "/tmp/promtail-positions.yaml";

      clients = [
        { url = "http://127.0.0.1:3100/loki/api/v1/push"; }
      ];

      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = "laptop";
            };
          };
          relabel_configs = [
            {
              source_labels = [ "__journal__systemd_unit" ];
              target_label = "unit";
            }
          ];
        }
      ];
    };
  };


  #######
  # Firewall: closed by default
  #######
  networking.firewall.allowedTCPPorts = [ ];
}
