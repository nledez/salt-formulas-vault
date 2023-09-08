# -*- coding: utf-8 -*-
# vim: ft=sls syntax=yaml softtabstop=2 tabstop=2 shiftwidth=2 expandtab autoindent

include:
  - .package
  - .tls
  - .config
  - .service

extend:
  vault-service-init-service-running:
    service:
      - watch:
        - file: vault-config-config-file
        - file: vault-config-systemd-env
