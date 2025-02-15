# -*- coding: utf-8 -*-
# vim: ft=sls syntax=yaml softtabstop=2 tabstop=2 shiftwidth=2 expandtab autoindent

{% from "vault/map.jinja" import vault with context %}

vault-package-install-group-present:
  group.present:
    - name: vault
    - system: True

vault-package-install-user-present:
  user.present:
    - name: vault
    - system: True
    - gid: vault
    - home: /var/lib/vault
    - require:
      - group: vault-package-install-group-present

vault-package-etc:
  file.directory:
    - name: /etc/vault
    - mode: 0755
    - user: vault
    - group: vault
    - require:
      - user: vault-package-install-user-present

vault-package-etc-conf:
  file.directory:
    - name: /etc/vault/conf.d
    - mode: 0750
    - user: vault
    - group: vault
    - require:
      - file: vault-package-etc

vault-var-directory:
  file.directory:
    - name: /var/lib/vault
    - mode: 0755
    - user: vault
    - group: vault
    - require:
      - user: vault-package-install-user-present

vault-var-tls-directory:
  file.directory:
    - name: /var/lib/vault/tls
    - mode: 0755
    - user: vault
    - group: vault
    - require:
      - file: vault-var-directory

vault-var-data-directory:
  file.directory:
    - name: /var/lib/vault/data
    - mode: 0750
    - user: vault
    - group: vault
    - require:
      - file: vault-var-directory

vault-var-log-directory:
  file.directory:
    - name: /var/log/vault
    - mode: 0750
    - user: vault
    - group: vault
    - require:
      - user: vault-package-install-user-present

vault-package-install-file-directory:
  file.directory:
    - name: /opt/vault/v{{ vault.version }}
    - makedirs: True

vault-package-install-file-managed:
  file.managed:
    - name: /opt/vault/{{ vault.version }}_SHA256SUMS
    - source: https://releases.hashicorp.com/vault/{{ vault.version }}/vault_{{ vault.version }}_SHA256SUMS
    - skip_verify: True
    - makedirs: True

vault-package-install-service-dead:
  service.dead:
    - name: vault
    - onchanges:
      - file: vault-package-install-file-managed
    - onlyif: test -f /etc/systemd/system/vault.service

vault-package-install-archive-extracted:
  archive.extracted:
    - name: /opt/vault/v{{ vault.version }}
    - source: https://releases.hashicorp.com/vault/{{ vault.version }}/vault_{{ vault.version }}_{{ vault.platform }}.zip
    - source_hash: https://releases.hashicorp.com/vault/{{ vault.version }}/vault_{{ vault.version }}_SHA256SUMS
    - source_hash_name: vault_{{ vault.version }}_{{ vault.platform }}.zip
    - enforce_toplevel: False
    - overwrite: True
    - onchanges:
      - file: vault-package-install-file-managed

vault-package-install-file-symlink:
  file.symlink:
    - name: /usr/local/bin/vault
    - target: /opt/vault/v{{ vault.version }}/vault
    - force: true

vault-package-install-pkg-installed:
  pkg.installed:
    - name: {{ vault.setcap_pkg }}

vault-package-install-cmd-run:
  cmd.run:
    - name: setcap cap_ipc_lock=+ep /opt/vault/v{{ vault.version }}/vault
    - require:
      - pkg: vault-package-install-pkg-installed
    - onchanges:
      - archive: vault-package-install-archive-extracted
