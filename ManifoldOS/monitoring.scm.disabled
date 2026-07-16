;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (core-system user-space root loaders monitoring)
  #:use-module (gnu services)
  #:use-module (gnu services containers)
  #:use-module (guix gexp)
  #:use-module (core-system user-space root monitoring services configuration)
  #:use-module (core-system user-space root monitoring services grafana)
  #:use-module (core-system user-space root monitoring services prometheus)
  #:use-module (core-system user-space root monitoring grafana-tui)
  #:use-module (core-system user-space root monitoring kelora)
  #:re-export (oci-grafana-service-type
               oci-grafana-configuration
               oci-grafana-configuration?
               oci-grafana-configuration-fields
               oci-grafana-configuration-runtime
               oci-grafana-configuration-datadir
               oci-grafana-configuration-image
               oci-grafana-configuration-port
               oci-grafana-configuration-log-file
               oci-grafana-configuration-auto-start?
               oci-grafana-configuration-grafana.ini
               oci-grafana-configuration-network
               oci-grafana-configuration->oci-container-configuration
               grafana-configuration
               grafana-configuration?
               grafana-configuration-fields
               grafana-configuration-server
               grafana-configuration-smtp
               grafana-configuration-extra-content
               grafana-server-configuration
               grafana-server-configuration?
               grafana-server-configuration-fields
               grafana-server-configuration-root-url
               grafana-server-configuration-serve-from-subpath?
               grafana-smtp-configuration
               grafana-smtp-configuration?
               grafana-smtp-configuration-fields
               grafana-smtp-configuration-enabled?
               grafana-smtp-configuration-host
               grafana-smtp-configuration-user
               grafana-smtp-configuration-password
               grafana-smtp-configuration-password-file
               grafana-smtp-configuration-from-address
               oci-prometheus-service-type
               oci-prometheus-configuration
               oci-prometheus-configuration?
               oci-prometheus-configuration-fields
               oci-prometheus-configuration-runtime
               oci-prometheus-configuration-datadir
               oci-prometheus-configuration-network
               oci-prometheus-configuration-file
               oci-prometheus-configuration-record
               oci-prometheus-configuration-image
               oci-prometheus-configuration-log-file
               oci-prometheus-configuration-port
               oci-prometheus-configuration->oci-container-configuration
               prometheus-configuration
               prometheus-configuration?
               prometheus-configuration-fields
               prometheus-configuration-global
               prometheus-configuration-scrape-configs
               prometheus-configuration-retention-time
               prometheus-configuration-retention-size
               prometheus-configuration-extra-content
               prometheus-global-configuration
               prometheus-global-configuration?
               prometheus-global-configuration-fields
               prometheus-global-configuration-scrape-timeout
               prometheus-global-configuration-scrape-interval
               prometheus-global-configuration-extra-content
               prometheus-scrape-configuration
               prometheus-scrape-configuration?
               prometheus-scrape-configuration-fields
               prometheus-scrape-configuration-job-name
               prometheus-scrape-configuration-metrics-path
               prometheus-scrape-configuration-static-configs
               prometheus-scrape-configuration-extra-content
               prometheus-static-configuration
               prometheus-static-configuration?
               prometheus-static-configuration-fields
               prometheus-static-configuration-targets
               prometheus-static-configuration-extra-content
               prometheus-extension
               prometheus-extension?
               prometheus-extension-scrape-jobs
               %prometheus-file
               oci-blackbox-exporter-configuration
               oci-blackbox-exporter-configuration?
               oci-blackbox-exporter-configuration-fields
               oci-blackbox-exporter-configuration-image
               oci-blackbox-exporter-configuration-datadir
               oci-blackbox-exporter-configuration-file
               oci-blackbox-exporter-configuration-network
               oci-blackbox-exporter-configuration-port
                oci-blackbox-exporter-service-type
                grafana-tui
                kelora)
  #:export (root-monitoring-services
            root-monitoring-packages))

(define-public root-monitoring-packages
  (list grafana-tui kelora))

(define-public root-monitoring-services
  (list
   (service oci-prometheus-service-type
            (oci-prometheus-configuration
             (record (prometheus-configuration))))
   (service oci-grafana-service-type)
   (service oci-blackbox-exporter-service-type)))
